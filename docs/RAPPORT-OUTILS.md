# Rapport d'installation — outils de travail « glass // SOC »

| | |
|---|---|
| Machine | ASUS ROG Strix G16 G614JV · i9-13980HX (32 threads) · 16 Go · Intel + RTX 4060 |
| Système | Debian GNU/Linux 13 (trixie) · noyau 6.12.115+deb13.1-amd64 · Sway (voir `RAPPORT.md`) |
| Utilisateur | `windyam_yannel` |
| Date | 2026-11-08 |
| Dépôt | `~/dotfiles` (git local, aucun push) |
| Suite de | `docs/RAPPORT.md` (poste Sway) — phases 11, 12 et 13 |

---

## 1. Vue d'ensemble

### Objectifs

1. Installer les outils de travail **réellement utiles** pour le profil : élève ingénieur Big Data & Data Science (ENSA Kénitra), futur **SOC analyst** et **data engineer**.
2. Garder les règles du poste Sway : dépôts officiels en priorité, simulation avant chaque installation (0 suppression, 0 changement de version), retour arrière possible, tout versionné dans `~/dotfiles`.
3. Intégrer chaque application au thème **glass // SOC** (verre sombre, accent sarcelle `#7dd3c0`).

### Profil retenu (sources : GitHub et portfolio)

| Indice | Besoin déduit |
|---|---|
| `ssh-sentinel` : Python 3.13, psycopg 3, pytest, PostgreSQL 16 sous `docker compose` (port 5433) | Python moderne, Docker + compose, client PostgreSQL, éditeur SQL |
| `ai-ml-projects` : notebooks Jupyter, pandas, scikit-learn | Jupyter dans VS Code, environnements par projet |
| `cybersecurity-ctf-writeups` (TeX), rapports d'école | LaTeX en français, XeLaTeX, minted, biber |
| `C_Projects` (Makefile) | gcc, gdb, valgrind |
| Portfolio Astro sur Vercel | Node.js LTS récent |
| Badges Wireshark / Kali, labs THM / HTB / OTW, Cisco CyberOps | Wireshark sans root, VM, archives 7z |
| Oracle (DBA, data engineering) | Docker (image Oracle Free le moment venu) |

> Les conversations claude.ai ne sont pas accessibles depuis le poste. Seuls le GitHub et le portfolio ont servi.

### Ce qui a été fait

| Domaine | Résultat |
|---|---|
| Paquets | 995 → **1407** paquets installés (≈ 410 ajoutés, dépendances comprises). **0 suppression, 0 changement de version.** |
| Dépôts tiers | 2, ajoutés via **extrepo** (définitions + clés maintenues par Debian) et **épinglés** : seul `code` peut venir de Microsoft, seul `virtualbox-7.2` peut venir d'Oracle. |
| Python | Python 3.13.5 (Debian) + **uv 0.13.7** (pipx) pour les projets. Jamais de `pip` global. |
| Node.js | **v26.13.0 LTS**, npm 11.20, via **fnm 1.39.0** (côté utilisateur, version suivie par projet). |
| Éditeur | **VS Code 1.145.2** + 10 extensions (17 avec leurs dépendances), réglages versionnés, télémétrie coupée, jetons dans gnome-keyring. |
| LaTeX | TeX Live 2024 ciblé (≈ 475 Mo au lieu de ≈ 6 Go pour `texlive-full`), français, XeLaTeX, minted, biber, latexmk. |
| Conteneurs | Docker 26.1.5 + compose 2.26.1, **démarrage à la demande**, ports publiés sur **127.0.0.1** par défaut. |
| SOC | Wireshark / tshark 4.4.19 avec capture sans root (groupe `wireshark`). |
| Virtualisation | **VirtualBox 7.2.22** (module DKMS chargé), cohabitation avec KVM réglée. |
| Bureau | Chromium, VLC, LibreOffice (fr), zathura, imv, KeePassXC, xarchiver, 7zip. Applications par défaut définies. |
| Thème | GTK/Qt sombres déjà en place ; palettes dédiées pour zathura, imv, VS Code, Chromium, KeePassXC. |
| Batterie | Charge **limitée à 80 %** (service systemd, réappliqué après veille). |
| Waybar | Bouton « yannel-asus // SOC » réparé ; barre du bas stabilisée (largeurs fixes). |

