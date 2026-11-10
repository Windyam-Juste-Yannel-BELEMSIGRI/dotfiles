#!/usr/bin/env python3
"""Garantit que les groupes d'onglets d'un profil existent dans sa session.
Usage: ensure-groups.py <dossier-profil> <main|coursera>   (profil FERMÉ uniquement)
Ne rajoute un groupe que s'il manque (par nom) ; ne touche pas aux groupes existants."""
import sys,json,time,pathlib
sys.path.insert(0,str(pathlib.Path(__file__).parent))
import mozlz4
prof=pathlib.Path(sys.argv[1]); kind=sys.argv[2]
spec=json.load(open(pathlib.Path(__file__).parent/'groups.json'))[kind]
def tab(title,url,gid):
    return {"entries":[{"url":url,"title":title,"triggeringPrincipal_base64":"{\"3\":{}}","hasUserInteraction":False,"cacheKey":0,"ID":0,"transient":False}],
            "lastAccessed":int(time.time()*1000),"hidden":False,"searchMode":None,"userContextId":0,"index":1,"image":None,"groupId":gid}
def fix(d):
    ws=[w for w in d.get('windows',[])]
    if not ws:
        w={"tabs":[{"entries":[{"url":"about:newtab","title":"New Tab","triggeringPrincipal_base64":"{\"3\":{}}"}],"index":1,"hidden":False,"userContextId":0}],
           "selected":1,"_closedTabs":[],"groups":[],"closedGroups":[],"sizemode":"maximized"}
        d['windows']=[w]; d['selectedWindow']=1
    else: w=ws[0]
    w.setdefault('groups',[])
    have={g['name'] for g in w['groups']}
    wid=str(w.get('__lastSessionWindowID','ff'))
    n=len(w['groups']); added=[]
    for g in spec:
        if g['name'] in have: continue
        n+=1; gid=f"{wid}-{n}"
        w['groups'].append({"id":gid,"name":g['name'],"color":g['color'],"collapsed":False,"saveOnWindowClose":True})
        w['tabs']+= [tab(t,u,gid) for t,u in g['tabs']]; added.append(g['name'])
    return added
done=False
for f in ['sessionstore.jsonlz4','sessionstore-backups/recovery.jsonlz4','sessionstore-backups/recovery.baklz4']:
    p=prof/f
    if p.exists():
        d=mozlz4.read(p); a=fix(d)
        if a: mozlz4.write(p,d)
        print(f, 'ajouté:',a or 'rien'); done=True
if not done:
    d={"version":["sessionrestore",1],"windows":[],"_closedWindows":[],"session":{"state":"stopped"},"global":{}}
    fix(d); mozlz4.write(prof/'sessionstore.jsonlz4',d); print('session créée')
