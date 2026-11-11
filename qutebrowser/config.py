# qutebrowser — « glass // SOC » (data engineer / SOC analyst)
# Un seul fichier pour les deux profils ; le profil est déduit du dossier de base (--basedir).
import os
config.load_autoconfig(False)
PROFILE = 'coursera' if 'coursera' in str(config.configdir) else 'yannel'
HERE = os.path.expanduser('~/dotfiles/qutebrowser/startpages')

# ── Palette (identique à foot / waybar / sway) ──
bg, surface, overlay = '#0b0f14', '#121821', '#1e2632'
fg, muted, accent    = '#c5d1de', '#7d8898', '#00ff9c'
red, green, yellow, blue, purple = '#ff5370', '#00ff9c', '#ffb000', '#4fc3f7', '#b388ff'

# ── Polices ──
c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.default_size = '11pt'
c.fonts.web.family.fixed = 'JetBrainsMono Nerd Font'

# ── Couleurs ──
c.colors.statusbar.normal.bg = bg;      c.colors.statusbar.normal.fg = fg
c.colors.statusbar.insert.bg = green;   c.colors.statusbar.insert.fg = bg
c.colors.statusbar.command.bg = surface; c.colors.statusbar.command.fg = fg
c.colors.statusbar.passthrough.bg = purple; c.colors.statusbar.passthrough.fg = bg
c.colors.statusbar.private.bg = overlay; c.colors.statusbar.private.fg = fg
c.colors.statusbar.url.fg = muted;      c.colors.statusbar.url.success.https.fg = accent
c.colors.statusbar.url.hover.fg = accent; c.colors.statusbar.url.warn.fg = yellow
c.colors.statusbar.url.error.fg = red
c.colors.statusbar.progress.bg = accent
c.colors.tabs.bar.bg = bg
c.colors.tabs.even.bg = surface;  c.colors.tabs.even.fg = muted
c.colors.tabs.odd.bg = surface;   c.colors.tabs.odd.fg = muted
c.colors.tabs.selected.even.bg = overlay; c.colors.tabs.selected.even.fg = accent
c.colors.tabs.selected.odd.bg = overlay;  c.colors.tabs.selected.odd.fg = accent
c.colors.tabs.indicator.start = blue; c.colors.tabs.indicator.stop = accent
c.colors.tabs.indicator.error = red
c.colors.completion.fg = fg
c.colors.completion.even.bg = bg; c.colors.completion.odd.bg = surface
c.colors.completion.category.bg = bg; c.colors.completion.category.fg = accent
c.colors.completion.category.border.top = bg; c.colors.completion.category.border.bottom = bg
c.colors.completion.item.selected.bg = overlay; c.colors.completion.item.selected.fg = accent
c.colors.completion.item.selected.border.top = overlay; c.colors.completion.item.selected.border.bottom = overlay
c.colors.completion.match.fg = yellow
c.colors.completion.scrollbar.bg = bg; c.colors.completion.scrollbar.fg = overlay
c.colors.hints.bg = accent; c.colors.hints.fg = bg; c.colors.hints.match.fg = red
c.hints.border = '1px solid ' + bg
c.colors.messages.info.bg = surface;  c.colors.messages.info.fg = fg; c.colors.messages.info.border = overlay
c.colors.messages.warning.bg = yellow; c.colors.messages.warning.fg = bg; c.colors.messages.warning.border = yellow
c.colors.messages.error.bg = red; c.colors.messages.error.fg = bg; c.colors.messages.error.border = red
c.colors.downloads.bar.bg = bg; c.colors.downloads.start.bg = blue; c.colors.downloads.stop.bg = accent
c.colors.downloads.error.bg = red
c.colors.keyhint.bg = surface; c.colors.keyhint.fg = fg; c.colors.keyhint.suffix.fg = accent
c.colors.prompts.bg = surface; c.colors.prompts.fg = fg; c.colors.prompts.border = '1px solid ' + overlay
c.colors.prompts.selected.bg = overlay
c.colors.contextmenu.menu.bg = surface; c.colors.contextmenu.menu.fg = fg
c.colors.contextmenu.selected.bg = overlay; c.colors.contextmenu.selected.fg = accent

# ── Pages web en sombre ──
c.colors.webpage.preferred_color_scheme = 'dark'
c.colors.webpage.darkmode.enabled = True
c.colors.webpage.darkmode.policy.images = 'never'
c.colors.webpage.bg = bg

# ── Interface ──
c.window.hide_decoration = True
c.window.title_format = '{perc}{current_title}{title_sep}qutebrowser'
c.tabs.position = 'top'
c.tabs.show = 'always'
c.tabs.padding = {'top': 5, 'bottom': 5, 'left': 8, 'right': 8}
c.tabs.title.format = '{audio}{index}: {current_title}'
c.tabs.title.format_pinned = '󰐃 {index}'
c.tabs.favicons.show = 'always'
c.tabs.width = '14%' if False else 220
c.tabs.max_width = 240
c.statusbar.padding = {'top': 4, 'bottom': 4, 'left': 6, 'right': 6}
c.completion.shrink = True
c.completion.open_categories = ['quickmarks', 'searchengines', 'history']
c.scrolling.smooth = False
c.auto_save.session = True            # restaure les onglets au redémarrage
c.session.lazy_restore = True
c.downloads.location.directory = os.path.expanduser('~/Downloads')
c.downloads.position = 'bottom'
c.editor.command = ['foot', '-e', 'nvim', '{file}', '-c', 'normal {line}G{column0}l']
c.input.insert_mode.auto_load = True

