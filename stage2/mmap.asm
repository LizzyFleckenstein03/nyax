%define MAPMAGIC 0x534D4150

mmap:
	mov ebx, .msg
	call print_str

	xor ebx, ebx    ; counter for interrupt
	mov di, MEMMAP

.loop:
	; issue an INT 0x15, EAX = 0xE820 interrupt
	mov eax, 0xE820
	mov ecx, 24
	mov edx, MAPMAGIC
	int 0x15

	cmp eax, MAPMAGIC ; detect failure
	jne .fail

	mov eax, [di+16]
	cmp eax, 2
	ja .next

	mov eax, [di+4]
	cmp eax, 0
	jne .keep

	mov eax, [di+0]
	cmp eax, 0x100000
	jb .next

.keep:
	add di, 24

.next:
	cmp ebx, 0
	jne .loop

	mov ax, di
	sub ax, MEMMAP
	xor dx, dx
	mov bx, 24
	div bx
	mov [MEMMAPCNT], ax

	mov eax, MEMMAPCNT
	call print_dec
	call newline
	;jmp $

	ret

.fail:
	mov ebx, .fail_msg
	call print_str
	jmp $

.msg: db "getting extended memory map", 10, 13, 0
.fail_msg: db "memory map failure", 10, 13, 0

