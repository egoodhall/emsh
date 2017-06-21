CC = dmd
CFLAGS = -w -wi

EXEC = emsh

all: $(EXEC)

emsh: emsh.d input.o
	$(CC) $(CFLAGS) emsh.d input.o 

input.o: input.d
	$(CC) $(CFLAGS) -c input.d

clean:
	rm -rf $(EXEC) *.o
