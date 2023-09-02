/datum/job/botanist
	title = JOB_BOTANIST
	description = "Grow plants for the cook, for medicine, and for recreation."
	department_head = list(JOB_HEAD_OF_PERSONNEL)
	faction = FACTION_STATION
	total_positions = 3
	spawn_positions = 2
	supervisors = "the head of personnel"
	exp_granted_type = EXP_TYPE_CREW

	employers = list(
		/datum/employer/cec,
		/datum/employer/eg,
		/datum/employer/uni,
	)

	outfits = list(
		"Default" = list(
			SPECIES_HUMAN = /datum/outfit/job/botanist,
			SPECIES_PLASMAMAN = /datum/outfit/job/botanist/plasmaman,
		),
	)

	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_STATION_MASTER
	bounty_types = CIV_JOB_GROW
	departments_list = list(
		/datum/job_department/service,
		)

	family_heirlooms = list(/obj/item/cultivator, /obj/item/reagent_containers/glass/bucket, /obj/item/toy/plush/beeplushie)

	mail_goodies = list(
		/obj/item/reagent_containers/glass/bottle/mutagen = 20,
		/obj/item/reagent_containers/glass/bottle/saltpetre = 20,
		/obj/item/reagent_containers/glass/bottle/diethylamine = 20,
		/obj/item/gun/energy/floragun = 10,
		/obj/effect/spawner/random/food_or_drink/seed_rare = 5,// These are strong, rare seeds, so use sparingly.
		/obj/item/food/monkeycube/bee = 2
	)

	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE | JOB_REOPEN_ON_ROUNDSTART_LOSS | JOB_ASSIGN_QUIRKS | JOB_CAN_BE_INTERN
	rpg_title = "Gardener"

/datum/outfit/job/botanist
	name = "Botanist"
	jobtype = /datum/job/botanist

	id_trim = /datum/id_trim/job/botanist
	uniform = /obj/item/clothing/under/rank/civilian/hydroponics/ds_bot
	suit = /obj/item/clothing/suit/apron
	suit_store = /obj/item/plant_analyzer
	belt = /obj/item/modular_computer/tablet/pda/botanist
	ears = /obj/item/radio/headset/headset_srv
	gloves = /obj/item/clothing/gloves/botanic_leather

/datum/outfit/job/botanist/plasmaman
	name = "Botanist (Plasmaman)"

	uniform = /obj/item/clothing/under/plasmaman/botany
	gloves = /obj/item/clothing/gloves/botanic_leather/plasmaman
	head = /obj/item/clothing/head/helmet/space/plasmaman/botany
	mask = /obj/item/clothing/mask/breath
	r_hand = /obj/item/tank/internals/plasmaman/belt/full
