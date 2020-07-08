#define MALFUNCTION_TEMPORARY 1
#define MALFUNCTION_PERMANENT 2


/obj/item/weapon/implant
	name = "implant"
	icon = 'icons/obj/device.dmi'
	icon_state = "implant"
	w_class = ITEMSIZE_TINY
	var/implanted = null
	var/mob/imp_in = null
	var/obj/item/organ/external/part = null
	var/implant_color = "b"
	var/allow_reagents = 0
	var/malfunction = 0
	var/initialize_loc = BP_TORSO
	show_messages = 1

/obj/item/weapon/implant/proc/trigger(emote, source as mob)
	return

/obj/item/weapon/implant/proc/activate()
	return

// Moves the implant where it needs to go, and tells it if there's more to be done in post_implant
/obj/item/weapon/implant/proc/handle_implant(var/mob/source, var/target_zone = BP_TORSO)
	. = TRUE
	imp_in = source
	implanted = TRUE
	if(ishuman(source))
		var/mob/living/carbon/human/H = source
		var/obj/item/organ/external/affected = H.get_organ(target_zone)
		if(affected)
			affected.implants |= src
			part = affected
	if(part)
		forceMove(part)
	else
		forceMove(source)

	listening_objects |= src

// Takes place after handle_implant, if that returns TRUE
/obj/item/weapon/implant/proc/post_implant(var/mob/source)

/obj/item/weapon/implant/proc/get_data()
	return "No information available"

/obj/item/weapon/implant/proc/hear(message, source as mob)
	return

/obj/item/weapon/implant/proc/islegal()
	return 0

/obj/item/weapon/implant/proc/meltdown()	//breaks it down, making implant unrecongizible
	to_chat(imp_in, "<span class='warning'>You feel something melting inside [part ? "your [part.name]" : "you"]!</span>")
	if (part)
		part.take_damage(burn = 15, used_weapon = "Electronics meltdown")
	else
		var/mob/living/M = imp_in
		M.apply_damage(15,BURN)
	name = "melted implant"
	desc = "Charred circuit in melted plastic case. Wonder what that used to be..."
	icon_state = "implant_melted"
	malfunction = MALFUNCTION_PERMANENT

/obj/item/weapon/implant/proc/implant_loadout(var/mob/living/carbon/human/H)
	if(H)
		if(handle_implant(H, initialize_loc))
			invisibility = initial(invisibility)
			post_implant(H)

/obj/item/weapon/implant/Destroy()
	if(part)
		part.implants.Remove(src)
	listening_objects.Remove(src)
	part = null
	imp_in = null
	return ..()

/obj/item/weapon/implant/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/weapon/implanter))
		var/obj/item/weapon/implanter/implanter = I
		if(implanter.imp)
			return // It's full.
		user.drop_from_inventory(src)
		forceMove(implanter)
		implanter.imp = src
		implanter.update()
	else
		..()



//////////////////////////////
//	Tracking Implant
//////////////////////////////
GLOBAL_LIST_BOILERPLATE(all_tracking_implants, /obj/item/weapon/implant/tracking)

/obj/item/weapon/implant/tracking
	name = "tracking implant"
	desc = "An implant normally given to dangerous criminals. Allows security to track your location."
	var/id = 1
	var/degrade_time = 10 MINUTES	//How long before the implant stops working outside of a living body.

/obj/item/weapon/implant/tracking/weak	//This is for the loadout
	degrade_time = 2.5 MINUTES

/obj/item/weapon/implant/tracking/New()
	id = rand(1, 1000)
	..()

/obj/item/weapon/implant/tracking/post_implant(var/mob/source)
	START_PROCESSING(SSobj, src)

/obj/item/weapon/implant/tracking/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/weapon/implant/tracking/process()
	var/implant_location = src.loc
	if(ismob(implant_location))
		var/mob/living/L = implant_location
		if(L.stat == DEAD)
			if(world.time >= L.timeofdeath + degrade_time)
				name = "melted implant"
				desc = "Charred circuit in melted plastic case. Wonder what that used to be..."
				icon_state = "implant_melted"
				malfunction = MALFUNCTION_PERMANENT
				STOP_PROCESSING(SSobj, src)
	return 1

