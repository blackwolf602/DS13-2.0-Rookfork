/datum/job/head_of_security
	title = JOB_HEAD_OF_SECURITY
	description = "Coordinate security personnel, ensure they are not corrupt, \
		make sure every department is protected."
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD|DEADMIN_POSITION_SECURITY
	department_head = list(JOB_CAPTAIN)
	head_announce = list(RADIO_CHANNEL_SECURITY)
	faction = FACTION_STATION
	total_positions = 1
	spawn_positions = 1
	supervisors = "the captain"
	selection_color = "#8e2929"
	req_admin_notify = 1
	minimal_player_age = 14
	exp_requirements = 300
	exp_required_type = EXP_TYPE_CREW
	exp_required_type_department = EXP_TYPE_SECURITY
	exp_granted_type = EXP_TYPE_CREW

	employers = list(
		/datum/employer/cec,
		/datum/employer/eg,
		/datum/employer/uni,
	)

	outfits = list(
		"Default" = list(
			SPECIES_HUMAN = /datum/outfit/job/hos,
			SPECIES_PLASMAMAN = /datum/outfit/job/hos/plasmaman,
		),
	)

	departments_list = list(
		/datum/job_department/security,
		/datum/job_department/command,
		)

	mind_traits = list(TRAIT_DONUT_LOVER)
	liver_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM, TRAIT_ROYAL_METABOLISM)

	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_STATION_MASTER

	bounty_types = CIV_JOB_SEC

	family_heirlooms = list(/obj/item/book/manual/wiki/security_space_law)
	rpg_title = "Guard Leader"
	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE | JOB_BOLD_SELECT_TEXT | JOB_REOPEN_ON_ROUNDSTART_LOSS | JOB_ASSIGN_QUIRKS | JOB_CAN_BE_INTERN

	voice_of_god_power = 1.4 //Command staff has authority


/datum/job/head_of_security/get_captaincy_announcement(mob/living/captain)
	return "Due to staffing shortages, newly promoted Acting Captain [captain.real_name] on deck!"


/datum/outfit/job/hos
	name = "Head of Security"
	jobtype = /datum/job/head_of_security

	id = /obj/item/card/id/advanced/silver
	id_trim = /datum/id_trim/job/head_of_security
	uniform = /obj/item/clothing/under/rank/security/ds_cseco
	suit = /obj/item/clothing/suit/toggle/cseco
	backpack_contents = list(
		/obj/item/evidencebag = 1,
		)
	belt = /obj/item/modular_computer/tablet/pda/heads/hos
	ears = /obj/item/radio/headset/heads/hos/alt
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/hos/beret
	shoes = /obj/item/clothing/shoes/jackboots
	l_pocket = /obj/item/restraints/handcuffs
	r_pocket = /obj/item/assembly/flash/handheld

	box = /obj/item/storage/box/survival/security
	chameleon_extras = list(
		/obj/item/gun/energy/e_gun/hos,
		/obj/item/stamp/hos,
		)
	implants = list(/obj/item/implant/mindshield)

/datum/outfit/job/hos/plasmaman
	name = "Head of Security (Plasmaman)"

	uniform = /obj/item/clothing/under/plasmaman/security/head_of_security
	gloves = /obj/item/clothing/gloves/color/plasmaman/black
	head = /obj/item/clothing/head/helmet/space/plasmaman/security/head_of_security
	mask = /obj/item/clothing/mask/breath
	r_hand = /obj/item/tank/internals/plasmaman/belt/full

/datum/outfit/job/hos/mod
	name = "Head of Security (MODsuit)"

	suit_store = /obj/item/tank/internals/oxygen
	back = /obj/item/mod/control/pre_equipped/safeguard
	suit = null
	head = null
	mask = /obj/item/clothing/mask/gas/sechailer
	internals_slot = ITEM_SLOT_SUITSTORE
	backpack_contents = null
	box = null
