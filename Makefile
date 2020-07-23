NASM_FLAGS = -f elf -g
LINK_FLAGS = -m elf_i386
SRC_PATH = ./src/
OBJ_PATH = ./build/
TARGET = snek
OBJ_FILES = snek.o
OBJ = $(patsubst %,$(OBJ_PATH)%,$(OBJ_FILES))

# Build .o first
$(OBJ_PATH)%.o : $(SRC_PATH)%.asm
	nasm $(NASM_FLAGS) -o $@ $<

# Build final binary
$(TARGET) : $(OBJ)
	ld $(LINK_FLAGS) -o $@ $<

# Clean all the object files and the binary
clean:
	rm -rfv $(OBJ)
	rm -rfv $(TARGET)
