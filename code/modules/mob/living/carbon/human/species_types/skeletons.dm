/datum/species/skeleton
	// 2spooky
	name = "\improper Spooky Scary Skeleton"
	id = SPECIES_SKELETON
	say_mod = "rattles"
	sexes = 0
	meat = /obj/item/food/meat/slab/human/mutant/skeleton
	species_traits = list(NOBLOOD, HAS_BONE, NOTRANSSTING, NOEYESPRITES, NO_DNA_COPY)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_CAN_STRIP,
		TRAIT_NOMETABOLISM,
		TRAIT_TOXIMMUNE,
		TRAIT_RESISTHEAT,
		TRAIT_NOBREATH,
		TRAIT_RESISTCOLD,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_RADIMMUNE,
		TRAIT_GENELESS,
		TRAIT_PIERCEIMMUNE,
		TRAIT_NOHUNGER,
		TRAIT_EASYDISMEMBER,
		TRAIT_LIMBATTACHMENT,
		TRAIT_FAKEDEATH,
		TRAIT_XENO_IMMUNE,
		TRAIT_NOCLONELOSS,
		TRAIT_CAN_USE_FLIGHT_POTION,
	)
	inherent_biotypes = MOB_UNDEAD|MOB_HUMANOID
	mutanttongue = /obj/item/organ/tongue/bone
	mutantstomach = /obj/item/organ/stomach/bone
	disliked_food = NONE
	liked_food = GROSS | MEAT | RAW
	wings_icons = list("Skeleton")
	//They can technically be in an ERT
	changesource_flags = MIRROR_BADMIN | WABBAJACK | ERT_SPAWN
	species_cookie = /obj/item/reagent_containers/food/condiment/milk
	species_language_holder = /datum/language_holder/skeleton

	bodypart_overrides = list(
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/skeleton,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/skeleton,
		BODY_ZONE_HEAD = /obj/item/bodypart/head/skeleton,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/skeleton,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/skeleton,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/skeleton,
	)

/datum/species/skeleton/on_species_gain(mob/living/carbon/C, datum/species/old_species, pref_load)
	. = ..()
	C.set_safe_hunger_level()

/datum/species/skeleton/check_roundstart_eligible()
	if(SSevents.holidays && SSevents.holidays[HALLOWEEN])
		return TRUE
	return ..()

/datum/species/skeleton/get_species_description()
	return "A rattling skeleton! They descend upon Space Station 13 \
		Every year to spook the crew! \"I've got a BONE to pick with you!\""

/datum/species/skeleton/get_species_lore()
	return list(
		"Skeletons want to be feared again! Their presence in media has been destroyed, \
		or at least that's what they firmly believe. They're always the first thing fought in an RPG, \
		they're Flanderized into pun rolling JOKES, and it's really starting to get to them. \
		You could say they're deeply RATTLED. Hah."
	)
