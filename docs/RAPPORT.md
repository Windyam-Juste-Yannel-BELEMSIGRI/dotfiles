# Rapport d'installation — poste Sway « glass // SOC »

| | |
|---|---|
| Machine | ASUS ROG Strix G16 G614JV · i9-13980HX (32 threads) · 16 Go · iGPU Intel Raptor Lake + RTX 4060 Laptop |
| Système | Debian GNU/Linux 13 (trixie) · noyau 6.12.115+deb13.1-amd64 · dual boot Windows 11 (GRUB) |
| Utilisateur | `windyam_yannel` |
| Date | 2026-11-08 |
| Dépôt | `~/dotfiles` (git local, aucun push) |

> Suite : outils de travail, applications et batterie → [`RAPPORT-OUTILS.md`](RAPPORT-OUTILS.md)

---

## 1. Vue d'ensemble

### Objectifs

1. Reprendre le thème des dotfiles GitHub et le rendre compatible avec les versions de Debian 13.
2. En faire un poste « geek » d'analyste SOC : télémétrie, surveillance réseau et authentification, outils métier.
3. Garantir la stabilité : dépôts officiels uniquement, simulation avant chaque installation, sauvegardes, retour arrière, Sway de secours, TTY toujours disponible.

### Ce qui a été fait

| Domaine | Résultat |
|---|---|
| Paquets | 83 paquets demandés, tous issus de Debian 13 officiel (dont 12 du composant `non-free` pour NVIDIA). 420 paquets installés avec les dépendances (575 → 995). **0 suppression, 0 changement de version.** |
| Réseau | Migration de `wlo1` d'ifupdown vers **NetworkManager** avec garde-fou à retour automatique. Bascule réussie en 2 s. |
| Audio | PipeWire et WirePlumber. **Haut-parleurs internes réparés** : il manquait le firmware des amplificateurs Cirrus CS35L41, fourni par `firmware-cirrus`. |
| Énergie | power-profiles-daemon, qui pilote aussi le `platform_profile` ASUS (ventilateurs quiet / balanced / performance). |
| Session | `sway-session.target` systemd : 9 démons graphiques supervisés, avec redémarrage automatique. |
| Interface | 2 barres waybar (principale + télémétrie SOC), fuzzel, mako, swaylock avec effet, fond d'écran généré. Fenêtres toujours espacées (10 px entre elles, 16 px aux bords), gestes 3 et 4 doigts. |
| Scripts | 23 scripts Bash à l'identité commune. 35 fichiers analysés par shellcheck, **0 avertissement**. |
| Démarrage | Écran de connexion greetd + tuigreet (vt7, thème glass // SOC) qui lance `sway-launch`, avec bascule automatique sur la config de secours si la config principale est invalide. |
| NVIDIA | Pilote **550.163.01** installé (DKMS, modeset activé). Sway reste sur l'Intel, avec repli automatique. **Actif après redémarrage** (section 9). |
| GRUB / TTY | Thème GRUB « glass // SOC » (fond `#1c1c1e`, JetBrains Mono, sélection sarcelle) et TTY à la palette de foot avec Terminus Bold 16×32. `/etc/default/grub` non modifié (fichier dédié dans `grub.d`). Détails en section 5. |

### Identité visuelle

Tes dotfiles d'origine utilisaient un **verre dépoli clair** (barre flottante blanche à 20–25 % d'opacité, pastilles arrondies, bordure blanche de 1 px). foot et swaylock utilisaient, eux, une palette sombre avec un accent sarcelle. L'évolution « glass // SOC » garde la *forme* du verre (barre flottante, pastilles, bordure translucide de 1 px, transparence du terminal) et passe au **verre sombre**, avec la palette de foot partout.

| Rôle | Hex | Usage |
|---|---|---|
| Fond (`bg`) | `#1c1c1e` | fonds, terminal (alpha 0,88) |
| Surface | `#2a2a2e` | pastilles, sélection |
| Overlay | `#3a3a40` | bordures inactives |
| Texte | `#e8e8ec` | texte principal |
| Atténué | `#a8a8ae` | texte secondaire |
| **Accent** | **`#7dd3c0`** | sarcelle : focus, horloge, anneau de verrouillage |
| Accent 2 | `#8de3d0` | survol, correspondances |
| Rouge / vert / jaune / bleu / violet | `#c07070` `#8fb090` `#d8a657` `#7a9dc0` `#b090c0` | états (critique / ok / alerte / info) |

- **Polices :** *JetBrainsMono Nerd Font* (icônes), *JetBrains Mono*, *Noto Color Emoji*, et *Sans* (DejaVu) pour GTK.
- **Ambiance :** terminal « hacker » sobre, néon discret, contrastes forts, bordures fines de 2 px (accent sur la fenêtre active), transparence limitée au terminal pour garder un texte net.

---

## 2. Architecture

### Dépôt `~/dotfiles`

```
~/dotfiles
├── install.sh            déploiement complet (idempotent, --dry-run)
├── uninstall.sh          retrait de la configuration utilisateur
├── rollback.sh           retour système : status | user | network | sources | nvidia | boot | packages
├── README.md
├── .shellcheckrc         source-path=SCRIPTDIR (résolution des `source`)
├── docs/RAPPORT.md       ce document
├── docs/RAPPORT-OUTILS.md outils de travail et applications (phases 11-13)
├── system/               scripts ROOT (jamais stowés)
│   ├── apt-install.sh            installe des listes ; simulation + refus suppressions/versions
│   ├── phase1-root.sh            sauvegarde /etc/apt+/etc/network, ajoute contrib, lot 10
│   ├── phase2-network-root.sh    migration wlo1 → NetworkManager avec garde-fou
│   ├── network-rollback-root.sh  retour wlo1 → ifupdown
│   ├── phase8-nvidia-root.sh     non-free + pilote NVIDIA + modeset + initramfs
│   ├── nvidia-rollback-root.sh   retrait du pilote NVIDIA (simulation par défaut)
│   ├── phase9-boot-theme-root.sh thème GRUB glass-soc + police/palette TTY
│   ├── boot-theme-rollback-root.sh retrait du thème GRUB / TTY
│   ├── boot-theme/               theme.txt + PNG GRUB, grub.d/90-glass-soc.cfg, vt-palette.txt, issue
│   ├── phase-root.sh             lots 30/40/50/70 + réglages (PPD, groupe journal)
│   └── packages/{10-base,20-network,30-audio-power,40-theme,50-cli,70-soc-tools,80-nvidia}.list
├── sway/.config/sway/
│   ├── config                    variables, palette, includes
│   ├── config.fallback           Sway minimal de secours
│   └── config.d/{10-input-output,20-theme,30-autostart,40-rules,50-keys,60-lid}.conf
├── waybar/.config/waybar/{config.jsonc,style.css}
├── foot/  fuzzel/  mako/  swaylock/  swayidle/  kanshi/  swappy/  cava/ (+ shaders GLSL d'origine)
├── mako/.local/share/dbus-1/services/org.freedesktop.Notifications.service
├── gtk/.config/gtk-{3,4}.0/settings.ini  + .local/share/icons/default/index.theme
├── systemd-user/.config/systemd/user/
│   ├── sway-session.target
│   └── {swayidle,wlsunset,kanshi,cliphist-text,cliphist-image,polkit-agent,battery-alert}.service
├── scripts/.local/bin/           23 scripts (section 6)
├── scripts/.local/lib/soc/ui.sh  bibliothèque commune (couleurs, boîtes, barres, spinner, menus)
├── soc/.config/soc/hooks.d/ssh-sentinel.sh.example
├── bash/.bash_profile  +  bash/.config/bash/{init,10-env,20-aliases,30-tools,40-prompt,50-sitrep}.sh
├── starship/.config/starship.toml
├── tmux/.config/tmux/tmux.conf
└── nvim/.config/nvim/init.lua
```

### Emplacements sur le système

| Emplacement | Contenu | Type |
|---|---|---|
| `~/.config/{sway,waybar,foot,fuzzel,mako,swaylock,swayidle,kanshi,swappy,cava,gtk-3.0,gtk-4.0,bash,tmux,nvim,soc,systemd/user}` | configurations | liens symboliques stow vers `~/dotfiles` (fichier par fichier, `--no-folding`) |
| `~/.config/starship.toml`, `~/.bash_profile` | prompt, shell de connexion | liens stow |
| `~/.local/bin/*`, `~/.local/lib/soc/ui.sh` | scripts | liens stow |
| `~/.local/share/fonts/JetBrainsMonoNerdFont/` | police (97 fichiers) | fichiers réels |
| `~/.local/share/backgrounds/` | `glass-soc.png`, `current` → fond actif, `lock-*.png` (cache) | générés |
| `~/.local/state/setup-sway/` | `journal.md`, `baseline-20261108-185953/` (état initial) | journal / sauvegardes |
| `~/.local/state/sway/sway.log*` | journal de Sway (5 rotations) | logs |
| `~/.config-backup-20261108/` | `.bashrc.orig`, `.config/cava/` d'avant installation | sauvegardes |
| `/etc/apt/sources.list` | ajout de `contrib`, puis de `non-free` (NVIDIA) | modifié |
| `/etc/modprobe.d/nvidia-drm-setup-sway.conf` | `options nvidia-drm modeset=1 fbdev=1` | créé |
| `/etc/network/interfaces` | bloc `wlo1` commenté (`#setup-sway# …`) | modifié |
| `/etc/NetworkManager/system-connections/wifi-wlo1-migrated.nmconnection` | profil Wi-Fi (root, 600) | créé |
| `/var/backups/setup-sway/` | sauvegardes root (`/etc/apt`, `/etc/network`, script de bascule) | créé (700) |
| `/etc/group` | `windyam_yannel` ajouté à `systemd-journal` | modifié (`usermod`) |
| `/etc/default/grub.d/90-glass-soc.cfg`, `/boot/grub/themes/glass-soc/` | thème GRUB + palette TTY | créés (source : `~/dotfiles/system/boot-theme/`) |
| `/etc/default/console-setup` | police TTY Terminus Bold 16×32 | modifié |
| `/etc/issue` | écran de connexion TTY centré | remplacé (original : `/var/backups/setup-sway/issue.orig`) |

### Services

| Service | Niveau | Rôle | Activation |
|---|---|---|---|
| `sway-session.target` | user | regroupe les démons graphiques ; `BindsTo=graphical-session.target` | `exec_always systemctl --user start sway-session.target` dans Sway ; arrêt à la sortie de Sway |
| `waybar`, `mako` | user | unités Debian, rattachées via `Wants=` | cible |
| `swayidle`, `wlsunset`, `kanshi`, `cliphist-text`, `cliphist-image`, `polkit-agent`, `battery-alert` | user | unités du dépôt | cible |
| `pipewire`, `pipewire-pulse`, `wireplumber`, `xdg-desktop-portal(-wlr/-gtk)` | user | audio, portails | sockets / D-Bus (Debian) |
| `NetworkManager` | système | réseau | activé par le paquet |
| `power-profiles-daemon` | système | profils d'énergie + ventilateurs ASUS | activé par le paquet |
| `bluetooth`, `rtkit-daemon` | système | Bluetooth, priorité temps réel de l'audio | activés par les paquets |
| `networking` (ifupdown) | système | conservé pour `lo` uniquement | inchangé |

> Aucun `systemctl enable` n'a été nécessaire : la cible déclare ses services dans `Wants=`, ce qui rend l'installation reproductible.

---

## 3. Paquets

Tous les paquets viennent de `deb.debian.org` / `security.debian.org` (trixie, trixie-updates, trixie-security). Avant chaque lot, `system/apt-install.sh` lance `apt-get -s` et **s'arrête** si une ligne `Remv`/`Purg` ou un changement de version (`Inst pkg [ancienne]`) apparaît. Les installations utilisent `--no-install-recommends`.

