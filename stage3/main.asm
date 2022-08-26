global _start
extern print_str, print_dec, print_hex, print_chr, clear_screen, page_map, page_region

%define GFXINFO 0x1000-10

section .data

headline: db "nyax stage3", 10, 10, 0

gfxregion:
	.start: dq 0
	.size: dq 0
	.type: dw 2
	dw 0

section .text

_start:
	call clear_screen

	mov rdi, headline
	call print_str

	call page_map

	;mov qword[rbx], -1

	;jmp $

	movzx rax, word[GFXINFO+0]
	movzx rbx, word[GFXINFO+4]
	mov rcx, 4

	xor rdx, rdx
	mul rbx

	xor rdx, rdx
	mul rcx

	xor rbx, rbx
	mov ebx, [GFXINFO+6]

	mov [gfxregion.start], rbx
	mov [gfxregion.size], rax

	mov r9, gfxregion
	call page_region

	mov rbx, [gfxregion.start]
	mov rax, [gfxregion.size]

	add rax, rbx

.clear:
	mov dword[rbx], 0x87CEEB
	add rbx, 4
	cmp rbx, rax
	jb .clear

	jmp $
