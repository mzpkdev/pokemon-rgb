"""Basic end-to-end coverage for the built debug ROM."""

from tools.rom_tests.emulator import Emulator


def test_debug_rom_reaches_title_screen(emulator: Emulator) -> None:
    emulator.tick(600)

    pixels = emulator.pyboy.screen.image.convert("RGB").getcolors(maxcolors=256)
    assert pixels is not None
    assert len(pixels) > 1


def test_debug_new_game_spawns_static_pikachu(emulator: Emulator) -> None:
    emulator.tick(1800)
    emulator.write("wDefaultMap", 0x26)
    # The title screen reads hJoyHeld after its exit animation, so keep Select
    # held until that check instead of sending a short button tap.
    emulator.pyboy.button("select", delay=1000)
    emulator.tick_until(
        emulator.is_in_bedroom_overworld,
        max_frames=3600,
        description="debug-new-game-bedroom",
    )
    emulator.tick(300)

    assert emulator.read("wNumSprites") == 0
    assert emulator.read("wPartyCount") == 6
    assert emulator.read("wSpritePikachuStateData1PictureID") == 0x65
    assert emulator.read("wSpritePikachuStateData1MovementStatus") == 1
    assert emulator.read("wSpritePikachuStateData1ImageIndex") != 0xFF
    assert emulator.read("wSpritePikachuStateData2ImageBaseOffset") == 2

    old_player = (emulator.read("wYCoord"), emulator.read("wXCoord"))
    opposites = {"left": "right", "right": "left", "up": "down", "down": "up"}
    moved_with = None
    for button in ("left", "right", "up", "down"):
        emulator.press(button)
        if (emulator.read("wYCoord"), emulator.read("wXCoord")) != old_player:
            moved_with = button
            break
    assert moved_with is not None

    emulator.tick_until(
        lambda: (
            emulator.read("wSpritePikachuStateData2MapY"),
            emulator.read("wSpritePikachuStateData2MapX"),
        )
        == (old_player[0] + 4, old_player[1] + 4),
        max_frames=120,
        description="pikachu-reaches-previous-player-tile",
    )

    # Pikachu is deliberately non-blocking, so immediately backtracking
    # through its tile cannot trap the player.
    emulator.press(opposites[moved_with])
    assert (emulator.read("wYCoord"), emulator.read("wXCoord")) == old_player

    found_wall = False
    for _ in range(8):
        before_player = (emulator.read("wYCoord"), emulator.read("wXCoord"))
        before_pikachu = (
            emulator.read("wSpritePikachuStateData2MapY"),
            emulator.read("wSpritePikachuStateData2MapX"),
        )
        emulator.press("up")
        after_player = (emulator.read("wYCoord"), emulator.read("wXCoord"))
        if after_player == before_player:
            emulator.tick(30)
            assert emulator.read("wPikachuFollowCommandBufferSize") == 0
            assert (
                emulator.read("wSpritePikachuStateData2MapY"),
                emulator.read("wSpritePikachuStateData2MapX"),
            ) == before_pikachu
            found_wall = True
            break
    assert found_wall


def test_debug_new_game_spawns_static_pikachu_outdoors(emulator: Emulator) -> None:
    emulator.tick(1800)
    emulator.write("wDefaultMap", 0x00)
    emulator.pyboy.button("select", delay=1000)
    emulator.tick_until(
        lambda: emulator.is_in_overworld_map(0x00),
        max_frames=3600,
        description="debug-new-game-pallet-town",
    )
    emulator.tick(300)

    assert emulator.read("wPartyCount") == 6
    assert emulator.read("wSpritePikachuStateData1PictureID") == 0x65
    assert emulator.read("wSpritePikachuStateData1MovementStatus") == 1
    assert emulator.read("wSpritePikachuStateData1ImageIndex") != 0xFF
    assert 2 <= emulator.read("wSpritePikachuStateData2ImageBaseOffset") < 11
