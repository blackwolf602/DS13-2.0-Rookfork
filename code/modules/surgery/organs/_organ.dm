
/obj/item/organ
	name = "organ"
	icon = 'icons/obj/surgery.dmi'
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	//Default value from 1.0
	biomass = 1
	///The mob that owns this organ.
	var/mob/living/carbon/owner = null
	///The body zone this organ is supposed to inhabit.
	var/zone = BODY_ZONE_CHEST
	///The organ slot this organ is supposed to inhabit. This should be unique by type. (Lungs, Appendix, Stomach, etc)
	var/slot
	// DO NOT add slots with matching names to different zones - it will break organs_by_slot list!
	var/organ_flags = ORGAN_EDIBLE
	var/maxHealth = STANDARD_ORGAN_THRESHOLD
	/// Total damage this organ has sustained
	/// Should only ever be modified by applyOrganDamage
	var/damage = 0
	///Healing factor and decay factor function on % of maxhealth, and do not work by applying a static number per tick
	var/healing_factor = 0 //fraction of maxhealth healed per on_life(), set to 0 for generic organs
	var/decay_factor = 0 //same as above but when without a living owner, set to 0 for generic organs
	var/high_threshold = STANDARD_ORGAN_THRESHOLD * 0.7 //when severe organ damage occurs
	var/low_threshold = STANDARD_ORGAN_THRESHOLD * 0.3 //when minor organ damage occurs
	var/severe_cooldown //cooldown for severe effects, used for synthetic organ emp effects.
	///Organ variables for determining what we alert the owner with when they pass/clear the damage thresholds
	var/prev_damage = 0
	var/low_threshold_passed
	var/high_threshold_passed
	var/now_failing
	var/now_fixed
	var/high_threshold_cleared
	var/low_threshold_cleared

	///When you take a bite you cant jam it in for surgery anymore.
	var/useable = TRUE
	var/list/food_reagents = list(/datum/reagent/consumable/nutriment = 5)
	///The size of the reagent container
	var/reagent_vol = 10

	var/failure_time = 0

	///Do we effect the appearance of our mob. Used to save time in preference code
	var/visual = FALSE
	///If the organ is cosmetic only, it loses all organ functionality.
	var/cosmetic_only = FALSE
	/// Traits that are given to the holder of the organ. If you want an effect that changes this, don't add directly to this. Use the add_organ_trait() proc
	var/list/organ_traits = list()

// Players can look at prefs before atoms SS init, and without this
// they would not be able to see external organs, such as moth wings.
// This is also necessary because assets SS is before atoms, and so
// any nonhumans created in that time would experience the same effect.
INITIALIZE_IMMEDIATE(/obj/item/organ)

/obj/item/organ/Initialize(mapload, mob_sprite)
	. = ..()
	if(organ_flags & ORGAN_EDIBLE)
		AddComponent(/datum/component/edible,\
			initial_reagents = food_reagents,\
			foodtypes = RAW | MEAT | GROSS,\
			volume = reagent_vol,\
			after_eat = CALLBACK(src, PROC_REF(OnEatFrom)))

	if(cosmetic_only) //Cosmetic organs don't process.
		if(mob_sprite)
			set_sprite(mob_sprite)

		if(!(organ_flags & ORGAN_UNREMOVABLE))
			color = "#[random_color()]" //A temporary random color that gets overwritten on insertion.
	else
		START_PROCESSING(SSobj, src)
		organ_flags |= ORGAN_CUT_AWAY

/obj/item/organ/Destroy(force)
	if(owner)
		// The special flag is important, because otherwise mobs can die
		// while undergoing transformation into different mobs.
		Remove(owner, special=TRUE)

	if(ownerlimb)
		ownerlimb.remove_organ(src)

	if(!cosmetic_only)
		STOP_PROCESSING(SSobj, src)

	return ..()

/// A little hack to ensure old behavior.
/obj/item/organ/ex_act(severity, target)
	if(ownerlimb)
		return
	return ..()

/*
 * Insert the organ into the select mob.
 *
 * reciever - the mob who will get our organ
 * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 * drop_if_replaced - if there's an organ in the slot already, whether we drop it afterwards
 */
