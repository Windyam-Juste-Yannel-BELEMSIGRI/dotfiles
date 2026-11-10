# dotfiles — Sway « glass // SOC »

Environnement Sway pour **Debian 13 (trixie)**, poste d'analyste SOC / data engineer sécurité.
Évolution sombre du thème « verre dépoli » de
[Sway_dot_config_files](https://github.com/Windyam-Juste-Yannel-BELEMSIGRI/Sway_dot_config_files).

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
| `ioc` | Pivot sur une IP, un domaine, une URL, un hash, une CVE ou une technique ATT&CK | `Super+Q` (depuis le presse-papiers) |
| `casenote` | Journal d'investigation horodaté UTC en Markdown | `casenote new "Titre"` |
| `workmode` | Prépare les espaces de travail : SOC, data ou étude | `Super+M` |
| `dq` | Profil rapide d'un CSV / JSON : types, vides, doublons | `dq fichier.csv` |

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
