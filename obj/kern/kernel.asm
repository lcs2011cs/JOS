
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
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

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
f010004e:	c7 04 24 a0 1b 10 f0 	movl   $0xf0101ba0,(%esp)
f0100055:	e8 60 0a 00 00       	call   f0100aba <cprintf>
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
f010008b:	c7 04 24 bc 1b 10 f0 	movl   $0xf0101bbc,(%esp)
f0100092:	e8 23 0a 00 00       	call   f0100aba <cprintf>
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
f01000a3:	b8 64 29 11 f0       	mov    $0xf0112964,%eax
f01000a8:	2d 20 23 11 f0       	sub    $0xf0112320,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 20 23 11 f0 	movl   $0xf0112320,(%esp)
f01000c0:	e8 dc 15 00 00       	call   f01016a1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 a2 04 00 00       	call   f010056c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 d7 1b 10 f0 	movl   $0xf0101bd7,(%esp)
f01000d9:	e8 dc 09 00 00       	call   f0100aba <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 00 08 00 00       	call   f01008f6 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 60 29 11 f0 00 	cmpl   $0x0,0xf0112960
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 60 29 11 f0    	mov    %esi,0xf0112960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 f2 1b 10 f0 	movl   $0xf0101bf2,(%esp)
f010012c:	e8 89 09 00 00       	call   f0100aba <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 4a 09 00 00       	call   f0100a87 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 2e 1c 10 f0 	movl   $0xf0101c2e,(%esp)
f0100144:	e8 71 09 00 00       	call   f0100aba <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 a1 07 00 00       	call   f01008f6 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 0a 1c 10 f0 	movl   $0xf0101c0a,(%esp)
f0100176:	e8 3f 09 00 00       	call   f0100aba <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 fd 08 00 00       	call   f0100a87 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 2e 1c 10 f0 	movl   $0xf0101c2e,(%esp)
f0100191:	e8 24 09 00 00       	call   f0100aba <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
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
f01001d9:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01001df:	88 82 40 23 11 f0    	mov    %al,-0xfeedcc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 25 11 f0       	mov    %eax,0xf0112544
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
f010027e:	83 3d 00 20 11 f0 00 	cmpl   $0x0,0xf0112000
f0100285:	75 0a                	jne    f0100291 <cons_putc+0x8a>
f0100287:	c7 05 00 20 11 f0 00 	movl   $0x700,0xf0112000
f010028e:	07 00 00 
  	if (!(c & ~0xFF))
f0100291:	89 fa                	mov    %edi,%edx
f0100293:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
   		 c |= mycolor;
f0100299:	89 f8                	mov    %edi,%eax
f010029b:	0b 05 00 20 11 f0    	or     0xf0112000,%eax
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
f01002d2:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002d9:	66 85 c0             	test   %ax,%ax
f01002dc:	0f 84 e4 00 00 00    	je     f01003c6 <cons_putc+0x1bf>
			crt_pos--;
f01002e2:	83 e8 01             	sub    $0x1,%eax
f01002e5:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002eb:	0f b7 c0             	movzwl %ax,%eax
f01002ee:	66 81 e7 00 ff       	and    $0xff00,%di
f01002f3:	83 cf 20             	or     $0x20,%edi
f01002f6:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f01002fc:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100300:	eb 77                	jmp    f0100379 <cons_putc+0x172>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100302:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f0100309:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010030a:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100311:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100317:	c1 e8 16             	shr    $0x16,%eax
f010031a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010031d:	c1 e0 04             	shl    $0x4,%eax
f0100320:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
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
f010035c:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100363:	0f b7 c8             	movzwl %ax,%ecx
f0100366:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f010036c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100370:	83 c0 01             	add    $0x1,%eax
f0100373:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100379:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f0100380:	cf 07 
f0100382:	76 42                	jbe    f01003c6 <cons_putc+0x1bf>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100384:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f0100389:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100390:	00 
f0100391:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100397:	89 54 24 04          	mov    %edx,0x4(%esp)
f010039b:	89 04 24             	mov    %eax,(%esp)
f010039e:	e8 59 13 00 00       	call   f01016fc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01003a3:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
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
f01003be:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f01003c5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003c6:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003cc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003d1:	89 ca                	mov    %ecx,%edx
f01003d3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003d4:	0f b7 35 54 25 11 f0 	movzwl 0xf0112554,%esi
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
f010041f:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f0100426:	bb 00 00 00 00       	mov    $0x0,%ebx
f010042b:	e9 c4 00 00 00       	jmp    f01004f4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100430:	84 c0                	test   %al,%al
f0100432:	79 37                	jns    f010046b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100434:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f010043a:	89 cb                	mov    %ecx,%ebx
f010043c:	83 e3 40             	and    $0x40,%ebx
f010043f:	83 e0 7f             	and    $0x7f,%eax
f0100442:	85 db                	test   %ebx,%ebx
f0100444:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100447:	0f b6 d2             	movzbl %dl,%edx
f010044a:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f0100451:	83 c8 40             	or     $0x40,%eax
f0100454:	0f b6 c0             	movzbl %al,%eax
f0100457:	f7 d0                	not    %eax
f0100459:	21 c1                	and    %eax,%ecx
f010045b:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f0100461:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100466:	e9 89 00 00 00       	jmp    f01004f4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010046b:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100471:	f6 c1 40             	test   $0x40,%cl
f0100474:	74 0e                	je     f0100484 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100476:	89 c2                	mov    %eax,%edx
f0100478:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010047b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010047e:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f0100484:	0f b6 d2             	movzbl %dl,%edx
f0100487:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f010048e:	0b 05 48 25 11 f0    	or     0xf0112548,%eax
	shift ^= togglecode[data];
