%include "init.inc"

[org 0x10000]
[bits 16]

시작:
	cld
	mov ax, cs
	mov ds, ax
	xor ax, ax
	mov ss, ax

	xor eax, eax
	lea eax, [tss]			; EAX에 tss 물리주소를 넣는다.
	add eax, 0x10000
	mov [descriptor4+2], ax
	shr eax, 16
	mov [descriptor4+4], al
	mov [descriptor4+7], ah


	xor eax, eax
	lea eax, [출력함수]		; EAX에 출력함수 함수의 주소를 넣는다.
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

	jmp dword SysCodeSelector:PM_시작


[bits 32]
	times 80 dd 0			; 스택 영역을 만들어 놓는다.

PM_시작:
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx

	lea esp, [PM_시작]

	cld
	mov ax, SysDataSelector
	mov es, ax
	xor eax, eax
	xor ecx, ecx
	mov ax, 256			; idt영역에 256개의 빈 디스크립터를 복사한다.
	mov edi, 0

loop_idt:
	lea esi, [idt_ignore]
	mov cx, 8			; 디스크립터 하나는 8바이트 이다.
	rep movsb
	dec ax
	jnz loop_idt

	mov edi, 8*0x20			; 타이머 idt 디스크립터를 복사한다.
	lea esi, [idt_timer]
	mov cx, 8
	rep movsb


	mov edi, 8*0x21			; 키보드 idt 디스크립터를 복사한다.
	lea esi, [idt_keyboard]
	mov cx, 8
	rep movsb

	mov edi, 8*0x80			; 트랩 idt 디스크립터를 복사한다.
	lea esi, [idt_soft_int]
	mov cx, 8
	rep movsb

	lidt [idtr]			; IDT를 등록한다.

	mov al, 0xFC			; 막아두었던 인터럽트 중
	out 0x21, al			; 타이머와 키보드만 다시 유효하게 한다.
	sti

	mov ax, TSSSelector
	ltr ax

	mov eax, [CurrentTask]		; Task Struct의 리스트를 만든다.
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

	mov eax, [CurrentTask]		; 첫번재 Task를 선택한다.(CurrentTask = 0).
	add eax, TaskList
	mov ebx, [eax]
	jmp sched

scheduler:
	lea esi, [esp]			; 커널 esp에 유저 레지스터들이 있다.
	
	xor eax, eax
	mov eax, [CurrentTask]
	add eax, TaskList

	mov edi, [eax]			; 현재 실행 중인 태스크의 저장 영역을 실행한다.
	
	mov ecx, 17			; 17개의 dword(68byte) 모든 레지스터의 바이트 합.
	rep movsd			; 복사한다.
	add esp, 68			; 17개의 dword만큼 스택을 되돌려 놓는다.

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
	mov [tss_esp0], esp		; 커널 영역의 스택 주소를 tss에 기입해 둔다.
	lea esp, [ebx]			; ebx에는 다음 태스트의 저장 영역의 주소가 있다.

	popad				; eax, ebx, ecx, edx, ebp, esi, edi를 복원한다.
	pop ds				; ds, es, fs, gs를 복원한다.
	pop es
	pop fs
	pop gs
					; iret명령으로 eip, cs, eflags, esp, ss가 복원되고,
	iret				; 다음 유저 태스크로 스위칭 된다.

	CurrentTask dd 0		; 현재 실행 중인 태스크 번호
	NumTask dd 20			; 모든 태스크 수
	TaskList: times 5 dd 0		; 각 태스크 저장 영역의 포인터 배열

;**************************************
;*********   Subrutines   *************
;**************************************
출력함수:
	push eax
	push es
	mov ax, VideoSelector
	mov es, ax

출력함수_loop:
	mov al, byte [esi]
	mov byte [es:edi], al
	inc edi
	mov byte [es:edi], 0x06
	inc esi
	inc edi
	or al, al
	jz 출력함수_end
	jmp 출력함수_loop

출력함수_end:
	pop es
	pop eax
	ret

