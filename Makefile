GBA_ROMNAME = arm-test

TARGETS = test

# Detect devkitPro support
ifneq (,$(wildcard $(DEVKITARM)/gba_rules))
	# Source GBA Make rules
	PATH := $(DEVKITARM)/bin:$(DEVKITPRO)/tools/bin:$(PATH)
	include $(DEVKITARM)/gba_rules

	# Add GBA target
	TARGETS += $(GBA_ROMNAME).gba
endif

all: $(TARGETS)
check: test
	./test

# Test binary flags
CXX = g++
CFLAGS = -g -O2
CXXFLAGS = $(CFLAGS) -std=c++17 -Wunused

# Rapidcheck flags and sources
RAPIDCHECK_CFLAGS = -Irapidcheck/include -fsanitize=address
RAPIDCHECK_SOURCES = $(shell grep '^[ \t]*src/.*\.cpp$$' rapidcheck/CMakeLists.txt)
RAPIDCHECK_SOURCES := $(RAPIDCHECK_SOURCES:%.cpp=rapidcheck/%.cpp)
RAPIDCHECK_OBJS = $(RAPIDCHECK_SOURCES:%.cpp=%.o)

# ARM test flags
GBA_RARCH = -mthumb-interwork -mthumb
GBA_IARCH = -mthumb-interwork -marm -mlong-calls
GBA_CC = arm-none-eabi-g++
GBA_ASFLAGS = -mthumb-interwork
GBA_CXXFLAGS = -mcpu=arm7tdmi -mtune=arm7tdmi \
	-fno-exceptions -fno-non-call-exceptions -fno-rtti -fno-threadsafe-statics \
	-I. -Iarm-test
GBA_LDFLAGS = -specs=gba_mb.specs -Wl,-Map,$(GBA_ROMNAME).map

# Remez submodule build
lolremez/install/bin/lolremez:
	cd lolremez && ./bootstrap && ./configure --prefix=$(PWD)/lolremez/install \
		&& make -j install

# Rapidcheck objects
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(RAPIDCHECK_CFLAGS) -c $< -o $@

# Rapidcheck static library
rapidcheck.a: $(RAPIDCHECK_OBJS)
	ar rcs rapidcheck.a $(RAPIDCHECK_OBJS)

# Generate polynomial coefficients
values_gen.py: gen_values.py lolremez/install/bin/lolremez
	python3 gen_values.py > values_gen.py

# Pack polynomial coefficients as word array
trig_array.gen.hpp: values_gen.py gen_array.py
	python3 gen_array.py > trig_array.gen.hpp

# Tangent and 1/cosine approximation object with coefficients
trig_approx.o: trig_approx.cpp trig_approx.hpp trig_array.gen.hpp
		$(CXX) $(CXXFLAGS) $(RAPIDCHECK_CFLAGS) -c $< -o $@

# Link test binary
test: test.cpp trig_approx.o rapidcheck.a
	$(CXX) $(CXXFLAGS) $(RAPIDCHECK_CFLAGS) test.cpp rapidcheck.a trig_approx.o -o test

# ARM test binary
$(GBA_ROMNAME).gba : arm-test/arm-test.cpp arm-test/nocash_printf.hpp \
	arm-test/nocash_printf.cpp arm-test/tan_approx.arm.s

	$(GBA_CC) $(CXXFLAGS) $(GBA_CXXFLAGS) $(GBA_RARCH) -c arm-test/nocash_printf.cpp -o nocash_printf.gba.o
	$(GBA_CC) $(CXXFLAGS) $(GBA_CXXFLAGS) $(GBA_IARCH) -c arm-test/arm-test.cpp -o arm-test.gba.o
	$(GBA_CC) $(CXXFLAGS) $(GBA_CXXFLAGS) $(GBA_IARCH) -c arm-test/tan_approx.arm.s -o tan_approx.gba.o
	$(GBA_CC) arm-test.gba.o nocash_printf.gba.o tan_approx.gba.o $(GBA_LDFLAGS) -o $(GBA_ROMNAME).elf
	arm-none-eabi-objcopy -v -O binary $(GBA_ROMNAME).elf $(GBA_ROMNAME).gba
	gbafix $(GBA_ROMNAME).gba -t$(GBA_ROMNAME)

clean:
	rm -rf __pycache__
	rm -f *.o *.a $(RAPIDCHECK_OBJS) *_gen.py *.gen.hpp tan *.map *.elf *.gba
