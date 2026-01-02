# MT7981 + MT7915/MT7976 TX Power Patcher (V2 layout, split 2/5/6)

[Language: RU](README.md)

Shell script to view, generate, and patch TX power fields in the EEPROM/Factory partition of MT7981-based devices with MT7915/MT7976 radios. Supports the V2 EEPROM layout used by mt76 (OpenWrt).

Based on mt76 sources:
- https://github.com/openwrt/mt76/blob/master/mt7915/eeprom.h
- https://github.com/openwrt/mt76/blob/master/mt7915/eeprom.c

Warning! Modifying calibration/production data may cause instability, overheating, hardware damage, and/or regulatory non-compliance. You proceed entirely at your own risk.

## Important note about the Factory partition

Do not flash a complete Factory dump from another model. The Factory partition stores much more than TX power values (MAC addresses, temperature/RF calibrations, Wi‑Fi configuration, etc.). Flashing a “foreign” Factory often breaks temperature readings, RF calibrations, and other things that may not be immediately obvious.

This script intentionally changes only TX power fields in the V2 layout and nothing else:
- 2.4 GHz: MT_EE_TX0_POWER_2G_V2 @ 0x441 (4 bytes)
- 5 GHz:   MT_EE_TX0_POWER_5G_V2 @ 0x445 (20 bytes)
- 6 GHz:   MT_EE_TX0_POWER_6G_V2 @ 0x465 (32 bytes)

All other EEPROM fields from mt76 (see mt7915/eeprom.h), such as MAC addresses, FT versions, rate deltas, PRECAL/group calibrations, etc., are not touched by the script. Example (excerpt from the driver’s enum):

```
MT_EE_MAC_ADDR       = 0x004,
MT_EE_WIFI_CONF      = 0x190,
MT_EE_RATE_DELTA_*   = 0x252 / 0x29d / 0x7d3 / 0x81e / 0x884,
MT_EE_TX0_POWER_*    = 0x2fc / 0x34b (V1), 0x441 / 0x445 / 0x465 (V2),
MT_EE_PRECAL         = 0xe10 (V1), 0x1010 (V2),
```

Recommended practice:
- Work only with your own Factory dump: the script creates /tmp/factory_dump.bin and patches that file.
- Do not flash “foreign” full dumps. If needed, transfer only TX power values using this script’s presets.

## Features

- Auto-locate “Factory” MTD partition via /proc/mtd and dump to /tmp/factory_dump.bin
- View per-band regions (2.4/5/6 GHz) with offsets
- Generate copy-paste “presets” from an existing Factory dump
- Apply presets to selected bands (2g/5g/6g/all)
- Bilingual interface: en/ru

A “preset” is a set of bytes for each band (2g/5g/6g), stored as shell variables:
- preset_<name>_2g = 4 bytes
- preset_<name>_5g = 20 bytes
- preset_<name>_6g = 32 bytes

## Layout (V2)

Factory/EEPROM offsets per mt76 (V2 layout):
- MT_EE_TX0_POWER_2G_V2 = 0x441 (4 bytes)
- MT_EE_TX0_POWER_5G_V2 = 0x445 (20 bytes)
- MT_EE_TX0_POWER_6G_V2 = 0x465 (32 bytes)

Band structure:
- 2.4 GHz: 4 bytes = 4 chains × 1 byte
- 5 GHz:   20 bytes = 4 chains × 5 groups
- 6 GHz:   32 bytes = 4 chains × 8 groups

These bytes are calibration/level indices consumed by mt76, not direct dBm values. The driver does not require checksums for these fields.

## Requirements

- OpenWrt or a compatible POSIX sh/BusyBox environment
- hexdump, dd, grep, awk, sed
- Access to /proc/mtd and /dev/mtdX (for auto-dump)
- Write permissions if you plan to flash the modified Factory back

## Quick start

1) Inspect band regions from the current Factory (auto-dumps to /tmp):
```
./txpwr.sh
```

2) Generate presets from a factory.bin:
```
./txpwr.sh -g -f factory.bin -p myrouter -b all
```
The script prints preset_myrouter_2g/5g/6g blocks you can copy into the script.

