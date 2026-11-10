#!/usr/bin/env python3
"""Génère userContent-<main|coursera>.css (fonds SVG intégrés en data: URI)."""
import urllib.parse,pathlib
here=pathlib.Path(__file__).parent
base=(here/'userContent.css').read_text()
chrome=(here/'userChrome.css').read_text()
CHOOSER='''/* ── Sélecteur de profil : carte centrée sur fond d'écran ── */
@-moz-document url-prefix("about:profilemanager"), url-prefix("chrome://browser/content/profiles/"){
  :root{
    background:
      radial-gradient(circle at 78% 50%,transparent 0,transparent 140px,rgba(125,211,192,.16) 141px,transparent 143px,transparent 260px,rgba(125,211,192,.12) 261px,transparent 263px,transparent 380px,rgba(125,211,192,.09) 381px,transparent 383px,transparent 500px,rgba(125,211,192,.06) 501px,transparent 503px),
      repeating-linear-gradient(0deg,rgba(58,58,64,.55) 0 1px,transparent 1px 48px),
      repeating-linear-gradient(90deg,rgba(58,58,64,.55) 0 1px,transparent 1px 48px),
      radial-gradient(ellipse at 50% 45%,#26302f 0,#1c1c1e 75%) !important;
    background-attachment:fixed !important;
    --background-color-canvas:transparent !important;
    --background-color-box:rgba(42,42,46,.88) !important;
    --card-background-color:rgba(42,42,46,.88) !important;
    --border-color-card:#3a3a40 !important;
    --text-color:#e8e8ec !important; --text-color-deemphasized:#a8a8ae !important;
    --color-accent-primary:#7dd3c0 !important; --focus-outline-color:#7dd3c0 !important;
    --button-background-color-hover:#3a3a40 !important; --button-text-color-hover:#7dd3c0 !important;
    --button-background-color-active:#7dd3c0 !important; --button-text-color-active:#1c1c1e !important;
  }
  html,body{min-height:100vh !important;margin:0 !important}
  body{display:flex !important;align-items:center !important;justify-content:center !important;
       font-family:"JetBrainsMono Nerd Font",monospace !important}
  profile-selector{padding:40px 56px !important;margin:auto !important;
       background:rgba(28,28,30,.74);backdrop-filter:blur(14px);
       border:1px solid #3a3a40;border-radius:16px;box-shadow:0 20px 60px rgba(0,0,0,.55)}
}
'''
def uri(n): return 'data:image/svg+xml,'+urllib.parse.quote((here/'wallpapers'/n).read_text(),safe="/:=' ")
def css(newtab):
    return base+'''
'''+CHOOSER+f'''
/* ── Nouvel onglet : fond d'écran du profil ── */
@-moz-document url("about:newtab"), url("about:home"){{
  body{{background:url("{uri(newtab)}") center/cover no-repeat fixed,
      repeating-linear-gradient(0deg,rgba(58,58,64,.5) 0 1px,transparent 1px 48px),
      repeating-linear-gradient(90deg,rgba(58,58,64,.5) 0 1px,transparent 1px 48px),
      #1c1c1e !important}}
}}
'''
for k,w in (('main','soc.svg'),('coursera','data.svg')):
    (here/f'userChrome-{k}.css').write_text(chrome+'\n'+CHOOSER)
    (here/f'userContent-{k}.css').write_text(css(w))
