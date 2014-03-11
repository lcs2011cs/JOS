
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/kclock.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1d 10 f0 	movl   $0xf0101d40,(%esp)
f0100055:	e8 f8 0b 00 00       	call   f0100c52 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mybacktrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 12 07 00 00       	call   f0100799 <mybacktrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1d 10 f0 	movl   $0xf0101d5c,(%esp)
f0100092:	e8 bb 0b 00 00       	call   f0100c52 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 70 39 11 f0       	mov    $0xf0113970,%eax
f01000a8:	2d 20 33 11 f0       	sub    $0xf0113320,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 20 33 11 f0 	movl   $0xf0113320,(%esp)
f01000c0:	e8 6c 17 00 00       	call   f0101831 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a2 04 00 00       	call   f010056c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1d 10 f0 	movl   $0xf0101d77,(%esp)
f01000d9:	e8 74 0b 00 00       	call   f0100c52 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000de:	e8 bc 09 00 00       	call   f0100a9f <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ea:	e8 07 08 00 00       	call   f01008f6 <monitor>
f01000ef:	eb f2                	jmp    f01000e3 <i386_init+0x46>

f01000f1 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f1:	55                   	push   %ebp
f01000f2:	89 e5                	mov    %esp,%ebp
f01000f4:	56                   	push   %esi
f01000f5:	53                   	push   %ebx
f01000f6:	83 ec 10             	sub    $0x10,%esp
f01000f9:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000fc:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f0100103:	75 3d                	jne    f0100142 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f0100105:	89 35 60 39 11 f0    	mov    %esi,0xf0113960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010010b:	fa                   	cli    
f010010c:	fc                   	cld    

	va_start(ap, fmt);
f010010d:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100110:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100113:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100117:	8b 45 08             	mov    0x8(%ebp),%eax
f010011a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011e:	c7 04 24 92 1d 10 f0 	movl   $0xf0101d92,(%esp)
f0100125:	e8 28 0b 00 00       	call   f0100c52 <cprintf>
	vcprintf(fmt, ap);
f010012a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010012e:	89 34 24             	mov    %esi,(%esp)
f0100131:	e8 e9 0a 00 00       	call   f0100c1f <vcprintf>
	cprintf("\n");
f0100136:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f010013d:	e8 10 0b 00 00       	call   f0100c52 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100142:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100149:	e8 a8 07 00 00       	call   f01008f6 <monitor>
f010014e:	eb f2                	jmp    f0100142 <_panic+0x51>

f0100150 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100150:	55                   	push   %ebp
f0100151:	89 e5                	mov    %esp,%ebp
f0100153:	53                   	push   %ebx
f0100154:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100157:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010015a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010015d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100161:	8b 45 08             	mov    0x8(%ebp),%eax
f0100164:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100168:	c7 04 24 aa 1d 10 f0 	movl   $0xf0101daa,(%esp)
f010016f:	e8 de 0a 00 00       	call   f0100c52 <cprintf>
	vcprintf(fmt, ap);
f0100174:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100178:	8b 45 10             	mov    0x10(%ebp),%eax
f010017b:	89 04 24             	mov    %eax,(%esp)
f010017e:	e8 9c 0a 00 00       	call   f0100c1f <vcprintf>
	cprintf("\n");
f0100183:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f010018a:	e8 c3 0a 00 00       	call   f0100c52 <cprintf>
	va_end(ap);
}
f010018f:	83 c4 14             	add    $0x14,%esp
f0100192:	5b                   	pop    %ebx
f0100193:	5d                   	pop    %ebp
f0100194:	c3                   	ret    
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 44 35 11 f0    	mov    0xf0113544,%edx
f01001df:	88 82 40 33 11 f0    	mov    %al,-0xfeeccc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 35 11 f0       	mov    %eax,0xf0113544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100217:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100218:	a8 20                	test   $0x20,%al
f010021a:	75 1b                	jne    f0100237 <cons_putc+0x30>
f010021c:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100221:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100226:	e8 75 ff ff ff       	call   f01001a0 <delay>
f010022b:	89 f2                	mov    %esi,%edx
f010022d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010022e:	a8 20                	test   $0x20,%al
f0100230:	75 05                	jne    f0100237 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100232:	83 eb 01             	sub    $0x1,%ebx
f0100235:	75 ef                	jne    f0100226 <cons_putc+0x1f>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010026f:	ee                   	out    %al,(%dx)
f0100270:	b2 7a                	mov    $0x7a,%dl
f0100272:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100277:	ee                   	out    %al,(%dx)
f0100278:	b8 08 00 00 00       	mov    $0x8,%eax
f010027d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!mycolor) mycolor = 0x0700;
f010027e:	83 3d 00 30 11 f0 00 	cmpl   $0x0,0xf0113000
f0100285:	75 0a                	jne    f0100291 <cons_putc+0x8a>
f0100287:	c7 05 00 30 11 f0 00 	movl   $0x700,0xf0113000
f010028e:	07 00 00 
  	if (!(c & ~0xFF))
f0100291:	89 fa                	mov    %edi,%edx
f0100293:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
   		 c |= mycolor;
f0100299:	89 f8                	mov    %edi,%eax
f010029b:	0b 05 00 30 11 f0    	or     0xf0113000,%eax
f01002a1:	85 d2                	test   %edx,%edx
f01002a3:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01002a6:	89 f8                	mov    %edi,%eax
f01002a8:	25 ff 00 00 00       	and    $0xff,%eax
f01002ad:	83 f8 09             	cmp    $0x9,%eax
f01002b0:	74 76                	je     f0100328 <cons_putc+0x121>
f01002b2:	83 f8 09             	cmp    $0x9,%eax
f01002b5:	7f 0b                	jg     f01002c2 <cons_putc+0xbb>
f01002b7:	83 f8 08             	cmp    $0x8,%eax
f01002ba:	0f 85 9c 00 00 00    	jne    f010035c <cons_putc+0x155>
f01002c0:	eb 10                	jmp    f01002d2 <cons_putc+0xcb>
f01002c2:	83 f8 0a             	cmp    $0xa,%eax
f01002c5:	74 3b                	je     f0100302 <cons_putc+0xfb>
f01002c7:	83 f8 0d             	cmp    $0xd,%eax
f01002ca:	0f 85 8c 00 00 00    	jne    f010035c <cons_putc+0x155>
f01002d0:	eb 38                	jmp    f010030a <cons_putc+0x103>
	case '\b':
		if (crt_pos > 0) {
f01002d2:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002d9:	66 85 c0             	test   %ax,%ax
f01002dc:	0f 84 e4 00 00 00    	je     f01003c6 <cons_putc+0x1bf>
			crt_pos--;
f01002e2:	83 e8 01             	sub    $0x1,%eax
f01002e5:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002eb:	0f b7 c0             	movzwl %ax,%eax
f01002ee:	66 81 e7 00 ff       	and    $0xff00,%di
f01002f3:	83 cf 20             	or     $0x20,%edi
f01002f6:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
f01002fc:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100300:	eb 77                	jmp    f0100379 <cons_putc+0x172>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100302:	66 83 05 54 35 11 f0 	addw   $0x50,0xf0113554
f0100309:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010030a:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f0100311:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100317:	c1 e8 16             	shr    $0x16,%eax
f010031a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010031d:	c1 e0 04             	shl    $0x4,%eax
f0100320:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
f0100326:	eb 51                	jmp    f0100379 <cons_putc+0x172>
		break;
	case '\t':
		cons_putc(' ');
f0100328:	b8 20 00 00 00       	mov    $0x20,%eax
f010032d:	e8 d5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100332:	b8 20 00 00 00       	mov    $0x20,%eax
f0100337:	e8 cb fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010033c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100341:	e8 c1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100346:	b8 20 00 00 00       	mov    $0x20,%eax
f010034b:	e8 b7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100350:	b8 20 00 00 00       	mov    $0x20,%eax
f0100355:	e8 ad fe ff ff       	call   f0100207 <cons_putc>
f010035a:	eb 1d                	jmp    f0100379 <cons_putc+0x172>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010035c:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f0100363:	0f b7 c8             	movzwl %ax,%ecx
f0100366:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
f010036c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100370:	83 c0 01             	add    $0x1,%eax
f0100373:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100379:	66 81 3d 54 35 11 f0 	cmpw   $0x7cf,0xf0113554
f0100380:	cf 07 
f0100382:	76 42                	jbe    f01003c6 <cons_putc+0x1bf>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100384:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0100389:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100390:	00 
f0100391:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100397:	89 54 24 04          	mov    %edx,0x4(%esp)
f010039b:	89 04 24             	mov    %eax,(%esp)
f010039e:	e8 e9 14 00 00       	call   f010188c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01003a3:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a9:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01003ae:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003b4:	83 c0 01             	add    $0x1,%eax
f01003b7:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003bc:	75 f0                	jne    f01003ae <cons_putc+0x1a7>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003be:	66 83 2d 54 35 11 f0 	subw   $0x50,0xf0113554
f01003c5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003c6:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f01003cc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003d1:	89 ca                	mov    %ecx,%edx
f01003d3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003d4:	0f b7 35 54 35 11 f0 	movzwl 0xf0113554,%esi
f01003db:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003de:	89 f0                	mov    %esi,%eax
f01003e0:	66 c1 e8 08          	shr    $0x8,%ax
f01003e4:	89 da                	mov    %ebx,%edx
f01003e6:	ee                   	out    %al,(%dx)
f01003e7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003ec:	89 ca                	mov    %ecx,%edx
f01003ee:	ee                   	out    %al,(%dx)
f01003ef:	89 f0                	mov    %esi,%eax
f01003f1:	89 da                	mov    %ebx,%edx
f01003f3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003f4:	83 c4 2c             	add    $0x2c,%esp
f01003f7:	5b                   	pop    %ebx
f01003f8:	5e                   	pop    %esi
f01003f9:	5f                   	pop    %edi
f01003fa:	5d                   	pop    %ebp
f01003fb:	c3                   	ret    

f01003fc <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003fc:	55                   	push   %ebp
f01003fd:	89 e5                	mov    %esp,%ebp
f01003ff:	53                   	push   %ebx
f0100400:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100403:	ba 64 00 00 00       	mov    $0x64,%edx
f0100408:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100409:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010040e:	a8 01                	test   $0x1,%al
f0100410:	0f 84 de 00 00 00    	je     f01004f4 <kbd_proc_data+0xf8>
f0100416:	b2 60                	mov    $0x60,%dl
f0100418:	ec                   	in     (%dx),%al
f0100419:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010041b:	3c e0                	cmp    $0xe0,%al
f010041d:	75 11                	jne    f0100430 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010041f:	83 0d 48 35 11 f0 40 	orl    $0x40,0xf0113548
		return 0;
f0100426:	bb 00 00 00 00       	mov    $0x0,%ebx
f010042b:	e9 c4 00 00 00       	jmp    f01004f4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100430:	84 c0                	test   %al,%al
f0100432:	79 37                	jns    f010046b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100434:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f010043a:	89 cb                	mov    %ecx,%ebx
f010043c:	83 e3 40             	and    $0x40,%ebx
f010043f:	83 e0 7f             	and    $0x7f,%eax
f0100442:	85 db                	test   %ebx,%ebx
f0100444:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100447:	0f b6 d2             	movzbl %dl,%edx
f010044a:	0f b6 82 00 1e 10 f0 	movzbl -0xfefe200(%edx),%eax
f0100451:	83 c8 40             	or     $0x40,%eax
f0100454:	0f b6 c0             	movzbl %al,%eax
f0100457:	f7 d0                	not    %eax
f0100459:	21 c1                	and    %eax,%ecx
f010045b:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
		return 0;
f0100461:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100466:	e9 89 00 00 00       	jmp    f01004f4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010046b:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f0100471:	f6 c1 40             	test   $0x40,%cl
f0100474:	74 0e                	je     f0100484 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100476:	89 c2                	mov    %eax,%edx
f0100478:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010047b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010047e:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
	}

	shift |= shiftcode[data];
f0100484:	0f b6 d2             	movzbl %dl,%edx
f0100487:	0f b6 82 00 1e 10 f0 	movzbl -0xfefe200(%edx),%eax
f010048e:	0b 05 48 35 11 f0    	or     0xf0113548,%eax
	shift ^= togglecode[data];
f0100494:	0f b6 8a 00 1f 10 f0 	movzbl -0xfefe100(%edx),%ecx
f010049b:	31 c8                	xor    %ecx,%eax
f010049d:	a3 48 35 11 f0       	mov    %eax,0xf0113548

	c = charcode[shift & (CTL | SHIFT)][data];
f01004a2:	89 c1                	mov    %eax,%ecx
f01004a4:	83 e1 03             	and    $0x3,%ecx
f01004a7:	8b 0c 8d 00 20 10 f0 	mov    -0xfefe000(,%ecx,4),%ecx
f01004ae:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004b2:	a8 08                	test   $0x8,%al
f01004b4:	74 19                	je     f01004cf <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004b6:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004b9:	83 fa 19             	cmp    $0x19,%edx
f01004bc:	77 05                	ja     f01004c3 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004be:	83 eb 20             	sub    $0x20,%ebx
f01004c1:	eb 0c                	jmp    f01004cf <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004c3:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004c6:	8d 53 20             	lea    0x20(%ebx),%edx
f01004c9:	83 f9 19             	cmp    $0x19,%ecx
f01004cc:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004cf:	f7 d0                	not    %eax
f01004d1:	a8 06                	test   $0x6,%al
f01004d3:	75 1f                	jne    f01004f4 <kbd_proc_data+0xf8>
f01004d5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004db:	75 17                	jne    f01004f4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004dd:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f01004e4:	e8 69 07 00 00       	call   f0100c52 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004e9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004ee:	b8 03 00 00 00       	mov    $0x3,%eax
f01004f3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004f4:	89 d8                	mov    %ebx,%eax
f01004f6:	83 c4 14             	add    $0x14,%esp
f01004f9:	5b                   	pop    %ebx
f01004fa:	5d                   	pop    %ebp
f01004fb:	c3                   	ret    

f01004fc <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100502:	80 3d 20 33 11 f0 00 	cmpb   $0x0,0xf0113320
f0100509:	74 0a                	je     f0100515 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010050b:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100510:	e8 b5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100515:	c9                   	leave  
f0100516:	c3                   	ret    

f0100517 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100517:	55                   	push   %ebp
f0100518:	89 e5                	mov    %esp,%ebp
f010051a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010051d:	b8 fc 03 10 f0       	mov    $0xf01003fc,%eax
f0100522:	e8 a3 fc ff ff       	call   f01001ca <cons_intr>
}
f0100527:	c9                   	leave  
f0100528:	c3                   	ret    

