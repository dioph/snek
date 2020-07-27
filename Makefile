vpath %.asm src
OBJS := build/snek.o build/random.o build/board.o
NASM_FLAGS := -f elf -g
LINK_FLAGS := -m elf_i386
TARGET := snek

# Build final binary
$(TARGET) : $(OBJS)
	ld -o $@ $(OBJS) $(LINK_FLAGS)

# Build .o first
build/%.o : %.asm
	nasm $(NASM_FLAGS) -o $@ $<

# Clean all the object files and the binary
clean:
	rm -rfv $(OBJS)
	rm -rfv $(TARGET)