---

## 2. Choix et justifications

| Choix | Pourquoi | Alternative écartée |
|---|---|---|
| **uv** pour Python | Crée le `.venv`, installe et verrouille (`uv.lock`) 10 à 100 fois plus vite que pip. Compatible `requirements.txt` (ssh-sentinel). | pip + venv à la main (fonction `venv` toujours disponible), conda (lourd) |
| **fnm** pour Node.js | Le Node 20 de Debian n'est plus maintenu en amont depuis avril 2026, et Astro récent demande Node ≥ 22. fnm lit `.nvmrc` / `.node-version` / `engines` et change de version tout seul. | nodejs Debian (trop vieux), nvm (lent au démarrage du shell), dépôt NodeSource (dépôt tiers root) |
| **extrepo** pour les dépôts tiers | Définition et clé GPG maintenues et signées par Debian ; aucune clé téléchargée « à la main ». | `curl … \| gpg --dearmor` (gpg absent, clé non vérifiée) |
| **Épinglage** (`Pin-Priority: -1` sauf le paquet voulu) | Un dépôt tiers ne peut jamais remplacer un paquet Debian. | — |
| TeX Live **ciblé** | Couvre rapports, beamer, maths/sciences, français, bibliographie, code coloré. | `texlive-full` (≈ 6 Go, 90 % inutile) |
| Docker **à la demande** | `docker.socket` démarre le démon à la première commande : rien ne tourne (ni ne consomme de batterie) sinon. | démon permanent |
| Docker `"ip": "127.0.0.1"` | Docker contourne le pare-feu : sans cela, `5433:5432` exposerait PostgreSQL à tout le Wi-Fi (école, café). | ports publiés sur toutes les interfaces (défaut Docker) |
| **VirtualBox** (demandé) | Import direct des OVA (VulnHub, labs CyberOps), interface connue. | virt-manager/KVM (plus intégré à Linux, mais OVA à convertir) |
| **zathura** pour les PDF | Navigation au clavier, entièrement thémable, SyncTeX vers VS Code. | Evince (GNOME), Okular (KDE) |
| **imv** pour les images | Natif Wayland, minuscule, thémable. | Eye of GNOME, gThumb |
| **LibreOffice** (Writer, Calc, Impress) | Rapports `.docx` et présentations `.pptx` de l'école ; polices Carlito/Caladea/Liberation pour une mise en page fidèle. | OnlyOffice (hors Debian) |
| **KeePassXC** | Coffre de mots de passe local et chiffré : réflexe de base en SOC (comptes THM/HTB, VM, labs). | gestionnaire du navigateur |

---

## 3. Paquets