| Paquet | Version | Rôle | Source | Justification |
|---|---|---|---|---|
| **Lot 10 — base** |||||
| git | 1:2.47.3-0+deb13u1 | versionnement des dotfiles | apt main | absent à l'origine |
| stow | 2.4.1-2 | liens symboliques des dotfiles | apt main | demandé (GNU stow) |
| shellcheck | 0.10.0-1 | validation des scripts | apt main | exigence qualité |
| jq | 1.7.1-6+deb13u4 | JSON (swaymsg, waybar-mod) | apt main | scripts |
| fuzzel | 1.12.0+ds-1 | lanceur + menus dmenu | apt main | remplace wofi (un seul lanceur) |
| swaylock | 1.8.2-1 | verrouillage | apt main | absent à l'origine |
| swayidle | 1.8.0-1 | inactivité | apt main | absent à l'origine |
| swaybg | 1.2.1-1 | fond d'écran | apt main | `output * bg` |
| grim / slurp | 1.4.0+ds-2+b1 / 1.5.0-1 | captures | apt main | absents à l'origine |
| swappy | 1.5.1-2 | annotation de captures | apt main | demandé |
| wl-clipboard | 2.2.1-2 | presse-papiers Wayland | apt main | absent à l'origine |
| cliphist | 0.5.0-1+b9 | historique du presse-papiers | apt main | demandé |
| wf-recorder | 0.5.0-2 | enregistrement d'écran | apt main | demandé |
| mako-notifier | 1.10.0-1 | notifications | apt main | un seul démon (swaync écarté) |
| libnotify-bin | 0.8.6-1 | `notify-send` | apt main | scripts / OSD |
| wlsunset | 0.3.0-1 | éclairage nocturne | apt main | natif wlroots (gammastep écarté) |
| kanshi | 1.5.1-2 | profils d'écrans (HDMI) | apt main | demandé |
| xdg-desktop-portal-wlr / -gtk | 0.7.1-2 / 1.15.3-1 | partage d'écran, boîtes de dialogue | apt main | demandé |
| mate-polkit | 1.26.1-4+b1 | agent polkit | apt main | celui du thème d'origine |
| **Lot 20 — réseau** |||||
| network-manager | 1.52.1-1 | gestion réseau (`nmcli`/`nmtui`) | apt main | demandé ; un seul gestionnaire |
| rfkill / iw | 2.41.5-0+deb13u1 / 6.9-1 | radio Wi-Fi/BT | apt main | diagnostic, bt-menu |
| blueman | 2.4.4-1 | gestionnaire Bluetooth graphique | apt main | bluetuith absent de Debian |
| **Lot 30 — audio / énergie** |||||
| pipewire-audio | 1.4.2-1 | serveur audio (+ pulse, alsa, bluetooth) | apt main | absent à l'origine |
| wireplumber | 0.5.8-2 | gestionnaire de session audio | apt main | idem |
| rtkit | 0.13-5.1 | priorité temps réel de l'audio | apt main | recommandation de PipeWire (manquait → avertissements) |
| pavucontrol | 6.1-1 | mixeur / choix de sortie | apt main | wiremix absent de Debian |
| playerctl | 2.4.1-3 | touches multimédias (MPRIS) | apt main | demandé |
| brightnessctl | 0.5.1-3.1 | lecture de la luminosité | apt main | écriture via logind (section 8) |
| power-profiles-daemon | 0.30-1.1 | profils d'énergie + ventilateurs ASUS | apt main | choisi plutôt que tlp |
| upower | 1.90.9-1 | batterie (waybar) | apt main | demandé |
| lm-sensors | 1:3.6.2-2 | capteurs (`sensors`) | apt main | télémétrie |
| cava | 0.10.4+dfsg-1 | visualiseur audio | apt main | présent dans le thème d'origine |
| firmware-cirrus | 20250410-2 | firmware des amplis CS35L41 (haut-parleurs) | apt **non-free-firmware** | haut-parleurs muets sans lui |
| **Lot 40 — thème** |||||
| papirus-icon-theme | 20250501-1 | icônes Papirus-Dark | apt main | cohérence sombre |
| gnome-themes-extra | 3.28-4 | GTK Adwaita-dark | apt main | thème GTK |
| bibata-cursor-theme | 2.0.6-1 | curseur Bibata-Modern-Classic | apt main | curseur cohérent |
| adwaita-qt / adwaita-qt6 | 1.4.2-3+b4 | style Qt sombre | apt main | thème Qt |
| qt6-wayland / qtwayland5 | 6.8.2-4 / 5.15.15-3 | Qt natif Wayland | apt main | `QT_QPA_PLATFORM=wayland` |
| fonts-noto-color-emoji | 2.051-0+deb13u1 | emojis | apt main | demandé |
| fonts-jetbrains-mono | 2.304+ds-5 | JetBrains Mono (non-Nerd) | apt main | repli |
| imagemagick | 8:7.1.1.43+dfsg1-1+deb13u14 | fond généré, effet de verrouillage | apt main | remplace swaylock-effects |
| thunar | 4.20.2-1+deb13u1 | gestionnaire de fichiers | apt main | yazi absent de Debian |
| xz-utils | 5.8.1-1+deb13u2 | extraction de la Nerd Font | apt main | install.sh |
| libglib2.0-bin | 2.84.4-3~deb13u5 | `gsettings` (thème libadwaita) | apt main | theme-apply |
| **Lot 50 — CLI** |||||
| tmux | 3.5a-3 | multiplexeur (soc-dashboard) | apt main | demandé |
| neovim | 0.10.4-8 | éditeur | apt main | demandé |
| starship | 1.22.1-5 | prompt | apt main | présent dans Debian |
| ripgrep / fd-find / bat / eza | 14.1.1 / 10.2.0 / 0.25.0 / 0.21.0 | CLI modernes | apt main | demandé |
| btop / nvtop | 1.3.2-0.1 / 3.2.0-1 | moniteurs CPU / GPU | apt main | demandé / GPU |
| fzf / zoxide | 0.60.3-1+b2 / 0.9.7-1+b1 | recherche floue, `z` | apt main | confort |
| fastfetch | 2.40.4+dfsg-1 | fiche système (sitrep) | apt main | neofetch absent de Debian 13 |
| bash-completion | 1:2.16.0-7 | complétion | apt main | confort |
| wev | 1.0.0-3 | diagnostic des touches (ASUS) | apt main | dépannage |
| **Lot 70 — outils SOC (légers)** |||||
| nmap | 7.95+dfsg-3 | scan réseau | apt main | métier |
| tcpdump | 4.99.5-2 | capture de paquets | apt main | métier |
| whois / bind9-dnsutils | 5.6.3 / 1:9.20.30-1~deb13u1 | OSINT, `dig` | apt main | métier (`dnsutils` est un paquet de transition) |
| postgresql-client | 17+278 | `psql` (ssh-sentinel) | apt main | métier |
| pipx / python3-venv | 1.7.1-1 / 3.13.5-1 | Python isolé (jamais de pip global) | apt main | règle Python |
| gh | 2.46.0-3 | CLI GitHub | apt main | métier |

Le tableau ci-dessus se termine par le lot 70. Le lot 80, ajouté avec ton accord explicite, est détaillé ici :

| Paquet | Version | Rôle | Source | Justification |
|---|---|---|---|---|
| **Lot 80 — NVIDIA** |||||
| nvidia-driver / nvidia-kernel-dkms | 550.163.01-2 | pilote propriétaire, module compilé par DKMS | apt **non-free** | pile standard Debian, la plus éprouvée (module « open » écarté) |
| firmware-nvidia-gsp | 550.163.01-2 | firmware GSP (Ada) | apt non-free | requis par le module |
| nvidia-smi | 550.163.01-2 | supervision du GPU | apt non-free | diagnostic, gpu-check |
| nvidia-suspend-common | 550.163.01-2 | services suspend/resume NVIDIA | apt non-free | mise en veille fiable |
| libnvidia-egl-gbm1 / libnvidia-egl-wayland1 / libnvidia-allocator1 | 1.1.2.1-1 / 1:1.1.18-1 / 550.163.01-2 | GBM / EGL Wayland | apt main / non-free | wlroots multi-GPU (sorties HDMI/DP de la dGPU) |
| nvidia-vulkan-icd | 550.163.01-2 | Vulkan | apt non-free | applis GPU |
| libcuda1 / libnvidia-encode1 | 550.163.01-2 | CUDA, NVENC | apt non-free | calcul, encodage |
| linux-headers-amd64 | 6.12.115-2 | headers du noyau | apt main | compilation DKMS |

Dépendances notables : `dkms`, `gcc-14`, `xserver-xorg-core` + `xserver-xorg-video-nvidia` (serveur X tiré par `nvidia-driver`, **inutilisé** sous Sway, sans risque). `nvidia-persistenced` n'est **pas** installé : il garderait le GPU éveillé et viderait la batterie. `nvidia-cuda-toolkit` (compilateur nvcc, environ 4 Go) n'est pas installé : il est disponible avec `sudo apt install nvidia-cuda-toolkit` si tu compiles du CUDA. Pour PyTorch et équivalents, un venv avec les roues CUDA suffit, car elles embarquent leur runtime.

**Hors apt :** JetBrainsMono Nerd Font v3.5.1, depuis la release officielle `ryanoasis/nerd-fonts`. SHA-256 vérifié contre `SHA-256.txt` : `04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf`.

### Retirés, remplacés ou refusés

| Élément d'origine / demandé | Statut | Raison | Remplacement |
|---|---|---|---|
| SwayFX (`blur`, `shadows`, `corner_radius`, `layer_effects`, `default_dim_inactive`) | retiré | absent de Debian ; ces options font échouer `sway -C` avec Sway 1.10.1 | Sway officiel + `opacity` / alpha de foot |
| swaylock-effects (`--effect-blur`, `--clock`, `--effect-vignette`) | remplacé | absent de Debian | swaylock 1.8.2 + image précalculée par `lock-glitch` |
| wofi | remplacé | un seul lanceur ; wofi est peu maintenu | fuzzel 1.12 (style wofi transposé) |
| wlogout | remplacé | doublon de fonction | `power-menu` (fuzzel) |
| nm-applet / blueman-applet (autostart) | non lancés | doublons des modules waybar | `wifi-menu`, `bt-menu`, `nmtui`, `blueman-manager` |
| wiremix, bluetuith, yazi, swaync, asusctl, neofetch | absents de Debian 13 | — | pavucontrol, blueman + bt-menu, thunar, mako, PPD + sysfs, fastfetch |
| tlp | non installé | conflit avec power-profiles-daemon | PPD |
| gammastep | non installé | un seul outil d'éclairage nocturne | wlsunset |
| `restart` (Sway) | retiré | commande i3, inexistante dans Sway | `reload` (Super+Shift+C) |
| Wireshark, Docker | **non installés** | lourds ; nécessitent ton accord explicite | — (voir section 13) |
| `mahoraga.png` | absent du dépôt | image non fournie (et soumise à des droits) | fond généré ; ton image est prioritaire si tu la déposes dans `~/Pictures/wallpaper/` |

---

## 4. Fichiers créés ou modifiés

### Fichiers système (`/etc`, root)

