/mob/living/carbon/human/necromorph/Initialize(mapload, obj/structure/marker/marker_master)
	.=..()

	if(!marker_master)
		return INITIALIZE_HINT_QDEL

	fully_replace_character_name(real_name, dna.species.random_name())

	marker = marker_master
	marker_master.add_necro(src)
	var/datum/necro_class/temp = marker_master.necro_classes[class]
	temp.load_data(src)
	set_health(temp.max_health)

/mob/living/carbon/human/necromorph/Destroy()
	evacuate()
	marker?.remove_necro(src)
	return ..()

/mob/living/carbon/human/necromorph/has_hand_for_held_index(i)
	return FALSE

/mob/living/carbon/human/necromorph/updatehealth()
	. = ..()
	if(hud_used)
		var/datum/hud/necromorph/hud = hud_used
		hud.update_healthbar(src)

/mob/living/carbon/human/necromorph/revive(full_heal = FALSE, admin_revive = FALSE, excess_healing = 0)
	.=..()
	marker?.add_necro(src)

/mob/living/carbon/human/necromorph/update_stat()
	. = ..()
	if(.)
		return

	if(status_flags & GODMODE)
		return

	if(stat == DEAD)
		return

	if(health <= 0)
		death()
		return

	if(HAS_TRAIT(src, TRAIT_KNOCKEDOUT))
		if(stat == UNCONSCIOUS)
			return
		set_stat(UNCONSCIOUS)
	else if(stat == UNCONSCIOUS)
		set_stat(CONSCIOUS)

/mob/living/carbon/human/necromorph/proc/handle_death_check()
	return TRUE

/mob/living/carbon/human/necromorph/set_stat(new_stat)
	.=..()
	if(stat < UNCONSCIOUS)
		see_in_dark = conscious_see_in_dark
	else
		see_in_dark = unconscious_see_in_dark

/mob/living/carbon/human/necromorph/update_sight()
	. = ..()
	if(stat < UNCONSCIOUS)
		see_in_dark = conscious_see_in_dark
	else if (stat < HARD_CRIT)
		see_in_dark = unconscious_see_in_dark
	//Otherwise we are dead and see_in_dark was handled in parent call

/mob/living/carbon/human/necromorph/death(gibbed)
	if(stat == DEAD)
		return
	stop_sound_channel(CHANNEL_HEARTBEAT)
	var/obj/item/organ/heart/H = getorganslot(ORGAN_SLOT_HEART)
	if(H)
		H.beat = BEAT_NONE

	silent = FALSE
	losebreath = 0

	if(!gibbed)
		INVOKE_ASYNC(src, .proc/emote, "deathgasp")
	reagents.end_metabolization(src)

	add_memory_in_range(src, 7, MEMORY_DEATH, list(DETAIL_PROTAGONIST = src), story_value = STORY_VALUE_MEH, memory_flags = MEMORY_CHECK_BLIND_AND_DEAF)

	set_stat(DEAD)
	unset_machine()
	timeofdeath = world.time
	tod = stationtime2text()
	evacuate()
	set_disgust(0)
	SetSleeping(0, 0)
	reset_perspective(null)
	reload_fullscreen()
	update_mob_action_buttons()
	update_damage_hud()
	update_health_hud()
	med_hud_set_health()
	med_hud_set_status()
	stop_pulling()

	set_ssd_indicator(FALSE)
	set_typing_indicator(FALSE)

	SEND_SIGNAL(src, COMSIG_LIVING_DEATH, gibbed)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_MOB_DEATH, src, gibbed)

	if (client)
		client.move_delay = initial(client.move_delay)

	if(!gibbed)
		attach_rot()

	for(var/T in get_traumas())
		var/datum/brain_trauma/BT = T
		BT.on_death()

	if(!QDELETED(dna)) //The gibbed param is bit redundant here since dna won't exist at this point if they got deleted.
		dna.species.spec_death(gibbed, src)

	if(SSticker.HasRoundStarted())
		SSblackbox.ReportDeath(src)
		log_message("has died (BRUTE: [src.getBruteLoss()], BURN: [src.getFireLoss()], TOX: [src.getToxLoss()], OXY: [src.getOxyLoss()], CLONE: [src.getCloneLoss()])", LOG_ATTACK)

	marker?.remove_necro(src)

