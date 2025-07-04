STM32 IP Configuration Registers
================================

Many peripherals on STM32 microcontrollers and STM32MP microprocessors have a set of four (or more) undocumented registers at the end of each peripheral's address window which can be used to identify the peripheral and its configuration:

```c
    uint32_t HWCFG;
    uint32_t VER;
    uint32_t IPID;
    uint32_t SIDR;
```

For example, we can see these registers at the end of the RTC peripheral on a STM32L562:
```
(gdb) x/8x (void *) RTC + 0x3e0
0x40002be0:	0x00000000	0x00000000	0x00000000	0x00000000
0x40002bf0:	0x01001111	0x00000020	0x00120033	0xa3c5dd01
```

These names can be found in some of ST's CMSIS headers and SVD files, which can include partial names and/or definitions for these registers.

Not all microcontrollers have these registers; on those that do, not all peripherals have them. (For instance, I've never seen these registers on the RCC or FLASH peripherals - which may be related to their unusual nature, or simply because they haven't been configured to support them.) However, these registers seem to be more common on newer families.

There is [some evidence][AN5524] that these registers are also present on SPC5 microcontrollers, but I haven't been able to confirm this myself.

The registers are as follows:


SIDR
----

SIDR is the "size identification" register. (Some documentation refers to it vaguely as the "magic ID".) It contains one of the following values depending on the size of the peripheral's address range:

* `0xA3C5DD01` - for 1K peripherals (most common)
* `0xA3C5DD02` - for 2K peripherals
* `0xA3C5DD04` - for 4K peripherals
* `0xA3C5DD08` - for 8K peripherals (extremely rare; only seen on some versions of the PKA peripheral)

The presence of a value at this address can be used to identify peripherals which support configuration registers, as well as the size of its address window.


IPID
----

IPID, the IP Identifier register, contains a unique value identifying the type of peripheral present.

Many values appear to be broken into two 16-bit fields. The top half appears to identify the general function of the peripheral, e.g. 0012 is used for many time-related peripherals (general timers, watchdog timers, RTC, etc).

```text
    IPID[32:16] - major ID
    IPID[15:0]  - minor ID
```

VER
---

VER, the Version register, contains a value indicating the version of the peripheral.

SVD files indicate that this register is broken into two four-bit fields containing major and minor versions, e.g. 0x0000025 = "v2.5". The rest of the register appears to always be zero.

```text
    VER[8:4] - major revision
    VER[4:0] - minor revision
```

Some ST presentations, e.g. [AN5543][], mention three-part version numbers for peripherals which aren't consistent with these internal version numbers.


HWCFG
-----

HWCFG, the Hardware Configuration register, contains information about the configuration of the peripheral. The exact contents of this register are peripheral-dependent, but fields are often aligned to 4-bit boundaries.

The values in this register often align closely with sections in the reference manual titled "PERIPH implementation".

Some peripherals may have multiple hardware configuration registers. If these are present, they appear before the normal HWCFG register (i.e. the configuration registers "grow down", leaving the other registers in their normal locations).



Sightings
=========

The `sightings` directory contains a list of IP configuration register values which have been seen "in the wild", and the values observed there.

If you have access to a STM32 microcontroller which isn't on this list, you can use the `scan.tcl` OpenOCD script to take observations:

1. Load the script into OpenOCD and halt the microcontroller.

2. Enable all peripherals by writing `~0` to each peripheral enable register.

3. Run `ipconfig_scan 0x20000000 0x40000000 0x60000000` to scan for IP configuration registers in the peripheral range, and paste the results into a new CSV file.

Confirm peripheral names and address ranges with a reference manual, and add notes as appropriate.


[AN5524]: https://www.st.com/resource/en/application_note/an5524-spc58ehxspc58nhx-octalspi-hyperbus-stmicroelectronics.pdf
[AN5543]: https://www.st.com/resource/en/application_note/an5543-guidelines-for-enhanced-spi-communication-on-stm32-mcus-and-mpus-stmicroelectronics.pdf
