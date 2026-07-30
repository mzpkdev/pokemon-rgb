"""Deterministic coverage for the monochrome overworld palette routines."""

import pytest

from tools.rom_tests.emulator import Emulator


COLOR_BANK = 0x2C
RETURN_HOOK = 0x0100
TEST_STACK = 0xCFF0
SVBK = 0xFF70

W2_BG_PALETTE_DATA = 0xD000
W2_SPR_PALETTE_DATA = 0xD040

BIT_MONOCHROME_OVERWORLD = 3
CEMETERY_TILESET = 15
CAVERN_TILESET = 17


def call_color_routine(
    emulator: Emulator,
    symbol: str,
    *,
    de: int = 0,
) -> int:
    """Call one bank 2C routine and return its A register.

    The test installs a return hook in the fixed ROM bank. The routine has
    completed by the time that hook records its result.
    """
    pyboy = emulator.pyboy
    # The routine is injected before normal boot has established interrupt
    # handlers, so mask pending hardware interrupts for the duration.
    pyboy.memory[0xFFFF] = 0
    pyboy.memory[0xFF0F] = 0
    pyboy.memory[0x2000] = COLOR_BANK
    pyboy.memory[TEST_STACK] = RETURN_HOOK & 0xFF
    pyboy.memory[TEST_STACK + 1] = RETURN_HOOK >> 8
    pyboy.register_file.SP = TEST_STACK
    pyboy.register_file.PC = emulator.symbols[symbol]
    pyboy.register_file.D = de >> 8
    pyboy.register_file.E = de & 0xFF

    result: list[int] = []

    def returned(_: object) -> None:
        result.append(pyboy.register_file.A)

    pyboy.hook_register(0, RETURN_HOOK, returned, None)
    pyboy.tick()
    assert len(result) == 1
    return result[0]


@pytest.mark.parametrize(
    ("current_map", "last_map", "tileset", "expected"),
    (
        (0x00, 0x00, 0, 1),  # Pallet Town
        (0x0A, 0x00, 0, 11),  # Saffron City
        (0x0C, 0x00, 0, 0),  # Route 1
        (0x25, 0x06, 0, 7),  # indoor map reached from Celadon City
        (0x25, 0x06, CEMETERY_TILESET, 12),
        (0x25, 0x06, CAVERN_TILESET, 13),
        (0xE2, 0x06, 0, 13),  # Cerulean Cave 2F
        (0xEF, 0x06, 0, 12),  # Trade Center
        (0xF5, 0x06, 0, 1),  # Lorelei's room
        (0xF6, 0x06, 0, 13),  # Bruno's room
    ),
)
def test_overworld_palette_resolver(
    emulator: Emulator,
    current_map: int,
    last_map: int,
    tileset: int,
    expected: int,
) -> None:
    emulator.write("wCurMap", current_map)
    emulator.write("wLastMap", last_map)
    emulator.write("wCurMapTileset", tileset)

    assert call_color_routine(emulator, "GetOverworldMonoPalette") == expected


def rgb15(red: int, green: int, blue: int) -> bytes:
    value = red | green << 5 | blue << 10
    return value.to_bytes(2, "little")


PALLET_PALETTE = b"".join(
    (
        rgb15(31, 31, 31),
        rgb15(23, 17, 31),
        rgb15(11, 23, 31),
        rgb15(3, 3, 3),
    )
)


@pytest.mark.parametrize(
    "destination",
    (W2_BG_PALETTE_DATA, W2_SPR_PALETTE_DATA),
    ids=("background", "sprites"),
)
def test_monochrome_loader_fills_all_eight_palettes(
    emulator: Emulator,
    destination: int,
) -> None:
    emulator.write("wOptions", 1 << BIT_MONOCHROME_OVERWORLD)
    emulator.write("wCurMap", 0x00)
    emulator.write("wLastMap", 0x00)
    emulator.write("wCurMapTileset", 0)

    call_color_routine(
        emulator,
        "LoadOverworldMonochromePalettes",
        de=destination,
    )

    emulator.pyboy.memory[SVBK] = 2
    actual = bytes(emulator.pyboy.memory[destination : destination + 64])
    assert actual == PALLET_PALETTE * 8


def test_full_color_option_leaves_palette_data_untouched(
    emulator: Emulator,
) -> None:
    sentinel = bytes(range(64))
    emulator.pyboy.memory[SVBK] = 2
    emulator.pyboy.memory[
        W2_BG_PALETTE_DATA : W2_BG_PALETTE_DATA + len(sentinel)
    ] = sentinel
    emulator.pyboy.memory[SVBK] = 1
    emulator.write("wOptions", 0)

    call_color_routine(
        emulator,
        "LoadOverworldMonochromePalettes",
        de=W2_BG_PALETTE_DATA,
    )

    emulator.pyboy.memory[SVBK] = 2
    actual = bytes(
        emulator.pyboy.memory[
            W2_BG_PALETTE_DATA : W2_BG_PALETTE_DATA + len(sentinel)
        ]
    )
    assert actual == sentinel