;***************************************
;********  유저 프로세스 루틴  *********
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

descriptor4:				; TSS 디스크립터
	dw 104
	dw 0
	db 0
	db 0x89
	db 0
	db 0

	dd 0x0000FFFF, 0x00FCFA00	; 유저 코드 세그먼트
	dd 0x0000FFFF, 0x00FCF200	; 유저 데이터 세그먼트


descriptor7:				; 콜게이트 디스크립터
	dw 0
	dw SysCodeSelector
	db 0x02
	db 0xEC
	db 0
	db 0

gdt_end:

tss:
	dw 0, 0				; 이전 테스크로의 back link

tss_esp0:
	dd 0				; ESP0
	dw SysDataSelector, 0		; SS0, 사용안함
	dd 0				; ESP1
	dw 0, 0				; SS1, 사용안함
	dd 0				; ESP2
	dw 0, 0				; SS2, 사용안함
	dd 0

tss_eip:
	dd 0, 0				; EIP, EFLAGS
	dd 0, 0, 0, 0

tss_esp:
	dd 0, 0, 0, 0			; ESP, EBP, ESI, EDI
	dw 0, 0				; ES, 사용안함
	dw 0, 0				; CS, 사용안함
	dw 0, 0				; SS, 사용안함
	dw 0, 0				; DS, 사용안함
	dw 0, 0				; FS, 사용안함
	dw 0, 0				; GS, 사용안함
	dw 0, 0				; LDT, 사용안함
	dw 0, 0				; 디버그용 T비트, IO허가 비트

;***************************************
;******** User1 Task_Structure *********
;***************************************
times 63 dd 0				; 유저 스택 영역
User1Stack:
User1regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA명령으로 모두 POP된다.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process1		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User1Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET명령으로 모두 pop된다.

;***************************************
;******** User2 Task_Structure *********
;***************************************
times 63 dd 0				; 유저 스택 영역
User2Stack:
User2regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA명령으로 모두 POP된다.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process2		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User2Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET명령으로 모두 pop된다.

;***************************************
;******** User3 Task_Structure *********
;***************************************
times 63 dd 0				; 유저 스택 영역
User3Stack:
User3regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA명령으로 모두 POP된다.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process3		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User3Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET명령으로 모두 pop된다.


;***************************************
;******** User4 Task_Structure *********
;***************************************
times 63 dd 0				; 유저 스택 영역
User4Stack:
User4regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA명령으로 모두 POP된다.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process4		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User4Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET명령으로 모두 pop된다.


;***************************************
;******** User5 Task_Structure *********
;***************************************
times 63 dd 0				; 유저 스택 영역
User5Stack:
User5regs:
	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, ESP, EBX, EDX, ECX, EAX
					; POPA명령으로 모두 POP된다.
	dw UserDataSelector, 0		; DS
	dw UserDataSelector, 0		; ES
	dw UserDataSelector, 0		; FS
	dw UserDataSelector, 0		; GS

	dd user_process5		; EIP
	dw UserCodeSelector, 0		; CS
	dd 0x200			; EFlags(0x200 enable ints)
	dd User5Stack			; ESP
	dw UserDataSelector, 0		; SS
					; IRET명령으로 모두 pop된다.

idtr:
	dw 256*8-1			; IDT의 Limit
	dd 0				; IDT의 Base Address


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
	lea esi, [무시_isr_메시지]
	call 출력함수
	inc byte [무시_isr_메시지]

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
	lea esi, [시계_32_isr_메시지]
	call 출력함수
	inc byte [시계_32_isr_메시지]

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
	lea esi, [키보드_33_isr_메시지]
	call 출력함수
	inc byte [키보드_33_isr_메시지]

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
	call 출력함수

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


무시_isr_메시지 db "This is an ignorable interrupt", 0
시계_32_isr_메시지 db ".this is the timer interrupt", 0
키보드_33_isr_메시지 db ".this is the keyboard interrupt", 0
응용SW_128_isr_메시지 db ". this is the soft_int interrupt", 0


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