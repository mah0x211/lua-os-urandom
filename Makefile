TARGET=urandom.$(LIB_EXTENSION)
SRCS=$(wildcard src/*.c)
OBJS=$(SRCS:.c=.o)
GCDA=$(OBJS:.o=.gcda)
INSTALL?=install

ifdef OS_URANDOM_COVERAGE
COVFLAGS=--coverage
endif

.PHONY: all install

all: $(TARGET)

%.o: %.c
	$(CC) $(CFLAGS) $(WARNINGS) $(COVFLAGS) $(CPPFLAGS) -o $@ -c $<

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS) $(LIBS) $(PLATFORM_LDFLAGS) $(COVFLAGS)

install:
	$(INSTALL) -d $(INST_LIBDIR)
	$(INSTALL) $(TARGET) $(INST_LIBDIR)
	rm -f $(OBJS) $(GCDA) *.so
