SysCodeSelector		equ 0x08
SysDataSelector 	equ 0x10
VideoSelector		equ 0x18
TSSSelector		equ 0x20
UserCodeSelector	equ 0x28+3
UserDataSelector	equ 0x30+3

IDT_BASE		equ 0xC0001000
TSS_ESP0_WHERE		equ 0x90000