// VENTCRAWLING
// Handles the entrance and exit on ventcrawling
// Copy paste of the /mob/living/proc/handle_ventcrawl()
// I've changed do_after() time and remove var/required_nudity
/mob/living/carbon/human/necromorph/handle_ventcrawl(obj/machinery/atmospherics/components/ventcrawl_target)
	// Cache the vent_movement bitflag var from atmos machineries
	var/vent_movement = ventcrawl_target.vent_movement

	if(!Adjacent(ventcrawl_target))
		return
	if(!HAS_TRAIT(src, TRAIT_VENTCRAWLER_NUDE) && !HAS_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS))
		return
	if(stat)
		to_chat(src, span_warning("You must be conscious to do this!"))
		return
	if(HAS_TRAIT(src, TRAIT_IMMOBILIZED))
		to_chat(src, span_warning("You currently can't move into the vent!"))
		return
	if(HAS_TRAIT(src, TRAIT_HANDS_BLOCKED))
		to_chat(src, span_warning("You need to be able to use your hands to ventcrawl!"))
		return
	if(has_buckled_mobs())
		to_chat(src, span_warning("You can't vent crawl with other creatures on you!"))
		return
	if(buckled)
		to_chat(src, span_warning("You can't vent crawl while buckled!"))
		return
	if(ventcrawl_target.welded)
		to_chat(src, span_warning("You can't crawl around a welded vent!"))
		return

	if(vent_movement & VENTCRAWL_ENTRANCE_ALLOWED)
		//Handle the exit here
		if(HAS_TRAIT(src, TRAIT_MOVE_VENTCRAWLING) && istype(loc, /obj/machinery/atmospherics) && movement_type & VENTCRAWLING)
			visible_message(span_notice("[src] begins climbing out from the ventilation system...") ,span_notice("You begin climbing out from the ventilation system..."))
			if(!client)
				return
			if(!do_after(src, vent_exit_speed, target = ventcrawl_target.loc))
				return
			visible_message(span_notice("[src] scrambles out from the ventilation ducts!"),span_notice("You scramble out from the ventilation ducts."))
			forceMove(ventcrawl_target.loc)
			REMOVE_TRAIT(src, TRAIT_MOVE_VENTCRAWLING, VENTCRAWLING_TRAIT)
			update_pipe_vision()

		//Entrance here
		else
			var/datum/pipeline/vent_parent = ventcrawl_target.parents[1]
			if(vent_parent && (vent_parent.members.len || vent_parent.other_atmos_machines))
				flick_overlay_static(image('icons/effects/vent_indicator.dmi', "arrow", ABOVE_MOB_LAYER, dir = get_dir(src.loc, ventcrawl_target.loc)), ventcrawl_target, 2 SECONDS)
				visible_message(span_notice("[src] begins climbing into the ventilation system...") ,span_notice("You begin climbing into the ventilation system..."))
				if(!client)
					return
				if(!do_after(src, vent_enter_speed, target = ventcrawl_target))
					return
				flick_overlay_static(image('icons/effects/vent_indicator.dmi', "insert", ABOVE_MOB_LAYER), ventcrawl_target, 1 SECONDS)
				visible_message(span_notice("[src] scrambles into the ventilation ducts!"),span_notice("You climb into the ventilation ducts."))
				move_into_vent(ventcrawl_target)
			else
				to_chat(src, span_warning("This ventilation duct is not connected to anything!"))

/mob/living/carbon/human/necromorph/create_dna()
	dna = new /datum/dna(src)
	dna.species = new necro_species

/mob/living/carbon/human/necromorph/update_stat()
	if(status_flags & GODMODE)
		return
	if(stat != DEAD)
		if(health <= 0 && !HAS_TRAIT(src, TRAIT_NODEATH))
			death()
			return
		else
			set_stat(CONSCIOUS)
	update_damage_hud()
	update_health_hud()
	update_stamina_hud()
	med_hud_set_status()

//Controversial, might bring back combat modes later
//Change ability keybinds if ever planned to bring back combat modes
/mob/living/carbon/human/necromorph/set_combat_mode(new_mode, silent)
	return
