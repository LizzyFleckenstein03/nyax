global main
extern print_str, print_num, print_chr, clear_screen

section .data

disclaimer: db \
	"NyanX", 10, \
	"(C) 2022 Flecken-chan", 10, \
	"Dis progwam comes with ABSOLUTELY NO WAWWANTY", 10, \
	"Dis iz fwee software, and your'e welcome to redistwibute it", 10, "  under certain conditions", 10, 0

greeting: db "Good morning Senpai UwU", 10, 0

section .text

main:
	call clear_screen
	mov rdi, disclaimer
	call print_str
	mov rdi, greeting
	call print_str
	xor rdi, rdi
	.loop:
	push rdi
	mov dil, 13
	call print_chr
	mov rdi, [rsp]
	call print_num
	pop rdi
	inc rdi
	jmp .loop
