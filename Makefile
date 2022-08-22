OBJS = main.o framebuffer.o memory.o

nyax.img: boot.out main.out
	cat boot.out main.out > nyax.img

boot.out: boot.asm main.out
	nasm -f bin boot.asm -o boot.out -dMAIN_SIZE=$$(stat -c%s main.out)

main.out: $(OBJS)
	ld -o main.out -Ttext 0xD000 --oformat binary $(OBJS)

%.o: %.asm
	nasm -f elf64 $< -o $@

.PHONY: run
run: nyax.img
	bochs -q
