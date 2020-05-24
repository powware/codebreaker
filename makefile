compiler=nasm
input=codebreaker.asm
output=codebreaker.bin
srcdir=src/
builddir=build/
bindir=$(builddir)bin/
flags=-f bin -o $(bindir)$(output)
default:
	mkdir -p $(bindir)
	$(compiler) $(flags) $(srcdir)$(input)
run:
	qemu-system-x86_64 $(bindir)$(output)
clean:
	rm -r $(builddir)