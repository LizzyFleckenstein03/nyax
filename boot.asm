[org 0x7C00]

%define PAGETABLE 0x1000
%define KERNEL 0xD000
%define STACK 0x7E00

boot:
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	mov bp, STACK
	mov sp, bp

	mov ax, booting_msg
	call print_str

	mov bx, KERNEL
	mov cl, 2
	mov al, (MAIN_SIZE + 511) / 512
	call load_disk

	mov di, PAGETABLE+0x0000
.clr_buf:
	mov byte[di], 0
	inc di
	cmp di, PAGETABLE+0x4000
	jne .clr_buf

	mov dword[PAGETABLE+0x0000], PAGETABLE+0x1003
	mov dword[PAGETABLE+0x1000], PAGETABLE+0x2003
	mov dword[PAGETABLE+0x2000], PAGETABLE+0x3003

	mov eax, 3
	mov di, PAGETABLE+0x3000
.build_pt:
	mov [di], eax
	add eax, 0x1000
	add di, 8
	cmp eax, 0x100000
	jb .build_pt

	mov di, PAGETABLE

	mov al, 0xFF
	out 0xA1, al
	out 0x21, al

	nop
	nop

	lidt [IDT]

	mov eax, 0b10100000
	mov cr4, eax

	mov edx, edi
	mov cr3, edx

	mov ecx, 0xC0000080
	rdmsr

	or eax, 0x00000100
	wrmsr

	mov ebx, cr0
	or ebx, 0x80000001
	mov cr0, ebx

	lgdt [GDT.pointer]

	jmp 0x0008:long_mode

load_disk:
	push ax
	mov ah, 0x02
	xor ch, ch
	xor dh, dh
	int 0x13
	jc disk_error
	pop cx
	cmp al, cl
	jne disk_error
	ret

disk_error:
	mov ax, disk_error_msg
	call print_str
	jmp $

print_str:
	push ax
	push bx
	mov bx, ax
	mov ah, 0x0E
.print:
	mov al, [bx]
	cmp al, 0
	je .return
	int 0x10
	inc bx
	jmp .print
.return:
	pop bx
	pop ax
	ret

booting_msg: db 10, 13, "Loading NyaX...", 10, 10, 13, 0
disk_error_msg: db "Disk is bwoken, cant boot ;-;", 10, 13, 0

GDT:
	dq 0
	dq 0x00209A0000000000
	dq 0x0000920000000000
	dw 0
.pointer:
	dw $ - GDT - 1
	dd GDT

IDT:
	dw 0
	dd 0

[bits 64]

long_mode:
	mov ax, 0x0010
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

	jmp KERNEL

times 510-($-$$) db 0
dw 0xAA55
