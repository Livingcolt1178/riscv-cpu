import struct, sys

data = open(sys.argv[1], 'rb').read()
data += b'\x00' * (-len(data) % 4)          # pad to a whole word
for i in range(0, len(data), 4):
    print('%08x' % struct.unpack('<I', data[i:i+4])[0])