f0100494:	0f b6 8a 60 1d 10 f0 	movzbl -0xfefe2a0(%edx),%ecx
f010049b:	31 c8                	xor    %ecx,%eax
f010049d:	a3 48 25 11 f0       	mov    %eax,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f01004a2:	89 c1                	mov    %eax,%ecx
f01004a4:	83 e1 03             	and    $0x3,%ecx
f01004a7:	8b 0c 8d 60 1e 10 f0 	mov    -0xfefe1a0(,%ecx,4),%ecx
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
f01004dd:	c7 04 24 24 1c 10 f0 	movl   $0xf0101c24,(%esp)
f01004e4:	e8 d1 05 00 00       	call   f0100aba <cprintf>
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
f0100502:	80 3d 20 23 11 f0 00 	cmpb   $0x0,0xf0112320
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
f0100539:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
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
f0100544:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f010054a:	74 1e                	je     f010056a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010054c:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100553:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100556:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010055c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100561:	0f 44 d1             	cmove  %ecx,%edx
f0100564:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
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
f0100592:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
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
f01005aa:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
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
f01005b9:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
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
f01005de:	89 35 50 25 11 f0    	mov    %esi,0xf0112550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e4:	0f b6 d8             	movzbl %al,%ebx
f01005e7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e9:	66 89 3d 54 25 11 f0 	mov    %di,0xf0112554
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
f010063c:	a2 20 23 11 f0       	mov    %al,0xf0112320
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
f010064d:	c7 04 24 30 1c 10 f0 	movl   $0xf0101c30,(%esp)
f0100654:	e8 61 04 00 00       	call   f0100aba <cprintf>
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
f0100696:	c7 04 24 70 1e 10 f0 	movl   $0xf0101e70,(%esp)
f010069d:	e8 18 04 00 00       	call   f0100aba <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 6c 1f 10 f0 	movl   $0xf0101f6c,(%esp)
f01006b1:	e8 04 04 00 00       	call   f0100aba <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 94 1f 10 f0 	movl   $0xf0101f94,(%esp)
f01006cd:	e8 e8 03 00 00       	call   f0100aba <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 95 1b 10 	movl   $0x101b95,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 95 1b 10 	movl   $0xf0101b95,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 b8 1f 10 f0 	movl   $0xf0101fb8,(%esp)
f01006e9:	e8 cc 03 00 00       	call   f0100aba <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 20 23 11 	movl   $0x112320,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 20 23 11 	movl   $0xf0112320,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 dc 1f 10 f0 	movl   $0xf0101fdc,(%esp)
f0100705:	e8 b0 03 00 00       	call   f0100aba <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 64 29 11 	movl   $0x112964,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 64 29 11 	movl   $0xf0112964,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 00 20 10 f0 	movl   $0xf0102000,(%esp)
f0100721:	e8 94 03 00 00       	call   f0100aba <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 63 2d 11 f0       	mov    $0xf0112d63,%eax
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
f0100747:	c7 04 24 24 20 10 f0 	movl   $0xf0102024,(%esp)
f010074e:	e8 67 03 00 00       	call   f0100aba <cprintf>
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
f0100766:	8b 83 24 21 10 f0    	mov    -0xfefdedc(%ebx),%eax
f010076c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100770:	8b 83 20 21 10 f0    	mov    -0xfefdee0(%ebx),%eax
f0100776:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077a:	c7 04 24 89 1e 10 f0 	movl   $0xf0101e89,(%esp)
f0100781:	e8 34 03 00 00       	call   f0100aba <cprintf>
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
f01007a6:	c7 04 24 92 1e 10 f0 	movl   $0xf0101e92,(%esp)
f01007ad:	e8 08 03 00 00       	call   f0100aba <cprintf>
  	while (ebp) {
f01007b2:	85 db                	test   %ebx,%ebx
f01007b4:	0f 84 8b 00 00 00    	je     f0100845 <mybacktrace+0xac>
    		uint32_t eip = ebp[1];
f01007ba:	8b 7e 04             	mov    0x4(%esi),%edi
    		cprintf("ebp %x  eip %x  args", ebp, eip);
f01007bd:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007c1:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007c5:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f01007cc:	e8 e9 02 00 00       	call   f0100aba <cprintf>
    		int i;
    		for (i = 2; i <= 6; ++i)
f01007d1:	bb 02 00 00 00       	mov    $0x2,%ebx
     			cprintf(" %08.x", ebp[i]);
f01007d6:	8b 04 9e             	mov    (%esi,%ebx,4),%eax
f01007d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007dd:	c7 04 24 b9 1e 10 f0 	movl   $0xf0101eb9,(%esp)
f01007e4:	e8 d1 02 00 00       	call   f0100aba <cprintf>
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
f01007f1:	c7 04 24 2e 1c 10 f0 	movl   $0xf0101c2e,(%esp)
f01007f8:	e8 bd 02 00 00       	call   f0100aba <cprintf>
   		struct Eipdebuginfo info;
    		debuginfo_eip(eip, &info);
f01007fd:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100800:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100804:	89 3c 24             	mov    %edi,(%esp)
f0100807:	e8 a8 03 00 00       	call   f0100bb4 <debuginfo_eip>

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
f010082f:	c7 04 24 c0 1e 10 f0 	movl   $0xf0101ec0,(%esp)
f0100836:	e8 7f 02 00 00       	call   f0100aba <cprintf>
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
f010085e:	c7 04 24 92 1e 10 f0 	movl   $0xf0101e92,(%esp)
f0100865:	e8 50 02 00 00       	call   f0100aba <cprintf>
  	while (ebp) {
f010086a:	85 db                	test   %ebx,%ebx
f010086c:	74 7c                	je     f01008ea <mon_backtrace+0x98>
   		cprintf("ebp %x  eip %x  args", ebp, *(ebp+1));
f010086e:	8b 46 04             	mov    0x4(%esi),%eax
f0100871:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100875:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100879:	c7 04 24 a4 1e 10 f0 	movl   $0xf0101ea4,(%esp)
f0100880:	e8 35 02 00 00       	call   f0100aba <cprintf>
    		cprintf(" %x", *(ebp+2));
f0100885:	8b 46 08             	mov    0x8(%esi),%eax
f0100888:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088c:	c7 04 24 d1 1e 10 f0 	movl   $0xf0101ed1,(%esp)
f0100893:	e8 22 02 00 00       	call   f0100aba <cprintf>
    		cprintf(" %x", *(ebp+3));
f0100898:	8b 46 0c             	mov    0xc(%esi),%eax
f010089b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010089f:	c7 04 24 d1 1e 10 f0 	movl   $0xf0101ed1,(%esp)
f01008a6:	e8 0f 02 00 00       	call   f0100aba <cprintf>
    		cprintf(" %x", *(ebp+4));
f01008ab:	8b 46 10             	mov    0x10(%esi),%eax
f01008ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b2:	c7 04 24 d1 1e 10 f0 	movl   $0xf0101ed1,(%esp)
f01008b9:	e8 fc 01 00 00       	call   f0100aba <cprintf>
    		cprintf(" %x", *(ebp+5));
f01008be:	8b 46 14             	mov    0x14(%esi),%eax
f01008c1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c5:	c7 04 24 d1 1e 10 f0 	movl   $0xf0101ed1,(%esp)
f01008cc:	e8 e9 01 00 00       	call   f0100aba <cprintf>
    		cprintf(" %x\n", *(ebp+6));
f01008d1:	8b 46 18             	mov    0x18(%esi),%eax
f01008d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d8:	c7 04 24 d5 1e 10 f0 	movl   $0xf0101ed5,(%esp)
f01008df:	e8 d6 01 00 00       	call   f0100aba <cprintf>
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
f01008ff:	c7 04 24 50 20 10 f0 	movl   $0xf0102050,(%esp)
f0100906:	e8 af 01 00 00       	call   f0100aba <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010090b:	c7 04 24 74 20 10 f0 	movl   $0xf0102074,(%esp)
f0100912:	e8 a3 01 00 00       	call   f0100aba <cprintf>
	cprintf("Type 'backtrace to see something interesting.\n");
f0100917:	c7 04 24 9c 20 10 f0 	movl   $0xf010209c,(%esp)
f010091e:	e8 97 01 00 00       	call   f0100aba <cprintf>
	cprintf("%m%s\n%m%s\n%m%s\n", 0x0100, "blue", 0x0200, "green", 0x0400, "red");
f0100923:	c7 44 24 18 da 1e 10 	movl   $0xf0101eda,0x18(%esp)
f010092a:	f0 
f010092b:	c7 44 24 14 00 04 00 	movl   $0x400,0x14(%esp)
f0100932:	00 
f0100933:	c7 44 24 10 de 1e 10 	movl   $0xf0101ede,0x10(%esp)
f010093a:	f0 
f010093b:	c7 44 24 0c 00 02 00 	movl   $0x200,0xc(%esp)
f0100942:	00 
f0100943:	c7 44 24 08 e4 1e 10 	movl   $0xf0101ee4,0x8(%esp)
f010094a:	f0 
f010094b:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
f0100952:	00 
f0100953:	c7 04 24 e9 1e 10 f0 	movl   $0xf0101ee9,(%esp)
f010095a:	e8 5b 01 00 00       	call   f0100aba <cprintf>

	while (1) {
		buf = readline("K> ");
f010095f:	c7 04 24 f9 1e 10 f0 	movl   $0xf0101ef9,(%esp)
f0100966:	e8 85 0a 00 00       	call   f01013f0 <readline>
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
f0100993:	c7 04 24 fd 1e 10 f0 	movl   $0xf0101efd,(%esp)
f010099a:	e8 a7 0c 00 00       	call   f0101646 <strchr>
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
f01009b5:	c7 04 24 02 1f 10 f0 	movl   $0xf0101f02,(%esp)
f01009bc:	e8 f9 00 00 00       	call   f0100aba <cprintf>
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
f01009e4:	c7 04 24 fd 1e 10 f0 	movl   $0xf0101efd,(%esp)
f01009eb:	e8 56 0c 00 00       	call   f0101646 <strchr>
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
f0100a06:	bb 20 21 10 f0       	mov    $0xf0102120,%ebx
f0100a0b:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a10:	8b 03                	mov    (%ebx),%eax
f0100a12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a16:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a19:	89 04 24             	mov    %eax,(%esp)
f0100a1c:	e8 aa 0b 00 00       	call   f01015cb <strcmp>
f0100a21:	85 c0                	test   %eax,%eax
f0100a23:	75 24                	jne    f0100a49 <monitor+0x153>
			return commands[i].func(argc, argv, tf);
f0100a25:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100a28:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a2b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a2f:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a32:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a36:	89 34 24             	mov    %esi,(%esp)
f0100a39:	ff 14 85 28 21 10 f0 	call   *-0xfefded8(,%eax,4)
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
f0100a5b:	c7 04 24 1f 1f 10 f0 	movl   $0xf0101f1f,(%esp)
f0100a62:	e8 53 00 00 00       	call   f0100aba <cprintf>
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

f0100a74 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a74:	55                   	push   %ebp
f0100a75:	89 e5                	mov    %esp,%ebp
f0100a77:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100a7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a7d:	89 04 24             	mov    %eax,(%esp)
f0100a80:	e8 dc fb ff ff       	call   f0100661 <cputchar>
	*cnt++;
}
f0100a85:	c9                   	leave  
f0100a86:	c3                   	ret    

f0100a87 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a87:	55                   	push   %ebp
f0100a88:	89 e5                	mov    %esp,%ebp
f0100a8a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100a8d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a94:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100a97:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100a9e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100aa2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100aa5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aa9:	c7 04 24 74 0a 10 f0 	movl   $0xf0100a74,(%esp)
f0100ab0:	e8 e3 04 00 00       	call   f0100f98 <vprintfmt>
	return cnt;
}
f0100ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ab8:	c9                   	leave  
f0100ab9:	c3                   	ret    

f0100aba <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100aba:	55                   	push   %ebp
f0100abb:	89 e5                	mov    %esp,%ebp
f0100abd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ac0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100ac3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ac7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100aca:	89 04 24             	mov    %eax,(%esp)
f0100acd:	e8 b5 ff ff ff       	call   f0100a87 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100ad2:	c9                   	leave  
f0100ad3:	c3                   	ret    

f0100ad4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100ad4:	55                   	push   %ebp
f0100ad5:	89 e5                	mov    %esp,%ebp
f0100ad7:	57                   	push   %edi
f0100ad8:	56                   	push   %esi
f0100ad9:	53                   	push   %ebx
f0100ada:	83 ec 10             	sub    $0x10,%esp
f0100add:	89 c3                	mov    %eax,%ebx
f0100adf:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100ae2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100ae5:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100ae8:	8b 0a                	mov    (%edx),%ecx
f0100aea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100aed:	8b 00                	mov    (%eax),%eax
f0100aef:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100af2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100af9:	eb 77                	jmp    f0100b72 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100afb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100afe:	01 c8                	add    %ecx,%eax
f0100b00:	bf 02 00 00 00       	mov    $0x2,%edi
f0100b05:	99                   	cltd   
f0100b06:	f7 ff                	idiv   %edi
f0100b08:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b0a:	eb 01                	jmp    f0100b0d <stab_binsearch+0x39>
			m--;
f0100b0c:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b0d:	39 ca                	cmp    %ecx,%edx
f0100b0f:	7c 1d                	jl     f0100b2e <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b11:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100b14:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100b19:	39 f7                	cmp    %esi,%edi
f0100b1b:	75 ef                	jne    f0100b0c <stab_binsearch+0x38>
f0100b1d:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b20:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100b23:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100b27:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b2a:	73 18                	jae    f0100b44 <stab_binsearch+0x70>
f0100b2c:	eb 05                	jmp    f0100b33 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100b2e:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100b31:	eb 3f                	jmp    f0100b72 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100b33:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b36:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100b38:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b3b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b42:	eb 2e                	jmp    f0100b72 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100b44:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100b47:	76 15                	jbe    f0100b5e <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100b49:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b4c:	4f                   	dec    %edi
f0100b4d:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100b50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b53:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b55:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100b5c:	eb 14                	jmp    f0100b72 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b5e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100b61:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100b64:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100b66:	ff 45 0c             	incl   0xc(%ebp)
f0100b69:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100b6b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b72:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100b75:	7e 84                	jle    f0100afb <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b77:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100b7b:	75 0d                	jne    f0100b8a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100b7d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b80:	8b 02                	mov    (%edx),%eax
f0100b82:	48                   	dec    %eax
f0100b83:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b86:	89 01                	mov    %eax,(%ecx)
f0100b88:	eb 22                	jmp    f0100bac <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b8a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100b8d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b8f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100b92:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b94:	eb 01                	jmp    f0100b97 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b96:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b97:	39 c1                	cmp    %eax,%ecx
f0100b99:	7d 0c                	jge    f0100ba7 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100b9b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100b9e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100ba3:	39 f2                	cmp    %esi,%edx
f0100ba5:	75 ef                	jne    f0100b96 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ba7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100baa:	89 02                	mov    %eax,(%edx)
	}
}
f0100bac:	83 c4 10             	add    $0x10,%esp
f0100baf:	5b                   	pop    %ebx
f0100bb0:	5e                   	pop    %esi
f0100bb1:	5f                   	pop    %edi
f0100bb2:	5d                   	pop    %ebp
f0100bb3:	c3                   	ret    

f0100bb4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100bb4:	55                   	push   %ebp
f0100bb5:	89 e5                	mov    %esp,%ebp
f0100bb7:	83 ec 58             	sub    $0x58,%esp
f0100bba:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100bbd:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100bc0:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100bc3:	8b 75 08             	mov    0x8(%ebp),%esi
f0100bc6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100bc9:	c7 03 44 21 10 f0    	movl   $0xf0102144,(%ebx)
	info->eip_line = 0;
f0100bcf:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100bd6:	c7 43 08 44 21 10 f0 	movl   $0xf0102144,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100bdd:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100be4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100be7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bee:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100bf4:	76 12                	jbe    f0100c08 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bf6:	b8 5c 7b 10 f0       	mov    $0xf0107b5c,%eax
f0100bfb:	3d c9 61 10 f0       	cmp    $0xf01061c9,%eax
f0100c00:	0f 86 e2 01 00 00    	jbe    f0100de8 <debuginfo_eip+0x234>
f0100c06:	eb 1c                	jmp    f0100c24 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100c08:	c7 44 24 08 4e 21 10 	movl   $0xf010214e,0x8(%esp)
f0100c0f:	f0 
f0100c10:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100c17:	00 
f0100c18:	c7 04 24 5b 21 10 f0 	movl   $0xf010215b,(%esp)
f0100c1f:	e8 d4 f4 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100c24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c29:	80 3d 5b 7b 10 f0 00 	cmpb   $0x0,0xf0107b5b
f0100c30:	0f 85 be 01 00 00    	jne    f0100df4 <debuginfo_eip+0x240>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100c36:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100c3d:	b8 c8 61 10 f0       	mov    $0xf01061c8,%eax
f0100c42:	2d 7c 23 10 f0       	sub    $0xf010237c,%eax
f0100c47:	c1 f8 02             	sar    $0x2,%eax
f0100c4a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100c50:	83 e8 01             	sub    $0x1,%eax
f0100c53:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c5a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100c61:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c64:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c67:	b8 7c 23 10 f0       	mov    $0xf010237c,%eax
f0100c6c:	e8 63 fe ff ff       	call   f0100ad4 <stab_binsearch>
	if (lfile == 0)
