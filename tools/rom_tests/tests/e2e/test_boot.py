"""Basic end-to-end coverage for the built debug ROM."""

from tools.rom_tests.emulator import Emulator


def test_debug_rom_reaches_title_screen(emulator: Emulator) -> None:
    emulator.tick(600)

    pixels = emulator.pyboy.screen.image.convert("RGB").getcolors(maxcolors=256)
    assert pixels is not None
    assert len(pixels) > 1


def test_debug_new_game_spawns_static_pikachu(emulator: Emulator) -> None:
    emulator.tick(600)
    emulator.advance_until(
        emulator.is_in_bedroom_overworld,
        button="select",
        max_presses=20,
        description="debug-new-game-bedroom",
    )

    assert emulator.read("wNumSprites") == 0
    assert emulator.read("wPartyCount") == 6
    assert emulator.read("wSpritePikachuStateData1PictureID") == 0x3A
    assert emulator.read("wSpritePikachuStateData1MovementStatus") == 1
    assert emulator.read("wSpritePikachuStateData1ImageIndex") != 0xFF
    assert emulator.read("wSpritePikachuStateData2ImageBaseOffset") == 2
