global paging
extern print_hex, print_chr, newline, print_dec, print_str
global paging

section .data

pagebuf:
	.ptr: dq 0x5000
	.size: dq 0x3000
	.used: dq 0

section .text
alloc:
	mov rdi, .msg
	call print_str
	jmp $
.msg: db "cock", 10, 0

tables:
; level 4
	mov rax, 0xfff
	not rax         ; offset mask

	mov rbx, -1     ; low bits mask
	shl rbx, 3      ;

	xor rcx, rcx

	mov r14, r10
	mov r13, r10
	mov r12, r10
	mov r11, r10

	not rcx               ; negate remainder mask
	and r14, rcx          ; apply remainder mask
	mov rcx, -1           ; reset remainder mask
	shl rcx, 12+9+9+9     ; update remainder mask

	shr r14, 12+9+9+9-3   ; divide
	and r14, rbx          ; clear lower bits

	mov rdx, 0x1000       ; offset
	and rdx, rax          ; offset mask
	add r14, rdx          ; add offset

	not rcx               ; negate remainder mask
	and r13, rcx          ; apply remainder mask
	mov rcx, -1           ; reset remainder mask
	shl rcx, 12+9+9       ; update remainder mask

	shr r13, 12+9+9-3     ; divide
	and r13, rbx          ; clear lower bits

	mov rdx, [r14]        ; offset
	jnz .exist3
	call alloc
.exist3:
	and rdx, rax          ; offset mask
	add r13, rdx          ; add offset


	not rcx               ; negate remainder mask
	and r12, rcx          ; apply remainder mask
	mov rcx, -1           ; reset remainder mask
	shl rcx, 12+9         ; update remainder mask

	shr r12, 12+9-3       ; divide
	and r12, rbx          ; clear lower bits

	mov rdx, [r13]        ; offset
	jnz .exist2
	call alloc
.exist2:
	and rdx, rax          ; offset mask
	add r12, rdx          ; add offset


	not rcx               ; negate remainder mask
	and r11, rcx          ; apply remainder mask

	mov rcx, -1           ; reset remainder mask
	shl rcx, 12           ; update remainder mask

	shr r11, 12-3         ; divide
	and r11, rbx          ; clear lower bits

	mov rdx, [r12]        ; offset
	jnz .exist1
	call alloc
.exist1:
	and rdx, rax          ; offset mask
	add r11, rdx          ; add offset

	ret

; level1
	mov rax, r11
	xor rdx, rdx
	mov rbx, 8
	mul rbx
	mov r11, rax
	add r11, [r12]
	sub r11, 3

	ret

space:
	mov dil, ' '
	jmp print_chr

paging:
	mov r8, 0x0500              ; start of extended memory map
	movzx r9, word[0x1000-10-2] ; number of map entries

	mov r15, pagebuf

.loop:
	;mov r10, [r8]
	;call tables

	mov r10, 0xfffff
	call tables

	mov rdi, r14
	call print_hex
	call space

	mov rdi, r13
	call print_hex
	call space

	mov rdi, r12
	call print_hex
	call space

	mov rdi, r11
	call print_hex
	call space

	mov rdi, [r11]
	call print_hex

	jmp $

	mov rdi, r12
	call print_hex
	call space

	mov rdi, r11
	call print_hex
	call space

	mov rdi, r10
	call print_hex
	call space



	call newline

	jmp $

	;jmp $

	;mov rcx, 1 << 63
	;or rdi, rcx
	;call print_hex

	;mov dil, ' '
	;call print_chr

	;mov rax, [rsp]
	;mov rdi, [rax+8]

	;mov rcx, 1 << 63
	;or rdi, rcx
	;call print_hex

	;mov dil, ' '
	;call print_chr

	; mov rax, [rsp]
	;xor rdi, rdi
	;mov edi, [rax+16]
	;call print_dec

	;call newline

	;pop rax
	add r8, 24

	;pop rbx

	dec r9
	jnz .loop

	jmp $

	ret
