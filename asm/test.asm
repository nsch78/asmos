section .txt
	global _main	
	extern _printf

_main:
	mov ebx, [mesg]
	mov eax, 4
	int 80

	ret
출력:
	push ebp
	mov ebp, esp

	mov esp, ebp
	pop ebp
	ret

mesg db "hi", 0
