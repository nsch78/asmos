%include "init.inc"

[org 0x10000]
[bits 16]

����:
	cld
	mov ax, cs
	mov ds, ax
	xor ax, ax
	mov ss, ax

	xor eax, eax
	lea eax, [tss]			; EAX�� tss �����ּҸ� �ִ´�.
	add eax, 0x10000
	mov [descriptor4+2], ax
	shr eax, 16
	mov [descriptor4+4], al
	mov [descriptor4+7], ah


	xor eax, eax
	lea eax, [����Լ�]		; EAX�� ����Լ� �Լ��� �ּҸ� �ִ´�.
	add eax, 0x10000
	mov [descriptor7], ax
	shr eax, 16
	mov [descriptor7+6], al
	mov [descriptor7+7], ah

	cli
	lgdt [gdtr]

	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax

	jmp $+2
	nop
	nop

	jmp dword SysCodeSelector:PM_����


[bits 32]
	times 80 dd 0			; ���� ������ ����� ���´�.

PM_����:
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx

	lea esp, [PM_����]

	cld
	mov ax, SysDataSelector
	mov es, ax
	xor eax, eax
	xor ecx, ecx
	mov ax, 256			; idt������ 256���� �� ��ũ���͸� �����Ѵ�.
	mov edi, 0

loop_idt:
	lea esi, [idt_ignore]
	mov cx, 8			; ��ũ���� �ϳ��� 8����Ʈ �̴�.
	rep movsb
	dec ax
	jnz loop_idt

	mov edi, 8*0x20			; Ÿ�̸� idt ��ũ���͸� �����Ѵ�.
	lea esi, [idt_timer]
	mov cx, 8
	rep movsb


	mov edi, 8*0x21			; Ű���� idt ��ũ���͸� �����Ѵ�.
	lea esi, [idt_keyboard]
	mov cx, 8
	rep movsb

	mov edi, 8*0x80			; Ʈ�� idt ��ũ���͸� �����Ѵ�.
	lea esi, [idt_soft_int]
	mov cx, 8
	rep movsb

	lidt [idtr]			; IDT�� ����Ѵ�.

	mov al, 0xFC			; ���Ƶξ��� ���ͷ�Ʈ ��
	out 0x21, al			; Ÿ�̸ӿ� Ű���常 �ٽ� ��ȿ�ϰ� �Ѵ�.
	sti

	mov ax, TSSSelector
	ltr ax

	mov eax, [CurrentTask]		; Task Struct�� ����Ʈ�� �����.
	add eax, TaskList
	lea edx, [User1regs]
	mov [eax], edx
	add eax, 4
	lea edx, [User2regs]
	mov [eax], edx
	add eax, 4
	lea edx, [User3regs]
	mov [eax], edx
	add eax, 4
	lea edx, [User4regs]
	mov [eax], edx
	add eax, 4
	lea edx, [User5regs]
	mov [eax], edx

	mov eax, [CurrentTask]		; ù���� Task�� �����Ѵ�.(CurrentTask = 0).
	add eax, TaskList
	mov ebx, [eax]
	jmp sched

scheduler:
	lea esi, [esp]			; Ŀ�� esp�� ���� �������͵��� �ִ�.
	
	xor eax, eax
	mov eax, [CurrentTask]
	add eax, TaskList

	mov edi, [eax]			; ���� ���� ���� �½�ũ�� ���� ������ �����Ѵ�.
	
	mov ecx, 17			; 17���� dword(68byte) ��� ���������� ����Ʈ ��.
	rep movsd			; �����Ѵ�.
	add esp, 68			; 17���� dword��ŭ ������ �ǵ��� ���´�.

	add dword [CurrentTask], 4
	mov eax, [NumTask]
	mov ebx, [CurrentTask]
	cmp eax, ebx
	jne yet
	mov byte [CurrentTask], 0

yet:
	xor eax, eax
	mov eax, [CurrentTask]
	add eax, TaskList
	mov ebx, [eax]

sched:
	mov [tss_esp0], esp		; Ŀ�� ������ ���� �ּҸ� tss�� ������ �д�.
	lea esp, [ebx]			; ebx���� ���� �½�Ʈ�� ���� ������ �ּҰ� �ִ�.

	popad				; eax, ebx, ecx, edx, ebp, esi, edi�� �����Ѵ�.
	pop ds				; ds, es, fs, gs�� �����Ѵ�.
	pop es
	pop fs
	pop gs
					; iret������� eip, cs, eflags, esp, ss�� �����ǰ�,
	iret				; ���� ���� �½�ũ�� ����Ī �ȴ�.

	CurrentTask dd 0		; ���� ���� ���� �½�ũ ��ȣ
	NumTask dd 20			; ��� �½�ũ ��
	TaskList: times 5 dd 0		; �� �½�ũ ���� ������ ������ �迭

