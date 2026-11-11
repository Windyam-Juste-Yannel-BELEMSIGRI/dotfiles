# Navigateurs — « glass // SOC »

Palette « SOC Matrix », identique à foot / waybar / sway et au portfolio (`#0b0f14` fond, `#00ff9c` accent, `#00e5ff` réseau), police JetBrainsMono Nerd Font.

## qutebrowser (navigateur principal)
- `./install.sh` : deux profils indépendants (`yannel`, `coursera`), lanceur `qb`, entrées fuzzel.
- `config.py` unique pour les deux profils ; onglet actif vert sur fond de sélection, URL verte en HTTPS et ambre en HTTP, survol en cyan.
- Pages d'accueil dans `startpages/` (`page.css` + `page.js` communs) : graphe réseau du portfolio à 20 images/s (à l'arrêt quand l'onglet est caché), `~/nom▌`, `$ whoami` tapé à la machine, cartes façon fenêtre `*.json`, horloge locale + UTC.
- « Groupes d'onglets » = alias : `,c` cyber · `,d` dev · `,r` réseau · `,e` échecs · `,s` SOC · `,n` data eng · `,k` cours.
- Souris : clic molette ferme l'onglet, boutons latéraux / geste rocker = retour/avance. `Alt+←/→` aussi.
- Mots de passe : KeePassXC (`,p`).

## Firefox (`../firefox/`) — secondaire, non maintenu au quotidien
Thème, préférences anti-distraction, groupes d'onglets (`groups.json`), lanceur `ff-launch` qui réinjecte les groupes
manquants. `install.sh <dossier-profil> <main|coursera>` (profil fermé). `import-keepassxc.py` : CSV Firefox → KeePassXC.

Aucun mot de passe ni donnée de profil n'est versionné.
