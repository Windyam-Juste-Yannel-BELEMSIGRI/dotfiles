#!/usr/bin/env python3
"""Importe un CSV Firefox (url,username,password) dans une base KeePassXC existante, via keepassxc-cli.
Usage: import-keepassxc.py <base.kdbx> <fichier.csv> [groupe]   — le mot de passe de la base est demandé (masqué)."""
import sys,csv,subprocess,getpass,urllib.parse
db,src=sys.argv[1],sys.argv[2]; grp=sys.argv[3] if len(sys.argv)>3 else 'Firefox'
pw=getpass.getpass('Mot de passe de la base KeePassXC : ')
def cli(*a,inp): return subprocess.run(['keepassxc-cli',*a],input=inp,capture_output=True,text=True)
r=cli('mkdir',db,grp,inp=pw+'\n')
if r.returncode and 'already exists' not in r.stderr+r.stdout and 'exist' not in r.stderr+r.stdout: print(r.stderr.strip()); sys.exit(1)
n=0
for row in csv.DictReader(open(src)):
    u=row['url']
    if not u.startswith('http'): continue            # ignore chrome://FirefoxAccounts
    host=urllib.parse.urlparse(u).hostname
    title=f"{host} ({row['username']})"
    r=cli('add','-u',row['username'],'--url',u,'-p',db,f'{grp}/{title}',inp=pw+'\n'+row['password']+'\n')
    if r.returncode: print('échec',host,r.stderr.strip()[:80])
    else: n+=1
print(n,'entrées ajoutées dans',db)