| Chemin | Rôle | Changement | Sauvegarde |
|---|---|---|---|
| `/etc/apt/sources.list` | dépôts | `contrib` ajouté sur les 6 lignes (deb et deb-src), puis `non-free` (NVIDIA) | `/var/backups/setup-sway/20261108-190*/etc-apt-network.tar.gz` + `~/.local/state/setup-sway/baseline-*/etc-apt.tar.gz` |
| `/etc/network/interfaces` | ifupdown | bloc `allow-hotplug wlo1` / `iface wlo1` commenté (`#setup-sway# `) | `/var/backups/setup-sway/20261108-192422-network/interfaces.orig` |
| `/etc/NetworkManager/system-connections/wifi-wlo1-migrated.nmconnection` | profil Wi-Fi | créé (root:root 600, PSK reprise sans affichage) | — (supprimable) |
| `/etc/modprobe.d/nvidia-drm-setup-sway.conf` | KMS NVIDIA | créé : `options nvidia-drm modeset=1 fbdev=1` | `/var/backups/setup-sway/*-nvidia/etc-apt-modprobe.tar.gz` ; retrait via `rollback.sh nvidia` |
| `/etc/default/grub.d/90-glass-soc.cfg` | GRUB | créé : `GRUB_THEME`, `GRUB_GFXMODE=2560x1600x32,auto`, `GRUB_TERMINAL_OUTPUT=gfxterm`, palette `vt.default_red/grn/blu` ajoutée à la ligne noyau | `/var/backups/setup-sway/20261108-204117-boot-theme/` ; retrait via `rollback.sh boot` |
| `/boot/grub/themes/glass-soc/` | thème GRUB | créé : `theme.txt`, 18 PNG (cadre du menu, sélection), 4 polices `.pf2` générées depuis JetBrains Mono | supprimé par `rollback.sh boot` |
| `/boot/grub/grub.cfg` | menu GRUB | régénéré par `update-grub` (après `grub-script-check` sur une copie) | `/var/backups/setup-sway/20261108-204117-boot-theme/grub.cfg.orig` |
| `/etc/default/console-setup` | police des TTY | `FONTFACE="Fixed"` → `"TerminusBold"`, `FONTSIZE="8x16"` → `"16x32"` | `/var/backups/setup-sway/20261108-204117-boot-theme/etc-default.tar.gz` |
| `/etc/issue` | bannière de connexion TTY | remplacé par une version centrée (séquences ANSI) | `/var/backups/setup-sway/issue.orig` ; restauré par `rollback.sh boot` |
| `/etc/group` | groupes | `systemd-journal` += `windyam_yannel` | `sudo gpasswd -d windyam_yannel systemd-journal` pour annuler |
| `/boot/initrd.img-6.12.115+deb13.1-amd64` | initramfs | régénéré par Debian (trigger fuse3), puis par l'installation NVIDIA (liste noire de nouveau + modeset), puis après le changement de police console | régénérable : `sudo update-initramfs -u` |
| `/lib/modules/6.12.115+deb13.1-amd64/updates/dkms/nvidia-current*.ko.xz` | modules NVIDIA | construits par DKMS | retirés par `rollback.sh nvidia` |

Ni l'EFI, ni `/etc/fstab`, ni les partitions, ni Windows n'ont été touchés. `/etc/default/grub` est intact : le thème GRUB passe par un fichier dédié dans `/etc/default/grub.d/` et seul `grub.cfg` a été régénéré (20:41) ; l'entrée Windows Boot Manager y est toujours détectée.

### Fichiers utilisateur

| Chemin | Rôle | Changement | Sauvegarde |
|---|---|---|---|
| `~/.bashrc` | shell interactif | +1 ligne : `[ -r ~/.config/bash/init.sh ] && . … # dotfiles glass-soc` | `~/.config-backup-20261108/.bashrc.orig` |
| `~/.bash_profile` | shell de connexion | créé (lien stow) ; source `~/.profile` (le démarrage de Sway est passé à greetd) | n'existait pas |
| `~/.config/cava/` | cava | remplacé par le paquet stow `cava` | `~/.config-backup-20261108/.config/cava/` |
| `~/.config/**`, `~/.local/bin/**` | toute la configuration | liens stow créés (aucun fichier existant écrasé) | — |
| `~/.local/share/dbus-1/services/org.freedesktop.Notifications.service` | activation D-Bus de mako | créé (lien) | — |
| `~/.local/share/fonts/JetBrainsMonoNerdFont/` | police | créé | — |
| `~/.local/share/backgrounds/` | fonds | créé | — |
| `~/Pictures/{wallpaper,Screenshots}`, `~/Videos/Recordings` | dossiers | créés | — |

---

## 5. Explication des configurations

### Sway (`~/.config/sway/`)

- `config` définit les variables (`$mod`=Super, `$term`=foot, `$menu`=fuzzel, `$bin`=~/.local/bin) et la palette. Il inclut ensuite `/etc/sway/config.d/*`, qui importe `WAYLAND_DISPLAY`, `SWAYSOCK`, etc. dans systemd et D-Bus. Viennent ensuite `config.d/*.conf`, puis `local.d/*.conf` (non versionné).
- **`10-input-output.conf`** : clavier `us` (QWERTY), répétition 300 ms / 40 Hz, pavé tactile (tap, défilement naturel, désactivé pendant la frappe), fond `~/.local/share/backgrounds/current`, `adaptive_sync` sur eDP-1, curseur Bibata 24.
- **`20-theme.conf`** : bordures de 2 px (accent sarcelle sur la fenêtre focalisée). **Gaps permanents** : `gaps inner 10` et `gaps outer 6` (soit 16 px aux bords), `smart_gaps off`, `hide_edge_borders none`. Les fenêtres ne se touchent jamais et ne collent pas aux bords, sauf en plein écran. Comme `gaps` ne vaut que pour les espaces créés ensuite, un `exec_always swaymsg "gaps inner all set 10"` les applique aussi aux espaces existants à chaque rechargement.
- **`30-autostart.conf`** : démarre `sway-session.target`. Abonnement à l'événement `shutdown` pour l'arrêter proprement, puis `theme-apply` (gsettings).
- **`40-rules.conf`** : fenêtres flottantes (pavucontrol, blueman, polkit, sudo-askpass, swappy, cava, dialogues), `inhibit_idle fullscreen`, étiquette `[X]` pour les fenêtres XWayland, `soc-dashboard` envoyé sur l'espace 9.
- **`50-keys.conf`** : tous les raccourcis (section 7). Une ligne `#? description` placée au-dessus d'un `bindsym` sert de libellé à `keys-help`. Sway n'accepte pas les commentaires en fin de ligne.
- **`60-lid.conf`** : capot fermé → eDP-1 désactivé, réactivé à l'ouverture. Sans écran externe, logind gère la mise en veille.

**Personnaliser :** crée `~/.config/sway/local.d/99-perso.conf`, par exemple `output eDP-1 scale 1.25` (l'écran est en 2560×1600 à l'échelle 1, donc le texte est petit), puis Super+Shift+C.

### Waybar (`~/.config/waybar/`)

Deux barres sont définies dans un seul processus (`[ {main}, {telemetry} ]`). La classe CSS de chaque barre vient de son `name`.

