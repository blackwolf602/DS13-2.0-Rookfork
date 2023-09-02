// Describes the three modes of scanning available for health analyzers
#define SCANMODE_HEALTH 0
#define SCANMODE_SURGERY 1
#define SCANMODE_CHEM 2
#define SCANMODE_COUNT 3 // Update this to be the number of scan modes if you add more
#define SCANNER_CONDENSED 0
#define SCANNER_VERBOSE 1

/obj/item/healthanalyzer
	name = "health analyzer"
	icon = 'icons/obj/device.dmi'
	icon_state = "health"
	inhand_icon_state = "healthanalyzer"
	worn_icon_state = "healthanalyzer"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	desc = "A hand-held body scanner capable of distinguishing vital signs of the subject. Can be toggled to scan for chemicals or wounds."
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/iron=200)
	var/mode = SCANNER_VERBOSE
	var/scanmode = SCANMODE_HEALTH
	var/advanced = FALSE
	custom_price = PAYCHECK_HARD

/obj/item/healthanalyzer/Initialize(mapload)
	. = ..()
	if(advanced)
		register_item_context()

/obj/item/healthanalyzer/examine(mob/user)
	. = ..()
	. += span_notice("Alt-click [src] to toggle the limb damage readout.")

/obj/item/healthanalyzer/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins to analyze [user.p_them()]self with [src]! The display shows that [user.p_theyre()] dead!"))
	return BRUTELOSS

/obj/item/healthanalyzer/attack_self(mob/user)
	if(!advanced)
		scanmode = (scanmode + 1) % (SCANMODE_COUNT - 1)
		switch(scanmode)
			if(SCANMODE_HEALTH)
				to_chat(user, span_notice("You switch the health analyzer to check physical health."))
			if(SCANMODE_SURGERY)
				to_chat(user, span_notice("You switch the health analyzer to output surgerical information."))
		return

	scanmode = (scanmode + 1) % SCANMODE_COUNT
	switch(scanmode)
		if(SCANMODE_HEALTH)
			to_chat(user, span_notice("You switch the health analyzer to check physical health."))
		if(SCANMODE_CHEM)
			to_chat(user, span_notice("You switch the health analyzer to scan chemical contents."))
		if(SCANMODE_SURGERY)
			to_chat(user, span_notice("You switch the health analyzer to output surgerical information."))

/obj/item/healthanalyzer/attack(mob/living/M, mob/living/carbon/human/user)
	flick("[icon_state]-scan", src) //makes it so that it plays the scan animation upon scanning, including clumsy scanning

	// Clumsiness/brain damage check
	if ((HAS_TRAIT(user, TRAIT_CLUMSY) || HAS_TRAIT(user, TRAIT_DUMB)) && prob(50))
		user.visible_message(span_warning("[user] analyzes the floor's vitals!"), \
							span_notice("You stupidly try to analyze the floor's vitals!"))
		to_chat(user, "[span_info("Analyzing results for The floor:\n\tOverall status: <b>Healthy</b>")]\
				\n[span_info("Key: <font color='#00cccc'>Suffocation</font>/<font color='#00cc66'>Toxin</font>/<font color='#ffcc33'>Burn</font>/<font color='#ff3333'>Brute</font>")]\
				\n[span_info("\tDamage specifics: <font color='#66cccc'>0</font>-<font color='#00cc66'>0</font>-<font color='#ff9933'>0</font>-<font color='#ff3333'>0</font>")]\
				\n[span_info("Body temperature: ???")]")
		return

	if(ispodperson(M)&& !advanced)
		to_chat(user, "<span class='info'>[M]'s biological structure is too complex for the health analyzer.")
		return

	playsound(user, 'sound/items/healthanalyzer.ogg', 50, 1)

	user.visible_message(span_notice("[user] analyzes [M]'s vitals."), \
						span_notice("You analyze [M]'s vitals."))

	switch (scanmode)
		if (SCANMODE_HEALTH)
			healthscan(user, M, advanced, mode)
		if (SCANMODE_CHEM)
			chemscan(user, M)
		if (SCANMODE_SURGERY)
			surgericalscan(user, M)

	add_fingerprint(user)
	playsound(user, 'sound/machines/ping.ogg', 50, FALSE)

