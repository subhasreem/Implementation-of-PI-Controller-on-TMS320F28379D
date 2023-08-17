ASM_OPTS = -v28 --float_support=fpu32

all:		main.bin main.sym

main.bin:	main.out
		hex2000 -boot -b -o main.bin main.out

main.out:	main.obj 
		lnk2000 -o main.out --entry_point=MAIN main.cmd main.obj

main.obj:	main.asm
		asm2000 $(ASM_OPTS) main.asm

main.sym:	main.out
		nm2000 -n main.out | awk '{if((($$2=="d")||($$2=="T")||($$2=="t"))\
			&& (substr($$3,1,1) !=".") && (substr($$3,1,3) !="___"))\
			print $$1" "$$3}' > main.sym

clean:
		rm -f *.obj *.out *.bin *.sym