f0100529 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100529:	55                   	push   %ebp
f010052a:	89 e5                	mov    %esp,%ebp
f010052c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010052f:	e8 c8 ff ff ff       	call   f01004fc <serial_intr>
	kbd_intr();
f0100534:	e8 de ff ff ff       	call   f0100517 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100539:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010053f:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100544:	3b 15 44 35 11 f0    	cmp    0xf0113544,%edx
f010054a:	74 1e                	je     f010056a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010054c:	0f b6 82 40 33 11 f0 	movzbl -0xfeeccc0(%edx),%eax
f0100553:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100556:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100561:	0f 44 d1             	cmove  %ecx,%edx
f0100564:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
		return c;
	}
	return 0;
}
f010056a:	c9                   	leave  
f010056b:	c3                   	ret    

f010056c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010056c:	55                   	push   %ebp
f010056d:	89 e5                	mov    %esp,%ebp
f010056f:	57                   	push   %edi
f0100570:	56                   	push   %esi
f0100571:	53                   	push   %ebx
f0100572:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100575:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010057c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100583:	5a a5 
	if (*cp != 0xA55A) {
f0100585:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010058c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100590:	74 11                	je     f01005a3 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100592:	c7 05 4c 35 11 f0 b4 	movl   $0x3b4,0xf011354c
f0100599:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010059c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f01005a1:	eb 16                	jmp    f01005b9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01005a3:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005aa:	c7 05 4c 35 11 f0 d4 	movl   $0x3d4,0xf011354c
f01005b1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b9:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f01005bf:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c4:	89 ca                	mov    %ecx,%edx
f01005c6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c7:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ca:	89 da                	mov    %ebx,%edx
f01005cc:	ec                   	in     (%dx),%al
f01005cd:	0f b6 f8             	movzbl %al,%edi
f01005d0:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d8:	89 ca                	mov    %ecx,%edx
f01005da:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005db:	89 da                	mov    %ebx,%edx
f01005dd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005de:	89 35 50 35 11 f0    	mov    %esi,0xf0113550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e4:	0f b6 d8             	movzbl %al,%ebx
f01005e7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e9:	66 89 3d 54 35 11 f0 	mov    %di,0xf0113554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005f0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005fa:	89 da                	mov    %ebx,%edx
f01005fc:	ee                   	out    %al,(%dx)
f01005fd:	b2 fb                	mov    $0xfb,%dl
f01005ff:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010060a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060f:	89 ca                	mov    %ecx,%edx
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 f9                	mov    $0xf9,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 fb                	mov    $0xfb,%dl
f010061c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100621:	ee                   	out    %al,(%dx)
f0100622:	b2 fc                	mov    $0xfc,%dl
f0100624:	b8 00 00 00 00       	mov    $0x0,%eax
f0100629:	ee                   	out    %al,(%dx)
f010062a:	b2 f9                	mov    $0xf9,%dl
f010062c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100631:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100632:	b2 fd                	mov    $0xfd,%dl
f0100634:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100635:	3c ff                	cmp    $0xff,%al
f0100637:	0f 95 c0             	setne  %al
f010063a:	89 c6                	mov    %eax,%esi
f010063c:	a2 20 33 11 f0       	mov    %al,0xf0113320
f0100641:	89 da                	mov    %ebx,%edx
f0100643:	ec                   	in     (%dx),%al
f0100644:	89 ca                	mov    %ecx,%edx
f0100646:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100647:	89 f0                	mov    %esi,%eax
f0100649:	84 c0                	test   %al,%al
f010064b:	75 0c                	jne    f0100659 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f010064d:	c7 04 24 d0 1d 10 f0 	movl   $0xf0101dd0,(%esp)
f0100654:	e8 f9 05 00 00       	call   f0100c52 <cprintf>
}
f0100659:	83 c4 1c             	add    $0x1c,%esp
f010065c:	5b                   	pop    %ebx
f010065d:	5e                   	pop    %esi
f010065e:	5f                   	pop    %edi
f010065f:	5d                   	pop    %ebp
f0100660:	c3                   	ret    

f0100661 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100667:	8b 45 08             	mov    0x8(%ebp),%eax
f010066a:	e8 98 fb ff ff       	call   f0100207 <cons_putc>
}
f010066f:	c9                   	leave  
f0100670:	c3                   	ret    

f0100671 <getchar>:

int
getchar(void)
{
f0100671:	55                   	push   %ebp
f0100672:	89 e5                	mov    %esp,%ebp
f0100674:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100677:	e8 ad fe ff ff       	call   f0100529 <cons_getc>
f010067c:	85 c0                	test   %eax,%eax
f010067e:	74 f7                	je     f0100677 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100680:	c9                   	leave  
f0100681:	c3                   	ret    

f0100682 <iscons>:

int
iscons(int fdnum)
{
f0100682:	55                   	push   %ebp
f0100683:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100685:	b8 01 00 00 00       	mov    $0x1,%eax
f010068a:	5d                   	pop    %ebp
f010068b:	c3                   	ret    
f010068c:	00 00                	add    %al,(%eax)
	...

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 10 20 10 f0 	movl   $0xf0102010,(%esp)
f010069d:	e8 b0 05 00 00       	call   f0100c52 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 0c 21 10 f0 	movl   $0xf010210c,(%esp)
f01006b1:	e8 9c 05 00 00       	call   f0100c52 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 34 21 10 f0 	movl   $0xf0102134,(%esp)
f01006cd:	e8 80 05 00 00       	call   f0100c52 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 25 1d 10 	movl   $0x101d25,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 25 1d 10 	movl   $0xf0101d25,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 58 21 10 f0 	movl   $0xf0102158,(%esp)
f01006e9:	e8 64 05 00 00       	call   f0100c52 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 20 33 11 	movl   $0x113320,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 20 33 11 	movl   $0xf0113320,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 7c 21 10 f0 	movl   $0xf010217c,(%esp)
f0100705:	e8 48 05 00 00       	call   f0100c52 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 70 39 11 	movl   $0x113970,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 70 39 11 	movl   $0xf0113970,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 a0 21 10 f0 	movl   $0xf01021a0,(%esp)
f0100721:	e8 2c 05 00 00       	call   f0100c52 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 6f 3d 11 f0       	mov    $0xf0113d6f,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100730:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	0f 48 c2             	cmovs  %edx,%eax
f0100740:	c1 f8 0a             	sar    $0xa,%eax
f0100743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100747:	c7 04 24 c4 21 10 f0 	movl   $0xf01021c4,(%esp)
f010074e:	e8 ff 04 00 00       	call   f0100c52 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	53                   	push   %ebx
f010075e:	83 ec 14             	sub    $0x14,%esp
f0100761:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100766:	8b 83 c4 22 10 f0    	mov    -0xfefdd3c(%ebx),%eax
f010076c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100770:	8b 83 c0 22 10 f0    	mov    -0xfefdd40(%ebx),%eax
f0100776:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077a:	c7 04 24 29 20 10 f0 	movl   $0xf0102029,(%esp)
f0100781:	e8 cc 04 00 00       	call   f0100c52 <cprintf>
f0100786:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100789:	83 fb 24             	cmp    $0x24,%ebx
f010078c:	75 d8                	jne    f0100766 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010078e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100793:	83 c4 14             	add    $0x14,%esp
f0100796:	5b                   	pop    %ebx
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    

f0100799 <mybacktrace>:
    		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
int mybacktrace(int argc, char **argv, struct Trapframe *tf)
{
f0100799:	55                   	push   %ebp
f010079a:	89 e5                	mov    %esp,%ebp
f010079c:	57                   	push   %edi
f010079d:	56                   	push   %esi
f010079e:	53                   	push   %ebx
f010079f:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a2:	89 eb                	mov    %ebp,%ebx
	uint32_t* ebp = (uint32_t*) read_ebp();
f01007a4:	89 de                	mov    %ebx,%esi
 	cprintf("Stack backtrace:\n");
f01007a6:	c7 04 24 32 20 10 f0 	movl   $0xf0102032,(%esp)
f01007ad:	e8 a0 04 00 00       	call   f0100c52 <cprintf>
  	while (ebp) {
f01007b2:	85 db                	test   %ebx,%ebx
f01007b4:	0f 84 8b 00 00 00    	je     f0100845 <mybacktrace+0xac>
    		uint32_t eip = ebp[1];
f01007ba:	8b 7e 04             	mov    0x4(%esi),%edi
    		cprintf("ebp %x  eip %x  args", ebp, eip);
f01007bd:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007c1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c5:	c7 04 24 44 20 10 f0 	movl   $0xf0102044,(%esp)
f01007cc:	e8 81 04 00 00       	call   f0100c52 <cprintf>
    		int i;
    		for (i = 2; i <= 6; ++i)
f01007d1:	bb 02 00 00 00       	mov    $0x2,%ebx
     			cprintf(" %08.x", ebp[i]);
f01007d6:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007dd:	c7 04 24 59 20 10 f0 	movl   $0xf0102059,(%esp)
f01007e4:	e8 69 04 00 00       	call   f0100c52 <cprintf>
 	cprintf("Stack backtrace:\n");
  	while (ebp) {
    		uint32_t eip = ebp[1];
    		cprintf("ebp %x  eip %x  args", ebp, eip);
    		int i;
    		for (i = 2; i <= 6; ++i)
f01007e9:	83 c3 01             	add    $0x1,%ebx
f01007ec:	83 fb 07             	cmp    $0x7,%ebx
f01007ef:	75 e5                	jne    f01007d6 <mybacktrace+0x3d>
     			cprintf(" %08.x", ebp[i]);
    		cprintf("\n");
f01007f1:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f01007f8:	e8 55 04 00 00       	call   f0100c52 <cprintf>
   		struct Eipdebuginfo info;
    		debuginfo_eip(eip, &info);
f01007fd:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100800:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100804:	89 3c 24             	mov    %edi,(%esp)
f0100807:	e8 40 05 00 00       	call   f0100d4c <debuginfo_eip>

   	 	cprintf("\t%s:%d: %.*s+%d\n", 
f010080c:	2b 7d e0             	sub    -0x20(%ebp),%edi
f010080f:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0100813:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100816:	89 44 24 10          	mov    %eax,0x10(%esp)
f010081a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010081d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100821:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100824:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100828:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010082b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010082f:	c7 04 24 60 20 10 f0 	movl   $0xf0102060,(%esp)
f0100836:	e8 17 04 00 00       	call   f0100c52 <cprintf>
      		info.eip_file, info.eip_line,
      		info.eip_fn_namelen, info.eip_fn_name,
      		eip-info.eip_fn_addr);

    		ebp = (uint32_t*) *ebp;
f010083b:	8b 36                	mov    (%esi),%esi
}
int mybacktrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* ebp = (uint32_t*) read_ebp();
 	cprintf("Stack backtrace:\n");
  	while (ebp) {
f010083d:	85 f6                	test   %esi,%esi
f010083f:	0f 85 75 ff ff ff    	jne    f01007ba <mybacktrace+0x21>
      		eip-info.eip_fn_addr);

    		ebp = (uint32_t*) *ebp;
  	}
  	return 0;
}
f0100845:	b8 00 00 00 00       	mov    $0x0,%eax
f010084a:	83 c4 4c             	add    $0x4c,%esp
f010084d:	5b                   	pop    %ebx
f010084e:	5e                   	pop    %esi
f010084f:	5f                   	pop    %edi
f0100850:	5d                   	pop    %ebp
f0100851:	c3                   	ret    

f0100852 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100852:	55                   	push   %ebp
f0100853:	89 e5                	mov    %esp,%ebp
f0100855:	56                   	push   %esi
f0100856:	53                   	push   %ebx
f0100857:	83 ec 10             	sub    $0x10,%esp
f010085a:	89 eb                	mov    %ebp,%ebx
	uint32_t* ebp = (uint32_t*) read_ebp();
f010085c:	89 de                	mov    %ebx,%esi
  	cprintf("Stack backtrace:\n");
f010085e:	c7 04 24 32 20 10 f0 	movl   $0xf0102032,(%esp)
f0100865:	e8 e8 03 00 00       	call   f0100c52 <cprintf>
  	while (ebp) {
f010086a:	85 db                	test   %ebx,%ebx
f010086c:	74 7c                	je     f01008ea <mon_backtrace+0x98>
   		cprintf("ebp %x  eip %x  args", ebp, *(ebp+1));
f010086e:	8b 46 04             	mov    0x4(%esi),%eax
f0100871:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100875:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100879:	c7 04 24 44 20 10 f0 	movl   $0xf0102044,(%esp)
f0100880:	e8 cd 03 00 00       	call   f0100c52 <cprintf>
    		cprintf(" %x", *(ebp+2));
f0100885:	8b 46 08             	mov    0x8(%esi),%eax
f0100888:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088c:	c7 04 24 71 20 10 f0 	movl   $0xf0102071,(%esp)
f0100893:	e8 ba 03 00 00       	call   f0100c52 <cprintf>
    		cprintf(" %x", *(ebp+3));
f0100898:	8b 46 0c             	mov    0xc(%esi),%eax
f010089b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089f:	c7 04 24 71 20 10 f0 	movl   $0xf0102071,(%esp)
f01008a6:	e8 a7 03 00 00       	call   f0100c52 <cprintf>
    		cprintf(" %x", *(ebp+4));
f01008ab:	8b 46 10             	mov    0x10(%esi),%eax
f01008ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b2:	c7 04 24 71 20 10 f0 	movl   $0xf0102071,(%esp)
f01008b9:	e8 94 03 00 00       	call   f0100c52 <cprintf>
    		cprintf(" %x", *(ebp+5));
f01008be:	8b 46 14             	mov    0x14(%esi),%eax
f01008c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c5:	c7 04 24 71 20 10 f0 	movl   $0xf0102071,(%esp)
f01008cc:	e8 81 03 00 00       	call   f0100c52 <cprintf>
    		cprintf(" %x\n", *(ebp+6));
f01008d1:	8b 46 18             	mov    0x18(%esi),%eax
f01008d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d8:	c7 04 24 75 20 10 f0 	movl   $0xf0102075,(%esp)
f01008df:	e8 6e 03 00 00       	call   f0100c52 <cprintf>
    		ebp = (uint32_t*) *ebp;
f01008e4:	8b 36                	mov    (%esi),%esi
int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t* ebp = (uint32_t*) read_ebp();
  	cprintf("Stack backtrace:\n");
  	while (ebp) {
f01008e6:	85 f6                	test   %esi,%esi
f01008e8:	75 84                	jne    f010086e <mon_backtrace+0x1c>
    		cprintf(" %x", *(ebp+5));
    		cprintf(" %x\n", *(ebp+6));
    		ebp = (uint32_t*) *ebp;
	}
	return 0;
}
f01008ea:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ef:	83 c4 10             	add    $0x10,%esp
f01008f2:	5b                   	pop    %ebx
f01008f3:	5e                   	pop    %esi
f01008f4:	5d                   	pop    %ebp
f01008f5:	c3                   	ret    

f01008f6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008f6:	55                   	push   %ebp
f01008f7:	89 e5                	mov    %esp,%ebp
f01008f9:	57                   	push   %edi
f01008fa:	56                   	push   %esi
f01008fb:	53                   	push   %ebx
f01008fc:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008ff:	c7 04 24 f0 21 10 f0 	movl   $0xf01021f0,(%esp)
f0100906:	e8 47 03 00 00       	call   f0100c52 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010090b:	c7 04 24 14 22 10 f0 	movl   $0xf0102214,(%esp)
f0100912:	e8 3b 03 00 00       	call   f0100c52 <cprintf>
	cprintf("Type 'backtrace to see something interesting.\n");
f0100917:	c7 04 24 3c 22 10 f0 	movl   $0xf010223c,(%esp)
f010091e:	e8 2f 03 00 00       	call   f0100c52 <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f0100923:	c7 44 24 18 7a 20 10 	movl   $0xf010207a,0x18(%esp)
f010092a:	f0 
f010092b:	c7 44 24 14 00 04 00 	movl   $0x400,0x14(%esp)
f0100932:	00 
f0100933:	c7 44 24 10 7e 20 10 	movl   $0xf010207e,0x10(%esp)
f010093a:	f0 
f010093b:	c7 44 24 0c 00 02 00 	movl   $0x200,0xc(%esp)
f0100942:	00 
f0100943:	c7 44 24 08 84 20 10 	movl   $0xf0102084,0x8(%esp)
f010094a:	f0 
f010094b:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
f0100952:	00 
f0100953:	c7 04 24 89 20 10 f0 	movl   $0xf0102089,(%esp)
f010095a:	e8 f3 02 00 00       	call   f0100c52 <cprintf>

	while (1) {
		buf = readline("K> ");
f010095f:	c7 04 24 99 20 10 f0 	movl   $0xf0102099,(%esp)
f0100966:	e8 15 0c 00 00       	call   f0101580 <readline>
f010096b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010096d:	85 c0                	test   %eax,%eax
f010096f:	74 ee                	je     f010095f <monitor+0x69>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100971:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100978:	be 00 00 00 00       	mov    $0x0,%esi
f010097d:	eb 06                	jmp    f0100985 <monitor+0x8f>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010097f:	c6 03 00             	movb   $0x0,(%ebx)
f0100982:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100985:	0f b6 03             	movzbl (%ebx),%eax
f0100988:	84 c0                	test   %al,%al
f010098a:	74 6a                	je     f01009f6 <monitor+0x100>
f010098c:	0f be c0             	movsbl %al,%eax
f010098f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100993:	c7 04 24 9d 20 10 f0 	movl   $0xf010209d,(%esp)
f010099a:	e8 37 0e 00 00       	call   f01017d6 <strchr>
f010099f:	85 c0                	test   %eax,%eax
f01009a1:	75 dc                	jne    f010097f <monitor+0x89>
			*buf++ = 0;
		if (*buf == 0)
f01009a3:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009a6:	74 4e                	je     f01009f6 <monitor+0x100>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009a8:	83 fe 0f             	cmp    $0xf,%esi
f01009ab:	75 16                	jne    f01009c3 <monitor+0xcd>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009ad:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01009b4:	00 
f01009b5:	c7 04 24 a2 20 10 f0 	movl   $0xf01020a2,(%esp)
f01009bc:	e8 91 02 00 00       	call   f0100c52 <cprintf>
f01009c1:	eb 9c                	jmp    f010095f <monitor+0x69>
			return 0;
		}
		argv[argc++] = buf;
f01009c3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009c7:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009ca:	0f b6 03             	movzbl (%ebx),%eax
f01009cd:	84 c0                	test   %al,%al
f01009cf:	75 0c                	jne    f01009dd <monitor+0xe7>
f01009d1:	eb b2                	jmp    f0100985 <monitor+0x8f>
			buf++;
f01009d3:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009d6:	0f b6 03             	movzbl (%ebx),%eax
f01009d9:	84 c0                	test   %al,%al
f01009db:	74 a8                	je     f0100985 <monitor+0x8f>
f01009dd:	0f be c0             	movsbl %al,%eax
f01009e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009e4:	c7 04 24 9d 20 10 f0 	movl   $0xf010209d,(%esp)
f01009eb:	e8 e6 0d 00 00       	call   f01017d6 <strchr>
f01009f0:	85 c0                	test   %eax,%eax
f01009f2:	74 df                	je     f01009d3 <monitor+0xdd>
f01009f4:	eb 8f                	jmp    f0100985 <monitor+0x8f>
			buf++;
	}
	argv[argc] = 0;
f01009f6:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009fd:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009fe:	85 f6                	test   %esi,%esi
f0100a00:	0f 84 59 ff ff ff    	je     f010095f <monitor+0x69>
f0100a06:	bb c0 22 10 f0       	mov    $0xf01022c0,%ebx
f0100a0b:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a10:	8b 03                	mov    (%ebx),%eax
f0100a12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a16:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a19:	89 04 24             	mov    %eax,(%esp)
f0100a1c:	e8 3a 0d 00 00       	call   f010175b <strcmp>
f0100a21:	85 c0                	test   %eax,%eax
f0100a23:	75 24                	jne    f0100a49 <monitor+0x153>
			return commands[i].func(argc, argv, tf);
f0100a25:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100a28:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a2b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a2f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a32:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a36:	89 34 24             	mov    %esi,(%esp)
f0100a39:	ff 14 85 c8 22 10 f0 	call   *-0xfefdd38(,%eax,4)
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a40:	85 c0                	test   %eax,%eax
f0100a42:	78 28                	js     f0100a6c <monitor+0x176>
f0100a44:	e9 16 ff ff ff       	jmp    f010095f <monitor+0x69>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a49:	83 c7 01             	add    $0x1,%edi
f0100a4c:	83 c3 0c             	add    $0xc,%ebx
f0100a4f:	83 ff 03             	cmp    $0x3,%edi
f0100a52:	75 bc                	jne    f0100a10 <monitor+0x11a>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a54:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a5b:	c7 04 24 bf 20 10 f0 	movl   $0xf01020bf,(%esp)
f0100a62:	e8 eb 01 00 00       	call   f0100c52 <cprintf>
f0100a67:	e9 f3 fe ff ff       	jmp    f010095f <monitor+0x69>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a6c:	83 c4 6c             	add    $0x6c,%esp
f0100a6f:	5b                   	pop    %ebx
f0100a70:	5e                   	pop    %esi
f0100a71:	5f                   	pop    %edi
f0100a72:	5d                   	pop    %ebp
f0100a73:	c3                   	ret    

f0100a74 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a74:	55                   	push   %ebp
f0100a75:	89 e5                	mov    %esp,%ebp
f0100a77:	56                   	push   %esi
f0100a78:	53                   	push   %ebx
f0100a79:	83 ec 10             	sub    $0x10,%esp
f0100a7c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a7e:	89 04 24             	mov    %eax,(%esp)
f0100a81:	e8 5e 01 00 00       	call   f0100be4 <mc146818_read>
f0100a86:	89 c6                	mov    %eax,%esi
f0100a88:	83 c3 01             	add    $0x1,%ebx
f0100a8b:	89 1c 24             	mov    %ebx,(%esp)
f0100a8e:	e8 51 01 00 00       	call   f0100be4 <mc146818_read>
f0100a93:	c1 e0 08             	shl    $0x8,%eax
f0100a96:	09 f0                	or     %esi,%eax
}
f0100a98:	83 c4 10             	add    $0x10,%esp
f0100a9b:	5b                   	pop    %ebx
f0100a9c:	5e                   	pop    %esi
f0100a9d:	5d                   	pop    %ebp
f0100a9e:	c3                   	ret    

