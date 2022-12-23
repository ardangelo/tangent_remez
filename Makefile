ROMNAME	= test

# Detect devkitPro support
ifneq (,$(wildcard $(DEVKITARM)/gba_rules))
	# Source GBA Make rules
	PATH := $(DEVKITARM)/bin:$(DEVKITPRO)/tools/bin:$(PATH)
	include $(DEVKITARM)/gba_rules

	# Add GBA target
	TARGETS += $(ROMNAME).gba
endif

all: tan $(ROMNAME).gba

CXX = g++
CFLAGS = -g -O2
CXXFLAGS = $(CFLAGS) -std=c++17 -Wunused

RAPIDCHECK_CFLAGS = -Irapidcheck/include -fsanitize=address

RAPIDCHECK_SOURCES = $(shell grep '^[ \t]*src/.*\.cpp$$' rapidcheck/CMakeLists.txt)
RAPIDCHECK_SOURCES := $(RAPIDCHECK_SOURCES:%.cpp=rapidcheck/%.cpp)
RAPIDCHECK_OBJS = $(RAPIDCHECK_SOURCES:%.cpp=%.o)

GBA_SPECS = -specs=gba_mb.specs

GBA_RARCH = -mthumb-interwork -mthumb
GBA_IARCH = -mthumb-interwork -marm -mlong-calls

GBA_CC       = arm-none-eabi-g++
GBA_ASFLAGS  = -mthumb-interwork
GBA_CXXFLAGS = -mcpu=arm7tdmi -mtune=arm7tdmi \
	-fno-exceptions -fno-non-call-exceptions -fno-rtti -fno-threadsafe-statics
GBA_LDFLAGS	 = $(TONC_LIBS) $(GBA_SPECS) -Wl,-Map,$(ROMNAME).map

lolremez/install/bin/lolremez:
	cd lolremez && ./bootstrap && ./configure --prefix=$(PWD)/lolremez/install \
		&& make -j install

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(RAPIDCHECK_CFLAGS) -c $< -o $@

rapidcheck.a: $(RAPIDCHECK_OBJS)
	ar rcs rapidcheck.a $(RAPIDCHECK_OBJS)

tan_values_gen.py: gen_tan_values.py lolremez/install/bin/lolremez
	python3 gen_tan_values.py > tan_values_gen.py

tan_array.gen.hpp: tan_values_gen.py gen_tan_array.py
	python3 gen_tan_array.py > tan_array.gen.hpp

tan_approx.o: tan_approx.cpp tan_approx.hpp tan_array.gen.hpp
		$(CXX) $(CXXFLAGS) $(RAPIDCHECK_CFLAGS) -c $< -o $@

tan: tan.cpp tan_approx.o rapidcheck.a
	$(CXX) $(CXXFLAGS) $(RAPIDCHECK_CFLAGS) tan.cpp rapidcheck.a tan_approx.o -o tan

$(ROMNAME).gba : test.cpp console.cpp tan_approx.arm.s
	$(GBA_CC) $(CXXFLAGS) $(GBA_CXXFLAGS) $(GBA_RARCH) -c console.cpp -o console.gba.o
	$(GBA_CC) $(CXXFLAGS) $(GBA_CXXFLAGS) $(GBA_RARCH) -c test.cpp -o test.gba.o
	$(GBA_CC) $(CXXFLAGS) $(GBA_CXXFLAGS) $(GBA_RARCH) -c tan_approx.arm.s -o tan_approx.gba.o
	$(GBA_CC) test.gba.o console.gba.o tan_approx.gba.o $(LDFLAGS) $(GBA_LDFLAGS) -o test.elf
	arm-none-eabi-objcopy -v -O binary test.elf test.gba
	gbafix test.gba -ttest

clean:
	rm -f *.o $(RAPIDCHECK_OBJS) tan_values.py *.gen.hpp tan
