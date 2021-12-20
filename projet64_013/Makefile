# Makefile  Lancer par make PGM=blockchain1

ARMGNU ?= /usr/bin/

# The directory in which source files are stored.
SOURCE = src

# The name of the output file to generate.
TARGET = $(PGM)

# The intermediate directory for compiled object files.
BUILD = build

# The names of all object files that must be generated. Deduced from the 
# assembly code files in source.
OBJECTS = $(patsubst $(SOURCE)/%.s,$(BUILD)/%.o,$(wildcard $(SOURCE)/*.s))

# Rule to make everything.
all: $(TARGET)

 
# Rule to make the elf file.
$(PGM): linkerldarm64.ld $(OBJECTS)
	$(ARMGNU)\gcc-8  -o $(BUILD)/$(PGM) $(OBJECTS) -lcrypto -lssl -T linkerldarm64.ld
 
# Rule to make the object files.
$(BUILD)/%.o: $(SOURCE)/%.s
	$(ARMGNU)\as   $< -o $@
 

clean:




