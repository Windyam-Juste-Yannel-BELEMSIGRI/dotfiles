# Rapport — navigateurs, transparence, agenda et outils SOC / data « glass // SOC »

Suite de `RAPPORT.md` (poste Sway) et `RAPPORT-OUTILS.md` (outils de travail).
Période : 2026-11-10. Machine : `yannel-asus`, Debian 13, Sway 1.10.1 standard.

Règles conservées : dépôts Debian officiels uniquement, pas de `pip` global, tout
est versionné dans `~/dotfiles` et déployé par GNU stow, aucun secret dans le dépôt.

---

## 1. Vue d'ensemble

| Domaine | Ce qui a été fait | Fichiers |
|---|---|---|
| Navigateur principal | qutebrowser 3.4.0, deux profils (`yannel`, `coursera`), pages d'accueil animées, navigateur par défaut | `qutebrowser/` |
| Firefox (conservé) | Thème, préférences anti-distraction, groupes d'onglets réinjectés au lancement | `firefox/` |
| Mots de passe | Export Firefox → KeePassXC (`~/Documents/coffre.kdbx`, hors dépôt) | `firefox/import-keepassxc.py` |
| Transparence | Fenêtres inactives estompées avec fondu, sur Sway standard | `sway-opacity`, `opacity.conf` |
| Agenda | CLI + interface GTK 3 + menu fuzzel + rappels + module waybar | `agenda`, `agenda-gui`, `agenda_core.py` |
| Google Agenda | Synchronisation Google → local au démarrage, puis toutes les 30 min | `agenda_gsync.py`, `agenda-gsync.timer` |
| Outils SOC / data | `ioc`, `casenote`, `workmode`, `dq` | `scripts/.local/bin/` |
| Thème étendu | btop, GTK 3/4, psql, fondus waybar | `btop/`, `gtk/`, `psql/`, `waybar/` |

## 2. Choix et justifications

- **qutebrowser plutôt que Firefox** : la page de choix de profil de Firefox n'applique pas
  `userChrome.css` dans tous les cas, donc le thème ne pouvait pas être garanti partout.
  qutebrowser se configure dans un seul `config.py` et est dans les dépôts Debian.
- **Pas de changement de compositeur** : SwayFX, Hyprland et niri ne sont pas dans Debian 13.
  La transparence passe par la commande `opacity` de Sway, pilotée par un démon IPC.
- **Pas de flou** : Sway standard n'en a pas. Conséquence assumée : une fenêtre flottante
  active reste opaque (`floating_focused = 1.0`), sinon le texte situé derrière resterait lisible.
- **Agenda maison plutôt que khal/vdirsyncer** : non installés, et l'objectif était une
  interface au thème. Stockage JSON local, échange par `.ics`.
- **Synchro Google en lecture seule par adresse iCal secrète** : aucun compte développeur,
  aucune dépendance, aucun jeton OAuth à stocker. Contrepartie : sens unique (Google → local).

## 3. Raccourcis ajoutés

| Touche | Action |
|---|---|
| `Super+C` | Agenda (interface) |
| `Super+Ctrl+C` | Agenda (menu rapide) |
| `Super+Shift+O` | Transparence : activer / couper |
| `Super+Ctrl+W` | Fond d'écran animé : activer / couper |
| `Super+Q` | Pivot IOC depuis le presse-papiers |
| `Super+M` | Mode de travail (SOC / data / étude) |

Dans qutebrowser : `,c` cyber · `,d` dev · `,r` réseau · `,e` échecs · `,s` SOC · `,n` data ·
`,k` cours · `,h` accueil · `Alt+←/→` retour / avance · clic molette = fermer l'onglet.

## 4. Agenda

```bash
agenda                               # aujourd'hui + 7 jours
agenda add "Revue alertes" demain 9h -t soc -r weekdays -e 9h30
agenda done 3 · agenda rm 3 · agenda mv 3 lundi 14h
agenda export sauvegarde.ics · agenda import fichier.ics
```

- Données : `~/.local/share/agenda/events.json` (hors dépôt).
- Étiquettes : `soc`, `data`, `cours`, `perso`, `admin` (couleur et icône propres).
- Rappels : `agenda-remind.timer` (chaque minute) → notification mako, 15 min avant par défaut ;
  urgence critique pour l'étiquette `soc`.
- waybar : module `custom/agenda` (prochain événement ; clic = interface, clic droit = menu).

### Synchronisation Google Agenda

Mise en service, une seule fois :

1. Google Agenda → Paramètres → choisir l'agenda → « Intégrer l'agenda » →
   copier l'**adresse secrète au format iCal**.
2. `agenda gsync set-url` puis coller l'adresse (saisie masquée).
3. `agenda gsync` pour une première synchronisation, `agenda gsync status` pour l'état.

Fonctionnement :

- `agenda-gsync.timer` : 20 s après le démarrage de la session, puis toutes les 30 min.
  Le script réessaie 6 fois à 10 s d'intervalle si le réseau n'est pas encore prêt.
- Fenêtre importée : 30 jours passés → 180 jours à venir.
- Pris en charge : fuseaux horaires, journées entières, récurrences (`DAILY`, `WEEKLY` avec
  `BYDAY`, `MONTHLY`, `YEARLY`, `INTERVAL`, `COUNT`, `UNTIL`), exceptions (`EXDATE`),
  occurrences déplacées (`RECURRENCE-ID`), événements annulés ignorés.
- Les événements Google sont remplacés à chaque synchro ; les événements locaux ne sont
  jamais modifiés. Les marques « terminé » et l'étiquette corrigée à la main sont conservées.
- L'adresse est dans `~/.config/agenda/google.url` (mode 600, **hors dépôt**) : elle donne
  accès en lecture à l'agenda, à traiter comme un mot de passe.

## 5. Outils SOC et data

| Commande | Usage |
|---|---|
| `ioc [VALEUR]` | Détecte IP, domaine, URL, hash, CVE, technique ATT&CK ; remet en forme les valeurs « defangées » ; propose les sources. Une IP privée n'est jamais envoyée à un tiers. |
| `casenote new "Titre"` · `casenote "texte"` · `casenote ioc VALEUR` | Dossier d'investigation Markdown horodaté UTC dans `~/Documents/soc/cases/`. |
| `workmode soc|data|etude` | Ouvre le tableau de bord, les sources et le terminal selon l'activité ; le mode étude met les notifications en sourdine. |
| `dq fichier.csv` | Types déduits, taux de vides, valeurs distinctes, doublons, colonnes constantes. CSV, TSV, JSON, JSONL, `.gz`. |

## 6. Sécurité

- Dépôt GitHub privé ; recherche de mots de passe, jetons et clés avant chaque publication.
- Hors dépôt : coffre KeePassXC, profils de navigateur, données de l'agenda, adresse iCal.
- Export des mots de passe Firefox : fichiers CSV en clair dans `~/firefox-export/`
  (mode 600), **à supprimer** après vérification du coffre (`shred -u`).
- qutebrowser : notifications, géolocalisation, caméra, micro, pop-ups et cookies tiers bloqués.

## 7. Tests effectués

| Élément | Vérification | Résultat |
|---|---|---|
| qutebrowser | Lancement des deux profils, captures d'écran, journal | Aucune erreur de configuration |
| Navigateur par défaut | `xdg-settings`, `xdg-mime` | `qb-yannel.desktop` |
| Transparence | Captures avec et sans le démon | Inactives estompées, flottante active opaque |
| Agenda CLI | Ajout, récurrence, dates en français, export | Conforme |
| Agenda interface | Captures d'écran | Conforme |
| Rappel | Événement de test à 5 min | Une notification, pas de doublon |
| Synchro Google | Fichier `.ics` de test (récurrence, exception, fuseau, journée entière, annulé) | 7 occurrences attendues, 7 importées ; identifiants stables entre deux synchros |
| `ioc`, `casenote`, `dq` | Exécution en terminal | Conforme |
| Sway | `sway -C` puis rechargement | Valide |