/obj/item/healthanalyzer/add_item_context(
	obj/item/source,
	list/context,
	atom/target,
)
	if (!isliving(target) || !advanced)
		return NONE

	switch (scanmode)
		if (SCANMODE_HEALTH)
			context[SCREENTIP_CONTEXT_LMB] = "Scan health"
		if (SCANMODE_CHEM)
			context[SCREENTIP_CONTEXT_LMB] = "Scan chemicals"

	return CONTEXTUAL_SCREENTIP_SET

/proc/healthscan(mob/living/user, mob/living/target, advanced = FALSE, verbose = SCANNER_VERBOSE, chat = TRUE)
	var/list/data_string_list = list("<b>Scan results for [target]:</b>\n\n")

	// Time of death
	if(target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH))
		data_string_list += span_warning("<b>Time of Death:</b> [stationtime2text("hh:mm", target.timeofdeath)]\n")

	// Temperature
	data_string_list += "Body temperature: [target.bodytemperature - T0C]&deg;C ([FAHRENHEIT(target.bodytemperature)]&deg;F)\n"

	// Health
	if(target.getBruteLoss() > 50)
		data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_BRUTE]'>Severe brute trauma detected.</span>\n"

	if(target.getFireLoss() > 50)
		data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_BURN]'>Severe burn damage detected.</span>\n"

	if(target.getOxyLoss() > 50)
		data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_OXYLOSS]'>Severe oxygen deprivation detected.</span>\n"

	if(target.getToxLoss() > 50)
		data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_TOXIN]'>Severe bloodstream intoxicification detected.</span>\n"

	if(target.blood_volume < BLOOD_VOLUME_SAFE)
		data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL]'>Severe bloodloss detected.</span>\n"

	if(iscarbon(target))
		var/mob/living/carbon/carbon_target = target
		if(carbon_target.undergoing_cardiac_arrest())
			data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL_DANGER]'>Patient is suffering from cardiovascular shock. Administer CPR immediately.</span>\n"

		// Brain
		var/obj/item/organ/brain/brain = carbon_target.getorganslot(ORGAN_SLOT_BRAIN)
		var/brain_activity = brain ? ((brain.maxHealth - brain.damage) / brain.maxHealth * 100) : -1
		switch(brain_activity)
			if(-1)
				brain_activity = span_bad("brain not found")

			if(0)
				brain_activity = span_bad("patient is braindead")

			if(1 to 24)
				brain_activity = span_bad("fading")

			if(25 to 49)
				brain_activity = span_bad("extremely weak")

			if(50 to 74)
				brain_activity = span_mild("weak")

			if(75 to 99)
				brain_activity = span_average("minor brain damage")

			if(100)
				brain_activity = span_good("normal")

			else
				brain_activity = span_warning("ERROR - hardware failure")

		data_string_list += "Brain activity: [brain_activity].\n"

		// Arteries, tendons, and embeds
		if(!advanced)
			var/found_bleed = FALSE
			var/found_tendon = FALSE
			for(var/obj/item/bodypart/limb as anything in carbon_target.bodyparts)
				if(!found_bleed && (limb.check_artery() == CHECKARTERY_SEVERED))
					data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL_DANGER]'>Arterial bleeding detected. Advanced scanner required for location.</span>\n"
					found_bleed = TRUE

				if(!found_tendon && (limb.check_tendon() == CHECKTENDON_SEVERED))
					data_string_list += "<span style='font-weight: bold; color: [COLOR_MEDICAL_LIGAMENT]'>Tendon or ligament damage detected. Advanced scanner required for location.</span>\n"
					found_tendon = TRUE

				if(found_bleed && found_tendon)
					break

		else
			var/artery_string = ""
			var/tendon_string = ""
			for(var/obj/item/bodypart/limb as anything in carbon_target.bodyparts)
				if(limb.check_artery() == CHECKARTERY_SEVERED)
					artery_string += "<span style='font-weight: bold; color: [COLOR_MEDICAL_INTERNAL_DANGER]'>Arterial bleeding detected in subject's [limb.plaintext_zone].</span>\n"

				if(limb.check_tendon() == CHECKTENDON_SEVERED)
					tendon_string += "<span style='font-weight: bold; color: [COLOR_MEDICAL_LIGAMENT]'>Tendon or ligament damage detected in subject's [limb.plaintext_zone].</span>\n"

			if(artery_string)
				data_string_list += artery_string
			if(tendon_string)
				data_string_list += tendon_string

		// Limb damage
		if(verbose)
			data_string_list += span_bold("\nSpecific limb damage:\n")
			var/list/damaged_limbs = carbon_target.get_damaged_bodyparts(TRUE, TRUE, check_flags = BP_TENDON_CUT|BP_ARTERY_CUT|BP_BROKEN_BONES|BP_BLEEDING)
			if(!length(damaged_limbs))
				data_string_list += "No detectable limb injuries.\n"

			sortTim(damaged_limbs, GLOBAL_PROC_REF(cmp_bodyparts_display_order))

			for(var/obj/item/bodypart/limb as anything in damaged_limbs)
				var/limb_string = "[capitalize(limb.plaintext_zone)][!IS_ORGANIC_LIMB(limb) ? " <span style='font-weight: bold; color: [COLOR_MEDICAL_ROBOTIC]'>(Cybernetic)</span>" : ""]:"
				if(limb.brute_dam)
					limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BRUTE]'>[advanced ? "[limb.brute_dam]" + " points of" : get_wound_severity(limb.brute_ratio)] physical trauma</span>\]"

				if(limb.burn_dam)
					limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BURN]'>[advanced ? "[limb.burn_dam]" + " points of": get_wound_severity(limb.burn_ratio)] burns</span>\]"

				if(limb.bodypart_flags & BP_BLEEDING)
					limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BRUTE]'>bleeding</span>\]"

				if(limb.bodypart_flags & BP_BROKEN_BONES)
					limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BROKEN]'>fractured</span>\]"
				data_string_list += (limb_string + "\n")


	SEND_SIGNAL(target, COMSIG_LIVING_HEALTHSCAN, data_string_list, user, verbose, advanced)

	if(chat)
		to_chat(user, examine_block(jointext(data_string_list, "")), trailing_newline = FALSE, type = MESSAGE_TYPE_INFO)

	return jointext(data_string_list, "")