3) Apply a built-in preset to all bands in the dump:
```
./txpwr.sh -p wr3000p
```
What it does:
- Locates Factory
- Creates /tmp/factory_dump.bin
- Patches the selected bands in the dump
- Shows before/after
- Does NOT write back to MTD automatically

## Writing the patched dump back to Factory

Proceed with extreme caution. Always back up the original partition first.
See also the section [“Important note about the Factory partition”](#important-note-about-the-factory-partition).

1) Enable write access to MTD (on some OpenWrt builds it’s protected):
```
opkg update && opkg install kmod-mtd-rw
insmod mtd-rw i_want_a_brick=1
```
Notes:
- This module bypasses write protection and can brick your device.
- Must match your running kernel version.
- Not persistent across reboots; load it again if needed.

2) Make a backup of Factory:
```
dd if=/dev/mtdX of=/tmp/factory_backup.bin
# or:
cat /dev/mtdX > /tmp/factory_backup.bin
```
Where /dev/mtdX is the “Factory” partition (check /proc/mtd).

3) Write the patched dump:
```
mtd write /tmp/factory_dump.bin Factory
```
Or direct writing (riskier; only if you fully understand the consequences):
```
dd if=/tmp/factory_dump.bin of=/dev/mtdX
```

4) If something goes wrong, restore from backup:
```
mtd write /tmp/factory_backup.bin Factory
```

## Confirmation and non-interactive mode

The script asks for confirmation before patching. To apply without manual input:
```
printf 'y\n' | ./txpwr.sh -p ax3000t -b all
```

Or modify the script at your own risk to remove the prompt.

## Localization

Default interface language: en. You can set it:
- via flag:
```
./txpwr.sh -L ru
```
- or via environment variable:
```
TXPWR_LANG=ru ./txpwr.sh
```

## Usage examples

- Show zones from a specific file:
```
./txpwr.sh -f /path/to/factory.bin
```

- Generate a preset for 5 GHz only:
```
./txpwr.sh -g -f factory.bin -p office -b 5g
```

- Apply a preset to 6 GHz only:
```
./txpwr.sh -p rax3000me -b 6g
```

- Apply a preset to all available bands:
```
./txpwr.sh -p wbr3000uax -b all
```

## Built-in presets

Included examples:
- ax3000t: preset_ax3000t_2g / _5g / _6g
- wbr3000uax: preset_wbr3000uax_2g / _5g / _6g
- wr3000p: preset_wr3000p_2g / _5g / _6g
- rax3000me: preset_rax3000me_2g / _5g / _6g

List available presets:
```
./txpwr.sh -h
```
A list of detected preset_<name>_* variables appears at the end of the help output.

## Adding your own preset

1) Generate it from an existing dump:
```
./txpwr.sh -g -f factory.bin -p mydevice -b all
```
2) Paste the generated lines into the script near other preset_*.
3) Adjust values (HEX bytes) if needed.
4) Apply:
```
./txpwr.sh -p mydevice -b all
```

## What exactly gets patched

- 2g: 0x441, 4 bytes (chains 0..3)
- 5g: 0x445, 20 bytes (4 chains × 5 groups)
- 6g: 0x465, 32 bytes (4 chains × 8 groups)

The script prints current bytes at the offsets and what will be written. Writing is done to the specified file (usually /tmp/factory_dump.bin), not directly to the MTD device.

## FAQ

- Do I need to fix checksums?
  - For these fields in the mt76 V2 layout, no additional checksums are required.

- What are these bytes?
  - Calibration/level indices per chain and channel group, interpreted by mt76 (see eeprom.h/eeprom.c).

- Can I patch only 2.4 GHz?
  - Yes: pass -b 2g. Similarly for 5g/6g/all.

- Does the script write directly to /dev/mtd?
  - No. By default it dumps to /tmp/factory_dump.bin and patches that file. You flash back manually with a separate command.

## Alignment with mt76 sources

Offsets and sizes are taken from:
- mt7915/eeprom.h: MT_EE_TX0_POWER_*_V2 constants
- mt7915/eeprom.c: logic that reads calibration fields

This ensures the bytes read/written match the structure expected by the driver for V2.

## License

See [LICENSE](LICENSE).

## Acknowledgements

- Thanks to the OpenWrt project and mt76 developers for the driver and EEPROM documentation.
- Thanks to everyone who shared Factory dumps that helped compare TX power across models.