f0100c71:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100c74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100c79:	85 d2                	test   %edx,%edx
f0100c7b:	0f 84 73 01 00 00    	je     f0100df4 <debuginfo_eip+0x240>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c81:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100c84:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c87:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c8a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100c8e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100c95:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c98:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c9b:	b8 7c 23 10 f0       	mov    $0xf010237c,%eax
f0100ca0:	e8 2f fe ff ff       	call   f0100ad4 <stab_binsearch>

	if (lfun <= rfun) {
f0100ca5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ca8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100cab:	39 d0                	cmp    %edx,%eax
f0100cad:	7f 3d                	jg     f0100cec <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100caf:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100cb2:	8d b9 7c 23 10 f0    	lea    -0xfefdc84(%ecx),%edi
f0100cb8:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100cbb:	8b 89 7c 23 10 f0    	mov    -0xfefdc84(%ecx),%ecx
f0100cc1:	bf 5c 7b 10 f0       	mov    $0xf0107b5c,%edi
f0100cc6:	81 ef c9 61 10 f0    	sub    $0xf01061c9,%edi
f0100ccc:	39 f9                	cmp    %edi,%ecx
f0100cce:	73 09                	jae    f0100cd9 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100cd0:	81 c1 c9 61 10 f0    	add    $0xf01061c9,%ecx
f0100cd6:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100cd9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100cdc:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100cdf:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ce2:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ce4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ce7:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100cea:	eb 0f                	jmp    f0100cfb <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100cec:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100cef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cf2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100cf5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cf8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100cfb:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100d02:	00 
f0100d03:	8b 43 08             	mov    0x8(%ebx),%eax
f0100d06:	89 04 24             	mov    %eax,(%esp)
f0100d09:	e8 6c 09 00 00       	call   f010167a <strfind>
f0100d0e:	2b 43 08             	sub    0x8(%ebx),%eax
f0100d11:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	 stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100d14:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100d18:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100d1f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100d22:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100d25:	b8 7c 23 10 f0       	mov    $0xf010237c,%eax
f0100d2a:	e8 a5 fd ff ff       	call   f0100ad4 <stab_binsearch>
    	 info->eip_line = stabs[lline].n_desc;
f0100d2f:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100d32:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100d35:	0f b7 80 82 23 10 f0 	movzwl -0xfefdc7e(%eax),%eax
f0100d3c:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d3f:	89 f0                	mov    %esi,%eax
f0100d41:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d44:	39 ce                	cmp    %ecx,%esi
f0100d46:	7c 5f                	jl     f0100da7 <debuginfo_eip+0x1f3>
	       && stabs[lline].n_type != N_SOL
f0100d48:	89 f2                	mov    %esi,%edx
f0100d4a:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100d4d:	80 be 80 23 10 f0 84 	cmpb   $0x84,-0xfefdc80(%esi)
f0100d54:	75 18                	jne    f0100d6e <debuginfo_eip+0x1ba>
f0100d56:	eb 30                	jmp    f0100d88 <debuginfo_eip+0x1d4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d58:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d5b:	39 c1                	cmp    %eax,%ecx
f0100d5d:	7f 48                	jg     f0100da7 <debuginfo_eip+0x1f3>
	       && stabs[lline].n_type != N_SOL
f0100d5f:	89 c2                	mov    %eax,%edx
f0100d61:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100d64:	80 3c b5 80 23 10 f0 	cmpb   $0x84,-0xfefdc80(,%esi,4)
f0100d6b:	84 
f0100d6c:	74 1a                	je     f0100d88 <debuginfo_eip+0x1d4>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100d6e:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d71:	8d 14 95 7c 23 10 f0 	lea    -0xfefdc84(,%edx,4),%edx
f0100d78:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100d7c:	75 da                	jne    f0100d58 <debuginfo_eip+0x1a4>
f0100d7e:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100d82:	74 d4                	je     f0100d58 <debuginfo_eip+0x1a4>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100d84:	39 c1                	cmp    %eax,%ecx
f0100d86:	7f 1f                	jg     f0100da7 <debuginfo_eip+0x1f3>
f0100d88:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100d8b:	8b 80 7c 23 10 f0    	mov    -0xfefdc84(%eax),%eax
f0100d91:	ba 5c 7b 10 f0       	mov    $0xf0107b5c,%edx
f0100d96:	81 ea c9 61 10 f0    	sub    $0xf01061c9,%edx
f0100d9c:	39 d0                	cmp    %edx,%eax
f0100d9e:	73 07                	jae    f0100da7 <debuginfo_eip+0x1f3>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100da0:	05 c9 61 10 f0       	add    $0xf01061c9,%eax
f0100da5:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100da7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100daa:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100dad:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100db2:	39 ca                	cmp    %ecx,%edx
f0100db4:	7d 3e                	jge    f0100df4 <debuginfo_eip+0x240>
		for (lline = lfun + 1;
f0100db6:	83 c2 01             	add    $0x1,%edx
f0100db9:	39 d1                	cmp    %edx,%ecx
f0100dbb:	7e 37                	jle    f0100df4 <debuginfo_eip+0x240>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dbd:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100dc0:	80 be 80 23 10 f0 a0 	cmpb   $0xa0,-0xfefdc80(%esi)
f0100dc7:	75 2b                	jne    f0100df4 <debuginfo_eip+0x240>
		     lline++)
			info->eip_fn_narg++;
f0100dc9:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100dcd:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100dd0:	39 d1                	cmp    %edx,%ecx
f0100dd2:	7e 1b                	jle    f0100def <debuginfo_eip+0x23b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100dd4:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100dd7:	80 3c 85 80 23 10 f0 	cmpb   $0xa0,-0xfefdc80(,%eax,4)
f0100dde:	a0 
f0100ddf:	74 e8                	je     f0100dc9 <debuginfo_eip+0x215>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100de1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100de6:	eb 0c                	jmp    f0100df4 <debuginfo_eip+0x240>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100de8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ded:	eb 05                	jmp    f0100df4 <debuginfo_eip+0x240>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100def:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100df4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100df7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100dfa:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100dfd:	89 ec                	mov    %ebp,%esp
f0100dff:	5d                   	pop    %ebp
f0100e00:	c3                   	ret    
f0100e01:	00 00                	add    %al,(%eax)
	...

f0100e04 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e04:	55                   	push   %ebp
f0100e05:	89 e5                	mov    %esp,%ebp
f0100e07:	57                   	push   %edi
f0100e08:	56                   	push   %esi
f0100e09:	53                   	push   %ebx
f0100e0a:	83 ec 3c             	sub    $0x3c,%esp
f0100e0d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e10:	89 d7                	mov    %edx,%edi
f0100e12:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e15:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100e18:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e1e:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e21:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e24:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e29:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100e2c:	72 11                	jb     f0100e3f <printnum+0x3b>
f0100e2e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e31:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e34:	76 09                	jbe    f0100e3f <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e36:	83 eb 01             	sub    $0x1,%ebx
f0100e39:	85 db                	test   %ebx,%ebx
f0100e3b:	7f 51                	jg     f0100e8e <printnum+0x8a>
f0100e3d:	eb 5e                	jmp    f0100e9d <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e3f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100e43:	83 eb 01             	sub    $0x1,%ebx
f0100e46:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100e4a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e4d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e51:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100e55:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100e59:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100e60:	00 
f0100e61:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e64:	89 04 24             	mov    %eax,(%esp)
f0100e67:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e6e:	e8 7d 0a 00 00       	call   f01018f0 <__udivdi3>
f0100e73:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100e77:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e7b:	89 04 24             	mov    %eax,(%esp)
f0100e7e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e82:	89 fa                	mov    %edi,%edx
f0100e84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e87:	e8 78 ff ff ff       	call   f0100e04 <printnum>
f0100e8c:	eb 0f                	jmp    f0100e9d <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e8e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e92:	89 34 24             	mov    %esi,(%esp)
f0100e95:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100e98:	83 eb 01             	sub    $0x1,%ebx
f0100e9b:	75 f1                	jne    f0100e8e <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e9d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ea1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100ea5:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ea8:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100eac:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100eb3:	00 
f0100eb4:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100eb7:	89 04 24             	mov    %eax,(%esp)
f0100eba:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ebd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ec1:	e8 5a 0b 00 00       	call   f0101a20 <__umoddi3>
f0100ec6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eca:	0f be 80 69 21 10 f0 	movsbl -0xfefde97(%eax),%eax
f0100ed1:	89 04 24             	mov    %eax,(%esp)
f0100ed4:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100ed7:	83 c4 3c             	add    $0x3c,%esp
f0100eda:	5b                   	pop    %ebx
f0100edb:	5e                   	pop    %esi
f0100edc:	5f                   	pop    %edi
f0100edd:	5d                   	pop    %ebp
f0100ede:	c3                   	ret    

f0100edf <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100edf:	55                   	push   %ebp
f0100ee0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ee2:	83 fa 01             	cmp    $0x1,%edx
f0100ee5:	7e 0e                	jle    f0100ef5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100ee7:	8b 10                	mov    (%eax),%edx
f0100ee9:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100eec:	89 08                	mov    %ecx,(%eax)
f0100eee:	8b 02                	mov    (%edx),%eax
f0100ef0:	8b 52 04             	mov    0x4(%edx),%edx
f0100ef3:	eb 22                	jmp    f0100f17 <getuint+0x38>
	else if (lflag)
f0100ef5:	85 d2                	test   %edx,%edx
f0100ef7:	74 10                	je     f0100f09 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100ef9:	8b 10                	mov    (%eax),%edx
f0100efb:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100efe:	89 08                	mov    %ecx,(%eax)
f0100f00:	8b 02                	mov    (%edx),%eax
f0100f02:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f07:	eb 0e                	jmp    f0100f17 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100f09:	8b 10                	mov    (%eax),%edx
f0100f0b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f0e:	89 08                	mov    %ecx,(%eax)
f0100f10:	8b 02                	mov    (%edx),%eax
f0100f12:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100f17:	5d                   	pop    %ebp
f0100f18:	c3                   	ret    

f0100f19 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0100f19:	55                   	push   %ebp
f0100f1a:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100f1c:	83 fa 01             	cmp    $0x1,%edx
f0100f1f:	7e 0e                	jle    f0100f2f <getint+0x16>
		return va_arg(*ap, long long);
f0100f21:	8b 10                	mov    (%eax),%edx
f0100f23:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100f26:	89 08                	mov    %ecx,(%eax)
f0100f28:	8b 02                	mov    (%edx),%eax
f0100f2a:	8b 52 04             	mov    0x4(%edx),%edx
f0100f2d:	eb 22                	jmp    f0100f51 <getint+0x38>
	else if (lflag)
f0100f2f:	85 d2                	test   %edx,%edx
f0100f31:	74 10                	je     f0100f43 <getint+0x2a>
		return va_arg(*ap, long);
f0100f33:	8b 10                	mov    (%eax),%edx
f0100f35:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f38:	89 08                	mov    %ecx,(%eax)
f0100f3a:	8b 02                	mov    (%edx),%eax
f0100f3c:	89 c2                	mov    %eax,%edx
f0100f3e:	c1 fa 1f             	sar    $0x1f,%edx
f0100f41:	eb 0e                	jmp    f0100f51 <getint+0x38>
	else
		return va_arg(*ap, int);
f0100f43:	8b 10                	mov    (%eax),%edx
f0100f45:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100f48:	89 08                	mov    %ecx,(%eax)
f0100f4a:	8b 02                	mov    (%edx),%eax
f0100f4c:	89 c2                	mov    %eax,%edx
f0100f4e:	c1 fa 1f             	sar    $0x1f,%edx
}
f0100f51:	5d                   	pop    %ebp
f0100f52:	c3                   	ret    