/proc/chemscan(mob/living/user, mob/living/target)
	if(user.incapacitated())
		return

	if(user.is_blind())
		to_chat(user, span_warning("You realize that your scanner has no accessibility support for the blind!"))
		return

	if(istype(target) && target.reagents)
		var/render_list = list()

		// Blood reagents
		if(target.reagents.reagent_list.len)
			render_list += "<span class='notice ml-1'>Subject contains the following reagents in their blood:</span>\n"
			for(var/r in target.reagents.reagent_list)
				var/datum/reagent/reagent = r
				if(reagent.chemical_flags & REAGENT_INVISIBLE) //Don't show hidden chems on scanners
					continue
				render_list += "<span class='notice ml-2'>[round(reagent.volume, 0.001)] units of [reagent.name][reagent.overdosed ? "</span> - [span_boldannounce("OVERDOSING")]" : ".</span>"]\n"
		else
			render_list += "<span class='notice ml-1'>Subject contains no reagents in their blood.</span>\n"

		// Stomach reagents
		var/obj/item/organ/stomach/belly = target.getorganslot(ORGAN_SLOT_STOMACH)
		if(belly)
			if(belly.reagents.reagent_list.len)
				render_list += "<span class='notice ml-1'>Subject contains the following reagents in their stomach:</span>\n"
				for(var/bile in belly.reagents.reagent_list)
					var/datum/reagent/bit = bile
					if(bit.chemical_flags & REAGENT_INVISIBLE) //Don't show hidden chems on scanners
						continue
					if(!belly.food_reagents[bit.type])
						render_list += "<span class='notice ml-2'>[round(bit.volume, 0.001)] units of [bit.name][bit.overdosed ? "</span> - [span_boldannounce("OVERDOSING")]" : ".</span>"]\n"
					else
						var/bit_vol = bit.volume - belly.food_reagents[bit.type]
						if(bit_vol > 0)
							render_list += "<span class='notice ml-2'>[round(bit_vol, 0.001)] units of [bit.name][bit.overdosed ? "</span> - [span_boldannounce("OVERDOSING")]" : ".</span>"]\n"
			else
				render_list += "<span class='notice ml-1'>Subject contains no reagents in their stomach.</span>\n"

		// Addictions
		if(LAZYLEN(target.mind?.active_addictions))
			render_list += "<span class='boldannounce ml-1'>Subject is addicted to the following types of drug:</span>\n"
			for(var/datum/addiction/addiction_type as anything in target.mind.active_addictions)
				render_list += "<span class='alert ml-2'>[initial(addiction_type.name)]</span>\n"

		// Special eigenstasium addiction
		if(target.has_status_effect(/datum/status_effect/eigenstasium))
			render_list += "<span class='notice ml-1'>Subject is temporally unstable. Stabilising agent is recommended to reduce disturbances.</span>\n"

		// Allergies
		for(var/datum/quirk/quirky as anything in target.quirks)
			if(istype(quirky, /datum/quirk/item_quirk/allergic))
				var/datum/quirk/item_quirk/allergic/allergies_quirk = quirky
				var/allergies = allergies_quirk.allergy_string
				render_list += "<span class='alert ml-1'>Subject is extremely allergic to the following chemicals:</span>\n"
				render_list += "<span class='alert ml-2'>[allergies]</span>\n"

		// we handled the last <br> so we don't need handholding
		to_chat(user, examine_block(jointext(render_list, "")), trailing_newline = FALSE, type = MESSAGE_TYPE_INFO)

