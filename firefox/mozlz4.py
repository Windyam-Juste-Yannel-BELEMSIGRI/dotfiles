import struct,json
MAGIC=b'mozLz40\0'
def dec_block(s,size):
    out=bytearray();i=0
    while i<len(s):
        t=s[i];i+=1;l=t>>4
        if l==15:
            while True:
                b=s[i];i+=1;l+=b
                if b!=255:break
        out+=s[i:i+l];i+=l
        if i>=len(s):break
        off=s[i]|s[i+1]<<8;i+=2;m=t&15
        if m==15:
            while True:
                b=s[i];i+=1;m+=b
                if b!=255:break
        m+=4
        for _ in range(m):out.append(out[-off])
    return bytes(out)
def enc_block(d):  # literal-only valid block
    n=len(d);o=bytearray()
    if n<15:o.append(n<<4)
    else:
        o.append(15<<4);r=n-15
        while r>=255:o.append(255);r-=255
        o.append(r)
    return bytes(o)+d
def read(p):
    r=open(p,'rb').read();assert r[:8]==MAGIC
    return json.loads(dec_block(r[12:],struct.unpack('<I',r[8:12])[0]))
def write(p,obj):
    d=json.dumps(obj,separators=(',',':')).encode()
    open(p,'wb').write(MAGIC+struct.pack('<I',len(d))+enc_block(d))
