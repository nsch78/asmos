%include "init.inc"

[org 0]
	jmp 07C0h:����

����:
	mov ax, cs
	mov ds, ax
	mov es, ax

	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov ax, word [��湮��]
	mov cx, 0x7FF

�׸���:
	mov word [es:di], ax
	add di, 2
	dec cx
	jnz �׸���

�б�:
	mov ax, 0x1000			; es:bx = 1000:0000
	mov es, ax
	mov bx, 0

	mov ah, 2			; ��ũ�� �ִ� �����͸� es:bx�� �ּҷ�
	mov al, 9			; 9���͸� ���� ���̴�.
	mov ch, 0			; 0��° Cylinder
	mov cl, 2			; 2��° ���͸� �б� �����Ѵ�.
	mov dh, 0			; Head=0
	mov dl, 0			; Drive=0, A: ����̺�
	int 13h				; �б�!

	;;jc �б�				; ������ ���� �ٽ� ��

	mov dx, 0x3F2			; �÷��ǵ�ũ ����̺���
	xor al, al			; ���͸� ����.
	out dx, al

	cli

	mov al, 0x11			; pic�� �ʱ�ȭ
	out 0x20, al			; ������ pic
	dw 0x00eb, 0x00eb		; jmp 4+2, jmp $+2
	out 0xA0, al			; �����̺� pic
	dw 0x00eb, 0x00eb

	mov al, 0x20			; ������ pic ���ͷ�Ʈ ������
	out 0x21, al
	dw 0x00eb, 0x00eb
	mov al, 0x28			; �����̺� pic ���ͷ�Ʈ ������
	out 0xA1, al
	dw 0x00eb, 0x00eb

	mov al, 0x04			; ������ pic�� irq 2����
	out 0x21, al			; �����̺� pic�� ����Ǿ� �ִ�.
	dw 0x00eb, 0x00eb
	mov al, 0x02			; �����̺� pic�� ������ pic��
	out 0xA1, al			; irq 2���� ����Ǿ� �ִ�.

	mov al, 0x01			; 8086��带 ����Ѵ�.
	out 0x21, al
	dw 0x00eb, 0x00eb
	out 0xA1, al
	dw 0x00eb, 0x00eb

	mov al, 0xFF			; �����̺� pic�� ��� ���ͷ�Ʈ��
	out 0xA1, al			; ���Ƶд�.
	dw 0x00eb, 0x00eb
	mov al, 0xFB			; ������ pic�� irq 2���� ������
	out 0x21, al			; ��� ���ͷ�Ʈ�� ���Ƶд�.

	jmp 0x1000:0000

	��湮�� db '.', 0x67

	times 510-($-$$) db 0
	dw 0AA55h