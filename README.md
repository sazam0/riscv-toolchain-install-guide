# RISC-V Toolchain Install Guide
How to download and install qemu and the GNU toolchain on Ubuntu 20.04 for building and running 
freestanding RISC-V Assembler and C/C++ programs.

Note this repository is mainly a set links to the submodules and versions that I use as 
described below.

## YouTube videos discussing the use of QEMU and these test programs:

- [Installation and Setup](https://youtu.be/iWQRV-KJ7tQ)

A playlist of RISC-V videos I have recorded: [RISC-V Lectures](https://www.youtube.com/playlist?list=PL3by7evD3F53Dz2RiB47Ztp9l_piGVuus)



## Clone this repo:

```bash
git clone https://github.com/johnwinans/riscv-toolchain-install-guide.git
```

## Update the sumbodules & checkout the correct versions

```bash
./installdeps.sh
./setup.sh
```

## Configure, build, and install the GNU toolchain and qemu
(Note that this can take the better part of an hour to complete!)

```bash
./buildall.sh
```

## Add the new tools to your PATH variable by altering your PATH
If you are using bash and installed the tools in the default location then
adding the following to the end of your .bashrc file will suffice: 

```bash
export PATH=${HOME}/opt/rv32i_qemu/bin:${PATH}
```

## Give qemu a basic sanity check

```bash
which qemu-system-riscv32
qemu-system-riscv32 --version
qemu-system-riscv32 -machine help
```

The output of the above commands on my box looks like this:

```
winans@x570:~$ which qemu-system-riscv32
/home/winans/projects/riscv/install/rv32i/bin/qemu-system-riscv32
winans@x570:~$ qemu-system-riscv32 --version
QEMU emulator version 5.2.0 (v5.2.0)
Copyright (c) 2003-2020 Fabrice Bellard and the QEMU Project developers
winans@x570:~$ qemu-system-riscv32 -machine help
Supported machines are:
none                 empty machine
opentitan            RISC-V Board compatible with OpenTitan
sifive_e             RISC-V Board compatible with SiFive E SDK
sifive_u             RISC-V Board compatible with SiFive U SDK
spike                RISC-V Spike board (default)
virt                 RISC-V VirtIO board
winans@x570:~$
```

## Give the gnu toolchain a basic sanity check

```bash
which riscv32-unknown-elf-as
riscv32-unknown-elf-as --version
riscv32-unknown-elf-gcc --version
```

The output of the above commands on my box looks like this:

```
winans@x570:~$ which riscv32-unknown-elf-as
/home/winans/projects/riscv/install/rv32i/bin/riscv32-unknown-elf-as
winans@x570:~$ riscv32-unknown-elf-as --version
GNU assembler (GNU Binutils) 2.36.1
Copyright (C) 2021 Free Software Foundation, Inc.
This program is free software; you may redistribute it under the terms of
the GNU General Public License version 3 or later.
This program has absolutely no warranty.
This assembler was configured for a target of `riscv32-unknown-elf'.
winans@x570:~$ riscv32-unknown-elf-gcc --version
riscv32-unknown-elf-gcc (GCC) 11.1.0
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

winans@x570:~$ 
```


## Install the gdb dashboard if you prefer

BE CAREFUL THAT YOU DO NOT CLOBBER ANY EXISTING ~/.gdbinit FILE!!!!

If the tools are installed in the default location then the following will copy the gdb-dashboard 
script into your home directory (possibly clobbering any existing one!)
so that it will be used when gdb is run:

```bash
cp ~/projects/riscv/riscv-toolchain-install-guide/gdb-dashboard/.gdbinit ~
```

Note that there is a problem with qemu v5.2.0 in that it tells gdb that there are 
more registers than there really ARE.  Thus the dashboard will complain like this:

```
0x00001000 in ?? ()
--- Assembly ----------------------------------------------------------------------------------------------
 0x00001000  ? auipc    t0,0x0
 0x00001004  ? addi    a2,t0,40
 0x00001008  ? csrr    a0,mhartid
 0x0000100c  ? lw    a1,32(t0)
 0x00001010  ? lw    t0,24(t0)
 0x00001014  ? jr    t0
 0x00001018  ? unimp
 0x0000101a  ? 0x8000
 0x0000101c  ? unimp
 0x0000101e  ? unimp
--- Breakpoints -------------------------------------------------------------------------------------------
--- Expressions -------------------------------------------------------------------------------------------
--- History -----------------------------------------------------------------------------------------------
--- Memory ------------------------------------------------------------------------------------------------
--- Registers ---------------------------------------------------------------------------------------------
Traceback (most recent call last):
  File "<string>", line 540, in render
  File "<string>", line 1945, in lines
error: Could not fetch register "dscratch"; remote failure reply 'E14'
--- Source ------------------------------------------------------------------------------------------------
--- Stack -------------------------------------------------------------------------------------------------
[0] from 0x00001000
--- Threads -----------------------------------------------------------------------------------------------
[1] id 1 from 0x00001000
--- Variables ---------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
```

A simple hack to 'fix' this problem (until there is a qemu release to address it) is to filter
out the incorrect register names by adding the following lines to the `~/.gdbinit` file starting
after line number 1945:

```
            if 'dscratch' in name:
                continue
            if 'mucounteren' in name:
                continue
```

The section code surrounding this addition will then look like this:

```
        for name in register_list:
            # Exclude registers with a dot '.' or parse_and_eval() will fail
            if '.' in name:
                continue
            if 'dscratch' in name:
                continue
            if 'mucounteren' in name:
                continue
            value = gdb.parse_and_eval('${}'.format(name))
            string_value = Registers.format_value(value)
            changed = self.table and (self.table.get(name, '') != string_value)
            self.table[name] = string_value
            registers.append((name, string_value, changed))
```

Keep in mind that python cares about white space (like FORTRAN, COBOL and numerous assembly languages!)
therefore the added lines have to be indented, in this case, using spaces (not tabs) such that they align with the
existing `if  '.' in name:` line as can be seen above!


Once corrected, the gdb dashboard will look like this:
```
0x00001000 in ?? ()
--- Assembly ----------------------------------------------------------------------------------------------
 0x00001000  ? auipc    t0,0x0
 0x00001004  ? addi    a2,t0,40
 0x00001008  ? csrr    a0,mhartid
 0x0000100c  ? lw    a1,32(t0)
 0x00001010  ? lw    t0,24(t0)
 0x00001014  ? jr    t0
 0x00001018  ? unimp
 0x0000101a  ? 0x8000
 0x0000101c  ? unimp
 0x0000101e  ? unimp
--- Breakpoints -------------------------------------------------------------------------------------------
--- Expressions -------------------------------------------------------------------------------------------
--- History -----------------------------------------------------------------------------------------------
--- Memory ------------------------------------------------------------------------------------------------
--- Registers ---------------------------------------------------------------------------------------------
    zero 0x00000000    ra 0x00000000     sp 0x00000000     gp 0x00000000    tp 0x00000000    t0 0x00000000
      t1 0x00000000    t2 0x00000000     fp 0x00000000     s1 0x00000000    a0 0x00000000    a1 0x00000000
      a2 0x00000000    a3 0x00000000     a4 0x00000000     a5 0x00000000    a6 0x00000000    a7 0x00000000
      s2 0x00000000    s3 0x00000000     s4 0x00000000     s5 0x00000000    s6 0x00000000    s7 0x00000000
      s8 0x00000000    s9 0x00000000    s10 0x00000000    s11 0x00000000    t3 0x00000000    t4 0x00000000
      t5 0x00000000    t6 0x00000000     pc 0x00001000
--- Source ------------------------------------------------------------------------------------------------
--- Stack -------------------------------------------------------------------------------------------------
[0] from 0x00001000
--- Threads -----------------------------------------------------------------------------------------------
[1] id 1 from 0x00001000
--- Variables ---------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
```

## Build a simple test app

```
cd test-freestanding
make world
```

Your output should look like this:

```
winans@x570:~/projects/riscv/riscv-toolchain-install-guide$ cd test-freestanding
winans@x570:~/projects/riscv/riscv-toolchain-install-guide/test-freestanding$ make world
rm -f prog prog.lst  *.o *.s *.lst *.bin *.srec
riscv32-unknown-elf-gcc -Wall -Werror -g -Wcast-align -ffreestanding  -fno-pic -O2  -march=rv32ima -mabi=ilp32 -c -o crt0.o crt0.S
riscv32-unknown-elf-gcc -Wall -Werror -g -Wcast-align -ffreestanding  -fno-pic -O2  -nostdlib -Wl,-T,vanilla.ld -march=rv32ima -mabi=ilp32 -o prog crt0.o -lc -lgcc
riscv32-unknown-elf-size -A -x prog
prog  :
section              size         addr
.text                0x30   0x80000000
.rodata               0xe   0x80000030
.eh_frame            0x2c   0x80000040
.riscv.attributes    0x28          0x0
.debug_line          0x82          0x0
.debug_line_str      0x38          0x0
.debug_info          0x24          0x0
.debug_abbrev        0x14          0x0
.debug_aranges       0x20          0x0
.debug_str           0x46          0x0
Total               0x1ea


riscv32-unknown-elf-objdump -Mnumeric,no-aliases -dr prog > prog.lst
winans@x570:~/projects/riscv/riscv-toolchain-install-guide/test-freestanding$ 
```


## Run qemu to make sure it works

```
qemu-system-riscv32 -machine virt -m 128M -bios none -device loader,file=./prog -nographic -s
```

Your output should look like this and then qemu should hang (until you halt it as shown below.)

```
winans@x570:~/projects/riscv/riscv-toolchain-install-guide/test-freestanding$ qemu-system-riscv32 -machine virt -m 128M -bios none -device loader,file=./prog -nographic -s
Hello World!
```

To halt and terminate qemu, press `CTRL+A` and then press `x` and you should see the following:

```
QEMU: Terminated
winans@x570:~/projects/riscv/riscv-toolchain-install-guide/test-freestanding$
```



## Run qemu and gdb together to make sure everything works

In one terminal run this command to stgart up qemu but tell it to wait (with the `-S` option)
for gdb to connect before any instructions begin executing:

```
qemu-system-riscv32 -machine virt -m 128M -bios none -device loader,file=./prog -nographic -s -S
```

In a different terminal (in the same directory that you ran the qemu emulator above) 
start up gdb and connect it to qemu:

```
riscv32-unknown-elf-gdb ./prog
target remote :1234
```

...which should look like this:

```
winans@x570:~/projects/riscv/riscv-toolchain-install-guide/test-freestanding$ riscv32-unknown-elf-gdb ./prog
GNU gdb (GDB) 10.1
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "--host=x86_64-pc-linux-gnu --target=riscv32-unknown-elf".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from ./prog...
>>> target remote :1234
Remote debugging using :1234
0x00001000 in ?? ()
--- Assembly ----------------------------------------------------------------------------------------------
 0x00001000  ? auipc    t0,0x0
 0x00001004  ? addi    a2,t0,40
 0x00001008  ? csrr    a0,mhartid
 0x0000100c  ? lw    a1,32(t0)
 0x00001010  ? lw    t0,24(t0)
 0x00001014  ? jr    t0
 0x00001018  ? unimp
 0x0000101a  ? 0x8000
 0x0000101c  ? unimp
 0x0000101e  ? unimp
--- Breakpoints -------------------------------------------------------------------------------------------
--- Expressions -------------------------------------------------------------------------------------------
--- History -----------------------------------------------------------------------------------------------
--- Memory ------------------------------------------------------------------------------------------------
--- Registers ---------------------------------------------------------------------------------------------
  zero 0x00000000   ra 0x00000000   sp 0x00000000   gp 0x00000000   tp 0x00000000   t0 0x00000000   t1 0x00000000
    t2 0x00000000   fp 0x00000000   s1 0x00000000   a0 0x00000000   a1 0x00000000   a2 0x00000000   a3 0x00000000
    a4 0x00000000   a5 0x00000000   a6 0x00000000   a7 0x00000000   s2 0x00000000   s3 0x00000000   s4 0x00000000
    s5 0x00000000   s6 0x00000000   s7 0x00000000   s8 0x00000000   s9 0x00000000  s10 0x00000000  s11 0x00000000
    t3 0x00000000   t4 0x00000000   t5 0x00000000   t6 0x00000000   pc 0x00001000
--- Source ------------------------------------------------------------------------------------------------
--- Stack -------------------------------------------------------------------------------------------------
[0] from 0x00001000
--- Threads -----------------------------------------------------------------------------------------------
[1] id 1 from 0x00001000
--- Variables ---------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------
>>>   
```


Once you get this far, you are ready to start experimenting with your own freestanding programs!
