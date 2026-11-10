# ╭──────────────────────────────────────────────────────────────────────╮
# │ agenda_gsync.py — Google Agenda → agenda local (sens unique, lecture) │
# │ Source : « adresse secrète au format iCal » de chaque agenda Google   │
# │ (Paramètres de l'agenda → Intégrer l'agenda). Aucune dépendance,      │
# │ aucun compte développeur : simple téléchargement HTTPS d'un .ics.     │
# │ Adresses : ~/.config/agenda/google.url (une par ligne, chmod 600).    │
# │ Les événements Google sont remplacés à chaque synchro ; les           │
# │ événements locaux ne sont jamais modifiés.                            │
# ╰──────────────────────────────────────────────────────────────────────╯
import calendar, os, re, time, urllib.error, urllib.request
from datetime import date, datetime, timedelta, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

import agenda_core as A

CONF = os.path.join(os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')), 'agenda', 'google.url')
PAST, FUTURE = 30, 180          # fenêtre importée : jours avant / après aujourd'hui
BYDAY = {'MO': 0, 'TU': 1, 'WE': 2, 'TH': 3, 'FR': 4, 'SA': 5, 'SU': 6}
KEYWORDS = (('soc', r'\b(soc|siem|alerte|incident|cti|pentest|ctf|hack|sécu|secu|cyber)'),
            ('data', r'\b(data|sql|etl|pipeline|postgres|spark|airflow|dbt)'),
            ('cours', r'\b(cours|coursera|examen|exam|td|tp|révision|revision|formation|certif|quiz)'),
            ('admin', r'\b(rdv|rendez|banque|impôt|impot|facture|dossier|bourse|visa|administratif)'))


def urls():
    try:
        with open(CONF) as f:
            return [l.strip() for l in f if l.strip() and not l.startswith('#')]
    except OSError:
        return []


def set_url(url):
    if not re.match(r'(https://calendar\.google\.com/calendar/ical/.+\.ics|file://.+)$', url):
        raise ValueError("adresse inattendue : il faut l'« adresse secrète au format iCal » (https://calendar.google.com/calendar/ical/…/basic.ics)")
    os.makedirs(os.path.dirname(CONF), exist_ok=True)
    cur = urls()
    if url not in cur:
        fd = os.open(CONF, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
        with os.fdopen(fd, 'a') as f: f.write(url + '\n')
    os.chmod(CONF, 0o600)
    return len(set(cur + [url]))


def clear_urls():
    try: os.remove(CONF); return True
    except OSError: return False


def fetch(url, tries=6, wait=10):
    """Télécharge le .ics ; réessaie tant que le réseau n'est pas prêt (démarrage)."""
    last = None
    for i in range(tries):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'agenda-glass-soc'})
            with urllib.request.urlopen(req, timeout=20) as r:
                return r.read().decode('utf-8', 'replace')
        except urllib.error.HTTPError as x:
            if 400 <= x.code < 500:         # adresse refusée : inutile de réessayer
                hint = " : agenda non public — utiliser l'adresse SECRÈTE au format iCal" if x.code in (403, 404) and '/public/' in url else ''
                raise ConnectionError(f'HTTP {x.code}{hint}')
            last = x
            if i < tries - 1: time.sleep(wait)
        except Exception as x:              # réseau absent, DNS, délai…
            last = x
            if i < tries - 1: time.sleep(wait)
    raise ConnectionError(f'téléchargement impossible ({type(last).__name__})')


# ── Lecture iCalendar ───────────────────────────────────────────────────
def _unescape(v): return v.replace('\\n', '\n').replace('\\N', '\n').replace('\\,', ',').replace('\\;', ';').replace('\\\\', '\\')


def _dt(value, params, local):
    """→ (datetime local naïf, journée_entière)."""
    if 'VALUE=DATE' in params or re.fullmatch(r'\d{8}', value):
        return datetime.strptime(value[:8], '%Y%m%d'), True
    d = datetime.strptime(value.rstrip('Z')[:15], '%Y%m%dT%H%M%S')
    if value.endswith('Z'): d = d.replace(tzinfo=timezone.utc)
    else:
        m = re.search(r'TZID=([^;:]+)', params)
        if m:
            try: d = d.replace(tzinfo=ZoneInfo(m.group(1)))
            except (ZoneInfoNotFoundError, ValueError): pass
    return (d.astimezone(local).replace(tzinfo=None) if d.tzinfo else d), False


def parse(text, local):
    text = re.sub(r'\r?\n[ \t]', '', text)            # lignes repliées
    out = []
    for blk in re.findall(r'BEGIN:VEVENT\r?\n(.*?)END:VEVENT', text, re.S):
        blk = re.sub(r'BEGIN:VALARM.*?END:VALARM\r?\n?', '', blk, flags=re.S)
        e = {'exdate': set()}
        for line in blk.splitlines():
            if ':' not in line: continue
            head, val = line.split(':', 1); name, _, params = head.partition(';')
            if name in ('DTSTART', 'DTEND', 'RECURRENCE-ID'):
                try: e[name] = _dt(val.strip(), params, local)
                except ValueError: pass
            elif name == 'EXDATE':
                for v in val.split(','):
                    try: e['exdate'].add(_dt(v.strip(), params, local)[0])
                    except ValueError: pass
            elif name in ('SUMMARY', 'DESCRIPTION', 'UID', 'STATUS', 'RRULE', 'LOCATION'): e[name] = val.strip()
        if 'DTSTART' in e and e.get('STATUS') != 'CANCELLED': out.append(e)
    return out