f0100a9f <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100a9f:	55                   	push   %ebp
f0100aa0:	89 e5                	mov    %esp,%ebp
f0100aa2:	83 ec 18             	sub    $0x18,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100aa5:	b8 15 00 00 00       	mov    $0x15,%eax
f0100aaa:	e8 c5 ff ff ff       	call   f0100a74 <nvram_read>
f0100aaf:	c1 e0 0a             	shl    $0xa,%eax
f0100ab2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100ab8:	85 c0                	test   %eax,%eax
f0100aba:	0f 48 c2             	cmovs  %edx,%eax
f0100abd:	c1 f8 0c             	sar    $0xc,%eax
f0100ac0:	a3 58 35 11 f0       	mov    %eax,0xf0113558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100ac5:	b8 17 00 00 00       	mov    $0x17,%eax
f0100aca:	e8 a5 ff ff ff       	call   f0100a74 <nvram_read>
f0100acf:	c1 e0 0a             	shl    $0xa,%eax
f0100ad2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100ad8:	85 c0                	test   %eax,%eax
f0100ada:	0f 48 c2             	cmovs  %edx,%eax
f0100add:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100ae0:	85 c0                	test   %eax,%eax
f0100ae2:	74 0e                	je     f0100af2 <mem_init+0x53>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100ae4:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100aea:	89 15 64 39 11 f0    	mov    %edx,0xf0113964
f0100af0:	eb 0c                	jmp    f0100afe <mem_init+0x5f>
	else
		npages = npages_basemem;
f0100af2:	8b 15 58 35 11 f0    	mov    0xf0113558,%edx
f0100af8:	89 15 64 39 11 f0    	mov    %edx,0xf0113964

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100afe:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b01:	c1 e8 0a             	shr    $0xa,%eax
f0100b04:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100b08:	a1 58 35 11 f0       	mov    0xf0113558,%eax
f0100b0d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b10:	c1 e8 0a             	shr    $0xa,%eax
f0100b13:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100b17:	a1 64 39 11 f0       	mov    0xf0113964,%eax
f0100b1c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100b1f:	c1 e8 0a             	shr    $0xa,%eax
f0100b22:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b26:	c7 04 24 e4 22 10 f0 	movl   $0xf01022e4,(%esp)
f0100b2d:	e8 20 01 00 00       	call   f0100c52 <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100b32:	c7 44 24 08 20 23 10 	movl   $0xf0102320,0x8(%esp)
f0100b39:	f0 
f0100b3a:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
f0100b41:	00 
f0100b42:	c7 04 24 4c 23 10 f0 	movl   $0xf010234c,(%esp)
f0100b49:	e8 a3 f5 ff ff       	call   f01000f1 <_panic>

f0100b4e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100b4e:	55                   	push   %ebp
f0100b4f:	89 e5                	mov    %esp,%ebp
f0100b51:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100b52:	83 3d 64 39 11 f0 00 	cmpl   $0x0,0xf0113964
f0100b59:	74 3b                	je     f0100b96 <page_init+0x48>
f0100b5b:	8b 1d 5c 35 11 f0    	mov    0xf011355c,%ebx
f0100b61:	b8 00 00 00 00       	mov    $0x0,%eax
		pages[i].pp_ref = 0;
f0100b66:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100b6d:	89 d1                	mov    %edx,%ecx
f0100b6f:	03 0d 6c 39 11 f0    	add    0xf011396c,%ecx
f0100b75:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100b7b:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100b7d:	89 d3                	mov    %edx,%ebx
f0100b7f:	03 1d 6c 39 11 f0    	add    0xf011396c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100b85:	83 c0 01             	add    $0x1,%eax
f0100b88:	39 05 64 39 11 f0    	cmp    %eax,0xf0113964
f0100b8e:	77 d6                	ja     f0100b66 <page_init+0x18>
f0100b90:	89 1d 5c 35 11 f0    	mov    %ebx,0xf011355c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100b96:	5b                   	pop    %ebx
f0100b97:	5d                   	pop    %ebp
f0100b98:	c3                   	ret    

f0100b99 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100b99:	55                   	push   %ebp
f0100b9a:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100b9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ba1:	5d                   	pop    %ebp
f0100ba2:	c3                   	ret    

f0100ba3 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100ba3:	55                   	push   %ebp
f0100ba4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100ba6:	5d                   	pop    %ebp
f0100ba7:	c3                   	ret    

f0100ba8 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100ba8:	55                   	push   %ebp
f0100ba9:	89 e5                	mov    %esp,%ebp
f0100bab:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100bae:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100bb3:	5d                   	pop    %ebp
f0100bb4:	c3                   	ret    

f0100bb5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100bb5:	55                   	push   %ebp
f0100bb6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100bb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bbd:	5d                   	pop    %ebp
f0100bbe:	c3                   	ret    

f0100bbf <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100bbf:	55                   	push   %ebp
f0100bc0:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100bc2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bc7:	5d                   	pop    %ebp
f0100bc8:	c3                   	ret    

f0100bc9 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100bc9:	55                   	push   %ebp
f0100bca:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100bcc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bd1:	5d                   	pop    %ebp
f0100bd2:	c3                   	ret    

f0100bd3 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100bd3:	55                   	push   %ebp
f0100bd4:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100bd6:	5d                   	pop    %ebp
f0100bd7:	c3                   	ret    

f0100bd8 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100bd8:	55                   	push   %ebp
f0100bd9:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100bdb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bde:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100be1:	5d                   	pop    %ebp
f0100be2:	c3                   	ret    
	...

f0100be4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100be4:	55                   	push   %ebp
f0100be5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100be7:	ba 70 00 00 00       	mov    $0x70,%edx
f0100bec:	8b 45 08             	mov    0x8(%ebp),%eax
f0100bef:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100bf0:	b2 71                	mov    $0x71,%dl
f0100bf2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100bf3:	0f b6 c0             	movzbl %al,%eax
}
f0100bf6:	5d                   	pop    %ebp
f0100bf7:	c3                   	ret    

f0100bf8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100bf8:	55                   	push   %ebp
f0100bf9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100bfb:	ba 70 00 00 00       	mov    $0x70,%edx
f0100c00:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c03:	ee                   	out    %al,(%dx)
f0100c04:	b2 71                	mov    $0x71,%dl
f0100c06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c09:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100c0a:	5d                   	pop    %ebp
f0100c0b:	c3                   	ret    