/obj/item/weapon/implant/tracking/get_data()
	var/dat = {"<b>Implant Specifications:</b><BR>
<b>Name:</b> Tracking Beacon<BR>
<b>Life:</b> 10 minutes after death of host<BR>
<b>Important Notes:</b> None<BR>
<HR>
<b>Implant Details:</b> <BR>
<b>Function:</b> Continuously transmits low power signal. Useful for tracking.<BR>
<b>Special Features:</b><BR>
<i>Neuro-Safe</i>- Specialized shell absorbs excess voltages self-destructing the chip if
a malfunction occurs thereby securing safety of subject. The implant will melt and
disintegrate into bio-safe elements.<BR>
<b>Integrity:</b> Gradient creates slight risk of being overcharged and frying the
circuitry. As a result neurotoxins can cause massive damage.<HR>
Implant Specifics:<BR>"}
	return dat

/obj/item/weapon/implant/tracking/emp_act(severity)
	if (malfunction)	//no, dawg, you can't malfunction while you are malfunctioning
		return
	malfunction = MALFUNCTION_TEMPORARY

	var/delay = 20
	switch(severity)
		if(1)
			if(prob(60))
				meltdown()
		if(2)
			delay = rand(5*60*10,15*60*10)	//from 5 to 15 minutes of free time
		if(3)
			delay = rand(2*60*10,5*60*10)	//from 2 to 5 minutes of free time
		if(4)
			delay = rand(0.5*60*10,1*60*10)	//from .5 to 1 minutes of free time

	spawn(delay)
		malfunction--

//////////////////////////////
//	Death Explosive Implant
//////////////////////////////
/obj/item/weapon/implant/dexplosive
	name = "explosive"
	desc = "And boom goes the weasel."
	icon_state = "implant_evil"

/obj/item/weapon/implant/dexplosive/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Robust Corp RX-78 Employee Management Implant<BR>
<b>Life:</b> Activates upon death.<BR>
<b>Important Notes:</b> Explodes<BR>
<HR>
<b>Implant Details:</b><BR>
<b>Function:</b> Contains a compact, electrically detonated explosive that detonates upon receiving a specially encoded signal or upon host death.<BR>
<b>Special Features:</b> Explodes<BR>
<b>Integrity:</b> Implant will occasionally be degraded by the body's immune system and thus will occasionally malfunction."}
	return dat


/obj/item/weapon/implant/dexplosive/trigger(emote, source as mob)
	if(emote == "deathgasp")
		src.activate("death")
	return


/obj/item/weapon/implant/dexplosive/activate(var/cause)
	if((!cause) || (!src.imp_in))	return 0
	explosion(src, -1, 0, 2, 3, 0)//This might be a bit much, dono will have to see.
	if(src.imp_in)
		src.imp_in.gib()

/obj/item/weapon/implant/dexplosive/islegal()
	return 0

//////////////////////////////
//	Explosive Implant
//////////////////////////////
/obj/item/weapon/implant/explosive
	name = "explosive implant"
	desc = "A military grade micro bio-explosive. Highly dangerous."
	var/elevel = "Localized Limb"
	var/phrase = "supercalifragilisticexpialidocious"
	icon_state = "implant_evil"

/obj/item/weapon/implant/explosive/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Robust Corp RX-78 Intimidation Class Implant<BR>
<b>Life:</b> Activates upon codephrase.<BR>
<b>Important Notes:</b> Explodes<BR>
<HR>
<b>Implant Details:</b><BR>
<b>Function:</b> Contains a compact, electrically detonated explosive that detonates upon receiving a specially encoded signal or upon host death.<BR>
<b>Special Features:</b> Explodes<BR>
<b>Integrity:</b> Implant will occasionally be degraded by the body's immune system and thus will occasionally malfunction."}
	return dat

/obj/item/weapon/implant/explosive/hear_talk(mob/M, list/message_pieces, verb)
	var/msg = multilingual_to_message(message_pieces)
	hear(msg)
	return

/obj/item/weapon/implant/explosive/hear(var/msg)
	var/list/replacechars = list("'" = "","\"" = "",">" = "","<" = "","(" = "",")" = "")
	msg = replace_characters(msg, replacechars)
	if(findtext(msg,phrase))
		activate()
		qdel(src)

/obj/item/weapon/implant/explosive/activate()
	if (malfunction == MALFUNCTION_PERMANENT)
		return

	if(istype(imp_in, /mob/))
		var/mob/T = imp_in
		message_admins("Explosive implant triggered in [T] ([T.key]). (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>) ")
		log_game("Explosive implant triggered in [T] ([T.key]).")

		if(ishuman(imp_in))
			if (elevel == "Localized Limb")
				if(part) //For some reason, small_boom() didn't work. So have this bit of working copypaste.
					imp_in.visible_message("<span class='warning'>Something beeps inside [imp_in][part ? "'s [part.name]" : ""]!</span>")
					playsound(src, 'sound/items/countdown.ogg', 75, 1, -3)
					sleep(25)
					if (istype(part,/obj/item/organ/external/chest) ||	\
						istype(part,/obj/item/organ/external/groin) ||	\
						istype(part,/obj/item/organ/external/head))
						part.createwound(BRUISE, 80)	//mangle them instead
						explosion(get_turf(imp_in), -1, -1, 1, 3)
						qdel(src)
					else
						explosion(get_turf(imp_in), -1, -1, 1, 3)
						part.droplimb(0,DROPLIMB_BLUNT)
						qdel(src)
			if (elevel == "Destroy Body")
				explosion(get_turf(T), -1, 0, 1, 6)
				T.gib()
			if (elevel == "Full Explosion")
				explosion(get_turf(T), 0, 1, 3, 6)
				T.gib()

		else
			explosion(get_turf(imp_in), 0, 1, 3, 6)

	var/turf/t = get_turf(imp_in)

	if(t)
		t.hotspot_expose(3500,125)

/obj/item/weapon/implant/explosive/post_implant(mob/source as mob)
	elevel = alert("What sort of explosion would you prefer?", "Implant Intent", "Localized Limb", "Destroy Body", "Full Explosion")
	phrase = input("Choose activation phrase:") as text
	var/list/replacechars = list("'" = "","\"" = "",">" = "","<" = "","(" = "",")" = "")
	phrase = replace_characters(phrase, replacechars)
	usr.mind.store_memory("Explosive implant in [source] can be activated by saying something containing the phrase ''[src.phrase]'', <B>say [src.phrase]</B> to attempt to activate.", 0, 0)
	to_chat(usr, "The implanted explosive implant in [source] can be activated by saying something containing the phrase ''[src.phrase]'', <B>say [src.phrase]</B> to attempt to activate.")

/obj/item/weapon/implant/explosive/emp_act(severity)
	if (malfunction)
		return
	malfunction = MALFUNCTION_TEMPORARY
	switch (severity)
		if (4)	//Weak EMP will make implant tear limbs off.
			if (prob(25))
				small_boom()
		if (3)	//Weak EMP will make implant tear limbs off.
			if (prob(50))
				small_boom()
		if (2)	//strong EMP will melt implant either making it go off, or disarming it
			if (prob(70))
				if (prob(75))
					small_boom()
				else
					if (prob(13))
						activate()		//chance of bye bye
					else
						meltdown()		//chance of implant disarming
		if (1)	//strong EMP will melt implant either making it go off, or disarming it
			if (prob(70))
				if (prob(50))
					small_boom()
				else
					if (prob(50))
						activate()		//50% chance of bye bye
					else
						meltdown()		//50% chance of implant disarming
	spawn (20)
		malfunction--

/obj/item/weapon/implant/explosive/islegal()
	return 0

/obj/item/weapon/implant/explosive/proc/small_boom()
	if (ishuman(imp_in) && part)
		imp_in.visible_message("<span class='warning'>Something beeps inside [imp_in][part ? "'s [part.name]" : ""]!</span>")
		playsound(src, 'sound/items/countdown.ogg', 75, 1, -3)
		spawn(25)
			if (ishuman(imp_in) && part)
				//No tearing off these parts since it's pretty much killing
				//and you can't replace groins
				if (istype(part,/obj/item/organ/external/chest) ||	\
					istype(part,/obj/item/organ/external/groin) ||	\
					istype(part,/obj/item/organ/external/head))
					part.createwound(BRUISE, 80)	//mangle them instead
				else
					part.droplimb(0,DROPLIMB_BLUNT)
			explosion(get_turf(imp_in), -1, -1, 1, 3)
			qdel(src)

//////////////////////////////
//	Chemical Implant
//////////////////////////////
GLOBAL_LIST_BOILERPLATE(all_chem_implants, /obj/item/weapon/implant/chem)

/obj/item/weapon/implant/chem
	name = "chemical implant"
	desc = "Injects things."
	allow_reagents = 1

/obj/item/weapon/implant/chem/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Robust Corp MJ-420 Prisoner Management Implant<BR>
<b>Life:</b> Deactivates upon death but remains within the body.<BR>
<b>Important Notes: Due to the system functioning off of nutrients in the implanted subject's body, the subject<BR>
will suffer from an increased appetite.</B><BR>
<HR>
<b>Implant Details:</b><BR>
<b>Function:</b> Contains a small capsule that can contain various chemicals. Upon receiving a specially encoded signal<BR>
the implant releases the chemicals directly into the blood stream.<BR>
<b>Special Features:</b>
<i>Micro-Capsule</i>- Can be loaded with any sort of chemical agent via the common syringe and can hold 50 units.<BR>
Can only be loaded while still in its original case.<BR>
<b>Integrity:</b> Implant will last so long as the subject is alive. However, if the subject suffers from malnutrition,<BR>
the implant may become unstable and either pre-maturely inject the subject or simply break."}
	return dat

/obj/item/weapon/implant/chem/New()
	..()
	var/datum/reagents/R = new/datum/reagents(50)
	reagents = R
	R.my_atom = src

/obj/item/weapon/implant/chem/trigger(emote, source as mob)
	if(emote == "deathgasp")
		src.activate(src.reagents.total_volume)
	return

/obj/item/weapon/implant/chem/activate(var/cause)
	if((!cause) || (!src.imp_in))	return 0
	var/mob/living/carbon/R = src.imp_in
	src.reagents.trans_to_mob(R, cause, CHEM_BLOOD)
	to_chat(R, "You hear a faint *beep*.")
	if(!src.reagents.total_volume)
		to_chat(R, "You hear a faint click from your chest.")
		playsound(R, 'sound/weapons/empty.ogg', 10, 1)
		spawn(0)
			qdel(src)
	return

/obj/item/weapon/implant/chem/emp_act(severity)
	if (malfunction)
		return
	malfunction = MALFUNCTION_TEMPORARY

	switch(severity)
		if(1)
			if(prob(60))
				activate(20)
		if(2)
			if(prob(40))
				activate(20)
		if(3)
			if(prob(40))
				activate(5)
		if(4)
			if(prob(20))
				activate(5)

	spawn(20)
		malfunction--

//////////////////////////////
//	Loyalty Implant
//////////////////////////////
/obj/item/weapon/implant/loyalty
	name = "loyalty implant"
	desc = "Makes you loyal or such."

/obj/item/weapon/implant/loyalty/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> [using_map.company_name] Employee Management Implant<BR>
<b>Life:</b> Ten years.<BR>
<b>Important Notes:</b> Personnel injected with this device tend to be much more loyal to the company.<BR>
<HR>
<b>Implant Details:</b><BR>
<b>Function:</b> Contains a small pod of nanobots that manipulate the host's mental functions.<BR>
<b>Special Features:</b> Will prevent and cure most forms of brainwashing.<BR>
<b>Integrity:</b> Implant will last so long as the nanobots are inside the bloodstream."}
	return dat

/obj/item/weapon/implant/loyalty/handle_implant(mob/M, target_zone = BP_TORSO)
	. = ..(M, target_zone)
	if(!istype(M, /mob/living/carbon/human))
		. = FALSE
	var/mob/living/carbon/human/H = M
	var/datum/antagonist/antag_data = get_antag_data(H.mind.special_role)
	if(antag_data && (antag_data.flags & ANTAG_IMPLANT_IMMUNE))
		H.visible_message("[H] seems to resist the implant!", "You feel the corporate tendrils of [using_map.company_name] try to invade your mind!")
		. = FALSE

/obj/item/weapon/implant/loyalty/post_implant(mob/M)
	var/mob/living/carbon/human/H = M
	clear_antag_roles(H.mind, 1)
	to_chat(H, "<span class='notice'>You feel a surge of loyalty towards [using_map.company_name].</span>")

//////////////////////////////
//	Adrenaline Implant
//////////////////////////////
/obj/item/weapon/implant/adrenalin
	name = "adrenalin"
	desc = "Removes all stuns and knockdowns."
	var/uses

/obj/item/weapon/implant/adrenalin/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> Cybersun Industries Adrenalin Implant<BR>
<b>Life:</b> Five days.<BR>
<b>Important Notes:</b> <font color='red'>Illegal</font><BR>
<HR>
<b>Implant Details:</b> Subjects injected with implant can activate a massive injection of adrenalin.<BR>
<b>Function:</b> Contains nanobots to stimulate body to mass-produce Adrenalin.<BR>
<b>Special Features:</b> Will prevent and cure most forms of brainwashing.<BR>
<b>Integrity:</b> Implant can only be used three times before the nanobots are depleted."}
	return dat


/obj/item/weapon/implant/adrenalin/trigger(emote, mob/source as mob)
	if (src.uses < 1)	return 0
	if (emote == "pale")
		src.uses--
		to_chat(source, "<span class='notice'>You feel a sudden surge of energy!</span>")
		source.SetStunned(0)
		source.SetWeakened(0)
		source.SetParalysis(0)

	return

/obj/item/weapon/implant/adrenalin/post_implant(mob/source)
	source.mind.store_memory("A implant can be activated by using the pale emote, <B>say *pale</B> to attempt to activate.", 0, 0)
	to_chat(source, "The implanted freedom implant can be activated by using the pale emote, <B>say *pale</B> to attempt to activate.")

//////////////////////////////
//	Death Alarm Implant
//////////////////////////////
/obj/item/weapon/implant/death_alarm
	name = "death alarm implant"
	desc = "An alarm which monitors host vital signs and transmits a radio message upon death."
	origin_tech = list(TECH_MATERIAL = 1, TECH_BIO = 2, TECH_DATA = 1)
	var/mobname = "Will Robinson"

/obj/item/weapon/implant/death_alarm/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> [using_map.company_name] \"Profit Margin\" Class Employee Lifesign Sensor<BR>
<b>Life:</b> Activates upon death.<BR>
<b>Important Notes:</b> Alerts crew to crewmember death.<BR>
<HR>
<b>Implant Details:</b><BR>
<b>Function:</b> Contains a compact radio signaler that triggers when the host's lifesigns cease.<BR>
<b>Special Features:</b> Alerts crew to crewmember death.<BR>
<b>Integrity:</b> Implant will occasionally be degraded by the body's immune system and thus will occasionally malfunction."}
	return dat

/obj/item/weapon/implant/death_alarm/process()
	if (!implanted) return
	var/mob/M = imp_in

	if(isnull(M)) // If the mob got gibbed
		activate()
	else if(M.stat == 2)
		activate("death")

/obj/item/weapon/implant/death_alarm/activate(var/cause)
	var/mob/M = imp_in
	var/area/t = get_area(M)
	switch (cause)
		if("death")
			var/obj/item/device/radio/headset/a = new /obj/item/device/radio/headset/heads/captain(null)
			if(istype(t, /area/syndicate_station) || istype(t, /area/syndicate_mothership) || istype(t, /area/shuttle/syndicate_elite) )
				//give the syndies a bit of stealth
				a.autosay("[mobname] has died in Space!", "[mobname]'s Death Alarm")
//				a.autosay("[mobname] has died in Space!", "[mobname]'s Death Alarm", "Security")
//				a.autosay("[mobname] has died in Space!", "[mobname]'s Death Alarm", "Medical")
			else
				a.autosay("[mobname] has died in [t.name]!", "[mobname]'s Death Alarm")
//				a.autosay("[mobname] has died in [t.name]!", "[mobname]'s Death Alarm", "Security")
//				a.autosay("[mobname] has died in [t.name]!", "[mobname]'s Death Alarm", "Medical")
			qdel(a)
			STOP_PROCESSING(SSobj, src)
		if ("emp")
			var/obj/item/device/radio/headset/a = new /obj/item/device/radio/headset/heads/captain(null)
			var/name = prob(50) ? t.name : pick(teleportlocs)
			a.autosay("[mobname] has died in [name]!", "[mobname]'s Death Alarm")
//			a.autosay("[mobname] has died in [name]!", "[mobname]'s Death Alarm", "Security")
//			a.autosay("[mobname] has died in [name]!", "[mobname]'s Death Alarm", "Medical")
			qdel(a)
		else
			var/obj/item/device/radio/headset/a = new /obj/item/device/radio/headset/heads/captain(null)
			a.autosay("[mobname] has died-zzzzt in-in-in...", "[mobname]'s Death Alarm")
//			a.autosay("[mobname] has died-zzzzt in-in-in...", "[mobname]'s Death Alarm", "Security")
//			a.autosay("[mobname] has died-zzzzt in-in-in...", "[mobname]'s Death Alarm", "Medical")
			qdel(a)
			STOP_PROCESSING(SSobj, src)

/obj/item/weapon/implant/death_alarm/emp_act(severity)			//for some reason alarms stop going off in case they are emp'd, even without this
	if (malfunction)		//so I'm just going to add a meltdown chance here
		return
	malfunction = MALFUNCTION_TEMPORARY

	activate("emp")	//let's shout that this dude is dead
	if(severity == 1)
		if(prob(40))	//small chance of obvious meltdown
			meltdown()
		else if (prob(60))	//but more likely it will just quietly die
			malfunction = MALFUNCTION_PERMANENT
		STOP_PROCESSING(SSobj, src)

	spawn(20)
		malfunction--

/obj/item/weapon/implant/death_alarm/post_implant(mob/source as mob)
	mobname = source.real_name
	START_PROCESSING(SSobj, src)

//////////////////////////////
//	Compressed Matter Implant
//////////////////////////////
/obj/item/weapon/implant/compressed
	name = "compressed matter implant"
	desc = "Based on compressed matter technology, can store a single item."
	icon_state = "implant_evil"
	var/activation_emote = "sigh"
	var/obj/item/scanned = null
	origin_tech = list(TECH_MATERIAL = 4, TECH_BIO = 2, TECH_ILLEGAL = 2)

/obj/item/weapon/implant/compressed/get_data()
	var/dat = {"
<b>Implant Specifications:</b><BR>
<b>Name:</b> [using_map.company_name] \"Profit Margin\" Class Employee Lifesign Sensor<BR>
<b>Life:</b> Activates upon death.<BR>
<b>Important Notes:</b> Alerts crew to crewmember death.<BR>
<HR>
<b>Implant Details:</b><BR>
<b>Function:</b> Contains a compact radio signaler that triggers when the host's lifesigns cease.<BR>
<b>Special Features:</b> Alerts crew to crewmember death.<BR>
<b>Integrity:</b> Implant will occasionally be degraded by the body's immune system and thus will occasionally malfunction."}
	return dat

/obj/item/weapon/implant/compressed/trigger(emote, mob/source as mob)
	if (src.scanned == null)
		return 0

	if (emote == src.activation_emote)
		to_chat(source, "The air glows as \the [src.scanned.name] uncompresses.")
		activate()

/obj/item/weapon/implant/compressed/activate()
	var/turf/t = get_turf(src)
	if (imp_in)
		imp_in.put_in_hands(scanned)
	else
		scanned.loc = t
	qdel(src)

/obj/item/weapon/implant/compressed/post_implant(mob/source)
	src.activation_emote = input("Choose activation emote:") in list("blink", "blink_r", "eyebrow", "chuckle", "twitch", "frown", "nod", "blush", "giggle", "grin", "groan", "shrug", "smile", "pale", "sniff", "whimper", "wink")
	if (source.mind)
		source.mind.store_memory("Compressed matter implant can be activated by using the [src.activation_emote] emote, <B>say *[src.activation_emote]</B> to attempt to activate.", 0, 0)
	to_chat(source, "The implanted compressed matter implant can be activated by using the [src.activation_emote] emote, <B>say *[src.activation_emote]</B> to attempt to activate.")


/obj/item/weapon/implant/compressed/islegal()
	return 0
