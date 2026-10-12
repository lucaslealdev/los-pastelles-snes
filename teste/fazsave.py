import struct, sys, os
def save(path, **kw):
    v = dict(day=40, money=30000, stock=50, level=30, xp=0, rep=90, fryer=3, counter=3, attend=1, ads=1,
             stores=3, fran=4, boss=3, mission=11, promo=0, upgrades=4, ending=0, chapter=3,
             fried=900, sales=9000, happy=800, perf=500)
    v.update(kw)
    b = b'LPST' + struct.pack('<HIHBHBBBBBBBBBBBBBHIHH', v['day'], v['money'], v['stock'], v['level'], v['xp'], v['rep'],
        v['fryer'], v['counter'], v['attend'], v['ads'], v['stores'], v['fran'], v['boss'], v['mission'], v['promo'],
        v['upgrades'], v['ending'], v['chapter'], v['fried'], v['sales'], v['happy'], v['perf'])
    assert len(b) == 38, len(b)
    cs = sum(b) & 0xFFFF
    data = b + struct.pack('<H', cs)
    data += b'\x00' * (2048 - len(data))
    open(path, 'wb').write(data)
save(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'mesen', 'Saves', 'LosPastelles.srm'), day=5, money=500, level=5, boss=1, stores=0, fran=0, mission=6, chapter=1, counter=3, fryer=1) if len(sys.argv)>1 else save(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'mesen', 'Saves', 'LosPastelles.srm'))
