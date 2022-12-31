compiler=nasm
input=codebreaker.asm
output=codebreaker
srcdir=src/
builddir=build/
flags=-f bin -o $(builddir)$(output)
default:
	mkdir -p $(builddir)
	$(compiler) $(flags) $(srcdir)$(input)

run:
	qemu-system-x86_64 $(builddir)$(output)

clean:
	rm -r $(builddir)

xxd:
	xxd $(builddir)$(output)