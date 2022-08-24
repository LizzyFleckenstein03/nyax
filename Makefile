OBJS = main.o framebuffer.o memory.o
DEV=/dev/sdb

nyax.img: stage1.out stage2.out stage3.out
	cat stage{1,2,3}.out > nyax.img

stage1.out: mbr.asm stage2.out stage3.out
	nasm -f bin mbr.asm -o stage1.out \
		-dKSIZE=$$(du -cb stage{2,3}.out | tail -n1 | cut -f1)

stage2.out: setup.asm
	nasm -f bin setup.asm -o stage2.out

stage3.out: $(OBJS) stage2.out
	ld -o stage3.out --oformat binary $(OBJS) \
		-Ttext $$(printf "%x\n" $$(echo $$(du -b stage2.out | cut -f1)+32256 | bc))

%.o: %.asm
	nasm -f elf64 $< -o $@

.PHONY: run
run: nyax.img
	bochs -q

.PHONY: clean
clean:
	rm -rf *.o *.out *.img

flash: nyax.img
	dd if=./nyax.img of=$(DEV)
