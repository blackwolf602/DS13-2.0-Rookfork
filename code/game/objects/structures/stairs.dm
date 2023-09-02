#define STAIR_TERMINATOR_AUTOMATIC 0
#define STAIR_TERMINATOR_NO 1
#define STAIR_TERMINATOR_YES 2

// dir determines the direction of travel to go upwards
// multiple stair objects can be chained together; the Z level transition will happen on the final stair object in the chain

/obj/structure/stairs
	name = "stairs"
	icon = 'icons/obj/stairs.dmi'
	icon_state = "stairs"
	anchored = TRUE
	loc_procs = EXIT

	var/terminator_mode = STAIR_TERMINATOR_AUTOMATIC
	var/turf/listeningTo

/obj/structure/stairs/north
	dir = NORTH

/obj/structure/stairs/south
	dir = SOUTH

/obj/structure/stairs/east
	dir = EAST

/obj/structure/stairs/west
	dir = WEST

/obj/structure/stairs/Initialize(mapload)
	GLOB.stairs += src
	update_surrounding()
	return ..()

/obj/structure/stairs/Destroy()
	listeningTo = null
	GLOB.stairs -= src
	return ..()

/obj/structure/stairs/Move() //Look this should never happen but...
	. = ..()
	update_surrounding()

/obj/structure/stairs/proc/update_surrounding()
	update_appearance()
	for(var/i in GLOB.cardinals)
		var/turf/T = get_step(get_turf(src), i)
		var/obj/structure/stairs/S = locate() in T
		if(S)
			S.update_appearance()

/obj/structure/stairs/Exit(atom/movable/leaving, direction)
	. = ..()
	if(!isobserver(leaving) && isTerminator() && direction == dir)
		leaving.set_currently_z_moving(CURRENTLY_Z_ASCENDING)
		INVOKE_ASYNC(src, PROC_REF(stair_ascend), leaving)
		leaving.Bump(src)
		return FALSE

/obj/structure/stairs/Cross(atom/movable/AM)
	if(isTerminator() && (get_dir(src, AM) == dir))
		return FALSE
	return ..()

/obj/structure/stairs/update_icon_state()
	icon_state = "stairs[isTerminator() ? "_t" : null]"
	return ..()

/obj/structure/stairs/proc/stair_ascend(atom/movable/climber)
	var/turf/my_turf = get_turf(src)
	var/turf/checking = GetAbove(my_turf)
	if(!istype(checking))
		return

	var/turf/target = get_step_multiz(my_turf, (dir|UP))
	if(!target)
		to_chat(climber, span_notice("There is nothing of interest in that direction."))
		return

	if(!checking.CanZPass(climber, UP, ZMOVE_STAIRS_FLAGS))
		to_chat(climber, span_warning("Something blocks the path."))
		return

	if(!target.Enter(climber))
		to_chat(climber, span_warning("Something blocks the path."))
		return

	climber.forceMove(target)
	if(!(climber.throwing || (climber.movement_type & (VENTCRAWLING | FLYING)) || HAS_TRAIT(climber, TRAIT_IMMOBILIZED)))
		playsound(my_turf, 'sound/effects/stairs_step.ogg', 50)
		playsound(my_turf, 'sound/effects/stairs_step.ogg', 50)

	/// Moves anything that's being dragged by src or anything buckled to it to the stairs turf.
	climber.pulling?.move_from_pull(climber, loc, climber.glide_size)
	for(var/mob/living/buckled as anything in climber.buckled_mobs)
		buckled.pulling?.move_from_pull(buckled, loc, buckled.glide_size)

/obj/structure/stairs/intercept_zImpact(list/falling_movables, levels = 1)
	. = ..()
	if(levels == 1 && isTerminator()) // Stairs won't save you from a steep fall.
		. |= FALL_INTERCEPTED | FALL_NO_MESSAGE | FALL_RETAIN_PULL

/obj/structure/stairs/proc/isTerminator() //If this is the last stair in a chain and should move mobs up
	if(terminator_mode != STAIR_TERMINATOR_AUTOMATIC)
		return (terminator_mode == STAIR_TERMINATOR_YES)
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	var/turf/them = get_step(T, dir)
	if(!them)
		return FALSE
	for(var/obj/structure/stairs/S in them)
		if(S.dir == dir)
			return FALSE
	return TRUE