/obj/item/healthanalyzer/AltClick(mob/user)
	..()

	if(!user.canUseTopic(src, BE_CLOSE))
		return

	mode = !mode
	to_chat(user, mode == SCANNER_VERBOSE ? "The scanner now shows specific limb damage." : "The scanner no longer shows limb damage.")

/obj/item/healthanalyzer/advanced
	name = "advanced health analyzer"
	icon_state = "health_adv"
	desc = "A hand-held body scanner able to distinguish vital signs of the subject with high accuracy."
	advanced = TRUE

/// Displays wounds with extended information on their status vs medscanners
/proc/woundscan(mob/user, mob/living/carbon/patient, obj/item/healthanalyzer/wound/scanner, advanced = FALSE)
	if(!istype(patient) || user.incapacitated())
		return

	if(user.is_blind())
		to_chat(user, span_warning("You realize that your scanner has no accessibility support for the blind!"))
		return

	var/data_string_list = ""
	var/list/damaged_limbs = patient.get_damaged_bodyparts(TRUE, TRUE)
	if(!length(damaged_limbs))
		data_string_list += "No detectable limb injuries.\n"

	sortTim(damaged_limbs, GLOBAL_PROC_REF(cmp_bodyparts_display_order))

	for(var/obj/item/bodypart/limb as anything in damaged_limbs)
		var/limb_string = "[capitalize(limb.body_zone)][(limb.bodytype & BODYTYPE_ROBOTIC) ? " <span style='font-weight: bold; color: [COLOR_MEDICAL_ROBOTIC]'>(Cybernetic)</span>" : ""]:"
		if(limb.brute_dam)
			limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BRUTE]'>[advanced ? "[limb.brute_dam]" + " points of" : get_wound_severity(limb.brute_ratio)] physical trauma</span>\]"

		if(limb.burn_dam)
			limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BURN]'>[advanced ? "[limb.burn_dam]" + " points of": get_wound_severity(limb.burn_ratio)] burns</span>\]"

		if(limb.bodypart_flags & BP_BLEEDING)
			limb_string += " \[<span style='font-weight: bold; color: [COLOR_MEDICAL_BRUTE]'>bleeding</span>\]"

		data_string_list += (limb_string + "\n")

	if(data_string_list == "")
		if(istype(scanner))
			// Only emit the cheerful scanner message if this scan came from a scanner
			to_chat(user, span_notice("[scanner] makes a happy ping and briefly displays a smiley face with several exclamation points! It's really excited to report that [patient] has no wounds!"))
		else
			to_chat(user, "<span class='notice ml-1'>No wounds detected in subject.</span>")
	else
		to_chat(user, jointext(data_string_list, ""), type = MESSAGE_TYPE_INFO)

