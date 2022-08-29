SHELL:=/bin/bash

STAGE3 = stage3/main.o stage3/framebuffer.o stage3/memory.o stage3/paging.o

nyax.img: stage1.out stage2.out stage3.out
	cat stage{1,2,3}.out > nyax.img

stage1.out: stage1/main.asm stage1/print.asm stage2.out stage3.out
	nasm -f bin stage1/main.asm -o stage1.out \
		-dKSIZE=$$(du -cb stage{2,3}.out | tail -n1 | cut -f1)

stage2.out: stage2/main.asm stage2/mmap.asm stage2/paging.asm stage2/vesa.asm stage1/print.asm
	nasm -f bin stage2/main.asm -o stage2.out

stage3.out: $(STAGE3) stage2.out
	ld -o stage3.out --oformat binary $(STAGE3) \
		-Ttext $$(printf "%x\n" $$(echo $$(du -b stage2.out | cut -f1)+32256 | bc))

stage3/%.o: stage3/%.asm
	nasm -f elf64 $< -o $@

.PHONY: run clean flash

run: nyax.img
	bochs -q

clean:
	rm -rf stage3/*.o *.out *.img

flash: nyax.img
	dd if=nyax.img of=$(DEV)