f0100f53 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f53:	55                   	push   %ebp
f0100f54:	89 e5                	mov    %esp,%ebp
f0100f56:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f59:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f5d:	8b 10                	mov    (%eax),%edx
f0100f5f:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f62:	73 0a                	jae    f0100f6e <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f64:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100f67:	88 0a                	mov    %cl,(%edx)
f0100f69:	83 c2 01             	add    $0x1,%edx
f0100f6c:	89 10                	mov    %edx,(%eax)
}
f0100f6e:	5d                   	pop    %ebp
f0100f6f:	c3                   	ret    

f0100f70 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100f70:	55                   	push   %ebp
f0100f71:	89 e5                	mov    %esp,%ebp
f0100f73:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100f76:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f79:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f7d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f80:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f87:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f8e:	89 04 24             	mov    %eax,(%esp)
f0100f91:	e8 02 00 00 00       	call   f0100f98 <vprintfmt>
	va_end(ap);
}
f0100f96:	c9                   	leave  
f0100f97:	c3                   	ret    

f0100f98 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100f98:	55                   	push   %ebp
f0100f99:	89 e5                	mov    %esp,%ebp
f0100f9b:	57                   	push   %edi
f0100f9c:	56                   	push   %esi
f0100f9d:	53                   	push   %ebx
f0100f9e:	83 ec 4c             	sub    $0x4c,%esp
f0100fa1:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100fa4:	8b 75 10             	mov    0x10(%ebp),%esi
f0100fa7:	eb 20                	jmp    f0100fc9 <vprintfmt+0x31>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0'){
f0100fa9:	85 c0                	test   %eax,%eax
f0100fab:	75 12                	jne    f0100fbf <vprintfmt+0x27>
				mycolor = 0x0700;
f0100fad:	c7 05 00 20 11 f0 00 	movl   $0x700,0xf0112000
f0100fb4:	07 00 00 
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
f0100fb7:	83 c4 4c             	add    $0x4c,%esp
f0100fba:	5b                   	pop    %ebx
f0100fbb:	5e                   	pop    %esi
f0100fbc:	5f                   	pop    %edi
f0100fbd:	5d                   	pop    %ebp
f0100fbe:	c3                   	ret    
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0'){
				mycolor = 0x0700;
				return;
			}
			putch(ch, putdat);