# ── Anti-distraction : pop-ups, notifs, pubs ──
c.content.notifications.enabled = False
c.content.geolocation = False
c.content.media.audio_capture = False
c.content.media.video_capture = False
c.content.media.audio_video_capture = False
c.content.register_protocol_handler = False
c.content.javascript.can_open_tabs_automatically = False
c.content.javascript.alert = False
c.content.autoplay = False
c.content.cookies.accept = 'no-3rdparty'
c.content.canvas_reading = False
c.content.webrtc_ip_handling_policy = 'default-public-interface-only'
c.content.headers.do_not_track = True
c.content.blocking.enabled = True
c.content.blocking.method = 'hosts'
c.content.blocking.hosts.lists = [
    'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts',
    'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext']
c.content.pdfjs = True

# ── Pages de démarrage par profil ──
start = f'file://{HERE}/{PROFILE}.html'
c.url.start_pages = [start]
c.url.default_page = start

# ── Moteurs de recherche ──
c.url.searchengines = {
    'DEFAULT': 'https://duckduckgo.com/?q={}',
    'gh': 'https://github.com/search?q={}',
    'cve': 'https://nvd.nist.gov/vuln/search/results?query={}',
    'attack': 'https://attack.mitre.org/search/?q={}',
    'vt': 'https://www.virustotal.com/gui/search/{}',
    'ip': 'https://www.abuseipdb.com/check/{}',
    'sh': 'https://www.shodan.io/search?query={}',
    'edb': 'https://www.exploit-db.com/search?q={}',
    'py': 'https://docs.python.org/3/search.html?q={}',
    'pg': 'https://www.postgresql.org/search/?q={}',
    'co': 'https://www.coursera.org/search?query={}',
}

# ── « Groupes d'onglets » = alias qui ouvrent un lot de sites ──
def group(*urls): return ' ;; '.join(f'open -t {u}' for u in urls)
c.aliases['cyber']  = group('https://tryhackme.com/dashboard','https://overthewire.org/wargames/','https://app.hackthebox.com/home','https://academy.hackthebox.com/')
c.aliases['dev']    = group('https://github.com/Windyam-Juste-Yannel-BELEMSIGRI')
c.aliases['reseau'] = group('https://www.netacad.com/')
c.aliases['echecs'] = group('https://www.chess.com/home','https://lichess.org/')
c.aliases['soc']    = group('https://attack.mitre.org/','https://www.virustotal.com/','https://www.abuseipdb.com/','https://urlscan.io/','https://gchq.github.io/CyberChef/')
c.aliases['dataeng']= group('https://duckdb.org/docs/','https://docs.getdbt.com/','https://airflow.apache.org/docs/','https://www.postgresql.org/docs/current/')
c.aliases['cours']  = group('https://www.coursera.org/my-learning','https://www.coursera.org/')
for key, cmd in {',c':'cyber', ',d':'dev', ',r':'reseau', ',e':'echecs', ',s':'soc', ',n':'dataeng', ',k':'cours'}.items():
    config.bind(key, cmd)
config.bind(',h', 'open ' + start)
config.bind(',p', 'spawn --userscript qute-keepassxc --key', mode='normal')   # KeePassXC (clé à renseigner)
config.bind('<Ctrl+p>', 'tab-pin')
config.bind('J', 'tab-prev'); config.bind('K', 'tab-next')
config.bind(',b', 'config-cycle statusbar.show always never ;; config-cycle tabs.show always never')

# ── Souris ──
c.tabs.close_mouse_button = 'middle'            # clic molette sur un onglet = le fermer
c.tabs.close_mouse_button_on_bar = 'new-tab'    # clic molette sur la barre vide = nouvel onglet
c.tabs.mousewheel_switching = True              # molette sur la barre d'onglets = changer d'onglet
c.input.mouse.back_forward_buttons = True       # boutons latéraux de la souris = précédent / suivant
c.input.mouse.rocker_gestures = True            # maintenir clic droit + clic gauche = retour ; clic gauche maintenu + droit = avance
config.bind('<Ctrl+w>', 'tab-close')            # fermer l'onglet
config.bind('<Alt+Left>', 'back'); config.bind('<Alt+Right>', 'forward')
# Retour / avance aussi quand un champ de texte a le focus (mode insertion)
config.bind('<Alt+Left>', 'back', mode='insert'); config.bind('<Alt+Right>', 'forward', mode='insert')
config.bind('<Alt+Left>', 'back', mode='caret'); config.bind('<Alt+Right>', 'forward', mode='caret')
