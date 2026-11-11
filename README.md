# dotfiles — Sway « glass // SOC »

Environnement Sway pour **Debian 13 (trixie)**, poste d'analyste SOC / data engineer sécurité.

Même identité visuelle que mon portfolio et que
[windows-geek-theme](https://github.com/Windyam-Juste-Yannel-BELEMSIGRI/windows-geek-theme) (palette « SOC Matrix ») :
fond `#0b0f14`, vert « matrix » `#00ff9c` pour ce qui est sain, cyan `#00e5ff` pour le réseau, ambre `#ffb000`
pour les avertissements, rouge `#ff5370` pour le critique, JetBrainsMono partout, fenêtres translucides.

| Élément | Sous Sway | Équivalent Windows |
|---|---|---|
| Barre du haut | waybar : `~/nom▌` (curseur clignotant), espaces numérotés, `> application titre`, horloge, débits ↓/↑, CPU et RAM avec mini-courbes | Zebar |
| Fond d'écran | `wallgen` : dégradé, halo vert, grille, coins ambre, `SOC // ONLINE` (dessiné, rien de téléchargé) | `lib/wallpaper.ps1` |
| Animation du bureau | `livebg` : graphe réseau du portfolio (nœuds, liens, paquets cyan) + carte `status.json` aux valeurs réelles | HUD Zebar |
| Fenêtres | bordure verte sur l'active, 93 % / 86 % d'opacité, marges de 12 px | GlazeWM |
| Verrouillage | même fond avec le graphe réseau figé et `$ whoami` | étape 09 |
| Terminal, prompt | foot (schéma SOC Matrix) et starship `┌─[user@host]─[chemin]─[git]` / `└─❯` | Windows Terminal, Oh My Posh |

- Dépôts **officiels Debian uniquement** (main, contrib, non-free-firmware). Pas de PPA, pas de `pip` global, pas de `curl | bash`.
- Une seule exception : la police JetBrainsMono Nerd Font v3.5.1, téléchargée depuis la release GitHub officielle, avec vérification SHA-256.
- Installation idempotente, `--dry-run` partout, sauvegardes automatiques, retour arrière en un script.

## Démarrage rapide

```bash
git clone <ce dépôt> ~/dotfiles && cd ~/dotfiles
./install.sh --dry-run          # voir ce qui serait fait
./install.sh                    # paquets + configuration (sudo demandé)
./install.sh --with-soc-tools   # + nmap, tcpdump, psql, pipx, gh…
./install.sh --migrate-network  # + bascule wlo1 ifupdown → NetworkManager (garde-fou)
```

Ensuite, `sudo system/phase10-greetd-root.sh` installe l'écran de connexion **greetd + tuigreet** (thème glass // SOC) : au démarrage, connecte-toi dessus et Sway se lance. Console de secours : `Ctrl+Alt+F2`…`F6`.

| Besoin | Commande |
|---|---|
| Aide raccourcis | `Super+F1` ou `keys-help --print` |
| Sway de secours | `sway -c ~/.config/sway/config.fallback` (ou `touch ~/.config/sway/use-fallback`) |
| Retirer la config | `./uninstall.sh` |
| Retour système | `./rollback.sh status` · `network` · `sources` · `nvidia` · `boot` · `packages` |

## Agenda, transparence et outils SOC / data

| Outil | Rôle | Accès |
|---|---|---|
| `agenda` · `agenda-gui` | Agenda local (JSON), récurrences, rappels mako, export/import `.ics` | `Super+C` (interface) · `Super+Ctrl+C` (menu) · module waybar |
| `agenda gsync` | Google Agenda → agenda local au démarrage puis toutes les 30 min (`agenda gsync set-url` une fois) | minuterie `agenda-gsync.timer` |
| `sway-opacity` | Fenêtres inactives estompées avec fondu, sur Sway standard (`~/.config/sway/opacity.conf`) | `Super+Shift+O` (activer / couper) |
| `livebg` | Fond animé « graphe réseau » du portfolio + carte `status.json`, sous les fenêtres (`~/.config/sway/livebg.conf`) | `Super+Ctrl+W` (activer / couper) |
| `wallgen` · `set-wallpaper gen` | (Re)génère le fond « SOC Matrix » à la résolution de l'écran | `Super+Shift+W` (fond suivant) |
| `ioc` | Pivot sur une IP, un domaine, une URL, un hash, une CVE ou une technique ATT&CK | `Super+Q` (depuis le presse-papiers) |
| `casenote` | Journal d'investigation horodaté UTC en Markdown | `casenote new "Titre"` |
| `workmode` | Prépare les espaces de travail : SOC, data ou étude | `Super+M` |
| `dq` | Profil rapide d'un CSV / JSON : types, vides, doublons | `dq fichier.csv` |

Nom affiché dans la barre : `$USER` par défaut, ou une ligne dans `~/.config/soc/logo`.
Thème étendu à btop (`glass-soc.theme`), GTK 3/4 (`gtk.css`) et psql (`~/.psqlrc`).
Détails, tests et limites : `docs/RAPPORT-NAVIGATEURS-AGENDA.md`.

## Arborescence

Chaque dossier de premier niveau est un paquet **GNU stow** (`stow --no-folding`, cible `$HOME`), sauf `system/` et `docs/`.

```
sway/ waybar/ foot/ fuzzel/ mako/ swaylock/ swayidle/ kanshi/ swappy/ cava/ gtk/
systemd-user/   services de session (sway-session.target)
scripts/        ~/.local/bin/* + ~/.local/lib/soc/ui.sh
soc/            ~/.config/soc/hooks.d (extension soc-dashboard → ssh-sentinel)
bash/ starship/ tmux/ nvim/
system/         scripts root (apt sûr, migration réseau, NVIDIA, thème GRUB/TTY, rollback) + listes de paquets
docs/RAPPORT.md documentation complète
```

Documentation détaillée : **[docs/RAPPORT.md](docs/RAPPORT.md)**.

## Licence

[MIT](LICENSE). Tu peux reprendre, modifier et redistribuer ces fichiers en gardant la mention de copyright ;
ils sont fournis sans garantie (plusieurs scripts touchent au système : lis-les et utilise `--dry-run`).

Les shaders `cava/.config/cava/shaders/` viennent des fichiers d'exemple de [cava](https://github.com/karlstav/cava) (MIT).
Les logiciels installés par `install.sh` (Sway, waybar, foot…) gardent chacun leur propre licence : ce dépôt ne contient que leur configuration.
