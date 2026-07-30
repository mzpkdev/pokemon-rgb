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

; Create a stationary synthetic sprite in slot 15. Maps which already use all
; 15 object slots retain their content and simply do not display Pikachu.
InitializePikachuCompanion::
	call ClearPikachuCompanion
	ld a, [wNumSprites]
	cp PIKACHU_SPRITE_INDEX
	ret nc
	ld a, [wWalkBikeSurfState]
	and a
	ret nz
	call FindLivingPikachuInParty
	ret nc

	ld a, SPRITE_PIKACHU
	ld [wSpritePikachuStateData1PictureID], a
	ld a, $ff
	ld [wSpritePikachuStateData1ImageIndex], a
	ld [wSpritePikachuStateData2MovementByte1], a
	ld a, [wSpritePlayerStateData1FacingDirection]
	ld [wSpritePikachuStateData1FacingDirection], a

; Start on the adjacent tile behind the direction the player faces.
	ld a, [wYCoord]
	add 4
	ld b, a
	ld a, [wXCoord]
	add 4
	ld c, a
	ld a, [wSpritePlayerStateData1FacingDirection]
	and a
	jr nz, .checkUp
	dec b
	jr .storeCoords
.checkUp
	cp SPRITE_FACING_UP
	jr nz, .checkLeft
	inc b
	jr .storeCoords
.checkLeft
	cp SPRITE_FACING_LEFT
	jr nz, .facingRight
	inc c
	jr .storeCoords
.facingRight
	dec c
.storeCoords
	ld a, b
	ld [wSpritePikachuStateData2MapY], a
	ld a, c
	ld [wSpritePikachuStateData2MapX], a
	ld a, 1
	ld [wSpritePikachuStateData1MovementStatus], a
	ld [wPikachuSpawnState], a
	xor a
	ld [wPikachuFollowCommandBufferSize], a
	ld [wPikachuStepTimer], a
	ld a, PIKACHU_SPRITE_INDEX * SPRITESTATEDATA1_LENGTH
	ldh [hCurrentSpriteOffset], a
	farjp InitializeSpriteScreenPosition

ClearPikachuCompanion::
	xor a
	ld [wPikachuSpawnState], a
	ld [wPikachuFollowCommandBufferSize], a
	ld [wPikachuStepTimer], a
; On a full map, slot 15 is real map content already initialized by
; LoadMapHeader. Clear companion state without erasing that object.
	ld a, [wNumSprites]
	cp PIKACHU_SPRITE_INDEX
	ret nc
	ld hl, wSpritePikachuStateData1
	ld bc, SPRITESTATEDATA1_LENGTH
	xor a
	call FillMemory
	ld hl, wSpritePikachuStateData2
	ld bc, SPRITESTATEDATA2_LENGTH
	xor a
	call FillMemory
	ld a, $ff
	ld [wSpritePikachuStateData1ImageIndex], a
	ret
