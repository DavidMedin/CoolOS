= ACPI - Advanced Configuration and Power Interface
Pain

==== Sources
https://wiki.osdev.org/ACPI
https://wiki.osdev.org/ACPICA

Two main parts : *The Tables* and *The Runtime*.

== The Tables
To start using ACPI, the OS must look for the *RSDP*. If found and is correct, it contains a pointer to the *RSDT* and *XSDT*.
/ RSDP : - Root System Description Pointer
/ RSDT : - Root System Description Table
/ XSDT : - eXtended System Description Table (RSDT but `64` bit)

The runtime contains the *FADT* which is needed to get info on enabling ACPI.
/ FADT : - Fixed ACPI Description Table

== Implementation
Um, maybe don't? Use ACPICA instead, which is an implementation already done, you just need to define 45 functions and you're good to go. Just.