f0100fbf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fc3:	89 04 24             	mov    %eax,(%esp)
f0100fc6:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100fc9:	0f b6 06             	movzbl (%esi),%eax
f0100fcc:	83 c6 01             	add    $0x1,%esi
f0100fcf:	83 f8 25             	cmp    $0x25,%eax
f0100fd2:	75 d5                	jne    f0100fa9 <vprintfmt+0x11>
f0100fd4:	c6 45 e0 20          	movb   $0x20,-0x20(%ebp)
f0100fd8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100fdf:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100fe4:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100feb:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ff0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ff3:	eb 2b                	jmp    f0101020 <vprintfmt+0x88>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ff5:	8b 75 e4             	mov    -0x1c(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ff8:	c6 45 e0 2d          	movb   $0x2d,-0x20(%ebp)
f0100ffc:	eb 22                	jmp    f0101020 <vprintfmt+0x88>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ffe:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101001:	c6 45 e0 30          	movb   $0x30,-0x20(%ebp)
f0101005:	eb 19                	jmp    f0101020 <vprintfmt+0x88>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101007:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010100a:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0101011:	eb 0d                	jmp    f0101020 <vprintfmt+0x88>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101013:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101016:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101019:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101020:	0f b6 06             	movzbl (%esi),%eax
f0101023:	0f b6 d0             	movzbl %al,%edx
f0101026:	8d 7e 01             	lea    0x1(%esi),%edi
f0101029:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f010102c:	83 e8 23             	sub    $0x23,%eax
f010102f:	3c 55                	cmp    $0x55,%al
f0101031:	0f 87 06 03 00 00    	ja     f010133d <vprintfmt+0x3a5>
f0101037:	0f b6 c0             	movzbl %al,%eax
f010103a:	ff 24 85 f8 21 10 f0 	jmp    *-0xfefde08(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101041:	83 ea 30             	sub    $0x30,%edx
f0101044:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0101047:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010104b:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010104e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0101051:	83 fa 09             	cmp    $0x9,%edx
f0101054:	77 4a                	ja     f01010a0 <vprintfmt+0x108>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101056:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101059:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f010105c:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f010105f:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101063:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0101066:	8d 50 d0             	lea    -0x30(%eax),%edx
f0101069:	83 fa 09             	cmp    $0x9,%edx
f010106c:	76 eb                	jbe    f0101059 <vprintfmt+0xc1>
f010106e:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101071:	eb 2d                	jmp    f01010a0 <vprintfmt+0x108>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101073:	8b 45 14             	mov    0x14(%ebp),%eax
f0101076:	8d 50 04             	lea    0x4(%eax),%edx
f0101079:	89 55 14             	mov    %edx,0x14(%ebp)
f010107c:	8b 00                	mov    (%eax),%eax
f010107e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101081:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101084:	eb 1a                	jmp    f01010a0 <vprintfmt+0x108>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101086:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0101089:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010108d:	79 91                	jns    f0101020 <vprintfmt+0x88>
f010108f:	e9 73 ff ff ff       	jmp    f0101007 <vprintfmt+0x6f>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101094:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101097:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f010109e:	eb 80                	jmp    f0101020 <vprintfmt+0x88>

		process_precision:
			if (width < 0)
f01010a0:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010a4:	0f 89 76 ff ff ff    	jns    f0101020 <vprintfmt+0x88>
f01010aa:	e9 64 ff ff ff       	jmp    f0101013 <vprintfmt+0x7b>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01010af:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010b2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01010b5:	e9 66 ff ff ff       	jmp    f0101020 <vprintfmt+0x88>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01010ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01010bd:	8d 50 04             	lea    0x4(%eax),%edx
f01010c0:	89 55 14             	mov    %edx,0x14(%ebp)
f01010c3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c7:	8b 00                	mov    (%eax),%eax
f01010c9:	89 04 24             	mov    %eax,(%esp)
f01010cc:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010cf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01010d2:	e9 f2 fe ff ff       	jmp    f0100fc9 <vprintfmt+0x31>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01010d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010da:	8d 50 04             	lea    0x4(%eax),%edx
f01010dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01010e0:	8b 00                	mov    (%eax),%eax
f01010e2:	89 c2                	mov    %eax,%edx
f01010e4:	c1 fa 1f             	sar    $0x1f,%edx
f01010e7:	31 d0                	xor    %edx,%eax
f01010e9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01010eb:	83 f8 06             	cmp    $0x6,%eax
f01010ee:	7f 0b                	jg     f01010fb <vprintfmt+0x163>
f01010f0:	8b 14 85 50 23 10 f0 	mov    -0xfefdcb0(,%eax,4),%edx
f01010f7:	85 d2                	test   %edx,%edx
f01010f9:	75 23                	jne    f010111e <vprintfmt+0x186>
				printfmt(putch, putdat, "error %d", err);
f01010fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010ff:	c7 44 24 08 81 21 10 	movl   $0xf0102181,0x8(%esp)
f0101106:	f0 
f0101107:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010110b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010110e:	89 3c 24             	mov    %edi,(%esp)
f0101111:	e8 5a fe ff ff       	call   f0100f70 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101116:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101119:	e9 ab fe ff ff       	jmp    f0100fc9 <vprintfmt+0x31>
			else
				printfmt(putch, putdat, "%s", p);
f010111e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101122:	c7 44 24 08 8a 21 10 	movl   $0xf010218a,0x8(%esp)
f0101129:	f0 
f010112a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010112e:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101131:	89 3c 24             	mov    %edi,(%esp)
f0101134:	e8 37 fe ff ff       	call   f0100f70 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101139:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010113c:	e9 88 fe ff ff       	jmp    f0100fc9 <vprintfmt+0x31>
f0101141:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101144:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101147:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010114a:	8b 45 14             	mov    0x14(%ebp),%eax
f010114d:	8d 50 04             	lea    0x4(%eax),%edx
f0101150:	89 55 14             	mov    %edx,0x14(%ebp)
f0101153:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101155:	85 f6                	test   %esi,%esi
f0101157:	ba 7a 21 10 f0       	mov    $0xf010217a,%edx
f010115c:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f010115f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101163:	7e 06                	jle    f010116b <vprintfmt+0x1d3>
f0101165:	80 7d e0 2d          	cmpb   $0x2d,-0x20(%ebp)
f0101169:	75 13                	jne    f010117e <vprintfmt+0x1e6>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010116b:	0f be 06             	movsbl (%esi),%eax
f010116e:	83 c6 01             	add    $0x1,%esi
f0101171:	85 c0                	test   %eax,%eax
f0101173:	0f 85 94 00 00 00    	jne    f010120d <vprintfmt+0x275>
f0101179:	e9 81 00 00 00       	jmp    f01011ff <vprintfmt+0x267>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010117e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101182:	89 34 24             	mov    %esi,(%esp)
f0101185:	e8 51 03 00 00       	call   f01014db <strnlen>
f010118a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010118d:	29 c1                	sub    %eax,%ecx
f010118f:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101192:	85 c9                	test   %ecx,%ecx
f0101194:	7e d5                	jle    f010116b <vprintfmt+0x1d3>
					putch(padc, putdat);
f0101196:	0f be 45 e0          	movsbl -0x20(%ebp),%eax
f010119a:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010119d:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01011a0:	89 ce                	mov    %ecx,%esi
f01011a2:	89 c7                	mov    %eax,%edi
f01011a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011a8:	89 3c 24             	mov    %edi,(%esp)
f01011ab:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01011ae:	83 ee 01             	sub    $0x1,%esi
f01011b1:	75 f1                	jne    f01011a4 <vprintfmt+0x20c>
f01011b3:	8b 7d d0             	mov    -0x30(%ebp),%edi
f01011b6:	89 75 dc             	mov    %esi,-0x24(%ebp)
f01011b9:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01011bc:	eb ad                	jmp    f010116b <vprintfmt+0x1d3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01011be:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01011c2:	74 1b                	je     f01011df <vprintfmt+0x247>
f01011c4:	8d 50 e0             	lea    -0x20(%eax),%edx
f01011c7:	83 fa 5e             	cmp    $0x5e,%edx
f01011ca:	76 13                	jbe    f01011df <vprintfmt+0x247>
					putch('?', putdat);
f01011cc:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01011cf:	89 54 24 04          	mov    %edx,0x4(%esp)
f01011d3:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01011da:	ff 55 08             	call   *0x8(%ebp)
f01011dd:	eb 0d                	jmp    f01011ec <vprintfmt+0x254>
				else
					putch(ch, putdat);
f01011df:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01011e2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01011e6:	89 04 24             	mov    %eax,(%esp)
f01011e9:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01011ec:	83 eb 01             	sub    $0x1,%ebx
f01011ef:	0f be 06             	movsbl (%esi),%eax
f01011f2:	83 c6 01             	add    $0x1,%esi
f01011f5:	85 c0                	test   %eax,%eax
f01011f7:	75 1a                	jne    f0101213 <vprintfmt+0x27b>
f01011f9:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01011fc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ff:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101202:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101206:	7f 1c                	jg     f0101224 <vprintfmt+0x28c>
f0101208:	e9 bc fd ff ff       	jmp    f0100fc9 <vprintfmt+0x31>
f010120d:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0101210:	8b 5d dc             	mov    -0x24(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101213:	85 ff                	test   %edi,%edi
f0101215:	78 a7                	js     f01011be <vprintfmt+0x226>
f0101217:	83 ef 01             	sub    $0x1,%edi
f010121a:	79 a2                	jns    f01011be <vprintfmt+0x226>
f010121c:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010121f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101222:	eb db                	jmp    f01011ff <vprintfmt+0x267>
f0101224:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101227:	89 de                	mov    %ebx,%esi
f0101229:	8b 5d dc             	mov    -0x24(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010122c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101230:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101237:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101239:	83 eb 01             	sub    $0x1,%ebx
f010123c:	75 ee                	jne    f010122c <vprintfmt+0x294>
f010123e:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101240:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101243:	e9 81 fd ff ff       	jmp    f0100fc9 <vprintfmt+0x31>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101248:	89 ca                	mov    %ecx,%edx
f010124a:	8d 45 14             	lea    0x14(%ebp),%eax
f010124d:	e8 c7 fc ff ff       	call   f0100f19 <getint>
f0101252:	89 c6                	mov    %eax,%esi
f0101254:	89 d7                	mov    %edx,%edi
			if ((long long) num < 0) {
f0101256:	85 d2                	test   %edx,%edx
f0101258:	78 0a                	js     f0101264 <vprintfmt+0x2cc>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010125a:	be 0a 00 00 00       	mov    $0xa,%esi
f010125f:	e9 9b 00 00 00       	jmp    f01012ff <vprintfmt+0x367>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f0101264:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101268:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010126f:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101272:	89 f0                	mov    %esi,%eax
f0101274:	89 fa                	mov    %edi,%edx
f0101276:	f7 d8                	neg    %eax
f0101278:	83 d2 00             	adc    $0x0,%edx
f010127b:	f7 da                	neg    %edx
			}
			base = 10;
f010127d:	be 0a 00 00 00       	mov    $0xa,%esi
f0101282:	eb 7b                	jmp    f01012ff <vprintfmt+0x367>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101284:	89 ca                	mov    %ecx,%edx
f0101286:	8d 45 14             	lea    0x14(%ebp),%eax
f0101289:	e8 51 fc ff ff       	call   f0100edf <getuint>
			base = 10;
f010128e:	be 0a 00 00 00       	mov    $0xa,%esi
			goto number;
f0101293:	eb 6a                	jmp    f01012ff <vprintfmt+0x367>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap,lflag);
f0101295:	89 ca                	mov    %ecx,%edx
f0101297:	8d 45 14             	lea    0x14(%ebp),%eax
f010129a:	e8 40 fc ff ff       	call   f0100edf <getuint>
			base = 8;
f010129f:	be 08 00 00 00       	mov    $0x8,%esi
                        goto number;
f01012a4:	eb 59                	jmp    f01012ff <vprintfmt+0x367>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f01012a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012aa:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01012b1:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01012b4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012b8:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01012bf:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01012c2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012c5:	8d 50 04             	lea    0x4(%eax),%edx
f01012c8:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01012cb:	8b 00                	mov    (%eax),%eax
f01012cd:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01012d2:	be 10 00 00 00       	mov    $0x10,%esi
			goto number;
f01012d7:	eb 26                	jmp    f01012ff <vprintfmt+0x367>
		case 'm':
			num = getint(&ap,lflag);
f01012d9:	89 ca                	mov    %ecx,%edx
f01012db:	8d 45 14             	lea    0x14(%ebp),%eax
f01012de:	e8 36 fc ff ff       	call   f0100f19 <getint>
			mycolor = num;
f01012e3:	a3 00 20 11 f0       	mov    %eax,0xf0112000
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012e8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			base = 16;
			goto number;
		case 'm':
			num = getint(&ap,lflag);
			mycolor = num;
			break;
f01012eb:	e9 d9 fc ff ff       	jmp    f0100fc9 <vprintfmt+0x31>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01012f0:	89 ca                	mov    %ecx,%edx
f01012f2:	8d 45 14             	lea    0x14(%ebp),%eax
f01012f5:	e8 e5 fb ff ff       	call   f0100edf <getuint>
			base = 16;
f01012fa:	be 10 00 00 00       	mov    $0x10,%esi
		number:
			printnum(putch, putdat, num, base, width, padc);
f01012ff:	0f be 4d e0          	movsbl -0x20(%ebp),%ecx
f0101303:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101307:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010130a:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010130e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101312:	89 04 24             	mov    %eax,(%esp)
f0101315:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101319:	89 da                	mov    %ebx,%edx
f010131b:	8b 45 08             	mov    0x8(%ebp),%eax
f010131e:	e8 e1 fa ff ff       	call   f0100e04 <printnum>
			break;
f0101323:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101326:	e9 9e fc ff ff       	jmp    f0100fc9 <vprintfmt+0x31>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010132b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010132f:	89 14 24             	mov    %edx,(%esp)
f0101332:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101335:	8b 75 e4             	mov    -0x1c(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101338:	e9 8c fc ff ff       	jmp    f0100fc9 <vprintfmt+0x31>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010133d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101341:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101348:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010134b:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010134f:	0f 84 74 fc ff ff    	je     f0100fc9 <vprintfmt+0x31>
f0101355:	83 ee 01             	sub    $0x1,%esi
f0101358:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f010135c:	75 f7                	jne    f0101355 <vprintfmt+0x3bd>
f010135e:	e9 66 fc ff ff       	jmp    f0100fc9 <vprintfmt+0x31>

f0101363 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101363:	55                   	push   %ebp
f0101364:	89 e5                	mov    %esp,%ebp
f0101366:	83 ec 28             	sub    $0x28,%esp
f0101369:	8b 45 08             	mov    0x8(%ebp),%eax
f010136c:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010136f:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101372:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101376:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101379:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101380:	85 c0                	test   %eax,%eax
f0101382:	74 30                	je     f01013b4 <vsnprintf+0x51>
f0101384:	85 d2                	test   %edx,%edx
f0101386:	7e 2c                	jle    f01013b4 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101388:	8b 45 14             	mov    0x14(%ebp),%eax
f010138b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010138f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101392:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101396:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101399:	89 44 24 04          	mov    %eax,0x4(%esp)
f010139d:	c7 04 24 53 0f 10 f0 	movl   $0xf0100f53,(%esp)
f01013a4:	e8 ef fb ff ff       	call   f0100f98 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01013a9:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01013ac:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01013af:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01013b2:	eb 05                	jmp    f01013b9 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01013b4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01013b9:	c9                   	leave  
f01013ba:	c3                   	ret    

f01013bb <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01013bb:	55                   	push   %ebp
f01013bc:	89 e5                	mov    %esp,%ebp
f01013be:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01013c1:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01013c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013c8:	8b 45 10             	mov    0x10(%ebp),%eax
f01013cb:	89 44 24 08          	mov    %eax,0x8(%esp)
f01013cf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013d9:	89 04 24             	mov    %eax,(%esp)
f01013dc:	e8 82 ff ff ff       	call   f0101363 <vsnprintf>
	va_end(ap);

	return rc;
}
f01013e1:	c9                   	leave  
f01013e2:	c3                   	ret    
	...

f01013f0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01013f0:	55                   	push   %ebp
f01013f1:	89 e5                	mov    %esp,%ebp
f01013f3:	57                   	push   %edi
f01013f4:	56                   	push   %esi
f01013f5:	53                   	push   %ebx
f01013f6:	83 ec 1c             	sub    $0x1c,%esp
f01013f9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013fc:	85 c0                	test   %eax,%eax
f01013fe:	74 10                	je     f0101410 <readline+0x20>
		cprintf("%s", prompt);
f0101400:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101404:	c7 04 24 8a 21 10 f0 	movl   $0xf010218a,(%esp)
f010140b:	e8 aa f6 ff ff       	call   f0100aba <cprintf>

	i = 0;
	echoing = iscons(0);
f0101410:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101417:	e8 66 f2 ff ff       	call   f0100682 <iscons>
f010141c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010141e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101423:	e8 49 f2 ff ff       	call   f0100671 <getchar>
f0101428:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010142a:	85 c0                	test   %eax,%eax
f010142c:	79 17                	jns    f0101445 <readline+0x55>
			cprintf("read error: %e\n", c);
f010142e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101432:	c7 04 24 6c 23 10 f0 	movl   $0xf010236c,(%esp)
f0101439:	e8 7c f6 ff ff       	call   f0100aba <cprintf>
			return NULL;
f010143e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101443:	eb 6d                	jmp    f01014b2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101445:	83 f8 08             	cmp    $0x8,%eax
f0101448:	74 05                	je     f010144f <readline+0x5f>
f010144a:	83 f8 7f             	cmp    $0x7f,%eax
f010144d:	75 19                	jne    f0101468 <readline+0x78>
f010144f:	85 f6                	test   %esi,%esi
f0101451:	7e 15                	jle    f0101468 <readline+0x78>
			if (echoing)
f0101453:	85 ff                	test   %edi,%edi
f0101455:	74 0c                	je     f0101463 <readline+0x73>
				cputchar('\b');
f0101457:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010145e:	e8 fe f1 ff ff       	call   f0100661 <cputchar>
			i--;
f0101463:	83 ee 01             	sub    $0x1,%esi
f0101466:	eb bb                	jmp    f0101423 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101468:	83 fb 1f             	cmp    $0x1f,%ebx
f010146b:	7e 1f                	jle    f010148c <readline+0x9c>
f010146d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101473:	7f 17                	jg     f010148c <readline+0x9c>
			if (echoing)
f0101475:	85 ff                	test   %edi,%edi
f0101477:	74 08                	je     f0101481 <readline+0x91>
				cputchar(c);
f0101479:	89 1c 24             	mov    %ebx,(%esp)
f010147c:	e8 e0 f1 ff ff       	call   f0100661 <cputchar>
			buf[i++] = c;
f0101481:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101487:	83 c6 01             	add    $0x1,%esi
f010148a:	eb 97                	jmp    f0101423 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010148c:	83 fb 0a             	cmp    $0xa,%ebx
f010148f:	74 05                	je     f0101496 <readline+0xa6>
f0101491:	83 fb 0d             	cmp    $0xd,%ebx
f0101494:	75 8d                	jne    f0101423 <readline+0x33>
			if (echoing)
f0101496:	85 ff                	test   %edi,%edi
f0101498:	74 0c                	je     f01014a6 <readline+0xb6>
				cputchar('\n');
f010149a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01014a1:	e8 bb f1 ff ff       	call   f0100661 <cputchar>
			buf[i] = 0;
f01014a6:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f01014ad:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f01014b2:	83 c4 1c             	add    $0x1c,%esp
f01014b5:	5b                   	pop    %ebx
f01014b6:	5e                   	pop    %esi
f01014b7:	5f                   	pop    %edi
f01014b8:	5d                   	pop    %ebp
f01014b9:	c3                   	ret    
f01014ba:	00 00                	add    %al,(%eax)
f01014bc:	00 00                	add    %al,(%eax)
	...

f01014c0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01014c0:	55                   	push   %ebp
f01014c1:	89 e5                	mov    %esp,%ebp
f01014c3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01014c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01014cb:	80 3a 00             	cmpb   $0x0,(%edx)
f01014ce:	74 09                	je     f01014d9 <strlen+0x19>
		n++;
f01014d0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01014d3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014d7:	75 f7                	jne    f01014d0 <strlen+0x10>
		n++;
	return n;
}
f01014d9:	5d                   	pop    %ebp
f01014da:	c3                   	ret    

f01014db <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014db:	55                   	push   %ebp
f01014dc:	89 e5                	mov    %esp,%ebp
f01014de:	53                   	push   %ebx
f01014df:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01014ea:	85 c9                	test   %ecx,%ecx
f01014ec:	74 1a                	je     f0101508 <strnlen+0x2d>
f01014ee:	80 3b 00             	cmpb   $0x0,(%ebx)
f01014f1:	74 15                	je     f0101508 <strnlen+0x2d>
f01014f3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01014f8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014fa:	39 ca                	cmp    %ecx,%edx
f01014fc:	74 0a                	je     f0101508 <strnlen+0x2d>
f01014fe:	83 c2 01             	add    $0x1,%edx
f0101501:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101506:	75 f0                	jne    f01014f8 <strnlen+0x1d>
		n++;
	return n;
}
f0101508:	5b                   	pop    %ebx
f0101509:	5d                   	pop    %ebp
f010150a:	c3                   	ret    

f010150b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010150b:	55                   	push   %ebp
f010150c:	89 e5                	mov    %esp,%ebp
f010150e:	53                   	push   %ebx
f010150f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101512:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101515:	ba 00 00 00 00       	mov    $0x0,%edx
f010151a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010151e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101521:	83 c2 01             	add    $0x1,%edx
f0101524:	84 c9                	test   %cl,%cl
f0101526:	75 f2                	jne    f010151a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101528:	5b                   	pop    %ebx
f0101529:	5d                   	pop    %ebp
f010152a:	c3                   	ret    

f010152b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010152b:	55                   	push   %ebp
f010152c:	89 e5                	mov    %esp,%ebp
f010152e:	53                   	push   %ebx
f010152f:	83 ec 08             	sub    $0x8,%esp
f0101532:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101535:	89 1c 24             	mov    %ebx,(%esp)
f0101538:	e8 83 ff ff ff       	call   f01014c0 <strlen>
	strcpy(dst + len, src);
f010153d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101540:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101544:	01 d8                	add    %ebx,%eax
f0101546:	89 04 24             	mov    %eax,(%esp)
f0101549:	e8 bd ff ff ff       	call   f010150b <strcpy>
	return dst;
}
f010154e:	89 d8                	mov    %ebx,%eax
f0101550:	83 c4 08             	add    $0x8,%esp
f0101553:	5b                   	pop    %ebx
f0101554:	5d                   	pop    %ebp
f0101555:	c3                   	ret    