;**************************************
;*********   Subrutines   *************
;**************************************
����Լ�:
	push eax
	push es
	mov ax, VideoSelector
	mov es, ax

����Լ�_loop:
	mov al, byte [esi]
	mov byte [es:edi], al
	inc edi
	mov byte [es:edi], 0x06
	inc esi
	inc edi
	or al, al
	jz ����Լ�_end
	jmp ����Լ�_loop

����Լ�_end:
	pop es
	pop eax
	ret

;***************************************
;********  ���� ���μ��� ��ƾ  *********
;***************************************
user_process1:
	mov eax, 80*2*2+2*5
	lea ebx, [msg_user_process1_1]
	int 0x80
	mov eax, 80*2*3+2*5
	lea ebx, [msg_user_process1_2]
	int 0x80
	inc byte [msg_user_process1_2]
	jmp user_process1

	msg_user_process1_1 db "User Process1", 0
	msg_user_process1_2 db ".I'am running now", 0

user_process2:
	mov eax, 80*2*2+2*35
	lea ebx, [msg_user_process2_1]
	int 0x80
	mov eax, 80*2*3+2*35
	lea ebx, [msg_user_process2_2]
	int 0x80
	inc byte [msg_user_process2_2]
	jmp user_process2

	msg_user_process2_1 db "User Process2", 0
	msg_user_process2_2 db ".I'am running now", 0

user_process3:
	mov eax, 80*2*5+2*5
	lea ebx, [msg_user_process3_1]
	int 0x80
	mov eax, 80*2*6+2*5
	lea ebx, [msg_user_process3_2]
	int 0x80
	inc byte [msg_user_process3_2]
	jmp user_process3

	msg_user_process3_1 db "User Process3", 0
	msg_user_process3_2 db ".I'am running now", 0


user_process4:
	mov eax, 80*2*5+2*35
	lea ebx, [msg_user_process4_1]
	int 0x80
	mov eax, 80*2*6+2*35
	lea ebx, [msg_user_process4_2]
	int 0x80
	inc byte [msg_user_process4_2]
	jmp user_process4

	msg_user_process4_1 db "User Process4", 0
	msg_user_process4_2 db ".I'am running now", 0

user_process5:
	mov eax, 80*2*9+2*5
	lea ebx, [msg_user_process5_1]
	int 0x80
	mov eax, 80*2*10+2*5
	lea ebx, [msg_user_process5_2]
	int 0x80
	inc byte [msg_user_process5_2]
	jmp user_process5

	msg_user_process5_1 db "User Process5", 0
	msg_user_process5_2 db ".I'am running now", 0

;***************************************
;********      Data Area       *********
;***************************************
gdtr:
	dw gdt_end-gdt-1
	dd gdt

gdt:
	dd 0, 0
	dd 0x0000FFFF, 0x00CF9A00
	dd 0x0000FFFF, 0x00CF9200
	dd 0x8000FFFF, 0x0040920B

descriptor4:				; TSS ��ũ����
	dw 104
	dw 0
	db 0
	db 0x89
	db 0
	db 0

	dd 0x0000FFFF, 0x00FCFA00	; ���� �ڵ� ���׸�Ʈ
	dd 0x0000FFFF, 0x00FCF200	; ���� ������ ���׸�Ʈ


descriptor7:				; �ݰ���Ʈ ��ũ����
	dw 0
	dw SysCodeSelector
	db 0x02
	db 0xEC
	db 0
	db 0

gdt_end:

tss:
	dw 0, 0				; ���� �׽�ũ���� back link

tss_esp0:
	dd 0				; ESP0
	dw SysDataSelector, 0		; SS0, ������
	dd 0				; ESP1
	dw 0, 0				; SS1, ������
	dd 0				; ESP2
	dw 0, 0				; SS2, ������
	dd 0

tss_eip:
	dd 0, 0				; EIP, EFLAGS
	dd 0, 0, 0, 0

tss_esp:
	dd 0, 0, 0, 0			; ESP, EBP, ESI, EDI
	dw 0, 0				; ES, ������
	dw 0, 0				; CS, ������
	dw 0, 0				; SS, ������
	dw 0, 0				; DS, ������
	dw 0, 0				; FS, ������
	dw 0, 0				; GS, ������
	dw 0, 0				; LDT, ������
	dw 0, 0				; ����׿� T��Ʈ, IO�㰡 ��Ʈ