/obj/item/organ/proc/Insert(mob/living/carbon/reciever, special = FALSE, drop_if_replaced = TRUE)
	if(!iscarbon(reciever) || owner == reciever)
		return FALSE

	var/obj/item/bodypart/limb
	limb = reciever.get_bodypart(deprecise_zone(zone))
	if(!limb)
		return FALSE

	var/obj/item/organ/replaced = reciever.getorganslot(slot)
	if(replaced)
		replaced.Remove(reciever, special = TRUE)
		if(drop_if_replaced)
			replaced.forceMove(get_turf(reciever))
		else
			qdel(replaced)

	organ_flags &= ~ORGAN_CUT_AWAY

	SEND_SIGNAL(src, COMSIG_ORGAN_IMPLANTED, reciever)
	SEND_SIGNAL(reciever, COMSIG_CARBON_GAIN_ORGAN, src, special)

	owner = reciever
	moveToNullspace()
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(on_owner_examine))
	update_organ_traits(reciever)
	for(var/datum/action/action as anything in actions)
		action.Grant(reciever)

	//Add to internal organs
	owner.organs |= src
	owner.organs_by_slot[slot] = src

	if(!cosmetic_only)
		STOP_PROCESSING(SSobj, src)
		owner.processing_organs |= src
		/// processing_organs must ALWAYS be ordered in the same way as organ_process_order
		/// Otherwise life processing breaks down
		sortTim(owner.processing_organs, GLOBAL_PROC_REF(cmp_organ_slot_asc))

	if(ownerlimb)
		ownerlimb.remove_organ(src)
	limb.add_organ(src)
	forceMove(limb)

	if(visual)
		if(!stored_feature_id && reciever.dna?.features) //We only want this set *once*
			stored_feature_id = reciever.dna.features[feature_key]

		reciever.cosmetic_organs.Add(src)
		reciever.update_body_parts()
	return TRUE


/*
 * Remove the organ from the select mob.
 *
 * organ_owner - the mob who owns our organ, that we're removing the organ from.
 * special - "quick swapping" an organ out - when TRUE, the mob will be unaffected by not having that organ for the moment
 */
/obj/item/organ/proc/Remove(mob/living/carbon/organ_owner, special = FALSE)
	if(!istype(organ_owner))
		CRASH("Tried to remove an organ with no owner argument.")

	UnregisterSignal(owner, COMSIG_PARENT_EXAMINE)

	owner = null
	for(var/datum/action/action as anything in actions)
		action.Remove(organ_owner)

	for(var/trait in organ_traits)
		REMOVE_TRAIT(organ_owner, trait, REF(src))

	SEND_SIGNAL(src, COMSIG_ORGAN_REMOVED, organ_owner)
	SEND_SIGNAL(organ_owner, COMSIG_CARBON_LOSE_ORGAN, src, special)

	organ_flags |= ORGAN_CUT_AWAY

	organ_owner.organs -= src
	if(organ_owner.organs_by_slot[slot] == src)
		organ_owner.organs_by_slot.Remove(slot)

	if(!cosmetic_only)
		if((organ_flags & ORGAN_VITAL) && !special && !(organ_owner.status_flags & GODMODE))
			organ_owner.death()
		organ_owner.processing_organs -= src
		START_PROCESSING(SSobj, src)

	if(ownerlimb)
		ownerlimb.remove_organ(src)

	if(visual)
		organ_owner.cosmetic_organs.Remove(src)
		organ_owner.update_body_parts()

/// Cut an organ away from it's container, but do not remove it from the container physically.
/obj/item/organ/proc/cut_away()
	if(!ownerlimb)
		return

	var/obj/item/bodypart/old_owner = ownerlimb
	Remove(owner)
	old_owner.add_cavity_item(src)

/// Updates the traits of the organ on the specific organ it is called on. Should be called anytime an organ is given a trait while it is already in a body.
/obj/item/organ/proc/update_organ_traits()
	for(var/trait in organ_traits)
		ADD_TRAIT(owner, trait, REF(src))

/// Add a trait to an organ that it will give its owner.
/obj/item/organ/proc/add_organ_trait(trait)
	organ_traits += trait
	update_organ_traits()

/// Removes a trait from an organ, and by extension, its owner.
/obj/item/organ/proc/remove_organ_trait(trait)
	organ_traits -= trait
	REMOVE_TRAIT(owner, trait, REF(src))

/obj/item/organ/proc/on_owner_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	return

/obj/item/organ/proc/on_find(mob/living/finder)
	return

/obj/item/organ/process(delta_time, times_fired)
	if(cosmetic_only)
		CRASH("Cosmetic organ processing!")
	on_death(delta_time, times_fired) //Kinda hate doing it like this, but I really don't want to call process directly.


