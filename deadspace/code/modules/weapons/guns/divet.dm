/**
Divet pistols
*/
//This is most handguns and bolt action rifles.  The bolt will lock back when it's empty.  You need yourgun_bolt and yourgun_bolt_locked icon states.
/obj/item/gun/ballistic/automatic/pistol/divet
	name = "divet pistol"
	desc = "A Winchester Arms NK-series pistol capable of fully automatic fire."
	icon = 'deadspace/icons/obj/weapons/ds13guns.dmi'
	icon_state = "divet"
	lefthand_file = 'deadspace/icons/mob/onmob/items/lefthand_guns.dmi'
	righthand_file = 'deadspace/icons/mob/onmob/items/righthand_guns.dmi'
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/divet
	can_suppress = TRUE
	actions_types = list(/datum/action/item_action/toggle_firemode)
	slot_flags = ITEM_SLOT_BELT|ITEM_SLOT_POCKETS
	burst_size = 3
	fire_delay = 4
	dual_wield_spread = 6
	firing_burst = TRUE
	fire_sound= 'deadspace/sound/weapons/guns/divet_fire.ogg'
	load_sound = 'deadspace/sound/weapons/guns/divet_magin.ogg'  //Old noises from 1.0, but weren't actually working and used before.
	eject_sound = 'deadspace/sound/weapons/guns/divet_magout.ogg' //They just sound like clockwork cult sounds.
	suppressed_sound = 'sound/weapons/gun/general/heavy_shot_suppressed.ogg'

/obj/item/gun/ballistic/automatic/pistol/divet/no_mag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/pistol/divet/rb/Initialize(mapload)
	magazine = new /obj/item/ammo_box/magazine/divet/rb(src)
	return ..()

/obj/item/gun/ballistic/automatic/pistol/divet/extended/Initialize(mapload)
	magazine = new /obj/item/ammo_box/magazine/divet/extended(src)
	return ..()

/obj/item/gun/ballistic/automatic/pistol/divet/extended/expanded/Initialize(mapload)
	magazine = new /obj/item/ammo_box/magazine/divet/extended/expanded(src)
	return ..()

/obj/item/gun/ballistic/automatic/pistol/divet/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.3 SECONDS)

/obj/item/gun/ballistic/automatic/pistol/divet/suppressed/Initialize(mapload)//Off chance you want a normal suppressed divet. Might not work.
	. = ..()
	var/obj/item/suppressor/S = new(src)
	install_suppressor(S)

/obj/item/gun/ballistic/automatic/pistol/divet/spec_ops
	name = "special ops divet pistol"
	desc = "A modified version of the Winchester Arms NK-series pistol. An integrated suppressor lowers the audio profile fairly well."
	icon_state = "divet_spec"
	suppressed_volume = 40
	suppressed = TRUE
	can_unsuppress = FALSE
	//tier_2_bonus = 1

/obj/item/gun/ballistic/automatic/pistol/divet/rending//For Ketrai or another to do the necro tier bonus/debuff damage stuff
	name = "jury-rigged divet pistol"
	desc = "An illegaly modified version of the Winchester Arms NK-series pistol. Shoots bullets at brutal speed, but at an odd angle. Fractures bones easily"
	//color = "#6e6ec1"
	//tier_2_bonus = 1
	//tier_1_bonus = 1

/**
Magazines
*/

/obj/item/ammo_box/magazine/divet
	name = "divet magazine (pistol slug)"
	icon = 'deadspace/icons/obj/ammo.dmi'
	icon_state = "divet_slug"
	ammo_type = /obj/item/ammo_casing/divet
	caliber = CALIBER_DIVET
	max_ammo = 12
	multiple_sprites = AMMO_BOX_FULL_EMPTY

/obj/item/ammo_box/magazine/divet/hp
	name = "divet magazine (hollow point)"
	icon_state = "divet_hp"
	ammo_type = /obj/item/ammo_casing/divet/hp

/obj/item/ammo_box/magazine/divet/ap
	name = "divet magazine (AP)"
	icon_state = "divet_ap"
	ammo_type = /obj/item/ammo_casing/divet/ap

/obj/item/ammo_box/magazine/divet/rb
	name = "divet magazine (rubber)"
	icon_state = "divet_rb"
	ammo_type = /obj/item/ammo_casing/divet/rb
	max_ammo = 15

/obj/item/ammo_box/magazine/divet/fire
	name = "divet magazine (incendiary)"
	icon_state = "divet_incind"
	ammo_type = /obj/item/ammo_casing/divet/inc

/obj/item/ammo_box/magazine/divet/extended
	name = "divet magazine (extended)"
	icon_state = "divet_ext_slug"
	max_ammo = 21
	ammo_type = /obj/item/ammo_casing/divet/extended

/obj/item/ammo_box/magazine/divet/extended/expanded
	name = "divet magazine (expanded)"
	icon_state = "divet_exp_slug"
	max_ammo = 60

