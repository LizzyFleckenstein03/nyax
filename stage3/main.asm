global _start
extern print_str, print_dec, print_chr, clear_screen, paging

section .data

headline: db "nyax stage3", 10, 10, 0

disclaimer: db \
	"NyaX", 10, \
	"(C) 2022 Flecken-chan", 10, \
	"Dis progwam comes with ABSOLUTELY NO WAWWANTY", 10, \
	"Dis iz fwee software, and your'e welcome to redistwibute it", 10, "  under certain conditions", 10, 0

section .text

_start:
	call clear_screen

	call paging

	mov rdi, headline
	call print_str

	mov rdi, disclaimer
	call print_str

	xor rdi, rdi
.loop:
	push rdi
	mov dil, 13
	call print_chr
	mov rdi, [rsp]
	call print_dec
	pop rdi
	inc rdi
	jmp .loop
