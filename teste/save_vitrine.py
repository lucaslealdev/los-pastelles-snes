# Save de demonstracao (fotos/trailer): nivel 15, loja reformada (premium), telefone,
# computador e motoboy, com uma filial para mostrar a escolha de bairro.
import os, struct, sys
pasta = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(pasta, 'fazsave.py')).read().split('\nsave(')[0]
exec(src)
path = os.path.join(pasta, 'mesen', 'Saves', 'LosPastelles.srm')
dia = int(sys.argv[1]) if len(sys.argv) > 1 else 21
save(path, day=dia, money=2600, level=15, boss=2, stores=1, fran=0, mission=10, chapter=2,
     counter=3, fryer=3, attend=1, ads=1, happy=180, perf=90)
d = bytearray(open(path, 'rb').read())
ext = b'EW' + bytes([1, 0]) + bytes(14) + bytes([0b0000000001011011 & 255, 0]) + bytes([2, 0]) + bytes([0, 0]) \
      + bytes([1, 1]) + bytes([1, 1, 1, 1, 2])
d[0x300:0x300 + len(ext)] = ext
open(path, 'wb').write(d)
print('save vitrine ok')