f0100c0c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c0c:	55                   	push   %ebp
f0100c0d:	89 e5                	mov    %esp,%ebp
f0100c0f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100c12:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c15:	89 04 24             	mov    %eax,(%esp)
f0100c18:	e8 44 fa ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100c1d:	c9                   	leave  
f0100c1e:	c3                   	ret    

f0100c1f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c1f:	55                   	push   %ebp
f0100c20:	89 e5                	mov    %esp,%ebp
f0100c22:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100c25:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c33:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c36:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c3a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c41:	c7 04 24 0c 0c 10 f0 	movl   $0xf0100c0c,(%esp)
f0100c48:	e8 e3 04 00 00       	call   f0101130 <vprintfmt>
	return cnt;
}
f0100c4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c50:	c9                   	leave  
f0100c51:	c3                   	ret    

f0100c52 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100c52:	55                   	push   %ebp
f0100c53:	89 e5                	mov    %esp,%ebp
f0100c55:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100c58:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100c5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c62:	89 04 24             	mov    %eax,(%esp)
f0100c65:	e8 b5 ff ff ff       	call   f0100c1f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100c6a:	c9                   	leave  
f0100c6b:	c3                   	ret    

f0100c6c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100c6c:	55                   	push   %ebp
f0100c6d:	89 e5                	mov    %esp,%ebp
f0100c6f:	57                   	push   %edi
f0100c70:	56                   	push   %esi
f0100c71:	53                   	push   %ebx
f0100c72:	83 ec 10             	sub    $0x10,%esp
f0100c75:	89 c3                	mov    %eax,%ebx
f0100c77:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100c7a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100c7d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100c80:	8b 0a                	mov    (%edx),%ecx
f0100c82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c85:	8b 00                	mov    (%eax),%eax
f0100c87:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c8a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100c91:	eb 77                	jmp    f0100d0a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100c93:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100c96:	01 c8                	add    %ecx,%eax
f0100c98:	bf 02 00 00 00       	mov    $0x2,%edi
f0100c9d:	99                   	cltd   
f0100c9e:	f7 ff                	idiv   %edi
f0100ca0:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ca2:	eb 01                	jmp    f0100ca5 <stab_binsearch+0x39>
			m--;
f0100ca4:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ca5:	39 ca                	cmp    %ecx,%edx
f0100ca7:	7c 1d                	jl     f0100cc6 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ca9:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cac:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100cb1:	39 f7                	cmp    %esi,%edi
f0100cb3:	75 ef                	jne    f0100ca4 <stab_binsearch+0x38>
f0100cb5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100cb8:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100cbb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100cbf:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100cc2:	73 18                	jae    f0100cdc <stab_binsearch+0x70>
f0100cc4:	eb 05                	jmp    f0100ccb <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100cc6:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100cc9:	eb 3f                	jmp    f0100d0a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ccb:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100cce:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100cd0:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100cd3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100cda:	eb 2e                	jmp    f0100d0a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100cdc:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100cdf:	76 15                	jbe    f0100cf6 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100ce1:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100ce4:	4f                   	dec    %edi
f0100ce5:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100ce8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ceb:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ced:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100cf4:	eb 14                	jmp    f0100d0a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100cf6:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100cf9:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100cfc:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100cfe:	ff 45 0c             	incl   0xc(%ebp)
f0100d01:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d03:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100d0a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100d0d:	7e 84                	jle    f0100c93 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100d0f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100d13:	75 0d                	jne    f0100d22 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100d15:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d18:	8b 02                	mov    (%edx),%eax
f0100d1a:	48                   	dec    %eax
f0100d1b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d1e:	89 01                	mov    %eax,(%ecx)
f0100d20:	eb 22                	jmp    f0100d44 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d22:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d25:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d27:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d2a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d2c:	eb 01                	jmp    f0100d2f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100d2e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d2f:	39 c1                	cmp    %eax,%ecx
f0100d31:	7d 0c                	jge    f0100d3f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100d33:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100d36:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100d3b:	39 f2                	cmp    %esi,%edx
f0100d3d:	75 ef                	jne    f0100d2e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100d3f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d42:	89 02                	mov    %eax,(%edx)
	}
}
f0100d44:	83 c4 10             	add    $0x10,%esp
f0100d47:	5b                   	pop    %ebx
f0100d48:	5e                   	pop    %esi
f0100d49:	5f                   	pop    %edi
f0100d4a:	5d                   	pop    %ebp
f0100d4b:	c3                   	ret    

f0100d4c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100d4c:	55                   	push   %ebp
f0100d4d:	89 e5                	mov    %esp,%ebp
f0100d4f:	83 ec 58             	sub    $0x58,%esp
f0100d52:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100d55:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100d58:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100d5b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d5e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100d61:	c7 03 58 23 10 f0    	movl   $0xf0102358,(%ebx)
	info->eip_line = 0;
f0100d67:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100d6e:	c7 43 08 58 23 10 f0 	movl   $0xf0102358,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100d75:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100d7c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100d7f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100d86:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100d8c:	76 12                	jbe    f0100da0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100d8e:	b8 dd 87 10 f0       	mov    $0xf01087dd,%eax
f0100d93:	3d 75 6b 10 f0       	cmp    $0xf0106b75,%eax
f0100d98:	0f 86 e2 01 00 00    	jbe    f0100f80 <debuginfo_eip+0x234>
f0100d9e:	eb 1c                	jmp    f0100dbc <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100da0:	c7 44 24 08 62 23 10 	movl   $0xf0102362,0x8(%esp)
f0100da7:	f0 
f0100da8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100daf:	00 
f0100db0:	c7 04 24 6f 23 10 f0 	movl   $0xf010236f,(%esp)
f0100db7:	e8 35 f3 ff ff       	call   f01000f1 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100dbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100dc1:	80 3d dc 87 10 f0 00 	cmpb   $0x0,0xf01087dc
f0100dc8:	0f 85 be 01 00 00    	jne    f0100f8c <debuginfo_eip+0x240>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100dce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100dd5:	b8 74 6b 10 f0       	mov    $0xf0106b74,%eax
f0100dda:	2d 90 25 10 f0       	sub    $0xf0102590,%eax
f0100ddf:	c1 f8 02             	sar    $0x2,%eax
f0100de2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100de8:	83 e8 01             	sub    $0x1,%eax
f0100deb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100dee:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100df2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100df9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100dfc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100dff:	b8 90 25 10 f0       	mov    $0xf0102590,%eax
f0100e04:	e8 63 fe ff ff       	call   f0100c6c <stab_binsearch>
	if (lfile == 0)
f0100e09:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100e0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100e11:	85 d2                	test   %edx,%edx
f0100e13:	0f 84 73 01 00 00    	je     f0100f8c <debuginfo_eip+0x240>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e19:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100e1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e1f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e22:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e26:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100e2d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100e30:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e33:	b8 90 25 10 f0       	mov    $0xf0102590,%eax
f0100e38:	e8 2f fe ff ff       	call   f0100c6c <stab_binsearch>

	if (lfun <= rfun) {
f0100e3d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e40:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e43:	39 d0                	cmp    %edx,%eax
f0100e45:	7f 3d                	jg     f0100e84 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100e47:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100e4a:	8d b9 90 25 10 f0    	lea    -0xfefda70(%ecx),%edi
f0100e50:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100e53:	8b 89 90 25 10 f0    	mov    -0xfefda70(%ecx),%ecx
f0100e59:	bf dd 87 10 f0       	mov    $0xf01087dd,%edi
f0100e5e:	81 ef 75 6b 10 f0    	sub    $0xf0106b75,%edi
f0100e64:	39 f9                	cmp    %edi,%ecx
f0100e66:	73 09                	jae    f0100e71 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100e68:	81 c1 75 6b 10 f0    	add    $0xf0106b75,%ecx
f0100e6e:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100e71:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100e74:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100e77:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100e7a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100e7c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100e7f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100e82:	eb 0f                	jmp    f0100e93 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100e84:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100e87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e8a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100e8d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e90:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100e93:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100e9a:	00 
f0100e9b:	8b 43 08             	mov    0x8(%ebx),%eax
f0100e9e:	89 04 24             	mov    %eax,(%esp)
f0100ea1:	e8 64 09 00 00       	call   f010180a <strfind>
f0100ea6:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ea9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	 stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100eac:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100eb0:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100eb7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100eba:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ebd:	b8 90 25 10 f0       	mov    $0xf0102590,%eax
f0100ec2:	e8 a5 fd ff ff       	call   f0100c6c <stab_binsearch>
    	 info->eip_line = stabs[lline].n_desc;
f0100ec7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100eca:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100ecd:	0f b7 80 96 25 10 f0 	movzwl -0xfefda6a(%eax),%eax
f0100ed4:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ed7:	89 f0                	mov    %esi,%eax
f0100ed9:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100edc:	39 ce                	cmp    %ecx,%esi
f0100ede:	7c 5f                	jl     f0100f3f <debuginfo_eip+0x1f3>
	       && stabs[lline].n_type != N_SOL
f0100ee0:	89 f2                	mov    %esi,%edx
f0100ee2:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100ee5:	80 be 94 25 10 f0 84 	cmpb   $0x84,-0xfefda6c(%esi)
f0100eec:	75 18                	jne    f0100f06 <debuginfo_eip+0x1ba>
f0100eee:	eb 30                	jmp    f0100f20 <debuginfo_eip+0x1d4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ef0:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ef3:	39 c1                	cmp    %eax,%ecx
f0100ef5:	7f 48                	jg     f0100f3f <debuginfo_eip+0x1f3>
	       && stabs[lline].n_type != N_SOL
f0100ef7:	89 c2                	mov    %eax,%edx
f0100ef9:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100efc:	80 3c b5 94 25 10 f0 	cmpb   $0x84,-0xfefda6c(,%esi,4)
f0100f03:	84 
f0100f04:	74 1a                	je     f0100f20 <debuginfo_eip+0x1d4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100f06:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100f09:	8d 14 95 90 25 10 f0 	lea    -0xfefda70(,%edx,4),%edx
f0100f10:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100f14:	75 da                	jne    f0100ef0 <debuginfo_eip+0x1a4>
f0100f16:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100f1a:	74 d4                	je     f0100ef0 <debuginfo_eip+0x1a4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f1c:	39 c1                	cmp    %eax,%ecx
f0100f1e:	7f 1f                	jg     f0100f3f <debuginfo_eip+0x1f3>
f0100f20:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f23:	8b 80 90 25 10 f0    	mov    -0xfefda70(%eax),%eax
f0100f29:	ba dd 87 10 f0       	mov    $0xf01087dd,%edx
f0100f2e:	81 ea 75 6b 10 f0    	sub    $0xf0106b75,%edx
f0100f34:	39 d0                	cmp    %edx,%eax
f0100f36:	73 07                	jae    f0100f3f <debuginfo_eip+0x1f3>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100f38:	05 75 6b 10 f0       	add    $0xf0106b75,%eax
f0100f3d:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f3f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f42:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f45:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f4a:	39 ca                	cmp    %ecx,%edx
f0100f4c:	7d 3e                	jge    f0100f8c <debuginfo_eip+0x240>
		for (lline = lfun + 1;
f0100f4e:	83 c2 01             	add    $0x1,%edx
f0100f51:	39 d1                	cmp    %edx,%ecx
f0100f53:	7e 37                	jle    f0100f8c <debuginfo_eip+0x240>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100f55:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100f58:	80 be 94 25 10 f0 a0 	cmpb   $0xa0,-0xfefda6c(%esi)
f0100f5f:	75 2b                	jne    f0100f8c <debuginfo_eip+0x240>
		     lline++)
			info->eip_fn_narg++;
f0100f61:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100f65:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100f68:	39 d1                	cmp    %edx,%ecx
f0100f6a:	7e 1b                	jle    f0100f87 <debuginfo_eip+0x23b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100f6c:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100f6f:	80 3c 85 94 25 10 f0 	cmpb   $0xa0,-0xfefda6c(,%eax,4)
f0100f76:	a0 
f0100f77:	74 e8                	je     f0100f61 <debuginfo_eip+0x215>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f79:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f7e:	eb 0c                	jmp    f0100f8c <debuginfo_eip+0x240>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100f80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f85:	eb 05                	jmp    f0100f8c <debuginfo_eip+0x240>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f87:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f8c:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100f8f:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100f92:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100f95:	89 ec                	mov    %ebp,%esp
f0100f97:	5d                   	pop    %ebp
f0100f98:	c3                   	ret    
f0100f99:	00 00                	add    %al,(%eax)
	...

f0100f9c <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	57                   	push   %edi
f0100fa0:	56                   	push   %esi
f0100fa1:	53                   	push   %ebx
f0100fa2:	83 ec 3c             	sub    $0x3c,%esp
f0100fa5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fa8:	89 d7                	mov    %edx,%edi
f0100faa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fad:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100fb6:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100fb9:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100fbc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fc1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100fc4:	72 11                	jb     f0100fd7 <printnum+0x3b>
f0100fc6:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fc9:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100fcc:	76 09                	jbe    f0100fd7 <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100fce:	83 eb 01             	sub    $0x1,%ebx
f0100fd1:	85 db                	test   %ebx,%ebx
f0100fd3:	7f 51                	jg     f0101026 <printnum+0x8a>
f0100fd5:	eb 5e                	jmp    f0101035 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100fd7:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100fdb:	83 eb 01             	sub    $0x1,%ebx
f0100fde:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100fe2:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fe5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100fe9:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100fed:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100ff1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100ff8:	00 
f0100ff9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ffc:	89 04 24             	mov    %eax,(%esp)
f0100fff:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101002:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101006:	e8 75 0a 00 00       	call   f0101a80 <__udivdi3>
f010100b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010100f:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101013:	89 04 24             	mov    %eax,(%esp)
f0101016:	89 54 24 04          	mov    %edx,0x4(%esp)
f010101a:	89 fa                	mov    %edi,%edx
f010101c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010101f:	e8 78 ff ff ff       	call   f0100f9c <printnum>
f0101024:	eb 0f                	jmp    f0101035 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0101026:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010102a:	89 34 24             	mov    %esi,(%esp)
f010102d:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101030:	83 eb 01             	sub    $0x1,%ebx
f0101033:	75 f1                	jne    f0101026 <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101035:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101039:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010103d:	8b 45 10             	mov    0x10(%ebp),%eax
f0101040:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101044:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010104b:	00 
f010104c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010104f:	89 04 24             	mov    %eax,(%esp)
f0101052:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101055:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101059:	e8 52 0b 00 00       	call   f0101bb0 <__umoddi3>
f010105e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101062:	0f be 80 7d 23 10 f0 	movsbl -0xfefdc83(%eax),%eax
f0101069:	89 04 24             	mov    %eax,(%esp)
f010106c:	ff 55 e4             	call   *-0x1c(%ebp)
}
f010106f:	83 c4 3c             	add    $0x3c,%esp
f0101072:	5b                   	pop    %ebx
f0101073:	5e                   	pop    %esi
f0101074:	5f                   	pop    %edi
f0101075:	5d                   	pop    %ebp
f0101076:	c3                   	ret    