;***************************************
;******** User1 Task_Structure *********
;***************************************
times 63 dd 0				; ���� ���� ����
User1Stack:
User1regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA������� ��� POP�ȴ�.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process1		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User1Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET������� ��� pop�ȴ�.

;***************************************
;******** User2 Task_Structure *********
;***************************************
times 63 dd 0				; ���� ���� ����
User2Stack:
User2regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA������� ��� POP�ȴ�.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process2		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User2Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET������� ��� pop�ȴ�.

;***************************************
;******** User3 Task_Structure *********
;***************************************
times 63 dd 0				; ���� ���� ����
User3Stack:
User3regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA������� ��� POP�ȴ�.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process3		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User3Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET������� ��� pop�ȴ�.


;***************************************
;******** User4 Task_Structure *********
;***************************************
times 63 dd 0				; ���� ���� ����
User4Stack:
User4regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA������� ��� POP�ȴ�.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process4		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User4Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET������� ��� pop�ȴ�.


;***************************************
;******** User5 Task_Structure *********
;***************************************
times 63 dd 0				; ���� ���� ����
User5Stack:
User5regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA������� ��� POP�ȴ�.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process5		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User5Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET������� ��� pop�ȴ�.

idtr:
	dw 256*8-1			; IDT�� Limit
	dd 0				; IDT�� Base Address


;***************************************
;***** interrupt Service Routines ******
;***************************************

isr_ignore:
	push gs
	push fs
	push es
	push ds
	pushad

	mov ax, SysDataSelector
	mov DS, ax
	mov ES, ax
	mov FS, ax
	mov GS, ax

	mov al, 0x20
	out 0x20, al

	mov edi, (80*2*0)
	lea esi, [����_isr_�޽���]
	call ����Լ�
	inc byte [����_isr_�޽���]

	jmp ret_from_int

isr_32_timer:
	push gs
	push fs
	push es
	push ds
	pushad

	mov ax, SysDataSelector
	mov DS, ax
	mov ES, ax
	mov FS, ax
	mov GS, ax

	mov al, 0x20
	out 0x20, al

	mov edi, 80*2*0
	lea esi, [�ð�_32_isr_�޽���]
	call ����Լ�
	inc byte [�ð�_32_isr_�޽���]

	jmp ret_from_int


isr_33_keyboard:
	push gs
	push fs
	push es
	push ds
	pushad

	mov ax, SysDataSelector
	mov DS, ax
	mov ES, ax
	mov FS, ax
	mov GS, ax

	in al, 0x60

	mov al, 0x20
	out 0x20, al

	mov edi, (80*2*0)+(2*35)
	lea esi, [Ű����_33_isr_�޽���]
	call ����Լ�
	inc byte [Ű����_33_isr_�޽���]

	jmp ret_from_int

isr_128_soft_int:
	push gs
	push fs
	push es
	push ds
	pushad

	mov cx, SysDataSelector
	mov DS, cx
	mov ES, cx
	mov FS, cx
	mov GS, cx
	
	;;pop eax
	
	mov edi, eax
	lea esi, [ebx]
	call ����Լ�

	jmp ret_from_int

ret_from_int:
	xor eax, eax
	mov eax, [esp+52]
	and eax, 0x00000003
	xor ebx, ebx
	mov bx, cs
	and ebx, 0x00000003
	cmp eax, ebx
	ja scheduler

	popad
	pop ds
	pop es
	pop fs
	pop gs

	iret


����_isr_�޽��� db "This is an ignorable interrupt", 0
�ð�_32_isr_�޽��� db ".this is the timer interrupt", 0
Ű����_33_isr_�޽��� db ".this is the keyboard interrupt", 0
����SW_128_isr_�޽��� db ". this is the soft_int interrupt", 0


;***************************************
;***************  IDT ******************
;***************************************
idt_ignore:
	dw isr_ignore
	dw 0x08
	db 0
	db 0x8E
	dw 0x0001

idt_timer:
	dw isr_32_timer
	dw 0x08
	db 0
	db 0x8E
	dw 0x0001

idt_keyboard:
	dw isr_33_keyboard
	dw 0x08
	db 0
	db 0x8E
	dw 0x0001

idt_soft_int:
	dw isr_128_soft_int
	dw 0x08
	db 0
	db 0xEF
	dw 0x0001

times 4608-($-$$) db 0