- **main (haut)** :
  - à gauche : logo (clic → soc-dashboard, clic droit → sitrep), espaces de travail (○ ● !, symboles du thème d'origine), mode, scratchpad, titre de la fenêtre ;
  - au centre : heure locale (clic → date ; survol → calendrier) et **heure UTC** (corrélation des logs) ;
  - à droite : ● REC, mpris, volume (wireplumber), luminosité, Wi-Fi (SSID, signal ; survol → IP, passerelle, débit ; clic → wifi-menu ; clic droit → nmtui), VPN, Bluetooth (nombre d'appareils), profil d'énergie, batterie, anti-veille, ne pas déranger, tray, alimentation.
- **telemetry (bas)** : hôte, CPU (et charge), RAM, température du CPU (coretemp), GPU NVIDIA (`zz` quand il est en veille : **lu sans le réveiller**), ventilateurs ASUS, disque, débit ↓↑, connexions TCP établies, IP locale, **IP publique masquée** (clic → afficher), échecs SSH sur 24 h, unités systemd en échec (système et utilisateur).
- Les modules personnalisés appellent `~/.local/bin/waybar-mod <module>`, qui renvoie du JSON (texte, infobulle, classe CSS). Le signal `RTMIN+8` force le rafraîchissement : `pkill -RTMIN+8 waybar`.
- `style.css` : `@define-color` de la palette, `alpha()` pour le verre, pastilles avec un rayon de 10 px, une classe CSS par état (`.critical`, `.warning`, `.recording`…).
- **Recharger :** `systemctl --user reload waybar`.

### foot (`~/.config/foot/foot.ini`)

C'est la palette d'origine, conservée à l'identique. Ajouts : la Nerd Font, `alpha=0.88`, le curseur sarcelle, un historique de 20 000 lignes, Ctrl+Shift+O pour ouvrir une URL et Ctrl+Shift+F pour rechercher. `dpi-aware=yes` est conservé (choix d'origine). Sur ce panneau à 189 dpi, la police apparaît donc grande. Si tu veux plus de colonnes, réduis `size` ou passe `dpi-aware=no`.

### fuzzel (`~/.config/fuzzel/fuzzel.ini`)

Style wofi d'origine transposé : centré, bordure de 1 px sarcelle à 50 %, rayon 12, fond `#1c1c1e` à 94 %, correspondances fzf, icônes Papirus-Dark. Avec **`exit-on-keyboard-focus-loss=no`**, le menu ne se ferme plus quand le curseur passe sur une fenêtre (avec `focus_follows_mouse`, Sway lui retirait le focus clavier). Il se ferme par Échap, par une sélection (Entrée, clic ou tap) ou par un **second clic sur le même bouton waybar** (fonction `menu` de ui.sh). En mode `--dmenu`, il sert aussi aux scripts. Les colonnes sont séparées par une tabulation (`--with-nth=1 --accept-nth=2`).

### mako (`~/.config/mako/config`)

Notifications en haut à droite, verre sombre, regroupées par application, 50 dans l'historique. L'application `osd` (volume, luminosité…) s'affiche **en bas au centre**, avec une jauge, remplacée sur place. Mode `do-not-disturb` : tout est masqué sauf l'urgence `critical`. Une surcharge D-Bus force l'activation par `mako.service` (section 13).

### swaylock / swayidle / lock-glitch

- `swaylock/config` : anneau sarcelle de rayon 100, état Verr. Maj en jaune, erreur en rouge, `ignore-empty-password`, nombre de tentatives affiché.
- `swayidle/config` : verrouillage à **5 min**, écrans éteints à **10 min**, verrouillage avant la veille (`before-sleep`) et sur `loginctl lock-session`.
- `lock-glitch` génère, à partir du fond, une image « glitch » : décalage des canaux R/B, bandes déplacées, scanlines, bandeau `LOCKED // hôte // utilisateur`. Elle est **mise en cache** : la première génération prend environ 6 s, ensuite le verrouillage est instantané. Avant une mise en veille, si le cache est absent, le verrouillage se fait immédiatement en couleur unie.

### tmux (`~/.config/tmux/tmux.conf`)

- Préfixe **Ctrl+a** (Ctrl+b conservé). Souris, mode vi, base 1, `|` et `-` pour découper, `hjkl` pour naviguer, `HJKL` pour redimensionner, `r` pour recharger.
- Copie vi vers `wl-copy`. Barre de statut thémée : session, hôte, heure locale et **UTC**. Titres de panneaux en bordure.

### Shell (bash + starship)

- `~/.bash_profile` source `~/.profile` (celui de Debian charge `~/.bashrc` et ajoute `~/.local/bin`). Sway est lancé par greetd, plus par ce fichier.
- `~/.bashrc` (Debian) + `~/.config/bash/init.sh`, qui charge `10-env` (PATH, historique de 50 000 entrées horodatées, `HISTCONTROL=ignoreboth` : une commande précédée d'une espace n'est pas enregistrée, couleurs fzf), `20-aliases`, `30-tools` (bash-completion, fzf Ctrl+R / Ctrl+T / Alt+C, zoxide, `venv`, `mkcd`, `extract`), `40-prompt` (starship, ou un prompt maison s'il est absent) et `50-sitrep`.
- **Alias :** sous Debian, `fd` s'appelle `fdfind` et `bat` s'appelle `batcat`, d'où des alias. `ls`/`ll`/`la`/`lt` utilisent eza. `ports`, `conns`, `lip`, `myip`, `authlog`, `sshfails`, `failed`, `jerr`, `upd`, `swaycheck`, `keys`, `dots`.
- **starship :** deux lignes `╭─`/`╰─`, dossier, git, venv Python, durée des commandes > 2 s, code de retour, heure à droite. Hôte en rouge **uniquement en SSH**.
- Surcharges locales : `~/.config/bash/local.sh` (non versionné), par exemple `export SITREP=0`.

### Neovim (`~/.config/nvim/init.lua`)

Configuration légère **sans gestionnaire de plugins** (aucun téléchargement) : numéros relatifs, presse-papiers système, `undofile`, palette appliquée au thème intégré `habamax` avec un fond transparent, leader = Espace, `*.log` / `auth.log` colorés en syslog.

### GTK / Qt

GTK 3/4 : `settings.ini` (Adwaita-dark, Papirus-Dark, Bibata) + `gsettings` (`color-scheme prefer-dark`, lu par libadwaita via le portail). Qt : `QT_STYLE_OVERRIDE=adwaita-dark`, `QT_QPA_PLATFORM=wayland;xcb` (exportés par `sway-launch`).

### kanshi

Profil `portable` (eDP-1 seul) et profil `hdmi` (externe à droite). Le nom exact de la sortie externe se lit avec `swaymsg -t get_outputs` une fois l'écran branché. Ensuite : `systemctl --user restart kanshi`.

### GRUB et TTY (`~/dotfiles/system/boot-theme/`)

Installés par `sudo system/phase9-boot-theme-root.sh` (accepte `--dry-run`), retirés par `./rollback.sh boot`.

**GRUB** (thème `glass-soc`, sources dans `system/boot-theme/grub/glass-soc/`) :

| Élément | Rendu |
|---|---|
| Fond | uni `#1c1c1e` (pas d'image) |
| Composition | **centrée** : titre à 26 % de la hauteur, menu sur 32→68 % en largeur et 37→61 % en hauteur, compte à rebours à 64 %, aide à 90 % |
| Titre | « glass // SOC » en JetBrains Mono Bold 48, sarcelle `#7dd3c0`, sous-titre « sélection du système » en `#a8a8ae`, centrés |
| Menu | panneau `#222225` bordé de 2 px `#3a3a40` (le verre sombre de waybar), entrées en JetBrains Mono 32 `#a8a8ae`. Le panneau est centré à l'écran ; le texte des entrées reste aligné à gauche **dans** le panneau, car GRUB n'a pas d'option pour centrer le texte d'une entrée |
| Entrée sélectionnée | fond `#2a2a2e` + barre d'accent de 6 px à gauche, texte gras sarcelle (comme la fenêtre active dans Sway) |
| Compte à rebours | barre de 6 px sarcelle sur `#2a2a2e` + « démarrage automatique dans N s » |
| Aide | rappel des touches en bas, en `#4a4a50` |

- Polices : `grub-mkfont` convertit JetBrains Mono (paquet `fonts-jetbrains-mono`) en `.pf2` à l'installation, limitées au latin, aux flèches et aux caractères de dessin de cadres. Noms GRUB : `JetBrains Mono Regular 24/32`, `JetBrains Mono Bold 32/48`.
- Mise en page en pourcentages : si le firmware n'accepte pas 2560×1600, GRUB prend le mode `auto` et le thème reste centré (avec un texte plus gros).
- Sécurité : le script génère `grub.cfg` dans un fichier temporaire, le valide (`grub-script-check`, présence du thème et de la palette) et **s'arrête en retirant sa config** si un contrôle échoue ; c'est seulement ensuite qu'il lance `update-grub`. Un thème défectueux ne bloque jamais le démarrage : GRUB revient au menu texte. Secure Boot est désactivé, donc il n'y a pas de contrainte de signature.

**TTY :**

- **Couleurs :** les 16 couleurs de la console sont exactement celles de foot (`regular0-7`, `bright0-7`). Elles passent par les paramètres noyau `vt.default_red/grn/blu`, donc dès le démarrage. Elles sont aussi appliquées tout de suite aux TTY ouverts avec `setvtrgb` (`system/boot-theme/vt-palette.txt`).
- **Police :** la console n'affiche que des polices bitmap PSF, donc JetBrains Mono ne peut pas y être utilisée. La plus proche est **Terminus Bold 16×32** (`Lat15-TerminusBold32x16`), lisible en 2560×1600 (160 colonnes × 50 lignes). Elle est réglée dans `/etc/default/console-setup` et l'initramfs est régénéré.
- **Écran de connexion centré** (`/etc/issue`, source `system/boot-theme/issue`) : agetty affiche ce fichier avant l'invite. Il efface l'écran puis place, par des séquences ANSI de position, « glass // SOC » en sarcelle (rangée 21), « Debian GNU/Linux 13 · ttyN » (rangée 23), un filet `─` (rangée 24), puis l'invite `yannel-asus login:` au centre (rangée 27, colonne 71). Les positions sont calculées pour une grille de 160×50 (Terminus 16×32 sur 2560×1600). Le fichier n'a pas de saut de ligne final, sinon l'invite repartirait à gauche. L'original est dans `/var/backups/setup-sway/issue.orig`.
- **Limite :** une console Linux est une grille de caractères qui commence en haut à gauche. Seul l'écran de connexion peut être centré. `Password:` (affiché par `login`) apparaît à gauche de la ligne suivante, et après la connexion le shell s'affiche normalement, depuis le haut à gauche. (Remplacé depuis par greetd + tuigreet, voir plus bas.)
- Plymouth (écran de démarrage graphique) n'a volontairement pas été installé.

---

## 6. Scripts (`~/.local/bin`)

Tous les scripts suivent les mêmes conventions : `#!/usr/bin/env bash`, `set -euo pipefail`, un en-tête encadré qui sert d'aide (`-h`), une vérification des dépendances (`need`), la bibliothèque `~/.local/lib/soc/ui.sh` (couleurs de la palette en ANSI 24 bits, désactivées si la sortie n'est pas un terminal ou si `NO_COLOR` est défini ; boîtes `╭─╮`, `section`, `bar` ▰▱ colorée selon des seuils, `spinner`, `menu` fuzzel, `notify`). Tous sont validés par shellcheck.

| Script | Usage | Fonctionnement interne | Dépendances |
|---|---|---|---|
| `wifi-menu` | `wifi-menu` · `--list` | `nmcli -t -e yes` → réseaux dédoublonnés (le réseau en cours d'utilisation d'abord) et triés par signal ; profil connu → `con up` ; sinon mot de passe saisi dans `fuzzel --password` et **passé par stdin** à `nmcli --ask` (jamais en argument, donc invisible dans `ps`) | nmcli, fuzzel |
| `bt-menu` | `bt-menu` · `--status` | `bluetoothctl` : allumer/éteindre, scan de 10 s, appairage + trust + connexion, connecter/déconnecter, oublier ; `rfkill unblock` si besoin | bluetoothctl, fuzzel, rfkill |
| `power-menu` | `power-menu` | verrouiller, quitter Sway, veille, redémarrer, éteindre ; **confirmation** pour les actions destructives ; uptime dans l'invite | fuzzel, systemctl |
| `screenshot-menu` | `screenshot-menu [region-copy\|region-save\|region-edit\|full-save\|full-copy\|window-save\|record-toggle\|record-full]` | grim/slurp/swappy ; wf-recorder lancé avec `setsid`, arrêté par SIGINT, avec indicateur waybar ● REC | grim, slurp, swappy, wf-recorder, jq |
| `clip-menu` | `clip-menu [pick\|delete\|wipe]` | `cliphist list → fuzzel → decode → wl-copy` ; suppression d'une entrée (utile après avoir copié un secret) | cliphist, wl-copy |
| `osd` | `osd volume-up\|…\|kbd-down` | volume via `wpctl` ; **luminosité via logind** (`busctl … Session SetBrightness`), sans root ni règle udev ; notification remplacée sur place (`notify-send -p/-r`) avec une jauge | wpctl, busctl, notify-send |
| `power-profile` | `power-profile [get\|cycle\|power-saver\|balanced\|performance]` | `powerprofilesctl` ; affiche le `platform_profile` ASUS obtenu (quiet/balanced/performance) | powerprofilesctl |
| `nightlight` | `nightlight [toggle\|on\|off\|status]` | démarre/arrête `wlsunset.service` | systemctl |
| `dnd-toggle` | `dnd-toggle` | `makoctl mode -t do-not-disturb` + rafraîchissement de waybar | makoctl |
| `keys-help` | `keys-help` · `--print` | analyse `50-keys.conf` (`#?` + `bindsym`) ; dans fuzzel, Entrée **exécute** le raccourci choisi | awk, fuzzel, swaymsg |
| `set-wallpaper` | `set-wallpaper [apply\|next\|gen\|list\|FICHIER]` | images de `~/Pictures/wallpaper/` en priorité ; `gen` produit un fond avec ImageMagick (dégradé radial, grille de 48 px à 5 %, points néon, liseré sarcelle, signature) à la résolution de l'écran ; recalcule le cache du verrouillage | magick, swaymsg, jq |
| `lock-glitch` | `lock-glitch [--now] [--screen] [--plain] [--preview F]` | voir section 5 ; `--screen` pixelise l'écran à 2 % (désactivé par défaut pour ne rien laisser fuiter) | swaylock, magick, grim |
| `sysmon` | `sysmon [-n S] [--once]` | /proc/stat (delta CPU), meminfo, loadavg, hwmon coretemp/asus, batterie, profil, état du GPU, débit de l'interface par défaut, top 5 des processus ; touche `q` pour quitter | ps, ip, ss |
| `netwatch` | `netwatch [-n S] [--once]` | débit par interface (/sys/class/net), états TCP, ports en écoute (avec processus), connexions établies, top des IP distantes | ss, ip |
| `soc-dashboard` | `soc-dashboard [auth\|alerts\|alerts-once\|ports\|procs\|kill]` | session tmux `soc` à 4 panneaux (identifiants `%N`, indépendants de `pane-base-index`) : **auth** = `journalctl -f` sur sshd, sudo, su, login, polkit, logind (échecs en rouge, sessions et commandes en jaune) ; **alerts** = synthèse sur 24 h (échecs SSH + top des IP sources, échecs sudo/su, **nouveaux ports par rapport à une référence**, unités en échec, erreurs noyau, hooks) ; **ports** ; **procs** | tmux, journalctl, ss |
| `sitrep` | `sitrep [--short]` | bannière + fastfetch compact + points de vigilance : mises à jour (dont sécurité), unités en échec, services exposés, échecs d'authentification, dernière connexion, disque, batterie, VPN. **< 0,3 s, aucune requête réseau.** Une fois par session TTY et une fois sous Sway | fastfetch, apt, ss, journalctl |
| `waybar-mod` | `waybar-mod <gpu\|fans\|conns\|ip-local\|ip-public\|vpn\|rec\|dnd\|ssh-fails>` | modules JSON pour waybar (section 5) ; IP publique via api.ipify.org au plus toutes les 10 min, désactivable avec `touch ~/.config/soc/no-public-ip` | jq, ss, nmcli, curl |
| `battery-alert` | `battery-alert [--once\|--daemon]` | toutes les 60 s : alerte à 20 %, critique à 10 %, notification au branchement/débranchement | notify-send |
| `theme-apply` | `theme-apply` | gsettings (thème sombre, icônes, curseur, polices) | gsettings |
| `sway-launch` | `sway-launch [--fallback] [--check]` | exporte l'environnement Wayland (Firefox, Qt, SDL, Java, Electron, curseur) ; `WLR_DRM_DEVICES=intel:nvidia` (résolution par vendor PCI, car les chemins by-path contiennent des `:`) ; bascule sur la config de secours si `use-fallback` existe ou si `sway -C` échoue ; **relance sur l'Intel seul si Sway plante en moins de 15 s en multi-GPU** (log conservé dans `sway.multigpu-fail.log`) ; logs en rotation | sway |
| `ws-switch` | `ws-switch next\|prev [--move]` | espace numéro ±1 (1↔10, y compris les espaces vides), contrairement à `workspace next_on_output` qui saute les espaces vides | swaymsg, jq |
| `gpu-check` | `gpu-check` | pilote chargé (nvidia et non nouveau), `modeset`, état RTD3, `nvidia-smi`, pilotes des cartes DRM, `WLR_DRM_DEVICES` effectif de Sway, sorties, repli iGPU déclenché ou non, erreurs dans sway.log | nvidia-smi, swaymsg, jq |
| `sudo-askpass` | `SUDO_ASKPASS=… sudo -A …` | petite fenêtre foot qui lit le mot de passe sans écho et le transmet par un FIFO 600 dans `$XDG_RUNTIME_DIR` ; rien n'est écrit sur disque | foot |

**Point d'extension ssh-sentinel :**

```bash
cd ~/.config/soc/hooks.d
cp ssh-sentinel.sh.example ssh-sentinel.sh && chmod +x ssh-sentinel.sh
# connexion via ~/.pg_service.conf [ssh-sentinel] + ~/.pgpass (chmod 600) — aucun secret dans le script
```

Chaque exécutable de `hooks.d/` est appelé (avec un délai maximal de 20 s) par le panneau **alerts**, et sa sortie y est affichée. Adapte la requête SQL de l'exemple (`auth_events`, `src_ip`, `outcome`) au schéma réel de ssh-sentinel.

**Exemple de sortie (`sitrep --short`) :**

```
  [✔] système à jour (selon le dernier apt update)
  [✔] aucune unité systemd en échec
  [✔] aucun service exposé hors loopback
  [✔] aucun échec d'authentification sur 24 h
```

**Exemple de sortie (`soc-dashboard alerts-once`) :**

```
── SSH ──────────────────────────────
  serveur SSH inactif / non installé (surface d'attaque réduite)
── SUDO / SU ────────────────────────
  échecs d'élévation : 0
  commandes sudo     : 16
── PORTS EN ÉCOUTE (écart avec la référence)
[✔] aucun nouveau port (3 en écoute)
── SYSTÈME ──────────────────────────
  unités en échec : 0
  erreurs noyau   : 107 (prio ≤ err, -24h)
```

---

## 7. Raccourcis clavier (QWERTY US, `Super` = touche Windows)

Cette liste est générée à partir de `50-keys.conf`. Elle est aussi consultable avec **Super+F1** ou `keys-help --print`.

| Touche | Action |
|---|---|
| `Super+Return` | terminal |
| `Super+Shift+Return` | terminal flottant |
| `Super+d` | lanceur d'applications |
| `Super+Shift+q` | fermer la fenêtre |
| `Super+Shift+c` | recharger sway |
| `Super+F1` | aide raccourcis |
| `Super+o` | gestionnaire de fichiers |
| `Super+Shift+e` | menu alimentation |
| `Super+Escape` | menu alimentation |
| `Super+Ctrl+l` | verrouiller |
| `Super+Shift+n` | menu Wi-Fi |
| `Super+Shift+b` | menu Bluetooth |
| `Super+Shift+a` | mixeur audio |
| `Super+v` | historique presse-papiers |
| `Super+Shift+v` | visualiseur audio cava |
| `Super+n` | fermer la notification |
| `Super+Ctrl+n` | fermer toutes les notifications |
| `Super+Alt+n` | rappeler la dernière notification |
| `Super+Shift+m` | ne pas déranger on/off |
| `Print` | menu capture |
| `Shift+Print` | zone → presse-papiers |
| `Super+Print` | écran → fichier |
| `Super+Shift+s` | zone → swappy |
| `Super+Shift+r` | enregistrement écran on/off |
| `Super+x` | tableau de bord SOC (tmux) |
| `Super+i` | sysmon |
| `Super+Shift+i` | netwatch |
| `Super+Shift+t` | btop |
| `Super+p` | profil énergie/ventilo suivant |
| `Super+Shift+z` | éclairage nocturne on/off |
| `Super+Shift+w` | fond d'écran suivant |
| `XF86AudioRaiseVolume` | volume + |
| `XF86AudioLowerVolume` | volume - |
| `XF86AudioMute` | muet |
| `XF86AudioMicMute` | micro muet |
| `XF86MonBrightnessUp` | luminosité + |
| `XF86MonBrightnessDown` | luminosité - |
| `XF86KbdBrightnessUp` | rétro-éclairage clavier + |
| `XF86KbdBrightnessDown` | rétro-éclairage clavier - |
| `XF86AudioPlay` | lecture/pause |
| `XF86AudioPause` | lecture/pause |
| `XF86AudioNext` | piste suivante |
| `XF86AudioPrev` | piste précédente |
| `XF86TouchpadToggle` | pavé tactile on/off |
| `XF86Launch4` | (ASUS) profil suivant |
| `XF86Launch1` | (ASUS) profil suivant |
| `Super+Tab` | espace précédent |
| `Super+Ctrl+Right` | espace suivant |
| `Super+Ctrl+Left` | espace précédent |
| `Super+b` | découpe horizontale |
| `Super+g` | découpe verticale |
| `Super+s` | disposition empilée |
| `Super+w` | disposition onglets |
| `Super+e` | alterner découpe |
| `Super+f` | plein écran |
| `Super+Shift+space` | flottant on/off |
| `Super+space` | focus tuilé/flottant |
| `Super+a` | focus parent |
| `Super+Shift+minus` | envoyer au scratchpad |
| `Super+minus` | afficher le scratchpad |
| `Super+r` | mode redimensionnement |
| `Super+Shift+p` | mode passthrough on/off |
| `Super+h/j/k/l` ou flèches | focus gauche / bas / haut / droite |
| `Super+Shift+h/j/k/l` ou flèches | déplacer la fenêtre |
| `Super+1…9`, `Super+0` | espace de travail 1…9, 10 |
| `Super+Shift+1…0` | envoyer la fenêtre sur l'espace 1…10 |
| `Super + glisser souris` | déplacer (clic gauche) / redimensionner (clic droit) une fenêtre flottante |
| Glisser à **4 doigts** ← / → (ou ↓ / ↑) | espace de travail suivant / précédent (vides compris) |
| Glisser à **3 doigts** ↑ / ↓ | plein écran on / off |
| Tap à 1 / 2 / 3 doigts | clic gauche / droit / milieu (`tap_button_map lrm`) |
| *mode resize* : `h/j/k/l`, flèches, `Entrée`/`Échap` | redimensionner de 20 px / quitter le mode |

Les touches **ASUS** (XF86Launch1 = Armoury Crate, XF86Launch4 = Fn+F5 ventilateur) sont liées au cycle des profils. Je n'ai pas pu les appuyer physiquement : vérifie leurs keysyms avec `wev` (section 13).

---

## 8. Réseau, Bluetooth, audio, énergie

### Réseau (NetworkManager 1.52.1)

- **Migration effectuée** par `system/phase2-network-root.sh` :
  1. sauvegarde ;
  2. installation : NetworkManager laisse `wlo1` « unmanaged » tant qu'il figure dans `interfaces`, donc aucune coupure ;
  3. extraction du SSID et de la PSK dans `interfaces`, écrits en **keyfile 600** ;
  4. bascule dans une unité systemd transitoire (`ifdown` → bloc commenté → redémarrage de NM → `nmcli con up`), avec un **garde-fou** : sans ping réussi en 60 s, restauration d'`interfaces` et `ifup`.
- **Incident** lors du premier essai : `/run` est monté `noexec`, donc le script de bascule n'a pas pu s'exécuter et **rien n'a été modifié**. J'ai corrigé (script placé dans `/var/backups/…` et lancé via `/bin/bash`), puis le second essai a basculé en 2 s.
- `networking.service` (ifupdown) reste actif pour `lo`. `/etc/resolv.conf` est géré par NM. Ethernet (`enp108s0`) : profil automatique « Wired connection 1 ».
- **Diagnostic :** `nmcli general status`, `nmcli device`, `nmcli connection show`, `nmtui`, `journalctl -u NetworkManager -b`, `ip -br a`, `ip route`, `resolvectl status` (si systemd-resolved), `wifi-menu --list`, `netwatch`.
- **Retour arrière :** `./rollback.sh network`, qui lance `system/network-rollback-root.sh`, utilisable depuis un TTY.
- **VPN :** aucun client installé. Le module waybar détecte les interfaces `wg*`/`tun*`/`tap*`/`tailscale*` actives et les connexions NM de type `vpn` ou `wireguard`. Pour WireGuard : `sudo apt install wireguard-tools`, puis `nmcli connection import type wireguard file wg0.conf`.

### Bluetooth (bluez 5.82, blueman 2.4.4)

- Contrôleur `hci0` allumé, sans blocage rfkill. **L'appairage n'a pas été testé : aucun appareil n'était disponible.**
- **Diagnostic :** `bt-menu --status`, `bluetoothctl show`, `bluetoothctl devices Paired`, `rfkill list`, `journalctl -u bluetooth -b`.
- Le profil audio Bluetooth (A2DP/HFP) est fourni par `libspa-0.2-bluetooth`, installé avec pipewire-audio.

### Audio (PipeWire 1.4.2 / WirePlumber 0.5.8)

- Sortie « Built-in Audio Analog Stereo » et micro détectés, HDMI NVIDIA présent. Touches, OSD et sourdine micro testés avec succès.
- **Haut-parleurs internes :** les amplificateurs Cirrus CS35L41 (SPI `CSC3551`, sous-système `10431c9f`) n'avaient pas de firmware (environ 180 erreurs noyau). Après installation de `firmware-cirrus`, le noyau indique `Firmware Loaded - Type: spk-prot, Gain: 17` et `Calibration applied` pour les deux amplis. **À confirmer à l'oreille :** je ne peux pas entendre le son.
- **Diagnostic :** `wpctl status`, `wpctl inspect @DEFAULT_AUDIO_SINK@`, `pavucontrol`, `journalctl --user -u wireplumber -u pipewire`, `cat /proc/asound/cards`, `journalctl -k | grep -i cs35l41`.

### Énergie, luminosité, ASUS

- **power-profiles-daemon 0.30** : pilotes `intel_pstate` + `platform_profile`. Le cycle a été testé : `power-saver` → firmware ASUS `quiet`, `balanced` → `balanced`, `performance` → `performance`. **Ce sont les modes ventilateur du firmware**, accessibles sans asusctl (absent de Debian). Une courbe de ventilation personnalisée (`asus_custom_fan_curve` dans hwmon) existe, mais n'est pas exploitée faute d'outil packagé (section 13).
- **Luminosité de l'écran :** `nvidia_wmi_ec_backlight` (et non `intel_backlight`, que la config d'origine visait à tort). Le brightnessctl de Debian ne fournit pas de règle udev et n'utilise pas logind, d'où « Permission denied ». J'ai donc choisi l'**écriture via logind D-Bus**, autorisée pour la session active, sans modifier `/etc`.
- **Clavier rétro-éclairé :** `asus::kbd_backlight` (niveaux 0–3), même mécanisme.
- **Batterie :** module waybar (temps restant, puissance, santé) + `battery-alert`.
- **Diagnostic :** `powerprofilesctl`, `cat /sys/firmware/acpi/platform_profile`, `sensors`, `upower -d`, `brightnessctl -l`.

---

## 9. NVIDIA / GPU

### Décision

Tu as donné ton accord pour activer `non-free`, et il n'existe **pas d'alternative sûre** pour CUDA : nouveau ne fait pas de calcul. J'ai donc installé la **pile standard de Debian** (module propriétaire compilé par DKMS). C'est la configuration la plus éprouvée sous Debian. Le module « open » (`nvidia-open-kernel-dkms`), lui aussi disponible, a été écarté par prudence. `non-free` présente un risque faible : ce sont les mêmes serveurs Debian, avec des paquets signés et une politique de mise à jour stable.

### Ce qui a été fait

1. Simulation **sans root** via un cache apt privé : 87 paquets, 0 suppression, 0 mise à jour.
2. `system/phase8-nvidia-root.sh` :
   - sauvegarde de `/etc/apt` et `/etc/modprobe.d` (`/var/backups/setup-sway/*-nvidia/`) ;
   - ajout de `non-free` ;
   - installation (lot 80) ;
   - DKMS : `nvidia-current/550.163.01` construit pour 6.12.115+deb13.1. Il est signé avec une clé MOK auto-générée, inutile tant que Secure Boot reste désactivé ;
   - nouveau en liste noire (fourni par le paquet) ;
   - `options nvidia-drm modeset=1 fbdev=1` dans `/etc/modprobe.d/nvidia-drm-setup-sway.conf` : ce réglage est désactivé par défaut en 550, alors que wlroots en a besoin pour les sorties de la dGPU. **Aucune modification de GRUB** ;
   - initramfs régénéré. Vérifié avec `lsinitramfs` : il contient la liste noire et le modeset, mais pas `nouveau.ko`.
3. **Un redémarrage est requis** : nouveau est encore en mémoire et utilisé par la session actuelle.

### Après le redémarrage

```bash
gpu-check          # attendu : nvidia chargé, nouveau absent, modeset = Y, RTX « suspended » au repos
nvidia-smi         # RTX 4060 Laptop GPU, driver 550.163.01
```

- Sway tourne toujours sur l'**iGPU Intel** : `WLR_DRM_DEVICES=intel:nvidia`, résolu par vendor PCI, donc insensible à l'ordre `card0`/`card1`. La NVIDIA reste secondaire, pour les sorties HDMI-A-3 et DP-3 qui lui sont câblées.
- **Filets de sécurité :**
  1. si Sway plante en moins de 15 s en multi-GPU, `sway-launch` le relance automatiquement sur l'Intel seul ;
  2. `SWAY_IGPU_ONLY=1` dans `~/.config/sway/env` force ce mode ;
  3. le TTY (Ctrl+Alt+F2) reste toujours accessible.
- **Batterie :** la gestion d'énergie RTD3 laisse la RTX en veille D3 quand elle ne sert pas. waybar et sysmon lisent son état sans la réveiller. `nvidia-smi` la réveille quelques secondes.
- **Lancer une application sur la NVIDIA :** pour CUDA, c'est automatique. Pour le rendu : `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia appli`, ou `DRI_PRIME=1` pour Vulkan/Mesa.
- CUDA : `libcuda1` est présent. Pour PyTorch : `python3 -m venv ~/venvs/torch && ~/venvs/torch/bin/pip install torch` (roues CUDA autonomes, sans pip global).

### Rollback NVIDIA

```bash
./rollback.sh nvidia            # simulation : liste ce qui serait purgé
./rollback.sh nvidia --apply    # purge, supprime le modeset, retire non-free, initramfs ; puis redémarrer
```

Depuis un TTY sans session graphique : `sudo ~/dotfiles/system/nvidia-rollback-root.sh --apply`. nouveau reprend la main au redémarrage. Sway n'est pas affecté, puisqu'il tourne sur l'Intel.

---

## 10. Stabilité et compatibilité

| Composant | Version | Contrainte prise en compte |
|---|---|---|
| Sway | 1.10.1 (wlroots 0.18) | pas d'options SwayFX ; `sway -C` validé après chaque modification |
| Waybar | 0.12.0 | modules `power-profiles-daemon`, `systemd-failed-units`, `wireplumber`, `sway/scratchpad`, `clock` avec `timezone` : tous présents en 0.12 ; mpris, upower et wireplumber compilés (vérifié avec `ldd`) |
| foot | 1.21.0 | `[colors-dark]` (≥ 1.22) → `[colors]` ; couleur du curseur dans `[cursor]` ; Ctrl+Shift+U réservé à la saisie Unicode |
| fuzzel | 1.12.0 | `--with-nth`/`--accept-nth` séparés par une tabulation ; `--password` et `--prompt-only` |
| mako | 1.10.0 | modes `do-not-disturb`, `[app-name=osd]` |
| swaylock | 1.8.2 | options de base uniquement (pas d'effets) |
| tmux | 3.5a | `pane-base-index 1`, d'où des panneaux adressés par identifiant |
| PipeWire / WirePlumber | 1.4.2 / 0.5.8 | `wpctl` |
| NetworkManager | 1.52.1 | plugin ifupdown en `managed=false` |
| Pilote NVIDIA | 550.163.01 (DKMS) | module nommé `nvidia-current` sous Debian ; `nvidia-drm modeset=1` ajouté |

**Prévention des conflits :**
- un seul outil par fonction (section 3) ;
- les démons sont supervisés par systemd (pas de doublons au rechargement de Sway, grâce à `exec_always` + `start` sur la cible) ;
- l'activation D-Bus de mako passe par systemd ;
- `--no-install-recommends` partout ;
- aucun mélange de dépôts.

**Adaptations des dotfiles d'origine :** options SwayFX retirées ; swaylock-effects → lock-glitch ; `[colors-dark]` → `[colors]` ; `intel_backlight` → `nvidia_wmi_ec_backlight` ; wofi → fuzzel ; wlogout → power-menu ; nm-applet/blueman-applet → menus ; `restart` retiré ; disposition `us` confirmée (QWERTY) ; agent polkit MATE et cliphist conservés ; cava conservé, avec tes shaders GLSL rangés dans `~/.config/cava/shaders/`.

**Les shaders GLSL du dépôt** (`pass_through.vert`, `bar_spectrum.frag`, `northern_lights.frag`) sont destinés à la sortie **`sdl_glsl` de cava**, un rendu OpenGL dans une fenêtre SDL. Ils n'ont **aucun lien avec Sway**, qui ne gère pas de shaders. Ta config cava utilisait `ncurses`, donc ils étaient inutilisés. Le cava de Debian est lié à SDL2 : pour les activer, mets `method = sdl_glsl` dans `~/.config/cava/config` (les lignes sont déjà présentes en commentaire). **Non testé.**

---

## 11. Sécurité

### Choix de durcissement

- **Aucun service exposé :** pas d'openssh-server, aucun port TCP en écoute hors loopback (vérifié). La référence des ports en écoute est suivie par `soc-dashboard`.
- **Secrets :**
  - PSK Wi-Fi uniquement dans le keyfile NetworkManager (root 600) et dans la sauvegarde root (700), jamais affichée ;
  - `wifi-menu` transmet le mot de passe par stdin ;
  - `sudo-askpass` n'écrit rien sur disque (FIFO 600 dans `/run/user/1000`) ;
  - aucun secret dans git (`.gitignore` exclut `local.d`, `env`, les hooks actifs) ;
  - le hook ssh-sentinel utilise `~/.pgpass` ou un service PG.
- **Écran de verrouillage :** basé sur le fond d'écran, **pas sur le contenu de l'écran**. Le mode `--screen` pixelise à 2 % et doit être demandé explicitement. Verrouillage avant chaque mise en veille.
- **Vie privée :** IP publique masquée dans la barre (utile pour les captures et les démos), appel externe limité à toutes les 10 min et désactivable ; `clip-menu delete`/`wipe` pour l'historique ; `HISTCONTROL=ignoreboth`.
- **Moindre privilège :** luminosité via logind plutôt qu'une règle udev ouverte au groupe video ; pas de `pkexec` installé ; Python uniquement via apt, pipx ou venv.
- **Chaîne d'approvisionnement :** paquets Debian signés (`non-free` activé uniquement pour NVIDIA, à ta demande) ; seule la police est téléchargée, avec vérification SHA-256 ; aucun script tiers exécuté (les dotfiles ont été récupérés en archive et lus, jamais exécutés).
- **Visibilité :** le groupe `systemd-journal` permet de lire les journaux d'authentification sans sudo (lecture seule, sans droit d'écriture). Retrait : `sudo gpasswd -d windyam_yannel systemd-journal`.

### Volontairement non activé

- **Pare-feu** (nftables/ufw) : aucun service n'écoute, donc ce n'était pas prioritaire. C'est néanmoins recommandé sur des réseaux publics, voir la section 13.
- Wireshark (accès non-root aux captures via le groupe `wireshark` : décision sensible), Docker (le groupe `docker` équivaut à root), openssh-server, hibernation (nécessiterait `resume=` dans GRUB), AppArmor (déjà actif par défaut sous Debian, non modifié), rsyslog (le journal suffit).

---

## 12. Procédures

### Installation depuis zéro (Debian 13 minimale)

```bash
sudo apt install git            # seul prérequis
git clone <dépôt> ~/dotfiles && cd ~/dotfiles
./install.sh --dry-run          # lire la simulation
./install.sh --with-soc-tools --migrate-network
sudo system/phase10-greetd-root.sh   # écran de connexion → Sway au redémarrage
```

`install.sh` : vérifie Debian 13 → (sudo) ajoute contrib, installe les lots 10/20/30/40/50(/70) avec simulation préalable → sauvegarde les fichiers en conflit → stow → hook `.bashrc` → Nerd Font avec vérification SHA-256 → fond d'écran → `daemon-reload` → `sway -C` + shellcheck → rechargement à chaud si Sway tourne. Le script est **relançable** : une deuxième exécution n'installe rien de plus (vérifié, « 0 newly installed »).

### Mise à jour

```bash
sudo apt update && apt list --upgradable   # ou : upd
sudo apt upgrade                            # pas de full-upgrade sans relire la liste
cd ~/dotfiles && git pull && ./install.sh --no-packages
```

### Retour à un Sway minimal

- Ponctuellement : depuis un TTY, `sway -c ~/.config/sway/config.fallback` (ou `sway-launch --fallback`).
- Durablement : `touch ~/.config/sway/use-fallback`, puis reconnexion via greetd.
- C'est automatique si `sway -C` échoue sur la config principale (vérifié avec une config volontairement cassée).
- Sans aucune config : `./uninstall.sh`, et Sway utilise `/etc/sway/config`.
- Accès texte : `Ctrl+Alt+F1`…`F6` (greetd est sur `Ctrl+Alt+F7`).

### Annuler le démarrage automatique

`sudo systemctl disable greetd` : au prochain démarrage, connexion texte sur tty1 et `sway-launch` à la main.

### Désinstallation / rollback

| Commande | Effet |
|---|---|
| `./uninstall.sh [--dry-run] [--keep-fonts]` | arrête les services, retire les liens stow et le hook `.bashrc`, restaure `~/.config-backup-*`, supprime la police |
| `./rollback.sh status` | paquets ajoutés depuis l'état initial, sauvegardes root, état du réseau |
| `./rollback.sh network` | rend `wlo1` à ifupdown |
| `./rollback.sh nvidia [--apply]` | retire le pilote NVIDIA (simulation par défaut) |
| `./rollback.sh boot` | retire le thème GRUB et le style des TTY (supprime `grub.d/90-glass-soc.cfg` et le thème, restaure `console-setup`, `update-grub`, initramfs) |
| `./rollback.sh sources` | restaure `/etc/apt/sources.list` d'origine (sans contrib ni non-free ; à faire **après** `nvidia --apply`) |
| `./rollback.sh packages [--apply]` | **simule** la purge des 68 paquets marqués manuels depuis l'état initial (NetworkManager exclu tant que le réseau n'est pas rendu à ifupdown), avec refus si un paquet critique est visé |