f0101077 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0101077:	55                   	push   %ebp
f0101078:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010107a:	83 fa 01             	cmp    $0x1,%edx
f010107d:	7e 0e                	jle    f010108d <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f010107f:	8b 10                	mov    (%eax),%edx
f0101081:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101084:	89 08                	mov    %ecx,(%eax)
f0101086:	8b 02                	mov    (%edx),%eax
f0101088:	8b 52 04             	mov    0x4(%edx),%edx
f010108b:	eb 22                	jmp    f01010af <getuint+0x38>
	else if (lflag)
f010108d:	85 d2                	test   %edx,%edx
f010108f:	74 10                	je     f01010a1 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101091:	8b 10                	mov    (%eax),%edx
f0101093:	8d 4a 04             	lea    0x4(%edx),%ecx
f0101096:	89 08                	mov    %ecx,(%eax)
f0101098:	8b 02                	mov    (%edx),%eax
f010109a:	ba 00 00 00 00       	mov    $0x0,%edx
f010109f:	eb 0e                	jmp    f01010af <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01010a1:	8b 10                	mov    (%eax),%edx
f01010a3:	8d 4a 04             	lea    0x4(%edx),%ecx
f01010a6:	89 08                	mov    %ecx,(%eax)
f01010a8:	8b 02                	mov    (%edx),%eax
f01010aa:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01010af:	5d                   	pop    %ebp
f01010b0:	c3                   	ret    

f01010b1 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f01010b1:	55                   	push   %ebp
f01010b2:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01010b4:	83 fa 01             	cmp    $0x1,%edx
f01010b7:	7e 0e                	jle    f01010c7 <getint+0x16>
		return va_arg(*ap, long long);
f01010b9:	8b 10                	mov    (%eax),%edx
f01010bb:	8d 4a 08             	lea    0x8(%edx),%ecx
f01010be:	89 08                	mov    %ecx,(%eax)
f01010c0:	8b 02                	mov    (%edx),%eax
f01010c2:	8b 52 04             	mov    0x4(%edx),%edx
f01010c5:	eb 22                	jmp    f01010e9 <getint+0x38>
	else if (lflag)
f01010c7:	85 d2                	test   %edx,%edx
f01010c9:	74 10                	je     f01010db <getint+0x2a>
		return va_arg(*ap, long);
f01010cb:	8b 10                	mov    (%eax),%edx
f01010cd:	8d 4a 04             	lea    0x4(%edx),%ecx
f01010d0:	89 08                	mov    %ecx,(%eax)
f01010d2:	8b 02                	mov    (%edx),%eax
f01010d4:	89 c2                	mov    %eax,%edx
f01010d6:	c1 fa 1f             	sar    $0x1f,%edx
f01010d9:	eb 0e                	jmp    f01010e9 <getint+0x38>
	else
		return va_arg(*ap, int);
f01010db:	8b 10                	mov    (%eax),%edx
f01010dd:	8d 4a 04             	lea    0x4(%edx),%ecx
f01010e0:	89 08                	mov    %ecx,(%eax)
f01010e2:	8b 02                	mov    (%edx),%eax
f01010e4:	89 c2                	mov    %eax,%edx
f01010e6:	c1 fa 1f             	sar    $0x1f,%edx
}
f01010e9:	5d                   	pop    %ebp
f01010ea:	c3                   	ret    

f01010eb <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01010eb:	55                   	push   %ebp
f01010ec:	89 e5                	mov    %esp,%ebp
f01010ee:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01010f1:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01010f5:	8b 10                	mov    (%eax),%edx
f01010f7:	3b 50 04             	cmp    0x4(%eax),%edx
f01010fa:	73 0a                	jae    f0101106 <sprintputch+0x1b>
		*b->buf++ = ch;
f01010fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01010ff:	88 0a                	mov    %cl,(%edx)
f0101101:	83 c2 01             	add    $0x1,%edx
f0101104:	89 10                	mov    %edx,(%eax)
}
f0101106:	5d                   	pop    %ebp
f0101107:	c3                   	ret    

f0101108 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101108:	55                   	push   %ebp
f0101109:	89 e5                	mov    %esp,%ebp
f010110b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010110e:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101111:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101115:	8b 45 10             	mov    0x10(%ebp),%eax
f0101118:	89 44 24 08          	mov    %eax,0x8(%esp)
f010111c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010111f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101123:	8b 45 08             	mov    0x8(%ebp),%eax
f0101126:	89 04 24             	mov    %eax,(%esp)
f0101129:	e8 02 00 00 00       	call   f0101130 <vprintfmt>
	va_end(ap);
}
f010112e:	c9                   	leave  
f010112f:	c3                   	ret    

f0101130 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101130:	55                   	push   %ebp
f0101131:	89 e5                	mov    %esp,%ebp
f0101133:	57                   	push   %edi
f0101134:	56                   	push   %esi
f0101135:	53                   	push   %ebx
f0101136:	83 ec 4c             	sub    $0x4c,%esp
f0101139:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010113c:	8b 75 10             	mov    0x10(%ebp),%esi
f010113f:	eb 20                	jmp    f0101161 <vprintfmt+0x31>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0'){
f0101141:	85 c0                	test   %eax,%eax
f0101143:	75 12                	jne    f0101157 <vprintfmt+0x27>
				mycolor = 0x0700;
f0101145:	c7 05 00 30 11 f0 00 	movl   $0x700,0xf0113000
f010114c:	07 00 00 
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f010114f:	83 c4 4c             	add    $0x4c,%esp
f0101152:	5b                   	pop    %ebx
f0101153:	5e                   	pop    %esi
f0101154:	5f                   	pop    %edi
f0101155:	5d                   	pop    %ebp
f0101156:	c3                   	ret    
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0'){
				mycolor = 0x0700;
				return;
			}
			putch(ch, putdat);
