import mmap, os, struct, sys
ADDR = 0x010ac000
try:
    fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
    m = mmap.mmap(fd, 4096, offset=ADDR)
    sys.stderr.write("mapped ok, writing 0 to PS_HOLD...\n")
    sys.stderr.flush()
    m.write(struct.pack("<I", 0))
    m.flush()
    sys.stderr.write("write returned (device should be resetting)\n")
except Exception as e:
    sys.stderr.write("ERROR: %r\n" % (e,))
    sys.exit(1)