Toutes les listes sont dans `~/dotfiles/system/packages/` et sont installées par `apt-install.sh` (simulation d'abord, refus de toute suppression ou changement de version, `--no-install-recommends`).

### Phase 12 — `90-dev.list` (outils de travail)

| Paquet(s) | Version | Rôle |
|---|---|---|
| `code` | 1.145.2 | VS Code (dépôt Microsoft, épinglé) |
| `build-essential` `gdb` `valgrind` | 12.12 · 16.3 · 3.24.0 | C : gcc 14.2, make, débogueur, fuites mémoire |
| `python3-dev` | 3.13.5 | en-têtes pour les rares paquets Python à compiler |
| `texlive-latex-recommended` `-latex-extra` `-fonts-recommended` `-lang-french` `-xetex` `-science` `-bibtex-extra` | 2024.20250309 | LaTeX (rapports, beamer, siunitx, babel français, fontspec) |
| `biber` `latexmk` `python3-pygments` | 2.20 · 4.86 · 2.18 | bibliographie, compilation automatique, coloration `minted` |
| `sqlite3` `pgcli` | 3.46.1 · 4.3.0 | SQL en ligne de commande (pgcli : complétion, couleurs) |
| `docker.io` `docker-cli` `docker-compose` `docker-buildx` | 26.1.5 · 2.26.1 · 0.13.1 | conteneurs (`docker compose` de ssh-sentinel) |
| `wireshark` `tshark` | 4.4.19 | analyse de trafic, graphique et CLI |
| `gnome-keyring` `libsecret-tools` | 48.0 · 0.21.7 | trousseau chiffré pour VS Code (comptes GitHub) |
| `extrepo` | 0.14 | dépôts tiers maintenus par Debian |

### Phase 13 — `95-apps.list` (applications de bureau)

| Paquet(s) | Version | Rôle |
|---|---|---|
| `chromium` | 156.0.8078.79 | second navigateur (tests, profils séparés) ; Firefox ESR reste celui par défaut |
| `vlc` `vlc-plugin-pipewire` `ffmpeg` | 3.0.24 · 7.1.5 | lecture audio/vidéo, sortie PipeWire native, conversion |
| `zathura` `zathura-pdf-poppler` | 0.5.11 | lecteur PDF (défaut) |
| `imv` | 4.5.0 | visionneuse d'images (défaut) |
| `libreoffice-writer` `-calc` `-impress` `-gtk3` `-l10n-fr` `hunspell-fr` | 25.2.3 | bureautique en français, thème sombre GTK |
| `fonts-crosextra-carlito` `-caladea` `fonts-liberation2` | — | métriques Calibri / Cambria / Arial / Times |
| `7zip` `zip` `unzip` `xarchiver` `thunar-archive-plugin` | 25.01 · — · 0.5.4 | archives (clic droit « Extraire » dans Thunar) |
| `keepassxc-full` | 2.7.10 | mots de passe + intégration navigateur |
| `virtualbox-7.2` | 7.2.22 | machines virtuelles (dépôt Oracle, épinglé) |

### Côté utilisateur (sans root)

| Outil | Version | Emplacement |
|---|---|---|
| uv / uvx | 0.13.7 | `~/.local/bin` (pipx) |
| fnm | 1.39.0 | `~/.local/share/fnm`, lien `~/.local/bin/fnm` |
| Node.js / npm | 26.13.0 LTS / 11.20.0 | `~/.local/share/fnm/node-versions` |

### Extensions VS Code (`~/dotfiles/vscode/.config/Code/User/extensions.list`)

| Extension | Version | Usage |
|---|---|---|
| `ms-python.python` (+ Pylance, debugpy, envs) | 2026.10.0 | Python, détection du `.venv` créé par uv |
| `ms-toolsai.jupyter` (+ renderers, keymap…) | 2025.9.1 | notebooks |
| `charliermarsh.ruff` | 2026.94.0 | lint + formatage Python |
| `ms-vscode.cpptools` | 1.35.6 | C : IntelliSense, débogage gdb |
| `james-yu.latex-workshop` | 10.20.0 | LaTeX : latexmk, aperçu, SyncTeX |
| `ms-azuretools.vscode-containers` | 2.5.3 | Docker / compose |
| `mtxr.sqltools` + `sqltools-driver-pg` | 0.28.6 / 0.5.8 | requêtes PostgreSQL dans l'éditeur |
| `redhat.vscode-yaml` | 2.0.0 | compose, règles Sigma, CI |
| `astro-build.astro-vscode` | 2.16.20 | portfolio |

### Volontairement non installés

| Élément | Raison |
|---|---|
| `texlive-full` | ≈ 6 Go ; la sélection couvre l'usage. Un paquet manquant se trouve avec `apt-file search nom.sty`. |
| R, Java / Spark, Hadoop | aucun projet actuel ne les utilise ; à ajouter le jour où un cours les demande (Spark se lance très bien sous Docker). |
| Oracle Database, DBeaver | Oracle Free tourne sous Docker (`gvenzl/oracle-free`) ; SQLTools/pgcli couvrent PostgreSQL. |
| VirtualBox Extension Pack | licence PUEL (non libre, gratuite seulement à titre personnel/éducatif) ; utile uniquement pour USB 3 / RDP dans les VM. |
| GIMP, OBS, Discord, Teams | non nécessaires au travail ; versions web ou installation ponctuelle possibles. |
| Kali / Burp / Metasploit sur l'hôte | ces outils offensifs vont **dans une VM Kali** (VirtualBox), pas sur le poste de travail. |

---

## 4. Fichiers créés ou modifiés

### Système (root)

| Fichier | Contenu |
|---|---|
| `/etc/systemd/system/battery-charge-limit.service` | écrit `80` dans `BAT0/charge_control_end_threshold` au démarrage et après chaque veille |
| `/etc/extrepo/config.yaml` | politiques `contrib` et `non-free` autorisées |
| `/etc/apt/sources.list.d/extrepo_vscode.sources` | dépôt `packages.microsoft.com/repos/code` |
| `/etc/apt/sources.list.d/extrepo_virtualbox.sources` | dépôt `download.virtualbox.org` |
| `/etc/apt/preferences.d/vscode.pref` | épinglage : `code` seul (500), le reste `-1` |
| `/etc/apt/preferences.d/virtualbox.pref` | épinglage : `virtualbox-7.2` seul (500), le reste `-1` |
| `/etc/docker/daemon.json` | `"ip": "127.0.0.1"`, logs `json-file` 3 × 10 Mo |
| `/etc/modprobe.d/glass-soc-kvm.conf` | `options kvm enable_virt_at_load=0` |
| `/etc/chromium/policies/managed/glass-soc.json` | barre `#1c1c1e`, télémétrie coupée, pas de demande « navigateur par défaut » |
| `/var/backups/glass-soc/phase12-*` | sauvegarde de `/etc/apt` avant l'ajout des dépôts |
| groupes | `windyam_yannel` ajouté à `docker`, `wireshark`, `vboxusers` |
| services | `docker.socket` activé ; `docker.service` et `containerd.service` désactivés au démarrage |

### Dépôt `~/dotfiles`

```
~/dotfiles
├── system/
│   ├── phase11-battery-root.sh      limite de charge (défaut 80, argument 40-100)
│   ├── battery-rollback-root.sh     retour à 100 %
│   ├── phase12-devtools-root.sh     dépôt VS Code, 90-dev.list, groupes, Docker
│   ├── devtools-rollback-root.sh    annulation (simulation sans --apply)
│   ├── phase13-apps-root.sh         dépôt VirtualBox, KVM, 95-apps.list, Chromium
│   ├── apps-rollback-root.sh        annulation (simulation sans --apply)
│   └── packages/{90-dev,95-apps}.list
├── scripts/.local/bin/dev-setup     partie utilisateur (uv, fnm/Node, VS Code, défauts)
├── bash/.config/bash/35-dev.sh      fnm, uv, alias dc / dps / texw / imv
├── vscode/.config/Code/User/        settings.json + extensions.list   (nouveau paquet stow)
├── zathura/.config/zathura/zathurarc                                   (nouveau paquet stow)
├── imv/.config/imv/config                                              (nouveau paquet stow)
├── sway/.config/sway/config.d/40-rules.conf   règles imv, KeePassXC, PiP, VirtualBox
├── waybar/.config/waybar/{config.jsonc,style.css}   largeurs fixes, infobulle batterie
├── scripts/.local/bin/sysmon        correctif set -e (bouton « yannel-asus // SOC »)
└── install.sh                       STOW_PKGS += vscode zathura imv
```

### Utilisateur (hors stow)

| Fichier | Contenu |
|---|---|
| `~/.vscode/argv.json` | `"password-store": "gnome-libsecret"` |
| `~/.config/keepassxc/keepassxc.ini` | thème sombre, verrouillage après 10 min, presse-papiers vidé après 10 s (écrit une seule fois) |
| `~/.config/mimeapps.list` | applications par défaut (section 5) |

---

## 5. Thème et intégration

Le poste fixait déjà `gtk-theme-name=Adwaita-dark`, `color-scheme=prefer-dark` et `QT_STYLE_OVERRIDE=adwaita-dark` (dans `sway-launch`). La plupart des applications suivent donc le thème sans réglage.

| Application | Toolkit | Intégration glass // SOC |
|---|---|---|
| VS Code | Electron | « Default Dark Modern » + accents `#7dd3c0` (focus, curseur, badges), barre d'état `#1c1c1e`, JetBrainsMono Nerd Font, barre de titre native (Sway dessine la bordure) |
| Chromium | GTK | sombre via `prefer-dark` ; barre forcée en `#1c1c1e` par politique |
| LibreOffice | GTK 3 | `libreoffice-gtk3` → Adwaita-dark, icônes Papirus |
| VLC | Qt 5 | `adwaita-dark` via `QT_STYLE_OVERRIDE` |
| VirtualBox | Qt 6 | `adwaita-qt6` ; fenêtre du gestionnaire flottante, centrée |
| KeePassXC | Qt 5 | thème sombre interne ; fenêtre flottante, centrée |
| zathura | GTK | palette complète (fond `#1c1c1e`, barre `#2a2a2e`, recherche sarcelle, erreurs `#c07070`) ; `Ctrl+R` inverse les couleurs du PDF |
| imv | Wayland | fond `#1c1c1e`, surimpression JetBrains Mono (`i`) ; fenêtre flottante 1400×900 |
| Wireshark | Qt 6 | `adwaita-dark` |
| Picture-in-Picture (Firefox/Chromium) | — | flottante, toujours visible, en bas à droite au-dessus de la barre |

### Applications par défaut

| Type | Application |
|---|---|
| PDF | zathura |
| Images (png, jpeg, gif, webp, bmp, tiff, svg) | imv |
| Vidéo (mp4, mkv, webm, mov, avi) et audio (mp3, ogg, flac, wav, m4a, aac, opus) | VLC |
| Archives (zip, 7z, tar, gz, xz) | xarchiver |
| Web | Firefox ESR (inchangé) |
| `.docx` / `.xlsx` / `.pptx` | LibreOffice (automatique) |

Toutes les applications apparaissent dans le lanceur fuzzel (`Super+D`).

---

## 6. Utilisation au quotidien

### Nouveau projet Python (data, scripts SOC)

```bash
uv init mon-projet && cd mon-projet
uv add pandas psycopg[binary]      # crée .venv + uv.lock
uv add --dev pytest ruff ipykernel # ipykernel : notebooks dans VS Code
uv run pytest
code .                             # VS Code détecte .venv tout seul
```

### ssh-sentinel (projet existant)

```bash
git clone git@github.com:Windyam-Juste-Yannel-BELEMSIGRI/ssh-sentinel.git && cd ssh-sentinel
dc up -d                           # PostgreSQL sur 127.0.0.1:5433 (alias de docker compose)
uv venv && uv pip install -r requirements.txt
uv run python src/sentinel/load_raw.py data/raw/OpenSSH_2k.log
pgcli -h 127.0.0.1 -p 5433 -U sentinel
```

### LaTeX

- Dans VS Code : enregistrer suffit (LaTeX Workshop lance latexmk ; les fichiers auxiliaires vont dans `build/`).
- En terminal : `texw rapport.tex` (compilation continue avec XeLaTeX) puis `zathura build/rapport.pdf`. **Ctrl+clic** dans zathura ramène à la ligne source dans VS Code.
- `minted` demande `-shell-escape` (déjà prévu par LaTeX Workshop si tu l'ajoutes à la recette, sinon `latexmk -xelatex -shell-escape`).

### Node.js / portfolio

```bash
cd portfolio && echo 22 > .nvmrc   # si le projet veut une version précise
cd . && npm install && npm run dev # fnm bascule tout seul à l'entrée du dossier
```

### C

`gcc -Wall -Wextra -g main.c -o main && valgrind --leak-check=full ./main` ; débogage graphique : F5 dans VS Code (gdb).

### Wireshark

Lancer depuis fuzzel ou `wireshark`. Capture sans `sudo` (groupe `wireshark`). En CLI : `tshark -i wlo1 -f "port 22"`. Ne jamais capturer sur un réseau qui n'est pas le tien sans autorisation.

### VirtualBox (labs)

- Importer une OVA : *Fichier → Importer un appareil*.
- Réseau des VM vulnérables : **Réseau interne** ou **Host-only**, jamais « Accès par pont » (la VM serait visible sur le réseau de l'école).
- Kali : prendre l'image VirtualBox officielle de kali.org.

### KeePassXC

Créer un coffre (`~/Documents/coffre.kdbx`), mot de passe maître long. L'intégration navigateur (Firefox/Chromium) s'active dans *Paramètres → Intégration navigateur*.

### Vérifier l'état

```bash
dev-setup --check    # versions, groupes actifs, extensions VS Code
```

---

## 7. Sécurité

| Point | Choix |
|---|---|
| Groupe `docker` | **Équivalent root** : quiconque contrôle ta session peut obtenir root via Docker. Acceptable sur un portable personnel. Pour retirer ce droit : `sudo gpasswd -d windyam_yannel docker` et utiliser `sudo docker`. |
| Ports Docker | publiés sur `127.0.0.1` par défaut ; pour exposer volontairement : `"0.0.0.0:8080:80"` dans le compose. |
| Wireshark | seul `dumpcap` a les capacités de capture, et seulement pour le groupe `wireshark` ; l'interface graphique tourne sans privilège. |
| Dépôts tiers | 2 seulement, clés fournies par Debian (extrepo), épinglés sur un seul paquet chacun. |
| Secrets | jetons VS Code dans gnome-keyring (chiffré) et non en clair ; mots de passe dans KeePassXC (presse-papiers vidé après 10 s). |
| Télémétrie | coupée dans VS Code (`telemetry.telemetryLevel: off`) et Chromium (politique). |
| VS Code | la « confiance de l'espace de travail » reste active : un dépôt CTF inconnu s'ouvre en mode restreint. |
| VM | outils offensifs confinés dans des VM ; réseau interne pour les cibles vulnérables. |

---

## 8. Tests effectués

| Test | Résultat |
|---|---|
| `uv init` + `uv add pytest` + `uv run pytest --version` | pytest 9.2.0 ✔ |
| Nouveau terminal : `node -v`, `npm -v`, complétions uv/fnm | v26.13.0 · 11.20.0 ✔ |
| XeLaTeX : fontspec + babel français + minted + siunitx + biblatex | PDF généré ✔ |
| `gcc -Wall -g` + `valgrind -q` | ✔ |
| `docker run --rm hello-world` (démarrage à la demande) | « Hello from Docker! » ✔ ; logs `json-file` ✔ |
| `dumpcap -D` dans le groupe wireshark | `wlo1`, `any`, `lo` listées ✔ |
| `VBoxManage --version` ; modules `vboxdrv`, `vboxnetflt`, `vboxnetadp` | 7.2.22r175245 ✔ ; `kvm enable_virt_at_load = N` ✔ |
| `code --list-extensions` | 10 extensions demandées (17 avec dépendances) ✔ |
| `xdg-mime query default` | pdf → zathura, png → imv, mp4/mp3 → VLC, zip → xarchiver ✔ |
| `sway -C` puis `swaymsg reload` | config valide ✔ |
| shellcheck sur tous les nouveaux scripts | 0 avertissement ✔ |
| Batterie | seuil 80 ✔, service `enabled`, `Result=success` |

---

## 9. Procédures

### Réinstallation depuis zéro (après `RAPPORT.md`)

```bash
sudo ~/dotfiles/system/phase11-battery-root.sh      # 80 % (ou : … 85)
sudo ~/dotfiles/system/phase12-devtools-root.sh     # --dry-run pour simuler
sudo ~/dotfiles/system/phase13-apps-root.sh         # --dry-run pour simuler
dev-setup                                           # uv, Node, VS Code, défauts
# puis se déconnecter / reconnecter (groupes docker, wireshark, vboxusers)
```

### Mise à jour

```bash
upd && sudo apt upgrade        # Debian + code + virtualbox (DKMS reconstruit vboxdrv au changement de noyau)
pipx upgrade uv
fnm install --lts && fnm default lts-latest
code --update-extensions
```

### Retour arrière

```bash
sudo ~/dotfiles/system/apps-rollback-root.sh       # simulation ; --apply pour exécuter
sudo ~/dotfiles/system/devtools-rollback-root.sh   # simulation ; --apply pour exécuter
sudo ~/dotfiles/system/battery-rollback-root.sh    # charge jusqu'à 100 % (ex. avant un long trajet)
dev-setup --remove                                 # uv, fnm, Node
```

Les VM (`~/VirtualBox VMs`), les images Docker (`/var/lib/docker`) et les profils de navigateur sont conservés par les retours arrière.

---

## 10. Limites et points en attente

| Point | Action |
|---|---|
| Groupes `docker`, `wireshark`, `vboxusers` | actifs à la **prochaine connexion** (déconnexion de Sway ou redémarrage). D'ici là : `sg docker -c "…"`. |
| Mise à jour de sécurité du noyau (6.12.116) disponible | `sudo apt upgrade` puis redémarrage ; DKMS recompile NVIDIA et VirtualBox automatiquement. |
| Node via fnm | disponible dans les terminaux ; une application graphique qui chercherait `node` hors terminal ne le verrait pas (VS Code l'hérite de son terminal intégré). |
| Premier usage de gnome-keyring | une fenêtre demande de créer le trousseau : choisir le même mot de passe que la session. |
| `imv` en terminal | Debian ne fournit que `imv-wayland` / `imv-x11` ; l'alias `imv` pointe vers le lanceur `/usr/libexec/imv/imv`. |
| VirtualBox et VM KVM en même temps | impossible (une seule technologie peut tenir VT-x à la fois) ; chacune fonctionne seule. |
| Limite batterie | à 80 %, le portable s'affiche « branché » sans charger : comportement normal. |

---

## 11. Journal chronologique

### 2026-11-08 — Waybar : bouton « yannel-asus // SOC »
`sysmon` quittait immédiatement : la boucle GPU `[[ … ]] && cat` renvoyait 1 sur le dernier périphérique PCI et `set -e` arrêtait le script. Remplacée par un `if`. Tous les autres boutons de la barre du bas testés dans un pseudo-terminal : OK.

### 2026-11-08 — Waybar : barre qui « bouge »
Pas de redémarrage de waybar (vérifié dans le journal) ; la largeur des modules variait avec les valeurs (débit, CPU…) et décalait leurs voisins. Formats à largeur fixe + `min-width` CSS. Vérifié par captures successives.

### 2026-11-08 — Phase 11 : batterie
Firmware ASUS compatible (`charge_control_end_threshold`). Service `battery-charge-limit` : seuil 80 %, réappliqué après veille.

### 2026-11-08 — Phase 12 : outils de travail
Profil établi (GitHub, portfolio). Simulation : 244 paquets, 0 suppression. `gpg` absent → dépôt VS Code via extrepo. Partie utilisateur : uv 0.13.7, fnm 1.39.0, Node 26.13.0 LTS, 10 extensions VS Code.

### 2026-11-08 — Phase 13 : applications de bureau
VirtualBox 7.2 (Oracle via extrepo, épinglé), KVM réglé en `enable_virt_at_load=0` pour la cohabitation. Simulation : 158 paquets Debian, 0 suppression. Configs zathura / imv / KeePassXC / Chromium, règles Sway, applications par défaut. Premier lancement : `command not found` (script non exécutable) → `chmod +x`, relancé avec succès.

### 2026-11-08 — Tests et documentation
Tests de la section 8, ce rapport.