f0101157:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010115b:	89 04 24             	mov    %eax,(%esp)
f010115e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101161:	0f b6 06             	movzbl (%esi),%eax
f0101164:	83 c6 01             	add    $0x1,%esi
f0101167:	83 f8 25             	cmp    $0x25,%eax
f010116a:	75 d5                	jne    f0101141 <vprintfmt+0x11>
f010116c:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0101170:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0101177:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f010117c:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0101183:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101188:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010118b:	eb 2b                	jmp    f01011b8 <vprintfmt+0x88>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010118d:	8b 75 e4             	mov    -0x1c(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0101190:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0101194:	eb 22                	jmp    f01011b8 <vprintfmt+0x88>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101196:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101199:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f010119d:	eb 19                	jmp    f01011b8 <vprintfmt+0x88>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010119f:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01011a2:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01011a9:	eb 0d                	jmp    f01011b8 <vprintfmt+0x88>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01011ab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011ae:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011b1:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011b8:	0f b6 06             	movzbl (%esi),%eax
f01011bb:	0f b6 d0             	movzbl %al,%edx
f01011be:	8d 7e 01             	lea    0x1(%esi),%edi
f01011c1:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01011c4:	83 e8 23             	sub    $0x23,%eax
f01011c7:	3c 55                	cmp    $0x55,%al
f01011c9:	0f 87 06 03 00 00    	ja     f01014d5 <vprintfmt+0x3a5>
f01011cf:	0f b6 c0             	movzbl %al,%eax
f01011d2:	ff 24 85 0c 24 10 f0 	jmp    *-0xfefdbf4(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01011d9:	83 ea 30             	sub    $0x30,%edx
f01011dc:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01011df:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01011e3:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011e6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01011e9:	83 fa 09             	cmp    $0x9,%edx
f01011ec:	77 4a                	ja     f0101238 <vprintfmt+0x108>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ee:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01011f1:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01011f4:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01011f7:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01011fb:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01011fe:	8d 50 d0             	lea    -0x30(%eax),%edx
f0101201:	83 fa 09             	cmp    $0x9,%edx
f0101204:	76 eb                	jbe    f01011f1 <vprintfmt+0xc1>
f0101206:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101209:	eb 2d                	jmp    f0101238 <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010120b:	8b 45 14             	mov    0x14(%ebp),%eax
f010120e:	8d 50 04             	lea    0x4(%eax),%edx
f0101211:	89 55 14             	mov    %edx,0x14(%ebp)
f0101214:	8b 00                	mov    (%eax),%eax
f0101216:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101219:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f010121c:	eb 1a                	jmp    f0101238 <vprintfmt+0x108>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010121e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0101221:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101225:	79 91                	jns    f01011b8 <vprintfmt+0x88>
f0101227:	e9 73 ff ff ff       	jmp    f010119f <vprintfmt+0x6f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010122c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010122f:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101236:	eb 80                	jmp    f01011b8 <vprintfmt+0x88>

		process_precision:
			if (width < 0)
f0101238:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010123c:	0f 89 76 ff ff ff    	jns    f01011b8 <vprintfmt+0x88>
f0101242:	e9 64 ff ff ff       	jmp    f01011ab <vprintfmt+0x7b>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101247:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010124a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010124d:	e9 66 ff ff ff       	jmp    f01011b8 <vprintfmt+0x88>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101252:	8b 45 14             	mov    0x14(%ebp),%eax
f0101255:	8d 50 04             	lea    0x4(%eax),%edx
f0101258:	89 55 14             	mov    %edx,0x14(%ebp)
f010125b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010125f:	8b 00                	mov    (%eax),%eax
f0101261:	89 04 24             	mov    %eax,(%esp)
f0101264:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101267:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f010126a:	e9 f2 fe ff ff       	jmp    f0101161 <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010126f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101272:	8d 50 04             	lea    0x4(%eax),%edx
f0101275:	89 55 14             	mov    %edx,0x14(%ebp)
f0101278:	8b 00                	mov    (%eax),%eax
f010127a:	89 c2                	mov    %eax,%edx
f010127c:	c1 fa 1f             	sar    $0x1f,%edx
f010127f:	31 d0                	xor    %edx,%eax
f0101281:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101283:	83 f8 06             	cmp    $0x6,%eax
f0101286:	7f 0b                	jg     f0101293 <vprintfmt+0x163>
f0101288:	8b 14 85 64 25 10 f0 	mov    -0xfefda9c(,%eax,4),%edx
f010128f:	85 d2                	test   %edx,%edx
f0101291:	75 23                	jne    f01012b6 <vprintfmt+0x186>
				printfmt(putch, putdat, "error %d", err);
f0101293:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101297:	c7 44 24 08 95 23 10 	movl   $0xf0102395,0x8(%esp)
f010129e:	f0 
f010129f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012a3:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012a6:	89 3c 24             	mov    %edi,(%esp)
f01012a9:	e8 5a fe ff ff       	call   f0101108 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012ae:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01012b1:	e9 ab fe ff ff       	jmp    f0101161 <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f01012b6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012ba:	c7 44 24 08 9e 23 10 	movl   $0xf010239e,0x8(%esp)
f01012c1:	f0 
f01012c2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012c9:	89 3c 24             	mov    %edi,(%esp)
f01012cc:	e8 37 fe ff ff       	call   f0101108 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012d1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01012d4:	e9 88 fe ff ff       	jmp    f0101161 <vprintfmt+0x31>
f01012d9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01012dc:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01012df:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01012e2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e5:	8d 50 04             	lea    0x4(%eax),%edx
f01012e8:	89 55 14             	mov    %edx,0x14(%ebp)
f01012eb:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01012ed:	85 f6                	test   %esi,%esi
f01012ef:	ba 8e 23 10 f0       	mov    $0xf010238e,%edx
f01012f4:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01012f7:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01012fb:	7e 06                	jle    f0101303 <vprintfmt+0x1d3>
f01012fd:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0101301:	75 13                	jne    f0101316 <vprintfmt+0x1e6>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101303:	0f be 06             	movsbl (%esi),%eax
f0101306:	83 c6 01             	add    $0x1,%esi
f0101309:	85 c0                	test   %eax,%eax
f010130b:	0f 85 94 00 00 00    	jne    f01013a5 <vprintfmt+0x275>
f0101311:	e9 81 00 00 00       	jmp    f0101397 <vprintfmt+0x267>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101316:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010131a:	89 34 24             	mov    %esi,(%esp)
f010131d:	e8 49 03 00 00       	call   f010166b <strnlen>
f0101322:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101325:	29 c1                	sub    %eax,%ecx
f0101327:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010132a:	85 c9                	test   %ecx,%ecx
f010132c:	7e d5                	jle    f0101303 <vprintfmt+0x1d3>
					putch(padc, putdat);
f010132e:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f0101332:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0101335:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101338:	89 ce                	mov    %ecx,%esi
f010133a:	89 c7                	mov    %eax,%edi
f010133c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101340:	89 3c 24             	mov    %edi,(%esp)
f0101343:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101346:	83 ee 01             	sub    $0x1,%esi
f0101349:	75 f1                	jne    f010133c <vprintfmt+0x20c>
f010134b:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010134e:	89 75 dc             	mov    %esi,-0x24(%ebp)
f0101351:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101354:	eb ad                	jmp    f0101303 <vprintfmt+0x1d3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101356:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010135a:	74 1b                	je     f0101377 <vprintfmt+0x247>
f010135c:	8d 50 e0             	lea    -0x20(%eax),%edx
f010135f:	83 fa 5e             	cmp    $0x5e,%edx
f0101362:	76 13                	jbe    f0101377 <vprintfmt+0x247>
					putch('?', putdat);
f0101364:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101367:	89 54 24 04          	mov    %edx,0x4(%esp)
f010136b:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101372:	ff 55 08             	call   *0x8(%ebp)
f0101375:	eb 0d                	jmp    f0101384 <vprintfmt+0x254>
				else
					putch(ch, putdat);
f0101377:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f010137a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010137e:	89 04 24             	mov    %eax,(%esp)
f0101381:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101384:	83 eb 01             	sub    $0x1,%ebx
f0101387:	0f be 06             	movsbl (%esi),%eax
f010138a:	83 c6 01             	add    $0x1,%esi
f010138d:	85 c0                	test   %eax,%eax
f010138f:	75 1a                	jne    f01013ab <vprintfmt+0x27b>
f0101391:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0101394:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101397:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010139a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010139e:	7f 1c                	jg     f01013bc <vprintfmt+0x28c>
f01013a0:	e9 bc fd ff ff       	jmp    f0101161 <vprintfmt+0x31>
f01013a5:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f01013a8:	8b 5d dc             	mov    -0x24(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01013ab:	85 ff                	test   %edi,%edi
f01013ad:	78 a7                	js     f0101356 <vprintfmt+0x226>
f01013af:	83 ef 01             	sub    $0x1,%edi
f01013b2:	79 a2                	jns    f0101356 <vprintfmt+0x226>
f01013b4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01013b7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01013ba:	eb db                	jmp    f0101397 <vprintfmt+0x267>
f01013bc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013bf:	89 de                	mov    %ebx,%esi
f01013c1:	8b 5d dc             	mov    -0x24(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01013c4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01013c8:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01013cf:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01013d1:	83 eb 01             	sub    $0x1,%ebx
f01013d4:	75 ee                	jne    f01013c4 <vprintfmt+0x294>
f01013d6:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013d8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01013db:	e9 81 fd ff ff       	jmp    f0101161 <vprintfmt+0x31>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01013e0:	89 ca                	mov    %ecx,%edx
f01013e2:	8d 45 14             	lea    0x14(%ebp),%eax
f01013e5:	e8 c7 fc ff ff       	call   f01010b1 <getint>
f01013ea:	89 c6                	mov    %eax,%esi
f01013ec:	89 d7                	mov    %edx,%edi
			if ((long long) num < 0) {
f01013ee:	85 d2                	test   %edx,%edx
f01013f0:	78 0a                	js     f01013fc <vprintfmt+0x2cc>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01013f2:	be 0a 00 00 00       	mov    $0xa,%esi
f01013f7:	e9 9b 00 00 00       	jmp    f0101497 <vprintfmt+0x367>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f01013fc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101400:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101407:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010140a:	89 f0                	mov    %esi,%eax
f010140c:	89 fa                	mov    %edi,%edx
f010140e:	f7 d8                	neg    %eax
f0101410:	83 d2 00             	adc    $0x0,%edx
f0101413:	f7 da                	neg    %edx
			}
			base = 10;
f0101415:	be 0a 00 00 00       	mov    $0xa,%esi
f010141a:	eb 7b                	jmp    f0101497 <vprintfmt+0x367>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010141c:	89 ca                	mov    %ecx,%edx
f010141e:	8d 45 14             	lea    0x14(%ebp),%eax
f0101421:	e8 51 fc ff ff       	call   f0101077 <getuint>
			base = 10;
f0101426:	be 0a 00 00 00       	mov    $0xa,%esi
			goto number;
f010142b:	eb 6a                	jmp    f0101497 <vprintfmt+0x367>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f010142d:	89 ca                	mov    %ecx,%edx
f010142f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101432:	e8 40 fc ff ff       	call   f0101077 <getuint>
			base = 8;
f0101437:	be 08 00 00 00       	mov    $0x8,%esi
                        goto number;
f010143c:	eb 59                	jmp    f0101497 <vprintfmt+0x367>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f010143e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101442:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101449:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010144c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101450:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0101457:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010145a:	8b 45 14             	mov    0x14(%ebp),%eax
f010145d:	8d 50 04             	lea    0x4(%eax),%edx
f0101460:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101463:	8b 00                	mov    (%eax),%eax
f0101465:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010146a:	be 10 00 00 00       	mov    $0x10,%esi
			goto number;
f010146f:	eb 26                	jmp    f0101497 <vprintfmt+0x367>
		case 'm':
			num = getint(&ap,lflag);
f0101471:	89 ca                	mov    %ecx,%edx
f0101473:	8d 45 14             	lea    0x14(%ebp),%eax
f0101476:	e8 36 fc ff ff       	call   f01010b1 <getint>
			mycolor = num;
f010147b:	a3 00 30 11 f0       	mov    %eax,0xf0113000
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101480:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			base = 16;
			goto number;
		case 'm':
			num = getint(&ap,lflag);
			mycolor = num;
			break;
f0101483:	e9 d9 fc ff ff       	jmp    f0101161 <vprintfmt+0x31>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101488:	89 ca                	mov    %ecx,%edx
f010148a:	8d 45 14             	lea    0x14(%ebp),%eax
f010148d:	e8 e5 fb ff ff       	call   f0101077 <getuint>
			base = 16;
f0101492:	be 10 00 00 00       	mov    $0x10,%esi
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101497:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f010149b:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010149f:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01014a2:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01014a6:	89 74 24 08          	mov    %esi,0x8(%esp)
f01014aa:	89 04 24             	mov    %eax,(%esp)
f01014ad:	89 54 24 04          	mov    %edx,0x4(%esp)
f01014b1:	89 da                	mov    %ebx,%edx
f01014b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b6:	e8 e1 fa ff ff       	call   f0100f9c <printnum>
			break;
f01014bb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01014be:	e9 9e fc ff ff       	jmp    f0101161 <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01014c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014c7:	89 14 24             	mov    %edx,(%esp)
f01014ca:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014cd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01014d0:	e9 8c fc ff ff       	jmp    f0101161 <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01014d5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014d9:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01014e0:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01014e3:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01014e7:	0f 84 74 fc ff ff    	je     f0101161 <vprintfmt+0x31>
f01014ed:	83 ee 01             	sub    $0x1,%esi
f01014f0:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01014f4:	75 f7                	jne    f01014ed <vprintfmt+0x3bd>
f01014f6:	e9 66 fc ff ff       	jmp    f0101161 <vprintfmt+0x31>

f01014fb <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01014fb:	55                   	push   %ebp
f01014fc:	89 e5                	mov    %esp,%ebp
f01014fe:	83 ec 28             	sub    $0x28,%esp
f0101501:	8b 45 08             	mov    0x8(%ebp),%eax
f0101504:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101507:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010150a:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010150e:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101511:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101518:	85 c0                	test   %eax,%eax
f010151a:	74 30                	je     f010154c <vsnprintf+0x51>
f010151c:	85 d2                	test   %edx,%edx
f010151e:	7e 2c                	jle    f010154c <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101520:	8b 45 14             	mov    0x14(%ebp),%eax
f0101523:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101527:	8b 45 10             	mov    0x10(%ebp),%eax
f010152a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010152e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101531:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101535:	c7 04 24 eb 10 10 f0 	movl   $0xf01010eb,(%esp)
f010153c:	e8 ef fb ff ff       	call   f0101130 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101541:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101544:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101547:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010154a:	eb 05                	jmp    f0101551 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f010154c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101551:	c9                   	leave  
f0101552:	c3                   	ret    

f0101553 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101553:	55                   	push   %ebp
f0101554:	89 e5                	mov    %esp,%ebp
f0101556:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101559:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010155c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101560:	8b 45 10             	mov    0x10(%ebp),%eax
f0101563:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101567:	8b 45 0c             	mov    0xc(%ebp),%eax
f010156a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010156e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101571:	89 04 24             	mov    %eax,(%esp)
f0101574:	e8 82 ff ff ff       	call   f01014fb <vsnprintf>
	va_end(ap);

	return rc;
}
f0101579:	c9                   	leave  
f010157a:	c3                   	ret    
f010157b:	00 00                	add    %al,(%eax)
f010157d:	00 00                	add    %al,(%eax)
	...

f0101580 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101580:	55                   	push   %ebp
f0101581:	89 e5                	mov    %esp,%ebp
f0101583:	57                   	push   %edi
f0101584:	56                   	push   %esi
f0101585:	53                   	push   %ebx
f0101586:	83 ec 1c             	sub    $0x1c,%esp
f0101589:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010158c:	85 c0                	test   %eax,%eax
f010158e:	74 10                	je     f01015a0 <readline+0x20>
		cprintf("%s", prompt);
f0101590:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101594:	c7 04 24 9e 23 10 f0 	movl   $0xf010239e,(%esp)
f010159b:	e8 b2 f6 ff ff       	call   f0100c52 <cprintf>

	i = 0;
	echoing = iscons(0);
f01015a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015a7:	e8 d6 f0 ff ff       	call   f0100682 <iscons>
f01015ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01015ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01015b3:	e8 b9 f0 ff ff       	call   f0100671 <getchar>
f01015b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01015ba:	85 c0                	test   %eax,%eax
f01015bc:	79 17                	jns    f01015d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01015be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015c2:	c7 04 24 80 25 10 f0 	movl   $0xf0102580,(%esp)
f01015c9:	e8 84 f6 ff ff       	call   f0100c52 <cprintf>
			return NULL;
f01015ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01015d3:	eb 6d                	jmp    f0101642 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015d5:	83 f8 08             	cmp    $0x8,%eax
f01015d8:	74 05                	je     f01015df <readline+0x5f>
f01015da:	83 f8 7f             	cmp    $0x7f,%eax
f01015dd:	75 19                	jne    f01015f8 <readline+0x78>
f01015df:	85 f6                	test   %esi,%esi
f01015e1:	7e 15                	jle    f01015f8 <readline+0x78>
			if (echoing)
f01015e3:	85 ff                	test   %edi,%edi
f01015e5:	74 0c                	je     f01015f3 <readline+0x73>
				cputchar('\b');
f01015e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01015ee:	e8 6e f0 ff ff       	call   f0100661 <cputchar>
			i--;
f01015f3:	83 ee 01             	sub    $0x1,%esi
f01015f6:	eb bb                	jmp    f01015b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01015f8:	83 fb 1f             	cmp    $0x1f,%ebx
f01015fb:	7e 1f                	jle    f010161c <readline+0x9c>
f01015fd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101603:	7f 17                	jg     f010161c <readline+0x9c>
			if (echoing)
f0101605:	85 ff                	test   %edi,%edi
f0101607:	74 08                	je     f0101611 <readline+0x91>
				cputchar(c);
f0101609:	89 1c 24             	mov    %ebx,(%esp)
f010160c:	e8 50 f0 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101611:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101617:	83 c6 01             	add    $0x1,%esi
f010161a:	eb 97                	jmp    f01015b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010161c:	83 fb 0a             	cmp    $0xa,%ebx
f010161f:	74 05                	je     f0101626 <readline+0xa6>
f0101621:	83 fb 0d             	cmp    $0xd,%ebx
f0101624:	75 8d                	jne    f01015b3 <readline+0x33>
			if (echoing)
f0101626:	85 ff                	test   %edi,%edi
f0101628:	74 0c                	je     f0101636 <readline+0xb6>
				cputchar('\n');
f010162a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101631:	e8 2b f0 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f0101636:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f010163d:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f0101642:	83 c4 1c             	add    $0x1c,%esp
f0101645:	5b                   	pop    %ebx
f0101646:	5e                   	pop    %esi
f0101647:	5f                   	pop    %edi
f0101648:	5d                   	pop    %ebp
f0101649:	c3                   	ret    
f010164a:	00 00                	add    %al,(%eax)
f010164c:	00 00                	add    %al,(%eax)
	...

f0101650 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101650:	55                   	push   %ebp
f0101651:	89 e5                	mov    %esp,%ebp
f0101653:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101656:	b8 00 00 00 00       	mov    $0x0,%eax
f010165b:	80 3a 00             	cmpb   $0x0,(%edx)
f010165e:	74 09                	je     f0101669 <strlen+0x19>
		n++;
f0101660:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101663:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101667:	75 f7                	jne    f0101660 <strlen+0x10>
		n++;
	return n;
}
f0101669:	5d                   	pop    %ebp
f010166a:	c3                   	ret    

f010166b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010166b:	55                   	push   %ebp
f010166c:	89 e5                	mov    %esp,%ebp
f010166e:	53                   	push   %ebx
f010166f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101672:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101675:	b8 00 00 00 00       	mov    $0x0,%eax
f010167a:	85 c9                	test   %ecx,%ecx
f010167c:	74 1a                	je     f0101698 <strnlen+0x2d>
f010167e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101681:	74 15                	je     f0101698 <strnlen+0x2d>
f0101683:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101688:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010168a:	39 ca                	cmp    %ecx,%edx
f010168c:	74 0a                	je     f0101698 <strnlen+0x2d>
f010168e:	83 c2 01             	add    $0x1,%edx
f0101691:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101696:	75 f0                	jne    f0101688 <strnlen+0x1d>
		n++;
	return n;
}
f0101698:	5b                   	pop    %ebx
f0101699:	5d                   	pop    %ebp
f010169a:	c3                   	ret    

f010169b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010169b:	55                   	push   %ebp
f010169c:	89 e5                	mov    %esp,%ebp
f010169e:	53                   	push   %ebx
f010169f:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01016a5:	ba 00 00 00 00       	mov    $0x0,%edx
f01016aa:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01016ae:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01016b1:	83 c2 01             	add    $0x1,%edx
f01016b4:	84 c9                	test   %cl,%cl
f01016b6:	75 f2                	jne    f01016aa <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01016b8:	5b                   	pop    %ebx
f01016b9:	5d                   	pop    %ebp
f01016ba:	c3                   	ret    

f01016bb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01016bb:	55                   	push   %ebp
f01016bc:	89 e5                	mov    %esp,%ebp
f01016be:	53                   	push   %ebx
f01016bf:	83 ec 08             	sub    $0x8,%esp
f01016c2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01016c5:	89 1c 24             	mov    %ebx,(%esp)
f01016c8:	e8 83 ff ff ff       	call   f0101650 <strlen>
	strcpy(dst + len, src);
f01016cd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016d0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01016d4:	01 d8                	add    %ebx,%eax
f01016d6:	89 04 24             	mov    %eax,(%esp)
f01016d9:	e8 bd ff ff ff       	call   f010169b <strcpy>
	return dst;
}
f01016de:	89 d8                	mov    %ebx,%eax
f01016e0:	83 c4 08             	add    $0x8,%esp
f01016e3:	5b                   	pop    %ebx
f01016e4:	5d                   	pop    %ebp
f01016e5:	c3                   	ret    

f01016e6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01016e6:	55                   	push   %ebp
f01016e7:	89 e5                	mov    %esp,%ebp
f01016e9:	56                   	push   %esi
f01016ea:	53                   	push   %ebx
f01016eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ee:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016f1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01016f4:	85 f6                	test   %esi,%esi
f01016f6:	74 18                	je     f0101710 <strncpy+0x2a>
f01016f8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01016fd:	0f b6 1a             	movzbl (%edx),%ebx
f0101700:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101703:	80 3a 01             	cmpb   $0x1,(%edx)
f0101706:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101709:	83 c1 01             	add    $0x1,%ecx
f010170c:	39 f1                	cmp    %esi,%ecx
f010170e:	75 ed                	jne    f01016fd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101710:	5b                   	pop    %ebx
f0101711:	5e                   	pop    %esi
f0101712:	5d                   	pop    %ebp
f0101713:	c3                   	ret    