/obj/item/ammo_box/magazine/divet/blank
	name = "divet magazine (blank/practice)"
	icon_state = "divet_rb"
	ammo_type = /obj/item/ammo_casing/divet/blank
	max_ammo = 15

/**
Ammo casings for the mags
*/

/obj/item/ammo_casing/divet
	name = "divet bullet casing"
	desc = "A divet bullet casing."
	caliber = CALIBER_DIVET
	projectile_type = /obj/projectile/bullet/divet

/obj/item/ammo_casing/divet/hp
	name = "divet hollow-point bullet casing"
	projectile_type = /obj/projectile/bullet/divet/hp

/obj/item/ammo_casing/divet/ap
	name = "divet armor-piercing bullet casing"
	projectile_type = /obj/projectile/bullet/divet/ap

/obj/item/ammo_casing/divet/rb
	name = "divet rubber bullet casing"
	projectile_type = /obj/projectile/bullet/divet/rb

/obj/item/ammo_casing/divet/inc
	name = "divet incendiary bullet casing"
	projectile_type = /obj/projectile/bullet/incendiary/divet

/obj/item/ammo_casing/divet/extended
	name = "divet steel bullet casing"
	projectile_type = /obj/projectile/bullet/divet/extended

/obj/item/ammo_casing/divet/blank
	name = "divet blank bullet casing"
	projectile_type = /obj/projectile/bullet/divet/blank
	// harmful = FALSE

/**
Projectiles for the casings
*/

/obj/projectile/bullet/divet
	name = "divet bullet"
	icon = 'deadspace/icons/obj/projectiles.dmi'
	icon_state = "divet"
	damage = 17.5
	armour_penetration = 10
	wound_falloff_tile = -10
	dismemberment = 5
	embedding = list(embed_chance=25, fall_chance=2, jostle_chance=2, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=3, jostle_pain_mult=5, rip_time=1 SECONDS)
	//muzzle_type = /obj/effect/projectile/pulse //+/light   dunno where the 'light' part is from. Maybe a calculation on normal pulse muzzle?
	impact_type = /obj/effect/projectile/divet

//More damage and shrapnel, less AP, structure damage and penetration
/obj/projectile/bullet/divet/hp
	name = "divet hollow-point bullet"
	icon_state = "divet_hp"
	damage = 22.5
	armour_penetration = 0
	weak_against_armour = TRUE

//Opposite of hollowpoint
/obj/projectile/bullet/divet/ap
	name = "divet armor-piercing bullet"
	icon_state = "divet_ap"
	damage = 15
	armour_penetration = 20

//Less lethal ammo. Rubber bullets, now with bounce!
/obj/projectile/bullet/divet/rb
	name = "divet rubber bullet"
	icon_state = "divet" //Maybe get rubber bullet sprite in future
	damage = 6
	stamina = 60
	armour_penetration = 10
	ricochets_max = 5
	ricochet_incidence_leeway = 0
	ricochet_chance = 120
	ricochet_auto_aim_angle = 40
	ricochet_auto_aim_range = 5
	ricochet_decay_damage = 0.8
	dismemberment = 0
	weak_against_armour = TRUE
	shrapnel_type = null
	sharpness = NONE
	embedding = null

//Bullets that set people AND THE ENVIRONMENT on fire, have reduced armor penetration
//They also have reduced flat damage, likely due to much of the casing space being taken for incindiary use instead (and balance)
/obj/projectile/bullet/incendiary/divet
	name = "divet incendiary bullet"
	icon = 'deadspace/icons/obj/projectiles.dmi'
	icon_state = "divet_incend"
	damage = 12.5
	armour_penetration = 5
	fire_stacks = 1

//Leaving here if someone wanted to try to use old incendiary stuff (slightly modified, not enougb to work though)
// /obj/projectile/bullet/incendiary/divet/on_impact(var/mob/living/L)    //Change on_impact to something of '/obj/projectile/proc/Impact'
// 	if (istype(L))
// 		L.fire_stacks += 5
// 		L.IgniteMob()    //Would likely change it to 'ignite_mob' or so, for 'mob/living/proc/ignite_mob()'

//Cheaper bullets that put inside the extended mags by default, to cut some costs of the more trigger happy prone who use the mags
/obj/projectile/bullet/divet/extended
	name = "divet steel bullet"
	damage = 15.5

/obj/projectile/bullet/divet/blank
	name = "divet blank bullet"
	icon_state = "divet"
	damage = 1 //Can do burn damage, reduced range...
	dismemberment = 0
	weak_against_armour = TRUE
	shrapnel_type = null
	sharpness = NONE
	embedding = null

/**
Projectiles for the casings
*/

/obj/effect/projectile/divet
	name = "impact"
	icon = 'deadspace/icons/obj/weapons/projectiles_effects.dmi'
	icon_state = "divet_hit"
