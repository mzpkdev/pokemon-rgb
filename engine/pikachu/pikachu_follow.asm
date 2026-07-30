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
	ld a, [wd736]
	bit 6, a
	ret nz
	ld a, [wPikachuFollowCommandBufferSize]
	cp 6 ; final four buffer bytes are reserved for follower scratch state
	jr nc, .snap
	add a
	ld e, a
	ld d, 0
	ld hl, wPikachuFollowCommandBuffer
	add hl, de
	ld a, [wYCoord]
	add 4
	ld [hli], a
	ld a, [wXCoord]
	add 4
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
	ld [wSpritePikachuStateData2MapY], a
	ld a, [wXCoord]
	add 4
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
	call InitializePikachuScreenPosition
	ld a, [wSpritePikachuStateData2ImageBaseOffset]
	dec a
	swap a
	ld b, a
	ld a, [wSpritePikachuStateData1FacingDirection]
	add b
	ld [wSpritePikachuStateData1ImageIndex], a
	ret

InitializePikachuScreenPosition:
	ld a, [wSpritePikachuStateData2MapY]
	ld b, a
	ld a, [wYCoord]
	ld c, a
	ld a, b
	sub c
	swap a
	sub 4
	ld [wSpritePikachuStateData1YPixels], a
	ld a, [wSpritePikachuStateData2MapX]
	ld b, a
	ld a, [wXCoord]
	ld c, a
	ld a, b
	sub c
	swap a
	ld [wSpritePikachuStateData1XPixels], a
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