## 8. Limites et points en attente

- Synchro Google **non testée sur un vrai agenda** : l'adresse iCal n'est pas encore configurée.
- Synchro à sens unique : un événement créé en local n'est pas envoyé à Google ; un événement
  Google supprimé en local revient à la synchro suivante.
- Règles de récurrence complexes (`BYSETPOS`, `BYMONTHDAY` multiples) non prises en charge.
- Menus fuzzel (`agenda menu`, `ioc --menu`) et `workmode` écrits mais non essayés en conditions réelles.
- Aspect de btop, Thunar et psql avec le nouveau thème non contrôlé visuellement.
- qutebrowser : pas de groupes d'onglets natifs (remplacés par des alias), pas de balayage à deux doigts.
- Firefox reste installé avec ses données ; désinstallation à décider.

## 9. Journal chronologique

### 2026-11-10 — Firefox : groupes d'onglets et épurage
- Groupes Cyber, Dev, Réseaux, Échecs (profil principal) et Coursera (second profil), `user.js` anti-distraction, thème `userChrome.css` / `userContent.css`.
- `ff-launch` réinjecte les groupes manquants dans les profils fermés. Ancien profil `default` vide supprimé.

### 2026-11-10 — Passage à qutebrowser
- Installation par l'utilisateur (`sudo apt install qutebrowser`). `config.py` unique, deux profils, pages d'accueil animées (radar SOC, pipeline data), souris et raccourcis retour / avance.
- Défini comme navigateur par défaut (profil `yannel`).

### 2026-11-10 — Export Firefox → KeePassXC
- NSS refusant de déchiffrer, lecture directe de `key4.db` (PBES2 / 3DES via `openssl`) : 13 + 2 identifiants. Import dans `coffre.kdbx` par `import-keepassxc.py`.

### 2026-11-10 — Transparence, agenda, thème, outils
- `sway-opacity` (service systemd), agenda complet, thème btop / GTK / psql, fondus waybar, `ioc`, `casenote`, `workmode`, `dq`.

### 2026-11-10 — Synchronisation Google Agenda
- `agenda gsync` + `agenda-gsync.timer` rattaché à `sway-session.target`. Reste à faire par l'utilisateur : `agenda gsync set-url`.

### 2026-11-10 — Agenda : première synchronisation réelle et centrage
- Adresse iCal secrète enregistrée par l'utilisateur : 91 événements importés. L'adresse publique renvoyait HTTP 404 (agenda privé) ; message d'erreur rendu explicite, sous-commande `clear-url`.
- Les longs titres élargissaient la fenêtre à 1855 px : textes tronqués avec infobulle, fenêtre de taille fixe recentrée après rendu.

### 2026-11-10 — Fond d'écran animé `livebg`
- Demande : animer le fond dans le style du portfolio (graphe réseau de `Hero.astro` : nœuds, liens, paquets).
- `livebg` : GTK 3 + Cairo sur une surface transparente en couche « bottom » (au-dessus de swaybg, sous les fenêtres), par `libgtk-layer-shell` appelée en ctypes — aucun paquet à installer. Service `livebg.service` rattaché à `sway-session.target`.
- Couche 0 écartée : Sway relance swaybg à chaque rechargement, ce qui recouvrait l'animation.
- Mesuré : 9 à 12 % d'un cœur à 24 images/s en 2560×1600 ; 12 images/s sur batterie ; aucun calcul quand la surface n'est pas affichée (plein écran, écran éteint).
- Limite : sous une fenêtre opaque l'animation est invisible ; elle se devine sous les terminaux et fenêtres inactives transparentes.
