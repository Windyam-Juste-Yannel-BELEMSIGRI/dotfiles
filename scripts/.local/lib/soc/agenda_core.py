# ╭──────────────────────────────────────────────────────────────────────╮
# │ agenda_core.py — moteur de l'agenda « glass // SOC »                  │
# │ Stockage JSON local, récurrences, analyse de dates en français.       │
# │ Utilisé par ~/.local/bin/agenda (CLI) et agenda-gui (GTK).            │
# ╰──────────────────────────────────────────────────────────────────────╯
import calendar, json, os, re, subprocess, tempfile
from datetime import date, datetime, timedelta

# AGENDA_DIR permet de pointer vers un autre dossier (tests, agenda partagé)
DATA = os.environ.get('AGENDA_DIR') or os.path.join(os.environ.get('XDG_DATA_HOME', os.path.expanduser('~/.local/share')), 'agenda')
FILE = os.path.join(DATA, 'events.json')
STATE = os.path.join(DATA, 'notified.json')

# étiquette → (couleur, icône Nerd Font)
TAGS = {
    'soc':   ('#c07070', '󰒃'),
    'data':  ('#7dd3c0', '󰆼'),
    'cours': ('#7a9dc0', '󰑴'),
    'perso': ('#b090c0', '󰋑'),
    'admin': ('#d8a657', '󰈙'),
}
DEFAULT_TAG = 'perso'
REPEATS = ('none', 'daily', 'weekdays', 'weekly', 'monthly')
REPEAT_FR = {'none': 'une fois', 'daily': 'chaque jour', 'weekdays': 'lun→ven', 'weekly': 'chaque semaine', 'monthly': 'chaque mois'}
JOURS = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche']
MOIS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre']
FMT = '%Y-%m-%dT%H:%M'