f0101556 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101556:	55                   	push   %ebp
f0101557:	89 e5                	mov    %esp,%ebp
f0101559:	56                   	push   %esi
f010155a:	53                   	push   %ebx
f010155b:	8b 45 08             	mov    0x8(%ebp),%eax
f010155e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101561:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101564:	85 f6                	test   %esi,%esi
f0101566:	74 18                	je     f0101580 <strncpy+0x2a>
f0101568:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010156d:	0f b6 1a             	movzbl (%edx),%ebx
f0101570:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101573:	80 3a 01             	cmpb   $0x1,(%edx)
f0101576:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101579:	83 c1 01             	add    $0x1,%ecx
f010157c:	39 f1                	cmp    %esi,%ecx
f010157e:	75 ed                	jne    f010156d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101580:	5b                   	pop    %ebx
f0101581:	5e                   	pop    %esi
f0101582:	5d                   	pop    %ebp
f0101583:	c3                   	ret    

f0101584 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101584:	55                   	push   %ebp
f0101585:	89 e5                	mov    %esp,%ebp
f0101587:	57                   	push   %edi
f0101588:	56                   	push   %esi
f0101589:	53                   	push   %ebx
f010158a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010158d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101590:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101593:	89 f8                	mov    %edi,%eax
f0101595:	85 f6                	test   %esi,%esi
f0101597:	74 2b                	je     f01015c4 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101599:	83 fe 01             	cmp    $0x1,%esi
f010159c:	74 23                	je     f01015c1 <strlcpy+0x3d>
f010159e:	0f b6 0b             	movzbl (%ebx),%ecx
f01015a1:	84 c9                	test   %cl,%cl
f01015a3:	74 1c                	je     f01015c1 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01015a5:	83 ee 02             	sub    $0x2,%esi
f01015a8:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01015ad:	88 08                	mov    %cl,(%eax)
f01015af:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01015b2:	39 f2                	cmp    %esi,%edx
f01015b4:	74 0b                	je     f01015c1 <strlcpy+0x3d>
f01015b6:	83 c2 01             	add    $0x1,%edx
f01015b9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01015bd:	84 c9                	test   %cl,%cl
f01015bf:	75 ec                	jne    f01015ad <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01015c1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01015c4:	29 f8                	sub    %edi,%eax
}
f01015c6:	5b                   	pop    %ebx
f01015c7:	5e                   	pop    %esi
f01015c8:	5f                   	pop    %edi
f01015c9:	5d                   	pop    %ebp
f01015ca:	c3                   	ret    

f01015cb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01015cb:	55                   	push   %ebp
f01015cc:	89 e5                	mov    %esp,%ebp
f01015ce:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01015d1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01015d4:	0f b6 01             	movzbl (%ecx),%eax
f01015d7:	84 c0                	test   %al,%al
f01015d9:	74 16                	je     f01015f1 <strcmp+0x26>
f01015db:	3a 02                	cmp    (%edx),%al
f01015dd:	75 12                	jne    f01015f1 <strcmp+0x26>
		p++, q++;
f01015df:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01015e2:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01015e6:	84 c0                	test   %al,%al
f01015e8:	74 07                	je     f01015f1 <strcmp+0x26>
f01015ea:	83 c1 01             	add    $0x1,%ecx
f01015ed:	3a 02                	cmp    (%edx),%al
f01015ef:	74 ee                	je     f01015df <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01015f1:	0f b6 c0             	movzbl %al,%eax
f01015f4:	0f b6 12             	movzbl (%edx),%edx
f01015f7:	29 d0                	sub    %edx,%eax
}
f01015f9:	5d                   	pop    %ebp
f01015fa:	c3                   	ret    

f01015fb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01015fb:	55                   	push   %ebp
f01015fc:	89 e5                	mov    %esp,%ebp
f01015fe:	53                   	push   %ebx
f01015ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101602:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101605:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101608:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010160d:	85 d2                	test   %edx,%edx
f010160f:	74 28                	je     f0101639 <strncmp+0x3e>
f0101611:	0f b6 01             	movzbl (%ecx),%eax
f0101614:	84 c0                	test   %al,%al
f0101616:	74 24                	je     f010163c <strncmp+0x41>
f0101618:	3a 03                	cmp    (%ebx),%al
f010161a:	75 20                	jne    f010163c <strncmp+0x41>
f010161c:	83 ea 01             	sub    $0x1,%edx
f010161f:	74 13                	je     f0101634 <strncmp+0x39>
		n--, p++, q++;
f0101621:	83 c1 01             	add    $0x1,%ecx
f0101624:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101627:	0f b6 01             	movzbl (%ecx),%eax
f010162a:	84 c0                	test   %al,%al
f010162c:	74 0e                	je     f010163c <strncmp+0x41>
f010162e:	3a 03                	cmp    (%ebx),%al
f0101630:	74 ea                	je     f010161c <strncmp+0x21>
f0101632:	eb 08                	jmp    f010163c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101634:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101639:	5b                   	pop    %ebx
f010163a:	5d                   	pop    %ebp
f010163b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010163c:	0f b6 01             	movzbl (%ecx),%eax
f010163f:	0f b6 13             	movzbl (%ebx),%edx
f0101642:	29 d0                	sub    %edx,%eax
f0101644:	eb f3                	jmp    f0101639 <strncmp+0x3e>

f0101646 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101646:	55                   	push   %ebp
f0101647:	89 e5                	mov    %esp,%ebp
f0101649:	8b 45 08             	mov    0x8(%ebp),%eax
f010164c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101650:	0f b6 10             	movzbl (%eax),%edx
f0101653:	84 d2                	test   %dl,%dl
f0101655:	74 1c                	je     f0101673 <strchr+0x2d>
		if (*s == c)
f0101657:	38 ca                	cmp    %cl,%dl
f0101659:	75 09                	jne    f0101664 <strchr+0x1e>
f010165b:	eb 1b                	jmp    f0101678 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010165d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101660:	38 ca                	cmp    %cl,%dl
f0101662:	74 14                	je     f0101678 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101664:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101668:	84 d2                	test   %dl,%dl
f010166a:	75 f1                	jne    f010165d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010166c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101671:	eb 05                	jmp    f0101678 <strchr+0x32>
f0101673:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101678:	5d                   	pop    %ebp
f0101679:	c3                   	ret    

f010167a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010167a:	55                   	push   %ebp
f010167b:	89 e5                	mov    %esp,%ebp
f010167d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101680:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101684:	0f b6 10             	movzbl (%eax),%edx
f0101687:	84 d2                	test   %dl,%dl
f0101689:	74 14                	je     f010169f <strfind+0x25>
		if (*s == c)
f010168b:	38 ca                	cmp    %cl,%dl
f010168d:	75 06                	jne    f0101695 <strfind+0x1b>
f010168f:	eb 0e                	jmp    f010169f <strfind+0x25>
f0101691:	38 ca                	cmp    %cl,%dl
f0101693:	74 0a                	je     f010169f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101695:	83 c0 01             	add    $0x1,%eax
f0101698:	0f b6 10             	movzbl (%eax),%edx
f010169b:	84 d2                	test   %dl,%dl
f010169d:	75 f2                	jne    f0101691 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010169f:	5d                   	pop    %ebp
f01016a0:	c3                   	ret    

