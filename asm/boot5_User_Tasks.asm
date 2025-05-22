%include "init.inc"

[org 0]
	jmp 07C0h:시작

시작:
	mov ax, cs
	mov ds, ax
	mov es, ax

	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov ax, word [배경문자]
	mov cx, 0x7FF

그리기:
	mov word [es:di], ax
	add di, 2
	dec cx
	jnz 그리기

읽기:
	mov ax, 0x1000			; es:bx = 1000:0000
	mov es, ax
	mov bx, 0

	mov ah, 2			; 디스크에 있는 데이터를 es:bx의 주소로
	mov al, 9			; 9섹터를 읽을 것이다.
	mov ch, 0			; 0번째 Cylinder
	mov cl, 2			; 2번째 섹터를 읽기 시작한다.
	mov dh, 0			; Head=0
	mov dl, 0			; Drive=0, A: 드라이브
	int 13h				; 읽기!

	;;jc 읽기				; 에러가 나면 다시 함

	mov dx, 0x3F2			; 플로피디스크 드라이브의
	xor al, al			; 모터를 끈다.
	out dx, al

	cli

	mov al, 0x11			; pic의 초기화
	out 0x20, al			; 마스터 pic
	dw 0x00eb, 0x00eb		; jmp 4+2, jmp $+2
	out 0xA0, al			; 슬레이브 pic
	dw 0x00eb, 0x00eb

	mov al, 0x20			; 마스터 pic 인터럽트 시작점
	out 0x21, al
	dw 0x00eb, 0x00eb
	mov al, 0x28			; 슬레이브 pic 인터럽트 시작점
	out 0xA1, al
	dw 0x00eb, 0x00eb

	mov al, 0x04			; 마스터 pic의 irq 2번에
	out 0x21, al			; 슬레이브 pic이 연결되어 있다.
	dw 0x00eb, 0x00eb
	mov al, 0x02			; 슬레이브 pic이 마스터 pic의
	out 0xA1, al			; irq 2번에 연결되어 있다.

	mov al, 0x01			; 8086모드를 사용한다.
	out 0x21, al
	dw 0x00eb, 0x00eb
	out 0xA1, al
	dw 0x00eb, 0x00eb

	mov al, 0xFF			; 슬레이브 pic의 모든 인터럽트를
	out 0xA1, al			; 막아둔다.
	dw 0x00eb, 0x00eb
	mov al, 0xFB			; 마스터 pic의 irq 2번을 제외한
	out 0x21, al			; 모든 인터럽트를 막아둔다.

	jmp 0x1000:0000

	배경문자 db '.', 0x67

	times 510-($-$$) db 0
	dw 0AA55h