# ── Stockage ────────────────────────────────────────────────────────────
def load():
    try:
        with open(FILE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return []


def save(events):
    os.makedirs(DATA, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=DATA, suffix='.tmp')
    with os.fdopen(fd, 'w') as f:
        json.dump(sorted(events, key=lambda e: e['start']), f, ensure_ascii=False, indent=1)
    os.replace(tmp, FILE)                      # écriture atomique
    subprocess.run(['pkill', '-RTMIN+9', 'waybar'], stderr=subprocess.DEVNULL)   # rafraîchit le module waybar


def new_id(events):
    return max([e['id'] for e in events], default=0) + 1


def add(title, start, end=None, tag=DEFAULT_TAG, repeat='none', remind=15, note=''):
    ev = load()
    e = dict(id=new_id(ev), title=title.strip(), start=start.strftime(FMT),
             end=end.strftime(FMT) if end else None, tag=tag if tag in TAGS else DEFAULT_TAG,
             repeat=repeat if repeat in REPEATS else 'none', remind=int(remind), note=note, done=[])
    ev.append(e); save(ev)
    return e


def remove(eid):
    ev = load(); n = len(ev)
    ev = [e for e in ev if e['id'] != eid]
    if len(ev) != n: save(ev)
    return len(ev) != n


def update(eid, **kw):
    ev = load()
    for e in ev:
        if e['id'] == eid:
            e.update(kw); save(ev); return e
    return None


def toggle_done(eid, day):
    """Marque (ou démarque) l'occurrence du jour `day` comme faite."""
    ev = load(); k = day.isoformat()
    for e in ev:
        if e['id'] == eid:
            d = e.setdefault('done', [])
            d.remove(k) if k in d else d.append(k)
            save(ev); return k in d
    return None


# ── Occurrences ─────────────────────────────────────────────────────────
def _hits(e, d, first):
    r = e.get('repeat', 'none')
    if d < first: return False
    if r == 'none': return d == first
    if r == 'daily': return True
    if r == 'weekdays': return d.weekday() < 5
    if r == 'weekly': return d.weekday() == first.weekday()
    if r == 'monthly': return d.day == min(first.day, calendar.monthrange(d.year, d.month)[1])
    return False


def occurrences(d0, d1, events=None):
    """Liste triée de (début: datetime, fin|None, événement, fait: bool) entre d0 et d1 inclus."""
    out = []
    for e in (load() if events is None else events):
        s = datetime.strptime(e['start'], FMT)
        en = datetime.strptime(e['end'], FMT) if e.get('end') else None
        d = max(d0, s.date())
        while d <= d1:
            if _hits(e, d, s.date()):
                st = datetime.combine(d, s.time())
                out.append((st, st + (en - s) if en else None, e, d.isoformat() in e.get('done', [])))
                if e.get('repeat', 'none') == 'none': break
            d += timedelta(days=1)
    return sorted(out, key=lambda o: o[0])


def next_occurrence(now=None, horizon=30):
    now = now or datetime.now()
    for o in occurrences(now.date(), now.date() + timedelta(days=horizon)):
        end = o[1] or o[0] + timedelta(minutes=30)
        if end >= now and not o[3] and not o[2].get('allday'): return o
    return None


# ── Analyse de dates en français ────────────────────────────────────────
def _time(s):
    m = re.fullmatch(r'(\d{1,2})\s*(?:h|:)\s*(\d{2})?', s) or re.fullmatch(r'(\d{1,2})(\d{2})', s)
    if not m: return None
    h, mi = int(m.group(1)), int(m.group(2) or 0)
    return (h, mi) if h < 24 and mi < 60 else None


def parse_when(text, now=None):
    """« demain 14h », « lundi 9h30 », « 12/11 14:00 », « 2026-11-12 14:00 », « dans 2h », « +45min », « 16h »."""
    now = now or datetime.now()
    t = text.strip().lower().replace('à ', '').replace("aujourd'hui", 'aujourdhui')
    m = re.fullmatch(r'(?:dans\s+|\+)\s*(\d+)\s*(min|m|h|j|jours?)', t)
    if m:
        n, u = int(m.group(1)), m.group(2)
        return now + (timedelta(minutes=n) if u in ('min', 'm') else timedelta(hours=n) if u == 'h' else timedelta(days=n))
    parts = t.split()
    day, hm = None, None
    for p in parts:
        if p == 'aujourdhui': day = now.date()
        elif p == 'demain': day = now.date() + timedelta(days=1)
        elif p in ('après-demain', 'apres-demain'): day = now.date() + timedelta(days=2)
        elif p in JOURS or p[:3] in [j[:3] for j in JOURS] and len(p) == 3:
            i = [j[:3] for j in JOURS].index(p[:3]); delta = (i - now.weekday()) % 7
            day = now.date() + timedelta(days=delta or 7)
        elif re.fullmatch(r'\d{4}-\d{2}-\d{2}', p): day = date.fromisoformat(p)
        elif re.fullmatch(r'\d{1,2}/\d{1,2}(/\d{2,4})?', p):
            a = [int(x) for x in p.split('/')]; y = a[2] if len(a) > 2 else now.year
            day = date(y + 2000 if y < 100 else y, a[1], a[0])
            if len(a) == 2 and day < now.date(): day = day.replace(year=now.year + 1)
        elif _time(p): hm = _time(p)
        else: raise ValueError(f'date non comprise : « {p} »')
    if day is None and hm is None: raise ValueError('date vide')
    if hm is None: hm = (9, 0)
    if day is None:
        day = now.date()
        if datetime.combine(day, datetime.min.time()).replace(hour=hm[0], minute=hm[1]) < now: day += timedelta(days=1)
    return datetime(day.year, day.month, day.day, hm[0], hm[1])


def fr_day(d, today=None):
    today = today or date.today()
    if d == today: return "Aujourd'hui"
    if d == today + timedelta(days=1): return 'Demain'
    return f'{JOURS[d.weekday()].capitalize()} {d.day} {MOIS[d.month - 1]}'


def countdown(dt, now=None):
    s = int((dt - (now or datetime.now())).total_seconds())
    if s < -60: return 'en cours'
    if s < 60: return 'maintenant'
    m = s // 60
    if m < 60: return f'dans {m} min'
    if m < 1440: return f'dans {m // 60} h {m % 60:02d}'
    return f'dans {m // 1440} j'


# ── Rappels ─────────────────────────────────────────────────────────────
def due_reminders(now=None):
    """Occurrences dont le rappel tombe maintenant et pas encore notifiées (puis les marque)."""
    now = now or datetime.now()
    try:
        with open(STATE) as f: seen = set(json.load(f))
    except (OSError, ValueError): seen = set()
    due = []
    for st, en, e, done in occurrences(now.date(), now.date() + timedelta(days=1)):
        key = f"{e['id']}@{st.strftime(FMT)}"
        if done or key in seen or e.get('allday'): continue
        if st - timedelta(minutes=e.get('remind', 15)) <= now <= st + timedelta(minutes=5):
            due.append((st, e)); seen.add(key)
    if due:
        os.makedirs(DATA, exist_ok=True)
        keep = [k for k in seen if k.split('@')[1] >= (now - timedelta(days=2)).strftime(FMT)]
        with open(STATE, 'w') as f: json.dump(keep, f)
    return due


# ── iCalendar (échange avec Google Agenda, Thunderbird…) ────────────────
def to_ics(events=None):
    L = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//glass-soc//agenda//FR']
    rr = {'daily': 'FREQ=DAILY', 'weekdays': 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR', 'weekly': 'FREQ=WEEKLY', 'monthly': 'FREQ=MONTHLY'}
    for e in (load() if events is None else events):
        s = datetime.strptime(e['start'], FMT)
        en = datetime.strptime(e['end'], FMT) if e.get('end') else s + timedelta(hours=1)
        L += ['BEGIN:VEVENT', f"UID:agenda-{e['id']}@glass-soc", f"DTSTART:{s:%Y%m%dT%H%M00}", f"DTEND:{en:%Y%m%dT%H%M00}",
              'SUMMARY:' + e['title'].replace(',', '\\,'), f"CATEGORIES:{e.get('tag', DEFAULT_TAG)}"]
        if e.get('note'): L.append('DESCRIPTION:' + e['note'].replace('\n', '\\n'))
        if e.get('repeat', 'none') in rr: L.append('RRULE:' + rr[e['repeat']])
        L.append('END:VEVENT')
    return '\r\n'.join(L + ['END:VCALENDAR']) + '\r\n'


def from_ics(text):
    """Import minimal : SUMMARY, DTSTART, DTEND, CATEGORIES, RRULE (FREQ simple). Retourne le nombre ajouté."""
    n = 0
    for blk in re.findall(r'BEGIN:VEVENT(.*?)END:VEVENT', text.replace('\r\n ', '').replace('\r', ''), re.S):
        f = {}
        for line in blk.strip().split('\n'):
            if ':' in line:
                k, v = line.split(':', 1); f[k.split(';')[0]] = v.strip()
        if 'DTSTART' not in f or 'SUMMARY' not in f: continue
        def dt(v):
            v = v.rstrip('Z')
            return datetime.strptime(v, '%Y%m%dT%H%M%S') if 'T' in v else datetime.strptime(v, '%Y%m%d').replace(hour=9)
        rep = 'none'
        m = re.search(r'FREQ=(\w+)', f.get('RRULE', ''))
        if m: rep = {'DAILY': 'daily', 'WEEKLY': 'weekly', 'MONTHLY': 'monthly'}.get(m.group(1), 'none')
        tag = f.get('CATEGORIES', '').lower()
        add(f['SUMMARY'].replace('\\,', ','), dt(f['DTSTART']), dt(f['DTEND']) if 'DTEND' in f else None,
            tag=tag if tag in TAGS else DEFAULT_TAG, repeat=rep, note=f.get('DESCRIPTION', '').replace('\\n', '\n'))
        n += 1
    return n