f01016a1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016a1:	55                   	push   %ebp
f01016a2:	89 e5                	mov    %esp,%ebp
f01016a4:	83 ec 0c             	sub    $0xc,%esp
f01016a7:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01016aa:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01016ad:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01016b0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016b6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016b9:	85 c9                	test   %ecx,%ecx
f01016bb:	74 30                	je     f01016ed <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016bd:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016c3:	75 25                	jne    f01016ea <memset+0x49>
f01016c5:	f6 c1 03             	test   $0x3,%cl
f01016c8:	75 20                	jne    f01016ea <memset+0x49>
		c &= 0xFF;
f01016ca:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016cd:	89 d3                	mov    %edx,%ebx
f01016cf:	c1 e3 08             	shl    $0x8,%ebx
f01016d2:	89 d6                	mov    %edx,%esi
f01016d4:	c1 e6 18             	shl    $0x18,%esi
f01016d7:	89 d0                	mov    %edx,%eax
f01016d9:	c1 e0 10             	shl    $0x10,%eax
f01016dc:	09 f0                	or     %esi,%eax
f01016de:	09 d0                	or     %edx,%eax
f01016e0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01016e2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01016e5:	fc                   	cld    
f01016e6:	f3 ab                	rep stos %eax,%es:(%edi)
f01016e8:	eb 03                	jmp    f01016ed <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016ea:	fc                   	cld    
f01016eb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016ed:	89 f8                	mov    %edi,%eax
f01016ef:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01016f2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01016f5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01016f8:	89 ec                	mov    %ebp,%esp
f01016fa:	5d                   	pop    %ebp
f01016fb:	c3                   	ret    

f01016fc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01016fc:	55                   	push   %ebp
f01016fd:	89 e5                	mov    %esp,%ebp
f01016ff:	83 ec 08             	sub    $0x8,%esp
f0101702:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101705:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101708:	8b 45 08             	mov    0x8(%ebp),%eax
f010170b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010170e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101711:	39 c6                	cmp    %eax,%esi
f0101713:	73 36                	jae    f010174b <memmove+0x4f>
f0101715:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101718:	39 d0                	cmp    %edx,%eax
f010171a:	73 2f                	jae    f010174b <memmove+0x4f>
		s += n;
		d += n;
f010171c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010171f:	f6 c2 03             	test   $0x3,%dl
f0101722:	75 1b                	jne    f010173f <memmove+0x43>
f0101724:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010172a:	75 13                	jne    f010173f <memmove+0x43>
f010172c:	f6 c1 03             	test   $0x3,%cl
f010172f:	75 0e                	jne    f010173f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101731:	83 ef 04             	sub    $0x4,%edi
f0101734:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101737:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010173a:	fd                   	std    
f010173b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010173d:	eb 09                	jmp    f0101748 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010173f:	83 ef 01             	sub    $0x1,%edi
f0101742:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101745:	fd                   	std    
f0101746:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101748:	fc                   	cld    
f0101749:	eb 20                	jmp    f010176b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010174b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101751:	75 13                	jne    f0101766 <memmove+0x6a>
f0101753:	a8 03                	test   $0x3,%al
f0101755:	75 0f                	jne    f0101766 <memmove+0x6a>
f0101757:	f6 c1 03             	test   $0x3,%cl
f010175a:	75 0a                	jne    f0101766 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010175c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010175f:	89 c7                	mov    %eax,%edi
f0101761:	fc                   	cld    
f0101762:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101764:	eb 05                	jmp    f010176b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101766:	89 c7                	mov    %eax,%edi
f0101768:	fc                   	cld    
f0101769:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010176b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010176e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101771:	89 ec                	mov    %ebp,%esp
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    

f0101775 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101775:	55                   	push   %ebp
f0101776:	89 e5                	mov    %esp,%ebp
f0101778:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010177b:	8b 45 10             	mov    0x10(%ebp),%eax
f010177e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101782:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101785:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101789:	8b 45 08             	mov    0x8(%ebp),%eax
f010178c:	89 04 24             	mov    %eax,(%esp)
f010178f:	e8 68 ff ff ff       	call   f01016fc <memmove>
}
f0101794:	c9                   	leave  
f0101795:	c3                   	ret    

f0101796 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101796:	55                   	push   %ebp
f0101797:	89 e5                	mov    %esp,%ebp
f0101799:	57                   	push   %edi
f010179a:	56                   	push   %esi
f010179b:	53                   	push   %ebx
f010179c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010179f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017a2:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01017a5:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017aa:	85 ff                	test   %edi,%edi
f01017ac:	74 37                	je     f01017e5 <memcmp+0x4f>
		if (*s1 != *s2)
f01017ae:	0f b6 03             	movzbl (%ebx),%eax
f01017b1:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017b4:	83 ef 01             	sub    $0x1,%edi
f01017b7:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01017bc:	38 c8                	cmp    %cl,%al
f01017be:	74 1c                	je     f01017dc <memcmp+0x46>
f01017c0:	eb 10                	jmp    f01017d2 <memcmp+0x3c>
f01017c2:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01017c7:	83 c2 01             	add    $0x1,%edx
f01017ca:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01017ce:	38 c8                	cmp    %cl,%al
f01017d0:	74 0a                	je     f01017dc <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01017d2:	0f b6 c0             	movzbl %al,%eax
f01017d5:	0f b6 c9             	movzbl %cl,%ecx
f01017d8:	29 c8                	sub    %ecx,%eax
f01017da:	eb 09                	jmp    f01017e5 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01017dc:	39 fa                	cmp    %edi,%edx
f01017de:	75 e2                	jne    f01017c2 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01017e0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017e5:	5b                   	pop    %ebx
f01017e6:	5e                   	pop    %esi
f01017e7:	5f                   	pop    %edi
f01017e8:	5d                   	pop    %ebp
f01017e9:	c3                   	ret    

f01017ea <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017ea:	55                   	push   %ebp
f01017eb:	89 e5                	mov    %esp,%ebp
f01017ed:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01017f0:	89 c2                	mov    %eax,%edx
f01017f2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017f5:	39 d0                	cmp    %edx,%eax
f01017f7:	73 19                	jae    f0101812 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017f9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01017fd:	38 08                	cmp    %cl,(%eax)
f01017ff:	75 06                	jne    f0101807 <memfind+0x1d>
f0101801:	eb 0f                	jmp    f0101812 <memfind+0x28>
f0101803:	38 08                	cmp    %cl,(%eax)
f0101805:	74 0b                	je     f0101812 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101807:	83 c0 01             	add    $0x1,%eax
f010180a:	39 d0                	cmp    %edx,%eax
f010180c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101810:	75 f1                	jne    f0101803 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101812:	5d                   	pop    %ebp
f0101813:	c3                   	ret    

f0101814 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101814:	55                   	push   %ebp
f0101815:	89 e5                	mov    %esp,%ebp
f0101817:	57                   	push   %edi
f0101818:	56                   	push   %esi
f0101819:	53                   	push   %ebx
f010181a:	8b 55 08             	mov    0x8(%ebp),%edx
f010181d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101820:	0f b6 02             	movzbl (%edx),%eax
f0101823:	3c 20                	cmp    $0x20,%al
f0101825:	74 04                	je     f010182b <strtol+0x17>
f0101827:	3c 09                	cmp    $0x9,%al
f0101829:	75 0e                	jne    f0101839 <strtol+0x25>
		s++;
f010182b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010182e:	0f b6 02             	movzbl (%edx),%eax
f0101831:	3c 20                	cmp    $0x20,%al
f0101833:	74 f6                	je     f010182b <strtol+0x17>
f0101835:	3c 09                	cmp    $0x9,%al
f0101837:	74 f2                	je     f010182b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101839:	3c 2b                	cmp    $0x2b,%al
f010183b:	75 0a                	jne    f0101847 <strtol+0x33>
		s++;
f010183d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101840:	bf 00 00 00 00       	mov    $0x0,%edi
f0101845:	eb 10                	jmp    f0101857 <strtol+0x43>
f0101847:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010184c:	3c 2d                	cmp    $0x2d,%al
f010184e:	75 07                	jne    f0101857 <strtol+0x43>
		s++, neg = 1;
f0101850:	83 c2 01             	add    $0x1,%edx
f0101853:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101857:	85 db                	test   %ebx,%ebx
f0101859:	0f 94 c0             	sete   %al
f010185c:	74 05                	je     f0101863 <strtol+0x4f>
f010185e:	83 fb 10             	cmp    $0x10,%ebx
f0101861:	75 15                	jne    f0101878 <strtol+0x64>
f0101863:	80 3a 30             	cmpb   $0x30,(%edx)
f0101866:	75 10                	jne    f0101878 <strtol+0x64>
f0101868:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010186c:	75 0a                	jne    f0101878 <strtol+0x64>
		s += 2, base = 16;
f010186e:	83 c2 02             	add    $0x2,%edx
f0101871:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101876:	eb 13                	jmp    f010188b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101878:	84 c0                	test   %al,%al
f010187a:	74 0f                	je     f010188b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010187c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101881:	80 3a 30             	cmpb   $0x30,(%edx)
f0101884:	75 05                	jne    f010188b <strtol+0x77>
		s++, base = 8;
f0101886:	83 c2 01             	add    $0x1,%edx
f0101889:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010188b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101890:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101892:	0f b6 0a             	movzbl (%edx),%ecx
f0101895:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101898:	80 fb 09             	cmp    $0x9,%bl
f010189b:	77 08                	ja     f01018a5 <strtol+0x91>
			dig = *s - '0';
f010189d:	0f be c9             	movsbl %cl,%ecx
f01018a0:	83 e9 30             	sub    $0x30,%ecx
f01018a3:	eb 1e                	jmp    f01018c3 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01018a5:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01018a8:	80 fb 19             	cmp    $0x19,%bl
f01018ab:	77 08                	ja     f01018b5 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01018ad:	0f be c9             	movsbl %cl,%ecx
f01018b0:	83 e9 57             	sub    $0x57,%ecx
f01018b3:	eb 0e                	jmp    f01018c3 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01018b5:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01018b8:	80 fb 19             	cmp    $0x19,%bl
f01018bb:	77 14                	ja     f01018d1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01018bd:	0f be c9             	movsbl %cl,%ecx
f01018c0:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01018c3:	39 f1                	cmp    %esi,%ecx
f01018c5:	7d 0e                	jge    f01018d5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01018c7:	83 c2 01             	add    $0x1,%edx
f01018ca:	0f af c6             	imul   %esi,%eax
f01018cd:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01018cf:	eb c1                	jmp    f0101892 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01018d1:	89 c1                	mov    %eax,%ecx
f01018d3:	eb 02                	jmp    f01018d7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01018d5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01018d7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018db:	74 05                	je     f01018e2 <strtol+0xce>
		*endptr = (char *) s;
f01018dd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018e0:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01018e2:	89 ca                	mov    %ecx,%edx
f01018e4:	f7 da                	neg    %edx
f01018e6:	85 ff                	test   %edi,%edi
f01018e8:	0f 45 c2             	cmovne %edx,%eax
}
f01018eb:	5b                   	pop    %ebx
f01018ec:	5e                   	pop    %esi
f01018ed:	5f                   	pop    %edi
f01018ee:	5d                   	pop    %ebp
f01018ef:	c3                   	ret    

