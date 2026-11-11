# Navigateurs — « glass // SOC »

Palette identique à foot / waybar / sway (`#0b0f14` fond, `#00ff9c` accent), police JetBrainsMono Nerd Font.

## qutebrowser (navigateur principal)
- `./install.sh` : deux profils indépendants (`yannel`, `coursera`), lanceur `qb`, entrées fuzzel.
- `config.py` unique pour les deux profils ; pages d'accueil animées dans `startpages/`.
- « Groupes d'onglets » = alias : `,c` cyber · `,d` dev · `,r` réseau · `,e` échecs · `,s` SOC · `,n` data eng · `,k` cours.
- Souris : clic molette ferme l'onglet, boutons latéraux / geste rocker = retour/avance. `Alt+←/→` aussi.
- Mots de passe : KeePassXC (`,p`).

## Firefox (`../firefox/`)
Thème, préférences anti-distraction, groupes d'onglets (`groups.json`), lanceur `ff-launch` qui réinjecte les groupes
manquants. `install.sh <dossier-profil> <main|coursera>` (profil fermé). `import-keepassxc.py` : CSV Firefox → KeePassXC.

Aucun mot de passe ni donnée de profil n'est versionné.
