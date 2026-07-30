; Yellow-style monochrome overworld palette selection.
;
; This is deliberately separate from the existing SGB palette IDs. RGB no
; longer has entries for Yellow's route and Pallet Town palettes at those IDs.
;
; GetOverworldMonoPalette:
;   Returns the MONO_PAL_* index for the current map in a.
;   Preserves bc, de, hl, and the current WRAM bank.
;   Clobbers flags.
GetOverworldMonoPalette::
	push bc
	push de
	push hl

	; The map state used here is in WRAM bank 1 (selected by SVBK value 0).
	ldh a, [rSVBK]
	push af
	xor a
	ldh [rSVBK], a
	ld a, [wCurMapTileset]
	ld b, a
	ld a, [wCurMap]
	ld c, a
	ld a, [wLastMap]
	ld d, a
	pop af
	ldh [rSVBK], a

	; Preserve Yellow's tileset overrides even when the map ordering changes.
	ld a, b
	cp CEMETERY
	jr z, .gray
	cp CAVERN
	jr z, .cave

	ld a, c
	cp FIRST_INDOOR_MAP
	jr c, .townOrRoute

	; These late-map checks match Yellow. The Cerulean Cave checks are
	; intentionally retained in addition to the CAVERN tileset override.
	cp CERULEAN_CAVE_2F
	jr c, .useLastMap
	cp CERULEAN_CAVE_1F + 1
	jr c, .cave
	cp LORELEIS_ROOM
	jr z, .pallet
	cp BRUNOS_ROOM
	jr z, .cave
	cp TRADE_CENTER
	jr z, .gray
	cp COLOSSEUM
	jr z, .gray

.useLastMap
	ld a, d
.townOrRoute
	cp NUM_CITY_MAPS
	jr nc, .route
	inc a ; map IDs PALLET_TOWN..SAFFRON_CITY map to indexes 1..11
	jr .done

.route
	xor a
	jr .done
.pallet
	ld a, MONO_PAL_PALLET
	jr .done
.gray
	ld a, MONO_PAL_GRAY
	jr .done
.cave
	ld a, MONO_PAL_CAVE

.done
	pop hl
	pop de
	pop bc
	ret

	const_def
	const MONO_PAL_ROUTE
	const MONO_PAL_PALLET
	const MONO_PAL_VIRIDIAN
	const MONO_PAL_PEWTER
	const MONO_PAL_CERULEAN
	const MONO_PAL_LAVENDER
	const MONO_PAL_VERMILION
	const MONO_PAL_CELADON
	const MONO_PAL_FUCHSIA
	const MONO_PAL_CINNABAR
	const MONO_PAL_INDIGO
	const MONO_PAL_SAFFRON
	const MONO_PAL_GRAY
	const MONO_PAL_CAVE
DEF NUM_OVERWORLD_MONO_PALETTES EQU const_value

; Exact CGB base ramps used by Pokemon Yellow. These are not the softer SGB
; ramps. Each entry is one four-color CGB palette in light-to-dark order.
OverworldMonoPalettes::
	table_width 2 * 4, OverworldMonoPalettes
	RGB 31,31,31, 16,31,04, 11,23,31, 03,03,03 ; MONO_PAL_ROUTE
	RGB 31,31,31, 23,17,31, 11,23,31, 03,03,03 ; MONO_PAL_PALLET
	RGB 31,31,31, 19,31,00, 11,23,31, 03,03,03 ; MONO_PAL_VIRIDIAN
	RGB 31,31,31, 18,18,15, 11,23,31, 03,03,03 ; MONO_PAL_PEWTER
	RGB 31,31,31, 05,08,31, 11,23,31, 03,03,03 ; MONO_PAL_CERULEAN
	RGB 31,31,31, 25,04,31, 11,23,31, 03,03,03 ; MONO_PAL_LAVENDER
	RGB 31,31,31, 31,19,00, 11,23,31, 03,03,03 ; MONO_PAL_VERMILION
	RGB 31,31,31, 05,31,05, 11,23,31, 03,03,03 ; MONO_PAL_CELADON
	RGB 31,31,31, 31,15,15, 11,23,31, 03,03,03 ; MONO_PAL_FUCHSIA
	RGB 31,31,31, 31,08,08, 11,23,31, 03,03,03 ; MONO_PAL_CINNABAR
	RGB 31,31,31, 11,08,31, 11,23,31, 03,03,03 ; MONO_PAL_INDIGO
	RGB 31,31,31, 31,31,00, 11,23,31, 03,03,03 ; MONO_PAL_SAFFRON
	RGB 31,31,31, 20,23,10, 11,11,05, 03,03,03 ; MONO_PAL_GRAY
	RGB 31,31,31, 23,08,00, 17,14,11, 03,03,03 ; MONO_PAL_CAVE
	assert_table_length NUM_OVERWORLD_MONO_PALETTES