/// This is on_life() but for when the organ is dead or outside of a mob. Bad name.
/obj/item/organ/proc/on_death(delta_time, times_fired)
	if(organ_flags & (ORGAN_SYNTHETIC | ORGAN_FROZEN))
		return
	applyOrganDamage(decay_factor * maxHealth * delta_time)

/// Called once every life tick on every organ in a carbon's body
/// NOTE: THIS IS VERY HOT. Be careful what you put in here
/// To give you some scale, if there's 100 carbons in the game, they each have maybe 9 organs
/// So that's 900 calls to this proc every life process. Please don't be dumb
/obj/item/organ/proc/on_life(delta_time, times_fired)
	if(cosmetic_only)
		CRASH("Cosmetic organ processing!")

	if(organ_flags & ORGAN_FAILING)
		handle_failing_organs(delta_time)
		return

	if(failure_time > 0)
		failure_time--

	if(organ_flags & ORGAN_SYNTHETIC_EMP) //Synthetic organ has been emped, is now failing.
		applyOrganDamage(decay_factor * maxHealth * delta_time)
		return

	if(!damage) // No sense healing if you're not even hurt bro
		return

	///Damage decrements by a percent of its maxhealth
	var/healing_amount = healing_factor
	///Damage decrements again by a percent of its maxhealth, up to a total of 4 extra times depending on the owner's health
	healing_amount += (owner.satiety > 0) ? (4 * healing_factor * owner.satiety / MAX_SATIETY) : 0
	applyOrganDamage(-healing_amount * maxHealth * delta_time, damage) // pass curent damage incase we are over cap

/obj/item/organ/examine(mob/user)
	. = ..()

	. += span_notice("It should be inserted in the [parse_zone(zone)].")

	if(organ_flags & ORGAN_FAILING)
		if(organ_flags & ORGAN_SYNTHETIC)
			. += span_warning("[src] seems to be broken.")
			return
		. += span_warning("[src] has decayed for too long, and has turned a sickly color. It probably won't work without repairs.")
		return

	if(damage > high_threshold)
		. += span_warning("[src] is starting to look discolored.")

///Used as callbacks by object pooling
/obj/item/organ/proc/exit_wardrobe()
	if(!cosmetic_only)
		START_PROCESSING(SSobj, src)

//See above
/obj/item/organ/proc/enter_wardrobe()
	if(!cosmetic_only)
		STOP_PROCESSING(SSobj, src)

/obj/item/organ/proc/OnEatFrom(eater, feeder)
	useable = FALSE //You can't use it anymore after eating it you spaztic

/obj/item/organ/item_action_slot_check(slot,mob/user)
	return //so we don't grant the organ's action to mobs who pick up the organ.

///Adjusts an organ's damage by the amount "damage_amount", up to a maximum amount, which is by default max damage
/obj/item/organ/proc/applyOrganDamage(damage_amount, maximum = maxHealth) //use for damaging effects
	if(!damage_amount || cosmetic_only) //Micro-optimization.
		return
	if(maximum < damage)
		return
	damage = clamp(damage + damage_amount, 0, maximum)
	var/mess = check_damage_thresholds(owner)
	check_failing_thresholds()
	prev_damage = damage
	if(owner && owner.stat <= SOFT_CRIT && !(organ_flags & ORGAN_SYNTHETIC) && damage_amount > 0 && (damage_amount > 5 || prob(10)))
		if(!mess)
			var/obj/item/bodypart/BP = loc
			if(!BP)
				return
			var/degree = ""
			if(damage > high_threshold)
				degree = " a lot"
			else if(damage < low_threshold)
				degree = " a bit"
			mess = span_warning("Something inside your [BP.plaintext_zone] hurts[degree].")
		to_chat(owner, mess)

///SETS an organ's damage to the amount "damage_amount", and in doing so clears or sets the failing flag, good for when you have an effect that should fix an organ if broken
/obj/item/organ/proc/setOrganDamage(damage_amount) //use mostly for admin heals
	applyOrganDamage(damage_amount - damage)

/** check_damage_thresholds
 * input: mob/organ_owner (a mob, the owner of the organ we call the proc on)
 * output: returns a message should get displayed.
 * description: By checking our current damage against our previous damage, we can decide whether we've passed an organ threshold.
 *  If we have, send the corresponding threshold message to the owner, if such a message exists.
 */
