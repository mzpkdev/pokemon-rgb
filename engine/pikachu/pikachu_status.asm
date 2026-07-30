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

; Called only when the player's tile coordinates are committed.
QueuePikachuPlayerStep::
	ld a, [wPikachuSpawnState]
	and a
	ret z
	ld a, [wWalkBikeSurfState]
	and a
	ret nz
; Scripted movement owns the joypad and must not pull the companion.
	ld a, [wd730]
	bit 7, a
	ret nz
	ld a, [wJoyIgnore]
	and a
	ret nz
	ld a, [wPikachuFollowCommandBufferSize]
	cp 8
	jr nc, .snap
	add a
	ld e, a
	ld d, 0
	ld hl, wPikachuFollowCommandBuffer
	add hl, de
	ld a, [wYCoord]
	add 4
	ld b, a
	ld a, [wSpritePlayerStateData1YStepVector]
	ld c, a
	ld a, b
	sub c
	ld [hli], a
	ld a, [wXCoord]
	add 4
	ld b, a
	ld a, [wSpritePlayerStateData1XStepVector]
	ld c, a
	ld a, b
	sub c
	ld [hl], a
	ld hl, wPikachuFollowCommandBufferSize
	inc [hl]
	ret
.snap
; Falling behind cannot corrupt the queue: snap to the just-vacated tile.
	xor a
	ld [wPikachuFollowCommandBufferSize], a
	ld [wPikachuStepTimer], a
	ld a, [wYCoord]
	add 4
	ld b, a
	ld a, [wSpritePlayerStateData1YStepVector]
	ld c, a
	ld a, b
	sub c
	ld [wSpritePikachuStateData2MapY], a
	ld a, [wXCoord]
	add 4
	ld b, a
	ld a, [wSpritePlayerStateData1XStepVector]
	ld c, a
	ld a, b
	sub c
	ld [wSpritePikachuStateData2MapX], a
	ret

UpdatePikachuFollower::
	ld a, [wPikachuStepTimer]
	and a
	jr z, .startNextStep
	ld b, a
	ld a, [wSpritePikachuStateData1FacingDirection]
	cp SPRITE_FACING_UP
	jr z, .moveUp
	cp SPRITE_FACING_LEFT
	jr z, .moveLeft
	cp SPRITE_FACING_RIGHT
	jr z, .moveRight
	ld hl, wSpritePikachuStateData1YPixels
	inc [hl]
	inc [hl]
	jr .animate
.moveUp
	ld hl, wSpritePikachuStateData1YPixels
	dec [hl]
	dec [hl]
	jr .animate
.moveLeft
	ld hl, wSpritePikachuStateData1XPixels
	dec [hl]
	dec [hl]
	jr .animate
.moveRight
	ld hl, wSpritePikachuStateData1XPixels
	inc [hl]
	inc [hl]
.animate
	ld a, b
	dec a
	ld [wPikachuStepTimer], a
	ld c, a
	and a
	jr nz, .setFrame
	ld a, [wPikachuTargetY]
	ld [wSpritePikachuStateData2MapY], a
	ld a, [wPikachuTargetX]
	ld [wSpritePikachuStateData2MapX], a
.setFrame
	ld a, c
	srl a
	and 3
	ld c, a
	ld a, [wSpritePikachuStateData2ImageBaseOffset]
	dec a
	swap a
	ld b, a
	ld a, [wSpritePikachuStateData1FacingDirection]
	add b
	add c
	ld [wSpritePikachuStateData1ImageIndex], a
	ret

.startNextStep
	ld a, [wPikachuFollowCommandBufferSize]
	and a
	jr z, .idle
	ld hl, wPikachuFollowCommandBuffer
	ld a, [hli]
	ld [wPikachuTargetY], a
	ld b, a
	ld a, [hl]
	ld [wPikachuTargetX], a
	call ShiftPikachuFollowQueue
	ld a, [wPikachuTargetY]
	ld b, a
	ld a, [wPikachuTargetX]
	ld c, a
	ld a, [wSpritePikachuStateData2MapY]
	cp b
	jr z, .horizontal
	ld a, SPRITE_FACING_DOWN
	jr c, .begin
	ld a, SPRITE_FACING_UP
	jr .begin
.horizontal
	ld a, [wSpritePikachuStateData2MapX]
	cp c
	jr z, .startNextStep
	ld a, SPRITE_FACING_RIGHT
	jr c, .begin
	ld a, SPRITE_FACING_LEFT
.begin
	ld [wSpritePikachuStateData1FacingDirection], a
	ld a, 8
	ld [wPikachuStepTimer], a
	ret
.idle
	farcall InitializeSpriteScreenPosition
	ld a, [wSpritePikachuStateData2ImageBaseOffset]
	dec a
	swap a
	ld b, a
	ld a, [wSpritePikachuStateData1FacingDirection]
	add b
	ld [wSpritePikachuStateData1ImageIndex], a
	ret

ShiftPikachuFollowQueue:
	ld a, [wPikachuFollowCommandBufferSize]
	dec a
	ld [wPikachuFollowCommandBufferSize], a
	ret z
	add a
	ld c, a
	ld b, 0
	ld hl, wPikachuFollowCommandBuffer + 2
	ld de, wPikachuFollowCommandBuffer
	jp CopyData
