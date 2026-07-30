"""Basic end-to-end coverage for the built debug ROM."""

from tools.rom_tests.emulator import Emulator


def test_debug_rom_reaches_title_screen(emulator: Emulator) -> None:
    emulator.tick(600)

    pixels = emulator.pyboy.screen.image.convert("RGB").getcolors(maxcolors=256)
    assert pixels is not None
    assert len(pixels) > 1
