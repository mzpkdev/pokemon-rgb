InitPikachuSpriteGraphics::
	ld a, [wNumSprites]
	cp PIKACHU_SPRITE_INDEX
	ret nc
	ld a, [wSpritePikachuStateData1PictureID]
	and a
	ret z
; Find an animated VRAM slot not used by a real map object. This preserves all
; RGB sprite sets and NPC pictures; graphics-full maps omit the companion.
	ld c, 2
.tryVRAMSlot
	ld a, c
	cp 11
	jr nc, .noVRAMSlot
	ld a, [wNumSprites]
	ld b, a
	ld hl, wSprite01StateData2ImageBaseOffset
.scanMapSprites
	ld a, b
	and a
	jr z, .foundVRAMSlot
	ld a, [hl]
	cp c
	jr z, .nextVRAMSlot
	ld a, SPRITESTATEDATA2_LENGTH
	add l
	ld l, a
	dec b
	jr .scanMapSprites
.nextVRAMSlot
	inc c
	jr .tryVRAMSlot

.foundVRAMSlot
	ld a, c
	ld [wSpritePikachuStateData2ImageBaseOffset], a
	ldh [hVRAMSlot], a
	ld hl, vNPCSprites
	ld de, 12 tiles
	dec c
.calculateVRAMAddress
	add hl, de
	dec c
	jr nz, .calculateVRAMAddress
	push hl
	ld a, [wFontLoaded]
	bit 0, a
	jr nz, .skipStandingTiles
	ld de, PikachuSprite
	ld bc, $c0
	ld a, BANK(PikachuSprite)
	call FarCopyData2
.skipStandingTiles
	pop hl
	set 3, h
	ld de, PikachuSprite + $c0
	ld a, [wFontLoaded]
	bit 0, a
	jr nz, .copyWalkingWithLCD
	ld bc, $c0
	ld a, BANK(PikachuSprite)
	call FarCopyData2
	jr .graphicsLoaded
.copyWalkingWithLCD
	lb bc, BANK(PikachuSprite), $0c
	call CopyVideoData
.graphicsLoaded
; An outdoor set preloads graphics for connected maps. Pikachu borrows only
; a slot unused by this map, so force the next map to restore its full set.
	ld a, [wCurMap]
	cp FIRST_INDOOR_MAP
	ret nc
	xor a
	ld [wSpriteSetID], a
	ret

.noVRAMSlot
	farjp ClearPikachuCompanion
