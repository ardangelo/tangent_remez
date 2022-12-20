all: tan

CXX = g++
CFLAGS = -g -O2
CXXFLAGS = $(CFLAGS) -std=c++17 -Wunused -fsanitize=address

RAPIDCHECK_CFLAGS = -Irapidcheck/include

RAPIDCHECK_SOURCES = $(shell grep '^[ \t]*src/.*\.cpp$$' rapidcheck/CMakeLists.txt)
RAPIDCHECK_SOURCES := $(RAPIDCHECK_SOURCES:%.cpp=rapidcheck/%.cpp)
RAPIDCHECK_OBJS = $(RAPIDCHECK_SOURCES:%.cpp=%.o)

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

clean:
	rm -f *.o $(RAPIDCHECK_OBJS) tan_values.py *.gen.hpp tan