État initial complet : `~/.local/state/setup-sway/baseline-20261108-185953/` (`apt-mark showmanual`, `dpkg --get-selections`, versions, `/etc/apt`, sorties swaymsg, services).

---

## 13. Dépannage, limites et améliorations

| Symptôme | Cause probable | Solution |
|---|---|---|
| Un menu waybar (Wi-Fi, Bluetooth…) se ferme dès que le curseur bouge | fuzzel quitte à la perte du focus (`focus_follows_mouse`) | **corrigé** (`exit-on-keyboard-focus-loss=no`) ; fermer avec Échap ou par un second clic |
| Le glisser à 4 doigts ne fait rien | `next_on_output` ignore les espaces vides | **corrigé** (`ws-switch`) ; vérifier que le geste est bien reconnu avec `libinput debug-events` (paquet libinput-tools) |
| Fenêtres collées entre elles ou aux bords | gaps non appliqués à un espace créé avant la config | **corrigé** ; sinon `swaymsg "gaps inner all set 10"` |
| LED du clavier éteintes | niveau 0 (un test `osd kbd-down` l'avait mis à 0) | **corrigé** (niveau 3) ; Fn+↑/↓ ou `osd kbd-up` |
| Sway ne démarre plus après le pilote NVIDIA | wlroots et le pilote propriétaire en multi-GPU | repli automatique sur l'Intel ; sinon `echo SWAY_IGPU_ONLY=1 >> ~/.config/sway/env` ; ou `./rollback.sh nvidia --apply` |
| Écran noir ou retour au TTY au lancement | config Sway invalide, ou problème de GPU | `cat ~/.local/state/sway/sway.log` ; `sway-launch --check` ; `sway-launch --fallback` |
| La barre ne s'affiche pas | waybar en échec | `systemctl --user status waybar` ; `journalctl --user -u waybar -b` ; `systemctl --user restart waybar` |
| « Failed to acquire service name » (mako) | un mako lancé hors systemd | `pkill -x mako; systemctl --user restart mako` (la surcharge D-Bus évite que cela se reproduise) |
| Pas de son sur les haut-parleurs | firmware CS35L41 | `journalctl -k -b \| grep -i cs35l41` doit afficher « Firmware Loaded » ; sinon `sudo apt install --reinstall firmware-cirrus` puis redémarrage |
| Pas de sortie audio après la connexion | WirePlumber démarre en quelques secondes | `wpctl status` ; `systemctl --user restart wireplumber` |
| Les touches de luminosité ne font rien | session logind non active | `loginctl show-session $XDG_SESSION_ID -p Active` |
| Touche ASUS sans effet | keysym différent | lancer `wev`, appuyer sur la touche, puis adapter `XF86Launch*` dans `50-keys.conf` |
| HDMI non détecté | port câblé sur la NVIDIA | vérifier que `SWAY_IGPU_ONLY` n'est pas à 1 ; `swaymsg -t get_outputs` ; `cat /sys/class/drm/card1-HDMI-A-3/status` |
| `soc-dashboard` : « journal non lisible » | groupe pas encore actif | se déconnecter puis se reconnecter (le groupe `systemd-journal` a été ajouté pendant cette session) |
| Texte trop petit / trop grand | 2560×1600 à l'échelle 1 ; foot en `dpi-aware` | `local.d/99-scale.conf` : `output eDP-1 scale 1.25` ; ou `size` dans foot.ini |
| Le Wi-Fi ne revient pas | profil NM | `nmcli connection up wifi-wlo1-migrated` ; `nmtui` ; sinon `./rollback.sh network` depuis un TTY |
| `systemd-analyze verify` signale un cycle `foot-server.socket` | artefact de verify sur l'unité Debian | sans effet à l'exécution (`sockets.target` est déjà actif) |
| « ACPI BIOS Error (bug) » dans le journal noyau | bugs du firmware ASUS | bénins, ignorables (comptés dans les « erreurs noyau » du dashboard) |
| Menu GRUB en texte brut / thème absent | thème illisible ou mode graphique refusé par le firmware | le démarrage fonctionne quand même ; `sudo update-grub` et lire la ligne « Found theme » ; sinon `./rollback.sh boot` |
| Menu GRUB minuscule ou énorme | résolution GOP différente de 2560×1600 | modifier `GRUB_GFXMODE` dans `system/boot-theme/grub.d/90-glass-soc.cfg`, relancer `phase9-boot-theme-root.sh` |
| Écran de connexion TTY décalé | grille différente de 160×50 (autre police ou résolution) | `stty size` sur le TTY, puis recalculer les positions dans `system/boot-theme/issue` |
| TTY aux couleurs Debian | ligne noyau sans `vt.default_*` | `cat /proc/cmdline` ; `sudo setvtrgb ~/dotfiles/system/boot-theme/vt-palette.txt` |
| systemd « Tainted: local-hwclock » | horloge matérielle en heure locale (dual boot Windows) | normal en dual boot, non modifié |

### Non testé (matériel ou action humaine nécessaire)

- Écoute effective des haut-parleurs.
- Appairage Bluetooth (aucun appareil).
- Écran HDMI externe et profil kanshi `hdmi`.
- Appui physique sur les touches (seules les commandes associées ont été testées).
- Saisie du mot de passe sur swaylock : seule l'image a été générée, la session n'a pas été verrouillée.
- Déclenchement réel des délais swayidle (5 et 10 min).
- Connexion à un nouveau réseau Wi-Fi protégé via `wifi-menu`.
- Rendu `sdl_glsl` de cava.
- Démarrage automatique réel sur tty1 : la logique a été vérifiée par simulation dans 5 scénarios.
- **Chargement réel du pilote NVIDIA** et HDMI via la dGPU : c'est pour après le redémarrage (`gpu-check`).
- Gestes du touchpad et taps sur les entrées fuzzel : à confirmer au doigt (testé par commandes).
- **Rendu réel du thème GRUB**, de l'écran de connexion centré et de la police Terminus au démarrage : la configuration a été validée par `grub-script-check`, mais l'affichage ne se voit qu'au redémarrage.

### Limites connues

- Pas d'outil packagé pour la courbe de ventilation personnalisée ASUS : seuls les 3 profils firmware sont disponibles.
- swaylock n'affiche pas d'horloge (fonction de swaylock-effects).
- Pas de flou ni d'ombres (fonctions de SwayFX).
- `lock-glitch` met environ 6 s au premier calcul de l'image, ensuite c'est instantané.

### Améliorations possibles

- Pare-feu nftables minimal (`policy drop` en entrée, sauf `established`/`related`, `lo`, DHCP et mDNS si besoin). `sudo apt install nftables`, à faire après validation.
- Wireshark, en refusant la capture non-root à la question debconf (capture via `sudo tcpdump -w`, analyse dans Wireshark en utilisateur).
- Docker rootless, ou **Podman** (dans Debian) pour un laboratoire ssh-sentinel isolé (un openssh-server dans un conteneur à attaquer).
- Brancher ssh-sentinel dans `hooks.d/`.
- Profil kanshi nommé pour ton écran externe une fois identifié.
- `nvidia-cuda-toolkit` si tu compiles du CUDA (nvcc).

---

## 14. Journal chronologique

Ce journal reproduit tel quel `~/.local/state/setup-sway/journal.md`.

### 2026-11-08 18:59:54 — Phase 0 : audit (aucune modification système)
- Dotfiles récupérés en lecture seule (tarball GitHub, sha256 db5d41ef…) dans le scratchpad ; aucun script exécuté.
- État initial sauvegardé dans `/home/windyam_yannel/.local/state/setup-sway/baseline-20261108-185953` : apt-mark showmanual (211 paquets), dpkg --get-selections, versions, /etc/apt (tar), listing /etc/network, ~/.bashrc ~/.profile ~/.bash_logout, sorties swaymsg, ip, services activés.
- NON sauvegardé (nécessite sudo) : contenu de /etc/network/interfaces (mode 600 root). À faire en début de phase 1.

### 2026-11-08 — Phase 1 : base
- Ajout du helper `sudo-askpass` (fenêtre foot, FIFO privé dans $XDG_RUNTIME_DIR) : le mot de passe sudo est saisi par l'utilisateur, jamais stocké.
- Sauvegarde root : `/var/backups/setup-sway/<ts>/etc-apt-network.tar.gz` (/etc/apt + /etc/network, dont interfaces).
- `/etc/apt/sources.list` : ajout de `contrib` sur les 3 lignes `deb` et les 3 `deb-src` (demande explicite de l'utilisateur). `apt-get update`.
- 1er essai bloqué par mon propre garde-fou (regex trop large sur `[amd64]`) → corrigé, aucune installation partielle.
- Installé (no-install-recommends, 125 paquets dont dépendances, 0 suppression, 0 mise à jour) : cliphist 0.5.0-1+b9, fuzzel 1.12.0+ds-1, git 1:2.47.3-0+deb13u1, grim 1.4.0+ds-2+b1, jq 1.7.1-6+deb13u4, kanshi 1.5.1-2, libnotify-bin 0.8.6-1, mako-notifier 1.10.0-1, mate-polkit 1.26.1-4+b1, shellcheck 0.10.0-1, slurp 1.5.0-1, stow 2.4.1-2, swappy 1.5.1-2, swaybg 1.2.1-1, swayidle 1.8.0-1, swaylock 1.8.2-1, wf-recorder 0.5.0-2, wl-clipboard 2.2.1-2, wlsunset 0.3.0-1, xdg-desktop-portal-gtk 1.15.3-1, xdg-desktop-portal-wlr 0.7.1-2. Dépendance notable : pipewire 1.4.2-1 (via portail/wf-recorder).
- Effet de bord standard : trigger fuse3 → `update-initramfs` régénère /boot/initrd.img-6.12.115+deb13.1-amd64 (automatique Debian, pas de modification manuelle de /boot).

### 2026-11-08 — Phase 1 (suite) : configuration
- Police JetBrainsMono Nerd Font v3.5.1 (release GitHub officielle ryanoasis/nerd-fonts) → ~/.local/share/fonts/JetBrainsMonoNerdFont ; SHA-256 vérifié (04d5e8f9…09010cf) ; fc-cache.
- ~/dotfiles créé (paquets stow) : sway (config modulaire config.d/, config.fallback), waybar (2 barres : main + telemetry), foot, fuzzel, mako, swaylock, swayidle, kanshi, swappy, systemd-user (sway-session.target + services), scripts (lib soc/ui.sh, waybar-mod, sudo-askpass).
- Adaptations vs dotfiles d'origine : options SwayFX retirées (blur/shadows/corner_radius/layer_effects/dim) ; swaylock-effects → swaylock + image précalculée ; foot [colors-dark] → [colors] (foot 1.21) ; backlight intel_backlight → nvidia_wmi_ec_backlight ; wofi → fuzzel ; wlogout → power-menu fuzzel ; `restart` (i3) retiré ; clavier us (QWERTY, confirmé par l'utilisateur).

### 2026-11-08 — Phase 2 : réseau / Bluetooth
- Simulation (sudo --dry-run) : SSID détecté, 41 paquets, 0 suppression.
- Installé : network-manager 1.52.1-1, rfkill 2.41.5-0+deb13u1, iw 6.9-1, blueman 2.4.4-1 (+ dépendances).
- Sauvegardes : /var/backups/setup-sway/20261108-192324-network (1er essai) et /var/backups/setup-sway/20261108-192422-network (essai réussi) — contiennent interfaces.orig + tar /etc/network /etc/NetworkManager.
- Profil créé : /etc/NetworkManager/system-connections/wifi-wlo1-migrated.nmconnection (root:root 600, keyfile ; PSK reprise d'/etc/network/interfaces sans affichage).
- 1er essai : l'unité de bascule n'a pas pu s'exécuter (/run monté noexec) → aucune modification ; diagnostic via journalctl ; correctif : script dans le dossier de sauvegarde, lancé par /bin/bash.
- 2e essai : ifdown wlo1 → bloc wlo1 de /etc/network/interfaces commenté (préfixe "#setup-sway# ") → restart NetworkManager → `nmcli con up` → ping OK en 2 s (garde-fou 60 s non déclenché). IP DHCP 192.168.11.125.
- Vérifications : nmcli connectivity full, DNS OK (/etc/resolv.conf géré par NM), pas de dhclient résiduel, networking.service (lo) actif, bluetooth actif, rfkill sans blocage.
- Retour arrière : sudo ~/dotfiles/system/network-rollback-root.sh
- Correctifs scripts : PATH + /usr/sbin (rfkill), marque ● du réseau en cours, alignement UTF-8 de box_title.
- 2026-11-08 19:35:32 — sauvegarde : ~/.config/cava/shaders/pass_through.vert → /home/windyam_yannel/.config-backup-20261108/.config/cava/shaders/pass_through.vert
- 2026-11-08 19:35:32 — sauvegarde : ~/.config/cava/shaders/northern_lights.frag → /home/windyam_yannel/.config-backup-20261108/.config/cava/shaders/northern_lights.frag
- 2026-11-08 19:35:32 — sauvegarde : ~/.config/cava/shaders/bar_spectrum.frag → /home/windyam_yannel/.config-backup-20261108/.config/cava/shaders/bar_spectrum.frag
- 2026-11-08 19:35:32 — stow : sway waybar foot fuzzel mako swaylock swayidle kanshi swappy cava systemd-user scripts soc gtk bash starship tmux nvim
- 2026-11-08 19:35:32 — $HOME/.bashrc : ajout du hook init.sh (original : /home/windyam_yannel/.config-backup-20261108/.bashrc.orig)
- 2026-11-08 19:35:37 — police JetBrainsMono Nerd Font v3.5.1 → /home/windyam_yannel/.local/share/fonts/JetBrainsMonoNerdFont (SHA-256 vérifié)

### 2026-11-08 — Phases 3 / 4 / 5 / 7 : audio, énergie, thème, CLI, outils SOC
- Simulations : 30 (32 nouveaux), 40 (55), 50 (27), 70 (21) → 0 suppression, 0 mise à jour.
- Installé (phase 3) : pipewire-audio 1.4.2-1, wireplumber 0.5.8-2, pavucontrol 6.1-1, playerctl 2.4.1-3, brightnessctl 0.5.1-3.1, power-profiles-daemon 0.30-1.1 (service système actif, tlp absent), upower 1.90.9-1, lm-sensors 1:3.6.2-2, cava 0.10.4+dfsg-1.
- Installé (lot 3b/4/5/7, 133 paquets) : rtkit 0.13-5.1, adwaita-qt/adwaita-qt6 1.4.2-3+b4, qt6-wayland 6.8.2-4, qtwayland5 5.15.15-3, papirus-icon-theme 20250501-1, gnome-themes-extra 3.28-4, bibata-cursor-theme 2.0.6-1, fonts-noto-color-emoji 2.051-0+deb13u1, fonts-jetbrains-mono 2.304+ds-5, imagemagick 8:7.1.1.43+dfsg1-1+deb13u14, thunar 4.20.2-1+deb13u1, xz-utils, tmux 3.5a-3, neovim 0.10.4-8, starship 1.22.1-5, ripgrep 14.1.1-1+b4, fd-find 10.2.0-1+b5, bat 0.25.0-2+b2, eza 0.21.0-1+b1, btop 1.3.2-0.1, fzf 0.60.3-1+b2, fastfetch 2.40.4+dfsg-1, zoxide 0.9.7-1+b1, nvtop 3.2.0-1, bash-completion 1:2.16.0-7, wev 1.0.0-3, nmap 7.95+dfsg-3, tcpdump 4.99.5-2, whois 5.6.3, bind9-dnsutils 1:9.20.30-1~deb13u1, postgresql-client 17+278, pipx 1.7.1-1, python3-venv 3.13.5-1, gh 2.46.0-3.
- Groupe : windyam_yannel ajouté à systemd-journal (lecture des journaux pour soc-dashboard/sitrep ; retrait : sudo gpasswd -d windyam_yannel systemd-journal).
- Luminosité : brightnessctl Debian sans règle udev ni logind → écriture via logind D-Bus (Session.SetBrightness) dans `osd` ; aucune modification de /etc.
- Audio : firmware des amplis Cirrus CS35L41 manquant (haut-parleurs internes muets, ~180 erreurs noyau) → installé firmware-cirrus 20250410-2 (non-free-firmware officiel), chargement vérifié : "Firmware Loaded - Type: spk-prot, Gain: 17" + calibration pour les 2 amplis. Ajout libglib2.0-bin 2.84.4-3~deb13u5 (gsettings).
- Installation de la configuration : `./install.sh --no-packages` → sauvegarde ~/.config-backup-20261108/ (.bashrc.orig, .config/cava créé par un test), stow --no-folding de 18 paquets, hook ~/.bashrc, fond généré, sway -C OK, sway rechargé à chaud, sway-session.target démarré.
- Correctifs après tests : mako lancé hors systemd par activation D-Bus → surcharge ~/.local/share/dbus-1/services/org.freedesktop.Notifications.service (SystemdService=mako.service) ; lock-glitch (alpha, cache, non bloquant en veille) ; sitrep (heuristique ports exposés) ; install.sh (fc-list/pipefail).

### 2026-11-08 — Tests, correctifs et documentation
- Tests fonctionnels réalisés : osd (volume, micro, luminosité, clavier), power-profile (3 profils ↔ platform_profile quiet/balanced/performance), nightlight, dnd, menus fuzzel (lanceur, wifi, bt, power, capture : rendu vérifié par capture d'écran puis fermeture sans sélection), captures plein écran/presse-papiers, cliphist texte+image, wf-recorder (fichier mp4 produit, indicateur ● REC), agent polkit (boîte affichée puis annulée), portails (ScreenCast, Screenshot, FileChooser, Settings ; color-scheme=1), kanshi (profil portable), soc-dashboard (4 panneaux), sitrep (0,29 s), netwatch, sysmon, keys-help, sway-launch --check, bascule auto sur fallback (config cassée simulée dans un HOME temporaire), garde d'autostart .bash_profile (5 scénarios simulés).
- Correctifs : icônes Nerd Font de la zone privée BMP perdues à l'écriture → réécrites par échappements Unicode ; espaces de travail ○ ● ! (thème d'origine) ; soc-dashboard (pane ids indépendants de pane-base-index, mawk bufferisé → boucle bash, panneau procs adaptatif, assign espace 9) ; règle polkit (app_id réel) ; install.sh inclut la liste 20-network par défaut.
- Recherche NVIDIA en lecture seule (cache apt privé dans le scratchpad, /etc/apt intact) : nvidia-driver / nvidia-open-kernel-dkms 550.163.01-2, nvidia-cuda-toolkit 12.4.131~12.4.1-2, linux-headers-amd64 6.12.115-2. Rien installé.
- Contrôles finaux : apt-get -s check OK, dpkg --audit vide, 0 mise à jour en attente, sway -C OK, shellcheck 0 avertissement (31 fichiers), 0 unité en échec (système/user), 12 services user + 4 services système actifs, connectivité OK, GPU NVIDIA suspendu, /etc/default/grub et grub.cfg inchangés (18:24).
- Idempotence : `./install.sh --dry-run` après installation → « 0 newly installed ».
- Documentation : README.md, docs/RAPPORT.md.

### 2026-11-08 — Retours utilisateur (touchpad, gaps, LED) et NVIDIA
- Menus waybar/fuzzel refermés au moindre mouvement du touchpad : fuzzel quitte à la perte du focus clavier et `focus_follows_mouse` le lui retirait → `exit-on-keyboard-focus-loss=no` (fuzzel.ini) ; re-clic sur un bouton waybar = fermeture (ui.sh `menu`). Testé : menu conservé après changement de focus, refermé au 2e clic.
- Glisser à 4 doigts sans effet : `workspace next_on_output` ne parcourt que les espaces existants (un seul) → nouveau script `ws-switch next|prev` (1↔10, espaces vides inclus) pour les gestes 4 doigts et Super+Ctrl+←/→ ; gestes 3 doigts haut/bas = plein écran on/off. Testé 1→2→1→10→1.
- Fenêtres collées entre elles et aux bords : gaps non appliqués à l'espace 1 (créé avant la config) + smart_gaps → `smart_gaps off`, `hide_edge_borders none`, gaps inner 10 / outer 6 appliqués à tous les espaces à chaque rechargement. Vérifié : 16 px aux bords, 10 px entre fenêtres.
- LED du clavier éteintes : causé par mon test `osd kbd-down` (19:30, niveau écrit à 0) → remis au niveau 3 via logind.
- Durcissement : tous les `cmd | grep -q` (faux négatifs possibles par SIGPIPE avec pipefail) remplacés par `grep -q … <<<"$(cmd)"`.
- NVIDIA (accord explicite de l'utilisateur) : simulation sans root (cache apt privé) → 87 paquets, 0 suppression. `system/phase8-nvidia-root.sh` : sauvegarde /var/backups/setup-sway/20261108-2009*-nvidia et 20261108-201107-nvidia ; `non-free` ajouté à /etc/apt/sources.list ; installé linux-headers-amd64 6.12.115-2, nvidia-driver / nvidia-kernel-dkms / nvidia-smi / nvidia-suspend-common / nvidia-vulkan-icd / libcuda1 / libnvidia-encode1 / libnvidia-allocator1 / firmware-nvidia-gsp 550.163.01-2, libnvidia-egl-gbm1 1.1.2.1-1, libnvidia-egl-wayland1 1:1.1.18-1 ; DKMS : nvidia-current/550.163.01 construit et signé (clé MOK DKMS auto-générée, inutile tant que Secure Boot est désactivé) ; nouveau en liste noire (paquet) ; /etc/modprobe.d/nvidia-drm-setup-sway.conf créé (`options nvidia-drm modeset=1 fbdev=1`, absent par défaut) ; initramfs régénéré (contient blacklist + modeset, sans nouveau.ko). 1er passage arrêté par mon test `modinfo nvidia` (module nommé nvidia-current) → corrigé et relancé (idempotent).
- sway-launch : repli automatique sur l'iGPU seul si Sway échoue < 15 s en multi-GPU. Nouveau script gpu-check. rollback.sh nvidia.
- REDÉMARRAGE requis pour charger le pilote (non effectué : à faire par l'utilisateur).

### 2026-11-08 — GRUB et TTY aux couleurs de Sway
- Demande : faire correspondre GRUB et les TTY au thème Sway. État relevé : UEFI, Secure Boot désactivé, GRUB 2.12-9+deb13u2, `/etc/default/grub.d/` vide, console `Fixed 8x16`, écran 2560×1600, `/boot` sur la racine ext4.
- Créé dans le dépôt : `system/boot-theme/` (thème GRUB `glass-soc` : `theme.txt` + 18 PNG générés avec ImageMagick ; `grub.d/90-glass-soc.cfg` ; `vt-palette.txt`), `system/phase9-boot-theme-root.sh`, `system/boot-theme-rollback-root.sh`, commande `./rollback.sh boot`. shellcheck : 0 avertissement.
- Exécuté (mot de passe saisi par l'utilisateur via `sudo-askpass`) : sauvegarde `/var/backups/setup-sway/20261108-204117-boot-theme/` ; thème + 4 polices `.pf2` dans `/boot/grub/themes/glass-soc` ; grub.cfg temporaire validé (syntaxe, `set theme=`, `vt.default_red=`) puis `update-grub` (« Found theme », 2 noyaux, Windows Boot Manager, UEFI Firmware Settings) ; console-setup → TerminusBold 16x32 ; `setvtrgb` OK ; initramfs régénéré.
- Reste : vérifier l'affichage de GRUB et des TTY au prochain redémarrage.

### 2026-11-08 — Centrage de GRUB et de l'écran de connexion TTY
- Demande : textes centrés à l'écran au lieu d'être en haut à gauche (GRUB et TTY).
- GRUB : composition resserrée et centrée (titre 26 %, menu 36 % de large × 24 % de haut, centré à 32 %/37 %, compte à rebours 64 %). Vérifiée sur une maquette ImageMagick en 2560×1600 (l'entrée la plus longue, « Windows Boot Manager (on /dev/nvme0n1p1) », tient dans le panneau). Le texte des entrées reste aligné à gauche dans le panneau : GRUB ne sait pas le centrer.
- TTY : nouveau `system/boot-theme/issue` (bannière + invite de connexion centrées par positionnement ANSI, grille 160×50), installé dans `/etc/issue` par `phase9-boot-theme-root.sh` ; original sauvegardé une seule fois dans `/var/backups/setup-sway/issue.orig` et restauré par `boot-theme-rollback-root.sh`. Rendu vérifié avec `agetty --show-issue` dans un pseudo-terminal (séquences conservées, `\l` développé, pas de saut de ligne final).
- Réexécuté (mot de passe saisi par l'utilisateur) : sauvegarde `/var/backups/setup-sway/20261108-205039-boot-theme/`, grub.cfg revalidé puis installé, `/etc/issue` et thème identiques au dépôt (`cmp`/`diff`). shellcheck : 0 avertissement.

### 2026-11-08 — Écran de connexion greetd + tuigreet, souris Sway
- Demande : tout centrer à la connexion (y compris `Password:` et les messages qui suivent), garder le thème ; le curseur de la souris ne doit plus sauter au centre en changeant de bureau.
- Souris : `sway/.config/sway/config.d/15-mouse.conf` → `mouse_warping none` (rechargé à chaud).
- Connexion : `system/phase10-greetd-root.sh` installe greetd 0.10.3 + tuigreet 0.9.1 (apt bloqué par `policy-rc.d` pour ne pas démarrer greetd pendant la session en cours), `/etc/greetd/config.toml` ← `system/boot-theme/greetd/config.toml` (vt7, bannière « glass // SOC · Debian GNU/Linux 13 », heure, nom mémorisé, astérisques, couleurs cyan/gris du thème, `--cmd sway-launch`). Original : `/etc/greetd/config.toml.debian`. Tout (invite, mot de passe, erreurs) est centré par tuigreet.
- TTY 1–6 (secours) : `/usr/local/sbin/login-centered` + `getty@.service.d/centered-login.conf` placent `Password:` sous `login:` ; `LOGIN_RETRIES 1` (écran recentré après un échec) ; `pam_motd` commenté dans `/etc/pam.d/login` (sauvegarde `login.bak`) ; `~/.hushlogin`. « Login incorrect » reste à gauche (écrit par `login`, la console Linux n'a pas de marge gauche).
- Supprimé : démarrage automatique de Sway dans `~/.bash_profile` (repris par greetd), drapeau `no-autostart` (.gitignore).
- Rollback : `./rollback.sh boot` désactive greetd, restaure sa config et retire les réglages TTY.