def _expand(e, lo, hi):
    """Dates de début de chaque occurrence dans [lo, hi]."""
    start = e['DTSTART'][0]
    if 'RRULE' not in e:
        return [start] if lo <= start <= hi else []
    r = dict(p.split('=', 1) for p in e['RRULE'].split(';') if '=' in p)
    freq, interval = r.get('FREQ'), max(1, int(r.get('INTERVAL', 1)))
    count = int(r['COUNT']) if 'COUNT' in r else None
    until = None
    if 'UNTIL' in r:
        try: until = _dt(r['UNTIL'], '', A_LOCAL)[0] + (timedelta(days=1) if len(r['UNTIL']) == 8 else timedelta())
        except ValueError: pass
    days = sorted(BYDAY[d[-2:]] for d in r.get('BYDAY', '').split(',') if d[-2:] in BYDAY) if freq == 'WEEKLY' else []
    out, n, cur, guard = [], 0, start, 0
    while cur <= hi and guard < 20000:
        guard += 1
        if freq == 'WEEKLY' and days:
            week0 = cur - timedelta(days=cur.weekday())
            cands = [week0 + timedelta(days=d) for d in days]
        else: cands = [cur]
        for c in cands:
            if c < start: continue
            if until and c > until: return out
            if count is not None and n >= count: return out
            n += 1
            if lo <= c <= hi and c not in e['exdate']: out.append(c)
        if freq == 'DAILY': cur += timedelta(days=interval)
        elif freq == 'WEEKLY': cur += timedelta(weeks=interval)
        elif freq == 'MONTHLY':
            m = cur.month - 1 + interval; y = cur.year + m // 12; m = m % 12 + 1
            cur = cur.replace(year=y, month=m, day=min(start.day, calendar.monthrange(y, m)[1]))
        elif freq == 'YEARLY':
            y = cur.year + interval
            cur = cur.replace(year=y, day=min(start.day, calendar.monthrange(y, start.month)[1]))
        else: break
    return out


A_LOCAL = None


def guess_tag(title):
    t = title.lower()
    for tag, rx in KEYWORDS:
        if re.search(rx, t): return tag
    return A.DEFAULT_TAG


def sync(url_list=None, tries=6):
    """Retourne (importés, agendas). Lève ConnectionError si aucun agenda n'a pu être lu."""
    global A_LOCAL
    A_LOCAL = datetime.now().astimezone().tzinfo
    url_list = url_list if url_list is not None else urls()
    if not url_list: raise LookupError('aucune adresse configurée')
    lo = datetime.combine(date.today() - timedelta(days=PAST), datetime.min.time())
    hi = datetime.combine(date.today() + timedelta(days=FUTURE), datetime.max.time())
    fresh, ok, last_err = {}, 0, None
    for u in url_list:
        try: raw = parse(fetch(u, tries), A_LOCAL)
        except ConnectionError as x: last_err = x; continue
        ok += 1
        moved = {(e.get('UID'), e['RECURRENCE-ID'][0]) for e in raw if 'RECURRENCE-ID' in e}   # occurrences modifiées
        for e in raw:
            dur = (e['DTEND'][0] - e['DTSTART'][0]) if 'DTEND' in e else None
            allday = e['DTSTART'][1]
            for st in _expand(e, lo, hi):
                if 'RECURRENCE-ID' not in e and (e.get('UID'), st) in moved: continue
                gid = f"{e.get('UID', '')}@{st:%Y%m%dT%H%M}"
                en = st + dur if dur and not allday else None
                title = _unescape(e.get('SUMMARY', '(sans titre)'))
                note = _unescape(e.get('LOCATION', '')) or _unescape(e.get('DESCRIPTION', '')).split('\n')[0][:120]
                fresh[gid] = dict(title=title, start=st.strftime(A.FMT), end=en.strftime(A.FMT) if en else None,
                                  tag=guess_tag(title), repeat='none', remind=0 if allday else 15, note=note,
                                  done=[], source='google', gid=gid, allday=allday)
    if not ok: raise last_err or ConnectionError('aucun agenda lisible')
    events = A.load()
    old = {e['gid']: e for e in events if e.get('source') == 'google'}
    keep = [e for e in events if e.get('source') != 'google']
    nid = max([e['id'] for e in events], default=0)
    for gid, e in fresh.items():
        if gid in old: e['id'], e['done'], e['tag'] = old[gid]['id'], old[gid].get('done', []), old[gid].get('tag', e['tag'])
        else: nid += 1; e['id'] = nid
        keep.append(e)
    A.save(keep)
    return len(fresh), ok
