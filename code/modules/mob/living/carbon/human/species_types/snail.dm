/datum/species/snail
	name = "\improper Snailperson"
	id = SPECIES_SNAIL
	offset_features = list(OFFSET_GLASSES = list(0,4))
	default_color = "336600" //vomit green
	species_traits = list(MUTCOLORS, NO_UNDERWEAR, HAS_FLESH, HAS_BONE)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_CAN_STRIP,
		TRAIT_NO_SLIP_ALL,
	)

	say_mod = "slurs"
	coldmod = 0.5 //snails only come out when its cold and wet
	burnmod = 2
	speedmod = 6
	siemens_coeff = 2 //snails are mostly water
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | RACE_SWAP
	sexes = FALSE //snails are hermaphrodites

	mutanteyes = /obj/item/organ/eyes/snail
	mutanttongue = /obj/item/organ/tongue/snail
	exotic_blood = /datum/reagent/lube

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/snail,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/snail,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/snail,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/snail,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/snail,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/snail
	)

/datum/species/snail/on_species_gain(mob/living/carbon/C, datum/species/old_species, pref_load)
	. = ..()
	var/obj/item/storage/backpack/bag = C.get_item_by_slot(ITEM_SLOT_BACK)
	if(!istype(bag, /obj/item/storage/backpack/snail))
		if(C.dropItemToGround(bag)) //returns TRUE even if its null
			C.equip_to_slot_or_del(new /obj/item/storage/backpack/snail(C), ITEM_SLOT_BACK)
	C.AddElement(/datum/element/snailcrawl)

/datum/species/snail/on_species_loss(mob/living/carbon/C)
	. = ..()
	C.RemoveElement(/datum/element/snailcrawl)
	var/obj/item/storage/backpack/bag = C.get_item_by_slot(ITEM_SLOT_BACK)
	if(istype(bag, /obj/item/storage/backpack/snail))
		bag.emptyStorage()
		C.temporarilyRemoveItemFromInventory(bag, TRUE)
		qdel(bag)

/obj/item/storage/backpack/snail
	name = "snail shell"
	desc = "Worn by snails as armor and storage compartment."
	icon_state = "snailshell"
	inhand_icon_state = "snailshell"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'
	armor = list(MELEE = 40, BULLET = 30, LASER = 30, ENERGY = 10, BOMB = 25, BIO = 0, FIRE = 0, ACID = 50)
	max_integrity = 200
	resistance_flags = FIRE_PROOF | ACID_PROOF
	supports_variations_flags = NONE

/obj/item/storage/backpack/snail/dropped(mob/user, silent)
	. = ..()
	emptyStorage()
	if(!QDELETED(src))
		qdel(src)

/obj/item/storage/backpack/snail/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, "snailshell")
