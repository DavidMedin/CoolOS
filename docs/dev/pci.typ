#import "@preview/bytefield:0.0.5": *

= PCI - Peripheral Component Interconnect

This is a mess.

== Sources:
https://forum.osdev.org/viewtopic.php?f=1&t=36972\
https://wiki.osdev.org/Pci#Enumerating_PCI_Buses\
https://wiki.osdev.org/PCI\
https://tldp.org/LDP/tlk/dd/pci.html\

= Memory
So there is the main system memory space we all know and love, and it lives in RAM, as one expects. But there are other memory spaces needed for PCI.\
- PCI I/O
- PCI Memory
- PCI Configuration
These don't live in RAM (I think) as it would slow down the CPU. So, maybe all devices have memory, and each device has a portion of the space, so that when you yell on the PCI bus "Hey, what's at address X?", whoever has address X would replay. Like a distributed memory system. *I DON'T KNOW IF THIS IS RIGHT!*
= Configuration
This memory space holds just a bunch of PCI Configuration Headers.
/ PCI Configuration Headers : A `256` byte data structure holding information about the device.
/ Cycle : An address as it appears on the PCI bus. There are two two types of cycles:
/ Cycle Type 0 : A cycle for a device that is on the current PCI bus.
/ Cycle Type 1 : A cycle for a device that is on _another_ PCI bus. All devices except for PCI-PCI Bridges ignore this cycle.

=== But how do I access this memory that isn't in RAM?
With CPU Port I/O, aka magic.\
There are two `32` bit I/O locations needed,\
- `0xcf8` - `CONFIG_ADDRESS` - Write to this to say where you're going.
- `0xcfc` - `CONFIG_DATA` - Read and Write from/to this to do data things.

#figure(caption: [`CONFIG_ADDRESS` (`0xcf8`) format])[
  #bytefield(
    bitheader("bits",
    // where are bit labels?
    0, [start],
    7,
    10,
    15,
    23,
    30,
    31,
    ),
    bits(8)[Register Offset],
    bits(3)[Function Number],
    bits(5)[Device Number],
    bits(8)[Bus Number],
    bits(7)[Reserved],
    bits(1)[Enable Bit]
  )
]

= PCI I/O and PCI Memory Addresses
These are used for Device Drivers running on the CPU to communicate with their PCI Devices.

Devices cannot use this space until the _command_ field in the Configuration Header has been set.


= PCIe - Peripheral Component Interconnect Express
More modern version of PCI. Allows bigger memory space, and memeory mappings into physical memory space. I.E, no `in`/`out` instructions.
