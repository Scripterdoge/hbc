GMP_V = 6.1.0
NTL_V = 9.9.1

error:
	$(error make has to be followed by something)

ini :
	$(info Checking pre-requisites...)
ifeq ($(shell uname -o),Cygwin)
	$(info Cygwin 32 bit detected, installing modules if necessary.)
	lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
	install apt-cyg /bin
	rm -f apt-cyg
	apt-cyg install curl libboost-devel
	#for helib, requires to manually install git on cygwin
	#for ntl, requires to manually install gcc-g++ on cygwin
#	else
#		$(info Cygwin 64 bit detected, installing modules if necessary.)
#		lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
#		install apt-cyg /bin
#		rm -f apt-cyg
#		apt-cyg install curl git gcc-g++
else
	$(info Linux detected, installing modules if necessary.)
	apt-get install -y curl git g++ libboost-all-dev
endif
	$(info = = = = = = = = = = = = = = = =)
	$(info All pre-requisites modules are installed.)
	$(info = = = = = = = = = = = = = = = =)

gmp : ini
	$(info Installing GMP...)
	$(info Installing pre-requisites M4 and perl)
ifeq ($(shell uname -o),Cygwin)
	$(info Cygwin detected, installing modules if necessary.)
	apt-cyg install m4 perl
else
	$(info Linux detected, installing modules if necessary.)
	apt-get install -y m4 perl
endif
	$(info M4 and Perl are installed.)
	curl https://gmplib.org/download/gmp/gmp-6.1.0.tar.bz2 > gmp.tar.bz2
	tar xjf gmp.tar.bz2
	rm -f gmp.tar.bz2
	#cd gmp-$(GMP_V) && ./configure ABI=64
	cd gmp-$(GMP_V) && ./configure
	cd gmp-$(GMP_V) && make
	cd gmp-$(GMP_V) && make install
	#cd gmp-$(GMP_V) && make check
ifeq ($(shell uname -o),Cygwin)
	if [ -d "/usr/x86_64-pc-cygwin/lib/" ]; then cp -f /usr/local/lib/libgmp.* /usr/x86_64-pc-cygwin/lib/; fi
	if [ -d "/usr/i686-pc-cygwin/lib/" ]; then cp -f /usr/local/lib/libgmp.* /usr/i686-pc-cygwin/lib/; fi
endif
	

ntl : ini gmp
	$(info Installing NTL...)
	curl http://www.shoup.net/ntl/ntl-9.9.1.tar.gz > ntl.tar.gz
	tar xf ntl.tar.gz
	rm -f ntl.tar.gz
    #CFLAGS="-O2 -m64"
	cd ntl-$(NTL_V)/src && ./configure NTL_GMP_LIP=on
	cd ntl-$(NTL_V)/src && make
	cd ntl-$(NTL_V)/src && make install
	
HElib : ntl gmp
	$(info Installing HELib...)
	git clone https://github.com/shaih/HElib.git
ifeq ($(shell uname -o),Cygwin)
	sed -i -- 's/_B/_B_/g' HElib/src/Test_Replicate.cpp
endif
	cd HElib/src && make
	cd HElib/src && make check
	cd HElib/src && make test

objects/helper_functions.o : src/helper_functions.cpp src/helper_functions.h
	$(info )
	$(info Building helper_functions.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/helper_functions.cpp -o objects/helper_functions.o
	
objects/test_gates.o : src/TEST_GATES.cpp src/TEST_GATES.h
	$(info )
	$(info Building test_gates.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/TEST_GATES.cpp -I HElib/src -o objects/test_gates.o
	
objects/test_circ_comb.o : src/TEST_CIRC_COMB.cpp src/TEST_CIRC_COMB.h
	$(info )
	$(info Building test_circ_comb.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/TEST_CIRC_COMB.cpp -I HElib/src -o objects/test_circ_comb.o
	
objects/test_circ_seq.o : src/TEST_CIRC_SEQ.cpp src/TEST_CIRC_SEQ.h
	$(info )
	$(info Building test_circ_seq.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/TEST_CIRC_SEQ.cpp -I HElib/src -o objects/test_circ_seq.o
	
objects/test_circ_arithm.o : src/TEST_CIRC_ARITHM.cpp src/TEST_CIRC_ARITHM.h
	$(info )
	$(info Building test_circ_arithm.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/TEST_CIRC_ARITHM.cpp -I HElib/src -o objects/test_circ_arithm.o
	
objects/he.o : src/he.cpp src/he.h
	$(info )
	$(info Building he.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/he.cpp -I HElib/src -o objects/he.o
	
objects/main.o: src/main.cpp
	$(info )
	$(info Building main.o...)
	mkdir -p objects
	g++ -std=c++11 -c src/main.cpp -I HElib/src -o objects/main.o
	
hbc : objects/he.o objects/helper_functions.o \
		objects/test_gates.o objects/test_circ_comb.o objects/test_circ_seq.o \
		objects/test_circ_arithm.o \
		objects/main.o
	$(info )
	$(info Building hbc...)
	g++ -std=c++11 objects/*.o HElib/src/fhe.a -o hbc -L/usr/local/lib -lntl -lgmp -lm
	
hbcNrun : hbc
	./hbc
	
clean :
	rm -fr *.exe *.o ./hbc
	
deepclean :
	$(info Cleaning up everything !)
	if [ -d "/gmp-$(GMP_V)" ]; then cd gmp-$(GMP_V)/src && make clean; fi
	if [ -d "/gmp-$(GMP_V)" ]; then cd gmp-$(GMP_V)/src && make uninstall; fi
	if [ -d "/ntl-$(NTL_V)" ]; then cd ntl-$(NTL_V)/src && make clobber; fi
	if [ -d "/ntl-$(NTL_V)" ]; then cd ntl-$(NTL_V)/src && make clean; fi
	if [ -d "/ntl-$(NTL_V)" ]; then cd ntl-$(NTL_V)/src && make uninstall; fi
ifeq ($(shell uname -o),Cygwin)
	$(info Cygwin detected, uninstalling static GMP and NTL.)
	rm -f /usr/x86_64-pc-cygwin/lib/libgmp.*
	rm -f /usr/i686-pc-cygwin/lib/libgmp.*
endif
	rm -fr /usr/local/include/NTL
	rm -f /usr/local/include/gmp.h
	rm -f /usr/local/lib/libgmp.*
	rm -f /usr/local/lib/libntl.*
	rm -fr gmp-$(GMP_V) ntl-$(NTL_V) HElib
	$(info ...Removed GMP, NTL, HELib folder)
ifeq ($(shell uname -o),Cygwin)
	lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
	install apt-cyg /bin
	rm -f apt-cyg
	apt-cyg remove --purge curl perl m4 git gcc-g++ libboost-devel
	$(info ...Removed curl perl m4 git gcc-g++ from CYGWIN)
else
	apt-get remove -y --purge perl git g++ libboost-all-dev libboost-dev
endif

help : 
	@echo Available commands are:
	@echo make HElib - Downloads HElib and other libraries and installs them
	@echo make hbc - Compiles the project source code into an executable "hbc"
	@echo make hbcNrun - Compiles the project source code and runs it.
	@echo make clean - Removes all executables .exe and objects .o
	@echo make deepclean - Removes all the libraries and packages installed. BE CAUTIOUS!