/obj/item/organ/proc/check_damage_thresholds(mob/organ_owner)
	if(damage == prev_damage)
		return
	var/delta = damage - prev_damage
	if(delta > 0)
		if(damage >= maxHealth)
			return now_failing
		if(damage > high_threshold && prev_damage <= high_threshold)
			return high_threshold_passed
		if(damage > low_threshold && prev_damage <= low_threshold)
			return low_threshold_passed
	else
		if(prev_damage > low_threshold && damage <= low_threshold)
			return low_threshold_cleared
		if(prev_damage > high_threshold && damage <= high_threshold)
			return high_threshold_cleared
		if(prev_damage == maxHealth)
			return now_fixed

///Checks if an organ should/shouldn't be failing and gives the appropriate organ flag
/obj/item/organ/proc/check_failing_thresholds()
	if(damage >= maxHealth)
		set_organ_failing(TRUE)
	else if(damage < maxHealth)
		set_organ_failing(FALSE)

/// Set or unset the organ as failing. Returns TRUE on success.
/obj/item/organ/proc/set_organ_failing(failing)
	if(failing)
		if(organ_flags & ORGAN_FAILING)
			return FALSE
		organ_flags |= ORGAN_FAILING
		return TRUE
	else
		if(organ_flags & ORGAN_FAILING)
			organ_flags &= ~ORGAN_FAILING
			return TRUE

//Looking for brains?
//Try code/modules/mob/living/carbon/brain/brain_item.dm

/mob/living/proc/regenerate_organs()
	return FALSE

/mob/living/carbon/regenerate_organs()
	if(dna?.species)
		dna.species.regenerate_organs(src)
		return

	else
		var/obj/item/organ/lungs/lungs = getorganslot(ORGAN_SLOT_LUNGS)
		if(!lungs)
			lungs = new()
			lungs.Insert(src)
		lungs.setOrganDamage(0)

		var/obj/item/organ/heart/heart = getorganslot(ORGAN_SLOT_HEART)
		if(!heart)
			heart = new()
			heart.Insert(src)
		heart.setOrganDamage(0)

		var/obj/item/organ/tongue/tongue = getorganslot(ORGAN_SLOT_TONGUE)
		if(!tongue)
			tongue = new()
			tongue.Insert(src)
		tongue.setOrganDamage(0)

		var/obj/item/organ/eyes/eyes = getorganslot(ORGAN_SLOT_EYES)
		if(!eyes)
			eyes = new()
			eyes.Insert(src)
		eyes.setOrganDamage(0)

		var/obj/item/organ/ears/ears = getorganslot(ORGAN_SLOT_EARS)
		if(!ears)
			ears = new()
			ears.Insert(src)
		ears.setOrganDamage(0)

/obj/item/organ/proc/handle_failing_organs(delta_time)
	if(owner.stat == DEAD)
		return

	failure_time += delta_time
	organ_failure(delta_time)

/** organ_failure
 * generic proc for handling dying organs
 *
 * Arguments:
 * delta_time - seconds since last tick
 */
/obj/item/organ/proc/organ_failure(delta_time)
	return

/** get_availability
 * returns whether the species should innately have this organ.
 *
 * regenerate organs works with generic organs, so we need to get whether it can accept certain organs just by what this returns.
 * This is set to return true or false, depending on if a species has a specific organless trait. stomach for example checks if the species has NOSTOMACH and return based on that.
 * Arguments:
 * owner_species - species, needed to return whether the species has an organ specific trait
 */
/obj/item/organ/proc/get_availability(datum/species/owner_species)
	return TRUE

/// Called before organs are replaced in regenerate_organs with new ones
/obj/item/organ/proc/before_organ_replacement(obj/item/organ/replacement)
	return

/// Called by medical scanners to get a simple summary of how healthy the organ is. Returns an empty string if things are fine.
/obj/item/organ/proc/get_scan_results(tag)
	RETURN_TYPE(/list)
	SHOULD_CALL_PARENT(TRUE)
	. = list()

	if(organ_flags & ORGAN_FAILING)
		. += tag ?"<span style='font-weight: bold; color:#cc3333'>Non-Functional</span>" : "Non-Functional"

	if(owner.has_reagent(/datum/reagent/technetium))
		. += tag ? "<span style='font-weight: bold; color:#E42426'> organ is [round((damage/maxHealth)*100, 1)]% damaged.</span>" : "[round((damage/maxHealth)*100, 1)]"
	else if(damage > high_threshold)
		. +=  tag ?"<span style='font-weight: bold; color:#ff9933'>Severely Damaged</span>" : "Severely Damaged"
	else if (damage > low_threshold)
		. += tag ?"<span style='font-weight: bold; color:#ffcc33'>Mildly Damaged</span>" : "Mildly Damaged"

	return