f0101714 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101714:	55                   	push   %ebp
f0101715:	89 e5                	mov    %esp,%ebp
f0101717:	57                   	push   %edi
f0101718:	56                   	push   %esi
f0101719:	53                   	push   %ebx
f010171a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010171d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101720:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101723:	89 f8                	mov    %edi,%eax
f0101725:	85 f6                	test   %esi,%esi
f0101727:	74 2b                	je     f0101754 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101729:	83 fe 01             	cmp    $0x1,%esi
f010172c:	74 23                	je     f0101751 <strlcpy+0x3d>
f010172e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101731:	84 c9                	test   %cl,%cl
f0101733:	74 1c                	je     f0101751 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101735:	83 ee 02             	sub    $0x2,%esi
f0101738:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010173d:	88 08                	mov    %cl,(%eax)
f010173f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101742:	39 f2                	cmp    %esi,%edx
f0101744:	74 0b                	je     f0101751 <strlcpy+0x3d>
f0101746:	83 c2 01             	add    $0x1,%edx
f0101749:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010174d:	84 c9                	test   %cl,%cl
f010174f:	75 ec                	jne    f010173d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101751:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101754:	29 f8                	sub    %edi,%eax
}
f0101756:	5b                   	pop    %ebx
f0101757:	5e                   	pop    %esi
f0101758:	5f                   	pop    %edi
f0101759:	5d                   	pop    %ebp
f010175a:	c3                   	ret    

f010175b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010175b:	55                   	push   %ebp
f010175c:	89 e5                	mov    %esp,%ebp
f010175e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101761:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101764:	0f b6 01             	movzbl (%ecx),%eax
f0101767:	84 c0                	test   %al,%al
f0101769:	74 16                	je     f0101781 <strcmp+0x26>
f010176b:	3a 02                	cmp    (%edx),%al
f010176d:	75 12                	jne    f0101781 <strcmp+0x26>
		p++, q++;
f010176f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101772:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0101776:	84 c0                	test   %al,%al
f0101778:	74 07                	je     f0101781 <strcmp+0x26>
f010177a:	83 c1 01             	add    $0x1,%ecx
f010177d:	3a 02                	cmp    (%edx),%al
f010177f:	74 ee                	je     f010176f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101781:	0f b6 c0             	movzbl %al,%eax
f0101784:	0f b6 12             	movzbl (%edx),%edx
f0101787:	29 d0                	sub    %edx,%eax
}
f0101789:	5d                   	pop    %ebp
f010178a:	c3                   	ret    

f010178b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010178b:	55                   	push   %ebp
f010178c:	89 e5                	mov    %esp,%ebp
f010178e:	53                   	push   %ebx
f010178f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101792:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101795:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101798:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010179d:	85 d2                	test   %edx,%edx
f010179f:	74 28                	je     f01017c9 <strncmp+0x3e>
f01017a1:	0f b6 01             	movzbl (%ecx),%eax
f01017a4:	84 c0                	test   %al,%al
f01017a6:	74 24                	je     f01017cc <strncmp+0x41>
f01017a8:	3a 03                	cmp    (%ebx),%al
f01017aa:	75 20                	jne    f01017cc <strncmp+0x41>
f01017ac:	83 ea 01             	sub    $0x1,%edx
f01017af:	74 13                	je     f01017c4 <strncmp+0x39>
		n--, p++, q++;
f01017b1:	83 c1 01             	add    $0x1,%ecx
f01017b4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017b7:	0f b6 01             	movzbl (%ecx),%eax
f01017ba:	84 c0                	test   %al,%al
f01017bc:	74 0e                	je     f01017cc <strncmp+0x41>
f01017be:	3a 03                	cmp    (%ebx),%al
f01017c0:	74 ea                	je     f01017ac <strncmp+0x21>
f01017c2:	eb 08                	jmp    f01017cc <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01017c4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01017c9:	5b                   	pop    %ebx
f01017ca:	5d                   	pop    %ebp
f01017cb:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01017cc:	0f b6 01             	movzbl (%ecx),%eax
f01017cf:	0f b6 13             	movzbl (%ebx),%edx
f01017d2:	29 d0                	sub    %edx,%eax
f01017d4:	eb f3                	jmp    f01017c9 <strncmp+0x3e>

f01017d6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01017d6:	55                   	push   %ebp
f01017d7:	89 e5                	mov    %esp,%ebp
f01017d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01017e0:	0f b6 10             	movzbl (%eax),%edx
f01017e3:	84 d2                	test   %dl,%dl
f01017e5:	74 1c                	je     f0101803 <strchr+0x2d>
		if (*s == c)
f01017e7:	38 ca                	cmp    %cl,%dl
f01017e9:	75 09                	jne    f01017f4 <strchr+0x1e>
f01017eb:	eb 1b                	jmp    f0101808 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01017ed:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01017f0:	38 ca                	cmp    %cl,%dl
f01017f2:	74 14                	je     f0101808 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01017f4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01017f8:	84 d2                	test   %dl,%dl
f01017fa:	75 f1                	jne    f01017ed <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01017fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101801:	eb 05                	jmp    f0101808 <strchr+0x32>
f0101803:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101808:	5d                   	pop    %ebp
f0101809:	c3                   	ret    

f010180a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010180a:	55                   	push   %ebp
f010180b:	89 e5                	mov    %esp,%ebp
f010180d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101810:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101814:	0f b6 10             	movzbl (%eax),%edx
f0101817:	84 d2                	test   %dl,%dl
f0101819:	74 14                	je     f010182f <strfind+0x25>
		if (*s == c)
f010181b:	38 ca                	cmp    %cl,%dl
f010181d:	75 06                	jne    f0101825 <strfind+0x1b>
f010181f:	eb 0e                	jmp    f010182f <strfind+0x25>
f0101821:	38 ca                	cmp    %cl,%dl
f0101823:	74 0a                	je     f010182f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101825:	83 c0 01             	add    $0x1,%eax
f0101828:	0f b6 10             	movzbl (%eax),%edx
f010182b:	84 d2                	test   %dl,%dl
f010182d:	75 f2                	jne    f0101821 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010182f:	5d                   	pop    %ebp
f0101830:	c3                   	ret    

f0101831 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101831:	55                   	push   %ebp
f0101832:	89 e5                	mov    %esp,%ebp
f0101834:	83 ec 0c             	sub    $0xc,%esp
f0101837:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010183a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010183d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101840:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101843:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101846:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101849:	85 c9                	test   %ecx,%ecx
f010184b:	74 30                	je     f010187d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010184d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101853:	75 25                	jne    f010187a <memset+0x49>
f0101855:	f6 c1 03             	test   $0x3,%cl
f0101858:	75 20                	jne    f010187a <memset+0x49>
		c &= 0xFF;
f010185a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010185d:	89 d3                	mov    %edx,%ebx
f010185f:	c1 e3 08             	shl    $0x8,%ebx
f0101862:	89 d6                	mov    %edx,%esi
f0101864:	c1 e6 18             	shl    $0x18,%esi
f0101867:	89 d0                	mov    %edx,%eax
f0101869:	c1 e0 10             	shl    $0x10,%eax
f010186c:	09 f0                	or     %esi,%eax
f010186e:	09 d0                	or     %edx,%eax
f0101870:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101872:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101875:	fc                   	cld    
f0101876:	f3 ab                	rep stos %eax,%es:(%edi)
f0101878:	eb 03                	jmp    f010187d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010187a:	fc                   	cld    
f010187b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010187d:	89 f8                	mov    %edi,%eax
f010187f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101882:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101885:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101888:	89 ec                	mov    %ebp,%esp
f010188a:	5d                   	pop    %ebp
f010188b:	c3                   	ret    

f010188c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010188c:	55                   	push   %ebp
f010188d:	89 e5                	mov    %esp,%ebp
f010188f:	83 ec 08             	sub    $0x8,%esp
f0101892:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101895:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101898:	8b 45 08             	mov    0x8(%ebp),%eax
f010189b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010189e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01018a1:	39 c6                	cmp    %eax,%esi
f01018a3:	73 36                	jae    f01018db <memmove+0x4f>
f01018a5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01018a8:	39 d0                	cmp    %edx,%eax
f01018aa:	73 2f                	jae    f01018db <memmove+0x4f>
		s += n;
		d += n;
f01018ac:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018af:	f6 c2 03             	test   $0x3,%dl
f01018b2:	75 1b                	jne    f01018cf <memmove+0x43>
f01018b4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01018ba:	75 13                	jne    f01018cf <memmove+0x43>
f01018bc:	f6 c1 03             	test   $0x3,%cl
f01018bf:	75 0e                	jne    f01018cf <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01018c1:	83 ef 04             	sub    $0x4,%edi
f01018c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01018c7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01018ca:	fd                   	std    
f01018cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01018cd:	eb 09                	jmp    f01018d8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01018cf:	83 ef 01             	sub    $0x1,%edi
f01018d2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01018d5:	fd                   	std    
f01018d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01018d8:	fc                   	cld    
f01018d9:	eb 20                	jmp    f01018fb <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018db:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01018e1:	75 13                	jne    f01018f6 <memmove+0x6a>
f01018e3:	a8 03                	test   $0x3,%al
f01018e5:	75 0f                	jne    f01018f6 <memmove+0x6a>
f01018e7:	f6 c1 03             	test   $0x3,%cl
f01018ea:	75 0a                	jne    f01018f6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01018ec:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01018ef:	89 c7                	mov    %eax,%edi
f01018f1:	fc                   	cld    
f01018f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01018f4:	eb 05                	jmp    f01018fb <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01018f6:	89 c7                	mov    %eax,%edi
f01018f8:	fc                   	cld    
f01018f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01018fb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01018fe:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101901:	89 ec                	mov    %ebp,%esp
f0101903:	5d                   	pop    %ebp
f0101904:	c3                   	ret    

f0101905 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101905:	55                   	push   %ebp
f0101906:	89 e5                	mov    %esp,%ebp
f0101908:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010190b:	8b 45 10             	mov    0x10(%ebp),%eax
f010190e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101912:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101915:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101919:	8b 45 08             	mov    0x8(%ebp),%eax
f010191c:	89 04 24             	mov    %eax,(%esp)
f010191f:	e8 68 ff ff ff       	call   f010188c <memmove>
}
f0101924:	c9                   	leave  
f0101925:	c3                   	ret    

f0101926 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101926:	55                   	push   %ebp
f0101927:	89 e5                	mov    %esp,%ebp
f0101929:	57                   	push   %edi
f010192a:	56                   	push   %esi
f010192b:	53                   	push   %ebx
f010192c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010192f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101932:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101935:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010193a:	85 ff                	test   %edi,%edi
f010193c:	74 37                	je     f0101975 <memcmp+0x4f>
		if (*s1 != *s2)
f010193e:	0f b6 03             	movzbl (%ebx),%eax
f0101941:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101944:	83 ef 01             	sub    $0x1,%edi
f0101947:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010194c:	38 c8                	cmp    %cl,%al
f010194e:	74 1c                	je     f010196c <memcmp+0x46>
f0101950:	eb 10                	jmp    f0101962 <memcmp+0x3c>
f0101952:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101957:	83 c2 01             	add    $0x1,%edx
f010195a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010195e:	38 c8                	cmp    %cl,%al
f0101960:	74 0a                	je     f010196c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101962:	0f b6 c0             	movzbl %al,%eax
f0101965:	0f b6 c9             	movzbl %cl,%ecx
f0101968:	29 c8                	sub    %ecx,%eax
f010196a:	eb 09                	jmp    f0101975 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010196c:	39 fa                	cmp    %edi,%edx
f010196e:	75 e2                	jne    f0101952 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101970:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101975:	5b                   	pop    %ebx
f0101976:	5e                   	pop    %esi
f0101977:	5f                   	pop    %edi
f0101978:	5d                   	pop    %ebp
f0101979:	c3                   	ret    

f010197a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010197a:	55                   	push   %ebp
f010197b:	89 e5                	mov    %esp,%ebp
f010197d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101980:	89 c2                	mov    %eax,%edx
f0101982:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101985:	39 d0                	cmp    %edx,%eax
f0101987:	73 19                	jae    f01019a2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101989:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f010198d:	38 08                	cmp    %cl,(%eax)
f010198f:	75 06                	jne    f0101997 <memfind+0x1d>
f0101991:	eb 0f                	jmp    f01019a2 <memfind+0x28>
f0101993:	38 08                	cmp    %cl,(%eax)
f0101995:	74 0b                	je     f01019a2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101997:	83 c0 01             	add    $0x1,%eax
f010199a:	39 d0                	cmp    %edx,%eax
f010199c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019a0:	75 f1                	jne    f0101993 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01019a2:	5d                   	pop    %ebp
f01019a3:	c3                   	ret    

f01019a4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01019a4:	55                   	push   %ebp
f01019a5:	89 e5                	mov    %esp,%ebp
f01019a7:	57                   	push   %edi
f01019a8:	56                   	push   %esi
f01019a9:	53                   	push   %ebx
f01019aa:	8b 55 08             	mov    0x8(%ebp),%edx
f01019ad:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019b0:	0f b6 02             	movzbl (%edx),%eax
f01019b3:	3c 20                	cmp    $0x20,%al
f01019b5:	74 04                	je     f01019bb <strtol+0x17>
f01019b7:	3c 09                	cmp    $0x9,%al
f01019b9:	75 0e                	jne    f01019c9 <strtol+0x25>
		s++;
f01019bb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019be:	0f b6 02             	movzbl (%edx),%eax
f01019c1:	3c 20                	cmp    $0x20,%al
f01019c3:	74 f6                	je     f01019bb <strtol+0x17>
f01019c5:	3c 09                	cmp    $0x9,%al
f01019c7:	74 f2                	je     f01019bb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01019c9:	3c 2b                	cmp    $0x2b,%al
f01019cb:	75 0a                	jne    f01019d7 <strtol+0x33>
		s++;
f01019cd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01019d0:	bf 00 00 00 00       	mov    $0x0,%edi
f01019d5:	eb 10                	jmp    f01019e7 <strtol+0x43>
f01019d7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01019dc:	3c 2d                	cmp    $0x2d,%al
f01019de:	75 07                	jne    f01019e7 <strtol+0x43>
		s++, neg = 1;