f01018f0 <__udivdi3>:
f01018f0:	83 ec 1c             	sub    $0x1c,%esp
f01018f3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018f7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01018fb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01018ff:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101903:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101907:	8b 74 24 24          	mov    0x24(%esp),%esi
f010190b:	85 ff                	test   %edi,%edi
f010190d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101911:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101915:	89 cd                	mov    %ecx,%ebp
f0101917:	89 44 24 04          	mov    %eax,0x4(%esp)
f010191b:	75 33                	jne    f0101950 <__udivdi3+0x60>
f010191d:	39 f1                	cmp    %esi,%ecx
f010191f:	77 57                	ja     f0101978 <__udivdi3+0x88>
f0101921:	85 c9                	test   %ecx,%ecx
f0101923:	75 0b                	jne    f0101930 <__udivdi3+0x40>
f0101925:	b8 01 00 00 00       	mov    $0x1,%eax
f010192a:	31 d2                	xor    %edx,%edx
f010192c:	f7 f1                	div    %ecx
f010192e:	89 c1                	mov    %eax,%ecx
f0101930:	89 f0                	mov    %esi,%eax
f0101932:	31 d2                	xor    %edx,%edx
f0101934:	f7 f1                	div    %ecx
f0101936:	89 c6                	mov    %eax,%esi
f0101938:	8b 44 24 04          	mov    0x4(%esp),%eax
f010193c:	f7 f1                	div    %ecx
f010193e:	89 f2                	mov    %esi,%edx
f0101940:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101944:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101948:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010194c:	83 c4 1c             	add    $0x1c,%esp
f010194f:	c3                   	ret    
f0101950:	31 d2                	xor    %edx,%edx
f0101952:	31 c0                	xor    %eax,%eax
f0101954:	39 f7                	cmp    %esi,%edi
f0101956:	77 e8                	ja     f0101940 <__udivdi3+0x50>
f0101958:	0f bd cf             	bsr    %edi,%ecx
f010195b:	83 f1 1f             	xor    $0x1f,%ecx
f010195e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101962:	75 2c                	jne    f0101990 <__udivdi3+0xa0>
f0101964:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101968:	76 04                	jbe    f010196e <__udivdi3+0x7e>
f010196a:	39 f7                	cmp    %esi,%edi
f010196c:	73 d2                	jae    f0101940 <__udivdi3+0x50>
f010196e:	31 d2                	xor    %edx,%edx
f0101970:	b8 01 00 00 00       	mov    $0x1,%eax
f0101975:	eb c9                	jmp    f0101940 <__udivdi3+0x50>
f0101977:	90                   	nop
f0101978:	89 f2                	mov    %esi,%edx
f010197a:	f7 f1                	div    %ecx
f010197c:	31 d2                	xor    %edx,%edx
f010197e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101982:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101986:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010198a:	83 c4 1c             	add    $0x1c,%esp
f010198d:	c3                   	ret    
f010198e:	66 90                	xchg   %ax,%ax
f0101990:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101995:	b8 20 00 00 00       	mov    $0x20,%eax
f010199a:	89 ea                	mov    %ebp,%edx
f010199c:	2b 44 24 04          	sub    0x4(%esp),%eax
f01019a0:	d3 e7                	shl    %cl,%edi
f01019a2:	89 c1                	mov    %eax,%ecx
f01019a4:	d3 ea                	shr    %cl,%edx
f01019a6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019ab:	09 fa                	or     %edi,%edx
f01019ad:	89 f7                	mov    %esi,%edi
f01019af:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01019b3:	89 f2                	mov    %esi,%edx
f01019b5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01019b9:	d3 e5                	shl    %cl,%ebp
f01019bb:	89 c1                	mov    %eax,%ecx
f01019bd:	d3 ef                	shr    %cl,%edi
f01019bf:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019c4:	d3 e2                	shl    %cl,%edx
f01019c6:	89 c1                	mov    %eax,%ecx
f01019c8:	d3 ee                	shr    %cl,%esi
f01019ca:	09 d6                	or     %edx,%esi
f01019cc:	89 fa                	mov    %edi,%edx
f01019ce:	89 f0                	mov    %esi,%eax
f01019d0:	f7 74 24 0c          	divl   0xc(%esp)
f01019d4:	89 d7                	mov    %edx,%edi
f01019d6:	89 c6                	mov    %eax,%esi
f01019d8:	f7 e5                	mul    %ebp
f01019da:	39 d7                	cmp    %edx,%edi
f01019dc:	72 22                	jb     f0101a00 <__udivdi3+0x110>
f01019de:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f01019e2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019e7:	d3 e5                	shl    %cl,%ebp
f01019e9:	39 c5                	cmp    %eax,%ebp
f01019eb:	73 04                	jae    f01019f1 <__udivdi3+0x101>
f01019ed:	39 d7                	cmp    %edx,%edi
f01019ef:	74 0f                	je     f0101a00 <__udivdi3+0x110>
f01019f1:	89 f0                	mov    %esi,%eax
f01019f3:	31 d2                	xor    %edx,%edx
f01019f5:	e9 46 ff ff ff       	jmp    f0101940 <__udivdi3+0x50>
f01019fa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a00:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101a03:	31 d2                	xor    %edx,%edx
f0101a05:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a09:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a0d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a11:	83 c4 1c             	add    $0x1c,%esp
f0101a14:	c3                   	ret    
	...

f0101a20 <__umoddi3>:
f0101a20:	83 ec 1c             	sub    $0x1c,%esp
f0101a23:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101a27:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101a2b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101a2f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101a33:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101a37:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101a3b:	85 ed                	test   %ebp,%ebp
f0101a3d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101a41:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a45:	89 cf                	mov    %ecx,%edi
f0101a47:	89 04 24             	mov    %eax,(%esp)
f0101a4a:	89 f2                	mov    %esi,%edx
f0101a4c:	75 1a                	jne    f0101a68 <__umoddi3+0x48>
f0101a4e:	39 f1                	cmp    %esi,%ecx
f0101a50:	76 4e                	jbe    f0101aa0 <__umoddi3+0x80>
f0101a52:	f7 f1                	div    %ecx
f0101a54:	89 d0                	mov    %edx,%eax
f0101a56:	31 d2                	xor    %edx,%edx
f0101a58:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a5c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a60:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a64:	83 c4 1c             	add    $0x1c,%esp
f0101a67:	c3                   	ret    
f0101a68:	39 f5                	cmp    %esi,%ebp
f0101a6a:	77 54                	ja     f0101ac0 <__umoddi3+0xa0>
f0101a6c:	0f bd c5             	bsr    %ebp,%eax
f0101a6f:	83 f0 1f             	xor    $0x1f,%eax
f0101a72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a76:	75 60                	jne    f0101ad8 <__umoddi3+0xb8>
f0101a78:	3b 0c 24             	cmp    (%esp),%ecx
f0101a7b:	0f 87 07 01 00 00    	ja     f0101b88 <__umoddi3+0x168>
f0101a81:	89 f2                	mov    %esi,%edx
f0101a83:	8b 34 24             	mov    (%esp),%esi
f0101a86:	29 ce                	sub    %ecx,%esi
f0101a88:	19 ea                	sbb    %ebp,%edx
f0101a8a:	89 34 24             	mov    %esi,(%esp)
f0101a8d:	8b 04 24             	mov    (%esp),%eax
f0101a90:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101a94:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101a98:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101a9c:	83 c4 1c             	add    $0x1c,%esp
f0101a9f:	c3                   	ret    
f0101aa0:	85 c9                	test   %ecx,%ecx
f0101aa2:	75 0b                	jne    f0101aaf <__umoddi3+0x8f>
f0101aa4:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aa9:	31 d2                	xor    %edx,%edx
f0101aab:	f7 f1                	div    %ecx
f0101aad:	89 c1                	mov    %eax,%ecx
f0101aaf:	89 f0                	mov    %esi,%eax
f0101ab1:	31 d2                	xor    %edx,%edx
f0101ab3:	f7 f1                	div    %ecx
f0101ab5:	8b 04 24             	mov    (%esp),%eax
f0101ab8:	f7 f1                	div    %ecx
f0101aba:	eb 98                	jmp    f0101a54 <__umoddi3+0x34>
f0101abc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ac0:	89 f2                	mov    %esi,%edx
f0101ac2:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ac6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101aca:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ace:	83 c4 1c             	add    $0x1c,%esp
f0101ad1:	c3                   	ret    
f0101ad2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ad8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101add:	89 e8                	mov    %ebp,%eax
f0101adf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101ae4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101ae8:	89 fa                	mov    %edi,%edx
f0101aea:	d3 e0                	shl    %cl,%eax
f0101aec:	89 e9                	mov    %ebp,%ecx
f0101aee:	d3 ea                	shr    %cl,%edx
f0101af0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101af5:	09 c2                	or     %eax,%edx
f0101af7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101afb:	89 14 24             	mov    %edx,(%esp)
f0101afe:	89 f2                	mov    %esi,%edx
f0101b00:	d3 e7                	shl    %cl,%edi
f0101b02:	89 e9                	mov    %ebp,%ecx
f0101b04:	d3 ea                	shr    %cl,%edx
f0101b06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b0b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101b0f:	d3 e6                	shl    %cl,%esi
f0101b11:	89 e9                	mov    %ebp,%ecx
f0101b13:	d3 e8                	shr    %cl,%eax
f0101b15:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b1a:	09 f0                	or     %esi,%eax
f0101b1c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b20:	f7 34 24             	divl   (%esp)
f0101b23:	d3 e6                	shl    %cl,%esi
f0101b25:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101b29:	89 d6                	mov    %edx,%esi
f0101b2b:	f7 e7                	mul    %edi
f0101b2d:	39 d6                	cmp    %edx,%esi
f0101b2f:	89 c1                	mov    %eax,%ecx
f0101b31:	89 d7                	mov    %edx,%edi
f0101b33:	72 3f                	jb     f0101b74 <__umoddi3+0x154>
f0101b35:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101b39:	72 35                	jb     f0101b70 <__umoddi3+0x150>
f0101b3b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101b3f:	29 c8                	sub    %ecx,%eax
f0101b41:	19 fe                	sbb    %edi,%esi
f0101b43:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b48:	89 f2                	mov    %esi,%edx
f0101b4a:	d3 e8                	shr    %cl,%eax
f0101b4c:	89 e9                	mov    %ebp,%ecx
f0101b4e:	d3 e2                	shl    %cl,%edx
f0101b50:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b55:	09 d0                	or     %edx,%eax
f0101b57:	89 f2                	mov    %esi,%edx
f0101b59:	d3 ea                	shr    %cl,%edx
f0101b5b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b5f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b63:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b67:	83 c4 1c             	add    $0x1c,%esp
f0101b6a:	c3                   	ret    
f0101b6b:	90                   	nop
f0101b6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b70:	39 d6                	cmp    %edx,%esi
f0101b72:	75 c7                	jne    f0101b3b <__umoddi3+0x11b>
f0101b74:	89 d7                	mov    %edx,%edi
f0101b76:	89 c1                	mov    %eax,%ecx
f0101b78:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101b7c:	1b 3c 24             	sbb    (%esp),%edi
f0101b7f:	eb ba                	jmp    f0101b3b <__umoddi3+0x11b>
f0101b81:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101b88:	39 f5                	cmp    %esi,%ebp
f0101b8a:	0f 82 f1 fe ff ff    	jb     f0101a81 <__umoddi3+0x61>
f0101b90:	e9 f8 fe ff ff       	jmp    f0101a8d <__umoddi3+0x6d>
