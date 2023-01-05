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

install:
	dd if=$(builddir)$(output) of=$(device) bs=446 count=1 oflag=sync
	dd if=$(builddir)$(output) of=$(device) bs=1 count=2 seek=510 skip=510 oflag=sync
	sync
	eject $(device)