f01019e0:	83 c2 01             	add    $0x1,%edx
f01019e3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01019e7:	85 db                	test   %ebx,%ebx
f01019e9:	0f 94 c0             	sete   %al
f01019ec:	74 05                	je     f01019f3 <strtol+0x4f>
f01019ee:	83 fb 10             	cmp    $0x10,%ebx
f01019f1:	75 15                	jne    f0101a08 <strtol+0x64>
f01019f3:	80 3a 30             	cmpb   $0x30,(%edx)
f01019f6:	75 10                	jne    f0101a08 <strtol+0x64>
f01019f8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01019fc:	75 0a                	jne    f0101a08 <strtol+0x64>
		s += 2, base = 16;
f01019fe:	83 c2 02             	add    $0x2,%edx
f0101a01:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101a06:	eb 13                	jmp    f0101a1b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101a08:	84 c0                	test   %al,%al
f0101a0a:	74 0f                	je     f0101a1b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101a0c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101a11:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a14:	75 05                	jne    f0101a1b <strtol+0x77>
		s++, base = 8;
f0101a16:	83 c2 01             	add    $0x1,%edx
f0101a19:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101a1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a20:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101a22:	0f b6 0a             	movzbl (%edx),%ecx
f0101a25:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101a28:	80 fb 09             	cmp    $0x9,%bl
f0101a2b:	77 08                	ja     f0101a35 <strtol+0x91>
			dig = *s - '0';
f0101a2d:	0f be c9             	movsbl %cl,%ecx
f0101a30:	83 e9 30             	sub    $0x30,%ecx
f0101a33:	eb 1e                	jmp    f0101a53 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101a35:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101a38:	80 fb 19             	cmp    $0x19,%bl
f0101a3b:	77 08                	ja     f0101a45 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101a3d:	0f be c9             	movsbl %cl,%ecx
f0101a40:	83 e9 57             	sub    $0x57,%ecx
f0101a43:	eb 0e                	jmp    f0101a53 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101a45:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101a48:	80 fb 19             	cmp    $0x19,%bl
f0101a4b:	77 14                	ja     f0101a61 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101a4d:	0f be c9             	movsbl %cl,%ecx
f0101a50:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101a53:	39 f1                	cmp    %esi,%ecx
f0101a55:	7d 0e                	jge    f0101a65 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101a57:	83 c2 01             	add    $0x1,%edx
f0101a5a:	0f af c6             	imul   %esi,%eax
f0101a5d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101a5f:	eb c1                	jmp    f0101a22 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101a61:	89 c1                	mov    %eax,%ecx
f0101a63:	eb 02                	jmp    f0101a67 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101a65:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101a67:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101a6b:	74 05                	je     f0101a72 <strtol+0xce>
		*endptr = (char *) s;
f0101a6d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a70:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101a72:	89 ca                	mov    %ecx,%edx
f0101a74:	f7 da                	neg    %edx
f0101a76:	85 ff                	test   %edi,%edi
f0101a78:	0f 45 c2             	cmovne %edx,%eax
}
f0101a7b:	5b                   	pop    %ebx
f0101a7c:	5e                   	pop    %esi
f0101a7d:	5f                   	pop    %edi
f0101a7e:	5d                   	pop    %ebp
f0101a7f:	c3                   	ret    

f0101a80 <__udivdi3>:
f0101a80:	83 ec 1c             	sub    $0x1c,%esp
f0101a83:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101a87:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101a8b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101a8f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101a93:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101a97:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101a9b:	85 ff                	test   %edi,%edi
f0101a9d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101aa1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101aa5:	89 cd                	mov    %ecx,%ebp
f0101aa7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101aab:	75 33                	jne    f0101ae0 <__udivdi3+0x60>
f0101aad:	39 f1                	cmp    %esi,%ecx
f0101aaf:	77 57                	ja     f0101b08 <__udivdi3+0x88>
f0101ab1:	85 c9                	test   %ecx,%ecx
f0101ab3:	75 0b                	jne    f0101ac0 <__udivdi3+0x40>
f0101ab5:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aba:	31 d2                	xor    %edx,%edx
f0101abc:	f7 f1                	div    %ecx
f0101abe:	89 c1                	mov    %eax,%ecx
f0101ac0:	89 f0                	mov    %esi,%eax
f0101ac2:	31 d2                	xor    %edx,%edx
f0101ac4:	f7 f1                	div    %ecx
f0101ac6:	89 c6                	mov    %eax,%esi
f0101ac8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101acc:	f7 f1                	div    %ecx
f0101ace:	89 f2                	mov    %esi,%edx
f0101ad0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ad4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101ad8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101adc:	83 c4 1c             	add    $0x1c,%esp
f0101adf:	c3                   	ret    
f0101ae0:	31 d2                	xor    %edx,%edx
f0101ae2:	31 c0                	xor    %eax,%eax
f0101ae4:	39 f7                	cmp    %esi,%edi
f0101ae6:	77 e8                	ja     f0101ad0 <__udivdi3+0x50>
f0101ae8:	0f bd cf             	bsr    %edi,%ecx
f0101aeb:	83 f1 1f             	xor    $0x1f,%ecx
f0101aee:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101af2:	75 2c                	jne    f0101b20 <__udivdi3+0xa0>
f0101af4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101af8:	76 04                	jbe    f0101afe <__udivdi3+0x7e>
f0101afa:	39 f7                	cmp    %esi,%edi
f0101afc:	73 d2                	jae    f0101ad0 <__udivdi3+0x50>
f0101afe:	31 d2                	xor    %edx,%edx
f0101b00:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b05:	eb c9                	jmp    f0101ad0 <__udivdi3+0x50>
f0101b07:	90                   	nop
f0101b08:	89 f2                	mov    %esi,%edx
f0101b0a:	f7 f1                	div    %ecx
f0101b0c:	31 d2                	xor    %edx,%edx
f0101b0e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b12:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b16:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b1a:	83 c4 1c             	add    $0x1c,%esp
f0101b1d:	c3                   	ret    
f0101b1e:	66 90                	xchg   %ax,%ax
f0101b20:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b25:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b2a:	89 ea                	mov    %ebp,%edx
f0101b2c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101b30:	d3 e7                	shl    %cl,%edi
f0101b32:	89 c1                	mov    %eax,%ecx
f0101b34:	d3 ea                	shr    %cl,%edx
f0101b36:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b3b:	09 fa                	or     %edi,%edx
f0101b3d:	89 f7                	mov    %esi,%edi
f0101b3f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b43:	89 f2                	mov    %esi,%edx
f0101b45:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b49:	d3 e5                	shl    %cl,%ebp
f0101b4b:	89 c1                	mov    %eax,%ecx
f0101b4d:	d3 ef                	shr    %cl,%edi
f0101b4f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b54:	d3 e2                	shl    %cl,%edx
f0101b56:	89 c1                	mov    %eax,%ecx
f0101b58:	d3 ee                	shr    %cl,%esi
f0101b5a:	09 d6                	or     %edx,%esi
f0101b5c:	89 fa                	mov    %edi,%edx
f0101b5e:	89 f0                	mov    %esi,%eax
f0101b60:	f7 74 24 0c          	divl   0xc(%esp)
f0101b64:	89 d7                	mov    %edx,%edi
f0101b66:	89 c6                	mov    %eax,%esi
f0101b68:	f7 e5                	mul    %ebp
f0101b6a:	39 d7                	cmp    %edx,%edi
f0101b6c:	72 22                	jb     f0101b90 <__udivdi3+0x110>
f0101b6e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101b72:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b77:	d3 e5                	shl    %cl,%ebp
f0101b79:	39 c5                	cmp    %eax,%ebp
f0101b7b:	73 04                	jae    f0101b81 <__udivdi3+0x101>
f0101b7d:	39 d7                	cmp    %edx,%edi
f0101b7f:	74 0f                	je     f0101b90 <__udivdi3+0x110>
f0101b81:	89 f0                	mov    %esi,%eax
f0101b83:	31 d2                	xor    %edx,%edx
f0101b85:	e9 46 ff ff ff       	jmp    f0101ad0 <__udivdi3+0x50>
f0101b8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101b90:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101b93:	31 d2                	xor    %edx,%edx
f0101b95:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b99:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b9d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ba1:	83 c4 1c             	add    $0x1c,%esp
f0101ba4:	c3                   	ret    
	...

f0101bb0 <__umoddi3>:
f0101bb0:	83 ec 1c             	sub    $0x1c,%esp
f0101bb3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101bb7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101bbb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101bbf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101bc3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101bc7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101bcb:	85 ed                	test   %ebp,%ebp
f0101bcd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bd5:	89 cf                	mov    %ecx,%edi
f0101bd7:	89 04 24             	mov    %eax,(%esp)
f0101bda:	89 f2                	mov    %esi,%edx
f0101bdc:	75 1a                	jne    f0101bf8 <__umoddi3+0x48>
f0101bde:	39 f1                	cmp    %esi,%ecx
f0101be0:	76 4e                	jbe    f0101c30 <__umoddi3+0x80>
f0101be2:	f7 f1                	div    %ecx
f0101be4:	89 d0                	mov    %edx,%eax
f0101be6:	31 d2                	xor    %edx,%edx
f0101be8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101bec:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101bf0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101bf4:	83 c4 1c             	add    $0x1c,%esp
f0101bf7:	c3                   	ret    
f0101bf8:	39 f5                	cmp    %esi,%ebp
f0101bfa:	77 54                	ja     f0101c50 <__umoddi3+0xa0>
f0101bfc:	0f bd c5             	bsr    %ebp,%eax
f0101bff:	83 f0 1f             	xor    $0x1f,%eax
f0101c02:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c06:	75 60                	jne    f0101c68 <__umoddi3+0xb8>
f0101c08:	3b 0c 24             	cmp    (%esp),%ecx
f0101c0b:	0f 87 07 01 00 00    	ja     f0101d18 <__umoddi3+0x168>
f0101c11:	89 f2                	mov    %esi,%edx
f0101c13:	8b 34 24             	mov    (%esp),%esi
f0101c16:	29 ce                	sub    %ecx,%esi
f0101c18:	19 ea                	sbb    %ebp,%edx
f0101c1a:	89 34 24             	mov    %esi,(%esp)
f0101c1d:	8b 04 24             	mov    (%esp),%eax
f0101c20:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c24:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c28:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c2c:	83 c4 1c             	add    $0x1c,%esp
f0101c2f:	c3                   	ret    
f0101c30:	85 c9                	test   %ecx,%ecx
f0101c32:	75 0b                	jne    f0101c3f <__umoddi3+0x8f>
f0101c34:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c39:	31 d2                	xor    %edx,%edx
f0101c3b:	f7 f1                	div    %ecx
f0101c3d:	89 c1                	mov    %eax,%ecx
f0101c3f:	89 f0                	mov    %esi,%eax
f0101c41:	31 d2                	xor    %edx,%edx
f0101c43:	f7 f1                	div    %ecx
f0101c45:	8b 04 24             	mov    (%esp),%eax
f0101c48:	f7 f1                	div    %ecx
f0101c4a:	eb 98                	jmp    f0101be4 <__umoddi3+0x34>
f0101c4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c50:	89 f2                	mov    %esi,%edx
f0101c52:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c56:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c5a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c5e:	83 c4 1c             	add    $0x1c,%esp
f0101c61:	c3                   	ret    
f0101c62:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101c68:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c6d:	89 e8                	mov    %ebp,%eax
f0101c6f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101c74:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101c78:	89 fa                	mov    %edi,%edx
f0101c7a:	d3 e0                	shl    %cl,%eax
f0101c7c:	89 e9                	mov    %ebp,%ecx
f0101c7e:	d3 ea                	shr    %cl,%edx
f0101c80:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c85:	09 c2                	or     %eax,%edx
f0101c87:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101c8b:	89 14 24             	mov    %edx,(%esp)
f0101c8e:	89 f2                	mov    %esi,%edx
f0101c90:	d3 e7                	shl    %cl,%edi
f0101c92:	89 e9                	mov    %ebp,%ecx
f0101c94:	d3 ea                	shr    %cl,%edx
f0101c96:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c9b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101c9f:	d3 e6                	shl    %cl,%esi
f0101ca1:	89 e9                	mov    %ebp,%ecx
f0101ca3:	d3 e8                	shr    %cl,%eax
f0101ca5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101caa:	09 f0                	or     %esi,%eax
f0101cac:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101cb0:	f7 34 24             	divl   (%esp)
f0101cb3:	d3 e6                	shl    %cl,%esi
f0101cb5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101cb9:	89 d6                	mov    %edx,%esi
f0101cbb:	f7 e7                	mul    %edi
f0101cbd:	39 d6                	cmp    %edx,%esi
f0101cbf:	89 c1                	mov    %eax,%ecx
f0101cc1:	89 d7                	mov    %edx,%edi
f0101cc3:	72 3f                	jb     f0101d04 <__umoddi3+0x154>
f0101cc5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101cc9:	72 35                	jb     f0101d00 <__umoddi3+0x150>
f0101ccb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101ccf:	29 c8                	sub    %ecx,%eax
f0101cd1:	19 fe                	sbb    %edi,%esi
f0101cd3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cd8:	89 f2                	mov    %esi,%edx
f0101cda:	d3 e8                	shr    %cl,%eax
f0101cdc:	89 e9                	mov    %ebp,%ecx
f0101cde:	d3 e2                	shl    %cl,%edx
f0101ce0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ce5:	09 d0                	or     %edx,%eax
f0101ce7:	89 f2                	mov    %esi,%edx
f0101ce9:	d3 ea                	shr    %cl,%edx
f0101ceb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cef:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101cf3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101cf7:	83 c4 1c             	add    $0x1c,%esp
f0101cfa:	c3                   	ret    
f0101cfb:	90                   	nop
f0101cfc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d00:	39 d6                	cmp    %edx,%esi
f0101d02:	75 c7                	jne    f0101ccb <__umoddi3+0x11b>
f0101d04:	89 d7                	mov    %edx,%edi
f0101d06:	89 c1                	mov    %eax,%ecx
f0101d08:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101d0c:	1b 3c 24             	sbb    (%esp),%edi
f0101d0f:	eb ba                	jmp    f0101ccb <__umoddi3+0x11b>
f0101d11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101d18:	39 f5                	cmp    %esi,%ebp
f0101d1a:	0f 82 f1 fe ff ff    	jb     f0101c11 <__umoddi3+0x61>
f0101d20:	e9 f8 fe ff ff       	jmp    f0101c1d <__umoddi3+0x6d>
