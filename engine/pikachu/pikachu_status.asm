; Find the first living Pikachu in the party.
; Return carry set and its zero-based party index in a when found.
; Return carry clear and a = $ff otherwise.
FindLivingPikachuInParty::
	ld a, [wPartyCount]
	ld b, a
	ld c, 0
	ld hl, wPartySpecies
	ld de, wPartyMon1HP
.loop
	ld a, b
	and a
	jr z, .notFound
	ld a, [hli]
	cp PIKACHU
	jr nz, .next
	push hl
	ld h, d
	ld l, e
	ld a, [hli]
	or [hl]
	pop hl
	jr nz, .found
.next
	push hl
	ld hl, PARTYMON_STRUCT_LENGTH
	add hl, de
	ld d, h
	ld e, l
	pop hl
	inc c
	dec b
	jr .loop
.found
	ld a, c
	scf
	ret
.notFound
	ld a, $ff
	and a
	ret