/proc/surgericalscan(mob/living/user, mob/living/carbon/target)
	if(!istype(target) || user.incapacitated())
		return

	if(user.is_blind())
		to_chat(user, span_warning("You realize that your scanner has no accessibility support for the blind!"))
		return

	var/list/data = list()
	for(var/obj/item/bodypart/BP as anything in sort_list(target.bodyparts, GLOBAL_PROC_REF(cmp_bodyparts_display_order)))
		var/list/bodypart_data = list()
		bodypart_data += "<span class='notice ml-1'>[capitalize(BP.plaintext_zone)]: </span>"
		switch(BP.how_open())
			if(SURGERY_CLOSED)
				bodypart_data += "<b>\[[span_good("CLOSED")]\]</b>"
			if(SURGERY_OPEN)
				bodypart_data += "<b>\[[span_mild("INCISED")]\]</b>"
			if(SURGERY_RETRACTED)
				bodypart_data += "<b>\[[span_average("RETRACTED")]\]</b>"
			if(SURGERY_DEENCASED)
				bodypart_data += "<b>\[[span_average("RETRACTED")]\] \[[span_bad("DEENCASED")]\]</b>"

		if(length(BP.wounds) && BP.clamped())
			bodypart_data += "<b>\[[span_mild("CLAMPED")]\]</b>"
		data += jointext(bodypart_data, " ")

	to_chat(user, jointext(data, "<br>"), type = MESSAGE_TYPE_INFO)

/obj/item/healthanalyzer/wound
	name = "first aid analyzer"
	icon_state = "adv_spectrometer"
	desc = "A prototype MeLo-Tech medical scanner used to diagnose injuries and recommend treatment for serious wounds, but offers no further insight into the patient's health. You hope the final version is less annoying to read!"
	var/next_encouragement
	var/greedy

/obj/item/healthanalyzer/wound/attack_self(mob/user)
	if(next_encouragement < world.time)
		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		var/list/encouragements = list("briefly displays a happy face, gazing emptily at you", "briefly displays a spinning cartoon heart", "displays an encouraging message about eating healthy and exercising", \
				"reminds you that everyone is doing their best", "displays a message wishing you well", "displays a sincere thank-you for your interest in first-aid", "formally absolves you of all your sins")
		to_chat(user, span_notice("\The [src] makes a happy ping and [pick(encouragements)]!"))
		next_encouragement = world.time + 10 SECONDS
		greedy = FALSE
	else if(!greedy)
		to_chat(user, span_warning("\The [src] displays an eerily high-definition frowny face, chastizing you for asking it for too much encouragement."))
		greedy = TRUE
	else
		playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
		if(isliving(user))
			var/mob/living/L = user
			to_chat(L, span_warning("\The [src] makes a disappointed buzz and pricks your finger for being greedy. Ow!"))
			L.adjustBruteLoss(4)
			L.dropItemToGround(src)

/obj/item/healthanalyzer/wound/attack(mob/living/carbon/patient, mob/living/carbon/human/user)
	add_fingerprint(user)
	user.visible_message(span_notice("[user] scans [patient] for serious injuries."), span_notice("You scan [patient] for serious injuries."))

	if(!istype(patient))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		to_chat(user, span_notice("\The [src] makes a sad buzz and briefly displays a frowny face, indicating it can't scan [patient]."))
		return

	woundscan(user, patient, src)

#undef SCANMODE_HEALTH
#undef SCANMODE_CHEM
#undef SCANMODE_SURGERY
#undef SCANMODE_COUNT
#undef SCANNER_CONDENSED
#undef SCANNER_VERBOSE

// Calculates severity based on the ratios defined external limbs.
/proc/get_wound_severity(damage_ratio, can_heal_overkill = FALSE)
	var/degree

	switch(damage_ratio)
		if(0 to 0.1)
			degree = "minor"
		if(0.1 to 0.25)
			degree = "moderate"
		if(0.25 to 0.5)
			degree = "significant"
		if(0.5 to 0.75)
			degree = "severe"
		if(0.75 to 1)
			degree = "extreme"
		else
			if(can_heal_overkill)
				degree = "critical"
			else
				degree = "irreparable"

	return degree
