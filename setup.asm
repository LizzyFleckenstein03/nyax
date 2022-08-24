[org 0x7E00]

%define PAGETABLE 0x1000
%define VESAINFO  0x0500
%define VESAMODE VESAINFO+512
%define OWNMODE  VESAMODE+256
%define GFXINFO 0x500

setup:
	; print message
	mov ebx, .msg
	call print_str

	; setup VESA
	call vesa

	; get extended memory map
	call mmap

	; build page table
	call paging

	; jump into long mode
	jmp 0x0008:long_mode

.msg:
	db 10, 13, "nyax stage2", 10, 13, 0


vesa:
	; print message
	mov ebx, .msg
	call print_str

	; get vesa bios info
	mov eax, dword[.vbe2]
	mov dword[VESAINFO], eax ; move "VBE2" to start of vesainfo struct
	mov ax, 0x4F00           ; get VESA BIOS information
	mov di, VESAINFO         ; struct buffer
	int 0x10

	cmp ax, 0x004F           ; check ax for correct magic number
	jne .fail_getinfo

	mov eax, dword[.vesa]
	cmp dword[VESAINFO], eax ; check if "VESA" is at start of stuct
	jne .fail_getinfo

	; print select message
	mov ebx, .select_msg
	call print_str

	; get segment:offset pointer to video modes into gs:ebx
	movzx ebx, word[VESAINFO+14]
	mov    ax, word[VESAINFO+16]
	mov gs, ax

	; convert modes to own structure

	xor esi, esi        ; number of avail modes

.mode_loop:
	; get mode info
	mov cx, [gs:ebx]    ; video mode into cx
	cmp cx, 0xFFFF      ; 0xFFFF is terminator, no suitable mode has been found
	je .mode_done
	mov ax, 0x4F01      ; get VESA mode information
	mov di, VESAMODE    ; vesa mode info struct buffer
	int 0x10

	cmp ax, 0x004F      ; check ax for correct magic number
	jne .fail_modeinfo

	mov al, byte[VESAMODE] ; get attributes
	and al, 0b10000000     ; extract bit 7, indicates linear framebuffer support
	jz .mode_next

	mov al, byte[VESAMODE+25] ; get bpp (bits per pixel)
	cmp al, 32
	jne .mode_next

	push ebx ; print_num and print_str modify ebx

	mov eax, esi
	mov ebx, 12
	mul ebx
	mov edi, eax
	add edi, OWNMODE

	mov [edi+10], cx ; copy mode

	mov eax, edi
	call print_num

	; print selector
	mov al, '['
	call print_chr

	mov eax, esi
	add eax, 'a'
	call print_chr

	mov al, ']'
	call print_chr

	mov al, ' '
	call print_chr

	mov ax, [VESAMODE+16] ; copy pitch
	mov [edi+0], ax

	movzx eax, word[VESAMODE+18] ; copy width
	mov [edi+2], ax
	call print_num

	mov al, 'x'
	call print_chr

	movzx eax, word[VESAMODE+20] ; copy height
	mov [edi+4], ax
	call print_num
	call newline

	mov eax, [VESAMODE+40] ; copy framebuffer
	mov [edi+6], eax

	pop ebx

	inc esi
	cmp esi, 'z'-'a'   ; only print up to z
	jg .mode_done

.mode_next:
	add ebx, 2         ; increase mode pointer
	jmp .mode_loop     ; loop

.mode_done:
	cmp esi, 0
	je .fail_nomode

.input:
	mov ebx, .select_prompt
	call print_str

	mov ah, 0x00   ; get keypress, blocking
	int 0x16

	call print_chr ; echo user input

	movzx edi, al  ; backup al
	call newline

	sub edi, 'a'
	cmp edi, esi
	jb .valid      ; check validity

	mov ebx, .invalid
	call print_str

	jmp .input

.valid:
	mov eax, edi
	call print_num
	call newline

	; convert selected number to address
	mov eax, edi
	mov ebx, 12
	mul ebx
	add eax, OWNMODE

	; copy to final gfx info location
	mov ebx, [eax]
	mov [GFXINFO], ebx

	mov ebx, [eax+4]
	mov [GFXINFO+4], ebx

	mov bx, [eax+6]
	mov [GFXINFO+6], bx

	; set mode
	mov bx, [eax+10]           ; video mode in bx (first 13 bits)
	or  bx, 0b0100000000000000 ; set bit 14: enable linear frame buffer
	and bx, 0b0111111111111111 ; clear deprecated bit 15
	mov ax, 0x4F02             ; set VBE mode
	int 0x10

	ret

.msg: db "setting up vesa", 10, 13, 0
.vbe2: db "VBE2"
.vesa: db "VESA"
.select_msg: db "avaliable video modes:", 10, 13, 0
.select_prompt: db "select video mode: ", 0
.invalid: db "invalid input", 10, 13, 0

.fail_getinfo:
	mov ebx, .fail_getinfo_msg
	jmp .fail

.fail_modeinfo:
	mov ebx, .fail_modeinfo_msg
	jmp .fail

.fail_nomode:
	mov ebx, .fail_nomode_msg
	jmp .fail

.fail_getinfo_msg: db "failed getting vesa bios info", 10, 13, 0
.fail_modeinfo_msg: db "failed getting video mode info", 10, 13, 0
.fail_nomode_msg: db "no suitable video modes available", 10, 13, 0

.fail:
	call print_str
	jmp $


mmap:
	mov ebx, .msg
	call print_str

	ret

.msg: db "getting extended memory map", 10, 13, 0


paging:
	; print message
	mov ebx, .msg
	call print_str

	; clear 4 levels of page maps
	mov di, PAGETABLE+0x0000
.clr_buf:
	mov byte[di], 0
	inc di
	cmp di, PAGETABLE+0x4000
	jne .clr_buf

	; init 3 page map levels
	mov dword[PAGETABLE+0x0000], PAGETABLE+0x1003
	mov dword[PAGETABLE+0x1000], PAGETABLE+0x2003
	mov dword[PAGETABLE+0x2000], PAGETABLE+0x3003

	; fill up level 4 page map
	mov eax, 3
	mov di, PAGETABLE+0x3000
.build_pt:
	mov [di], eax
	add eax, 0x1000
	add di, 8
	cmp eax, 0x100000
	jb .build_pt

	; enable paging and long mode

	mov di, PAGETABLE

	mov al, 0xFF
	out 0xA1, al
	out 0x21, al

	nop
	nop

	lidt [.idt]

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

	lgdt [.gdt_pointer]

	ret

.gdt:
	dq 0
	dq 0x00209A0000000000
	dq 0x0000920000000000
	dw 0

.gdt_pointer:
	dw $ - .gdt - 1
	dd .gdt

.idt:
	dw 0
	dd 0

.msg:
	db "building page table", 10, 13, 0


%include "bios_print.asm"

; uses eax, ebx, ecx, edx
print_num:
	mov ebx, 10
	xor ecx, ecx
.convert:
	inc ecx
	xor edx, edx
	div ebx
	add dl, '0'
	push dx
	cmp eax, 0
	jne .convert
.print:
	cmp ecx, 0
	je .return
	dec ecx
	pop ax
	mov ah, 0x0E
	int 0x10
	jmp .print
.return:
	ret


newline:
	mov al, 10
	call print_chr

	mov al, 13
	call print_chr

	ret

print_chr:
	mov ah, 0x0E
	int 0x10
	ret

[bits 64]

long_mode:
	; setup segment registers
	mov ax, 0x0010
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
