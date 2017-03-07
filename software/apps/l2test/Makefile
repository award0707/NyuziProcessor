#
# Copyright 2011-2015 Jeff Bush
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

TOPDIR=../../../

include $(TOPDIR)/build/target.mk

LIBS=-lc
SRCS=l2test.cpp
CFLAGS+=-ffast-math -std=c++11 -O0

OBJS := $(SRCS_TO_OBJS)
DEPS := $(SRCS_TO_DEPS)

$(OBJ_DIR)/l2test.hex: $(OBJS)
	$(LD) -o $(OBJ_DIR)/l2test.elf $(LDFLAGS) $(CRT0_BARE) $(OBJS) $(LIBS) -los-bare $(LDFLAGS)
	$(ELF2HEX) -o $(OBJ_DIR)/l2test.hex $(OBJ_DIR)/l2test.elf

run: $(OBJ_DIR)/l2test.hex
	$(EMULATOR) -f 640x480 $(OBJ_DIR)/l2test.hex

krun: fsimage.bin
	$(EMULATOR) -b fsimage.bin -f 640x480 $(TOPDIR)/software/kernel/kernel.hex

fsimage.bin: $(OBJ_DIR)/program.elf
	$(MKFS) fsimage.bin $(OBJ_DIR)/program.elf

# program.elf is the image that is executed by the kernel
$(OBJ_DIR)/program.elf: $(OBJS)
	$(LD) -o $(OBJ_DIR)/program.elf -Ttext=0x1000 $(LDFLAGS) $(CRT0_KERN) $(OBJS) $(LIBS) -los-kern $(LDFLAGS)

fpgarun: $(OBJ_DIR)/l2test.hex
	$(SERIAL_BOOT) $(SERIAL_PORT) $(OBJ_DIR)/l2test.hex

fpgakrun: $(OBJ_DIR)/l2test.hex fsimage.bin
	$(SERIAL_BOOT) $(SERIAL_PORT) $(TOPDIR)/software/kernel/kernel.hex fsimage.bin

clean:
	rm -rf $(OBJ_DIR) fsimage.bin

-include $(DEPS)

