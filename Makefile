.POSIX:
.SUFFIXES:

FC      = gfortran
CC      = gcc
AR      = ar
PREFIX  = /usr/local
DEBUG   = #-ggdb3 -O0

FFLAGS  = $(DEBUG) -Wall -Wno-unused-dummy-argument -std=f2008 -fmax-errors=1 -fcheck=all
CFLAGS  = $(DEBUG) -Wall
LDFLAGS = -I$(PREFIX)/include/ -L$(PREFIX)/lib/
LDLIBS  = -lcurl
ARFLAGS = rcs
TARGET  = libfortran-curl.a

DICT     = dict
DOWNLOAD = download
GETINFO  = getinfo
GOPHER   = gopher
HTTP     = http
IMAP     = imap
SMTP     = smtp
VERSION  = version

.PHONY: all clean examples

all: $(TARGET)
examples: $(DICT) $(DOWNLOAD) $(GETINFO) $(GOPHER) $(HTTP) $(IMAP) $(SMTP) $(VERSION)

$(TARGET):
	$(CC) $(CFLAGS) -c src/curlv.c
	$(FC) $(FFLAGS) -c src/curl.f90
	$(AR) $(ARFLAGS) $(TARGET) curl.o curlv.o

$(DICT): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(DICT) examples/dict/dict.f90 $(TARGET) $(LDLIBS)

$(DOWNLOAD): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(DOWNLOAD) examples/download/download.f90 $(TARGET) $(LDLIBS)

$(GETINFO): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(GETINFO) examples/getinfo/getinfo.f90 $(TARGET) $(LDLIBS)

$(GOPHER): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(GOPHER) examples/gopher/gopher.f90 $(TARGET) $(LDLIBS)

$(HTTP): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(HTTP) examples/http/http.f90 $(TARGET) $(LDLIBS)

$(IMAP): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(IMAP) examples/imap/imap.f90 $(TARGET) $(LDLIBS)

$(SMTP): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(SMTP) examples/smtp/smtp.f90 $(TARGET) $(LDLIBS)

$(VERSION): $(TARGET)
	$(FC) $(FFLAGS) $(LDFLAGS) -o $(VERSION) examples/version/version.f90 $(TARGET) $(LDLIBS)

clean:
	if [ `ls -1 *.mod 2>/dev/null | wc -l` -gt 0 ]; then rm *.mod; fi
	if [ `ls -1 *.o 2>/dev/null | wc -l` -gt 0 ]; then rm *.o; fi
	if [ -e $(TARGET) ]; then rm $(TARGET); fi
	if [ -e $(DICT) ]; then rm $(DICT); fi
	if [ -e $(DOWNLOAD) ]; then rm $(DOWNLOAD); fi
	if [ -e $(GETINFO) ]; then rm $(GETINFO); fi
	if [ -e $(GOPHER) ]; then rm $(GOPHER); fi
	if [ -e $(HTTP) ]; then rm $(HTTP); fi
	if [ -e $(IMAP) ]; then rm $(IMAP); fi
	if [ -e $(SMTP) ]; then rm $(SMTP); fi
	if [ -e $(VERSION) ]; then rm $(VERSION); fi
