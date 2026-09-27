# Tâches · islet

> Suivi partagé. Cocher ce qui est fait, ajouter ce qu'on découvre.
> Vue d'ensemble de tous les projets : `~/projects-hub/bin/projects-status`

## À faire

### Lot 1 · La coque
- [x] Île dans l'encoche : fenêtre au-dessus de tout, ouverture et fermeture au survol et au clic
- [x] Animations à ressort, gestes de balayage
- [x] Décider : coque maison (Core Animation + SwiftUI à la demande), pas de DynamicNotchKit
- [ ] Validation par Ruben au toucher (survol, clic, balayage, fermeture)

### Lot 2 · Musique
- [x] Now Playing (Apple Music, Spotify, autres lecteurs), pochette, contrôles, barre de lecture
- [x] Égaliseur animé à la couleur de la pochette (Core Animation, 0 % CPU)
- [ ] Visualiseur branché sur le vrai son (Core Audio tap, autorisation audio)
- [ ] Repli AppleScript si Apple casse la passerelle MediaRemote

### Lot 3 · Affichages système et live activities de base
- [x] Volume et luminosité (remplacent ceux de macOS avec l'autorisation Accessibilité)
- [ ] Rétroéclairage du clavier
- [x] Batterie et charge, sortie audio (AirPods, casque, AirPlay)
- [ ] Batterie des AirPods (IOBluetooth), mode Concentration, enregistrement d'écran, téléchargements
- [ ] Validation des touches volume et luminosité par Ruben (impossible à tester de nuit)

### Lot 4 · Encoche programmable
- [x] API ouverte : commande `islet`, socket Unix local, lien `islet://`
- [x] Actions Raccourcis (App Intents) : afficher, terminer, minuteur, ouvrir l'île
- [x] Poste de contrôle Claude Code : sessions, état, autoriser ou refuser depuis l'encoche (testé de bout en bout)
- [ ] Codex et autres agents
- [ ] Brancher les hooks sur le Mac de Ruben (`islet hooks install`), avec son accord

### Lot 5 · Outils
- [x] Agenda (EventKit, bouton Rejoindre les visios), étagère + AirDrop (glisser sur l'encoche), presse-papiers en mémoire seulement, minuteur (compte à rebours dans les ailes), pipette, miroir caméra
- [ ] Vue double musique + agenda côte à côte (réglage)

### Lot 6 · Écran verrouillé
- [x] Widgets musique, minuteur, charge + île au-dessus de l'écran verrouillé (réglage expérimental, désactivé par défaut)
- [ ] Valider sur le vrai écran verrouillé avec Ruben (testé seulement sur le bureau)
- [ ] Météo et Bluetooth sur l'écran verrouillé

### Lot 7 · Système, vie privée, sans encoche
- [x] Moniteur processeur, mémoire, réseau, disque (échantillonné seulement quand la page est affichée)
- [ ] GPU (IOReport)
- [x] Vie privée : quelle app utilise le micro, caméra active
- [ ] Bouton pour couper le micro depuis l'île
- [ ] Île flottante sur Mac sans encoche et écrans externes

### Lot 8 · Extensions
- [x] Format d'extension (dossier + extension.json + script), réglages, deux exemples
- [ ] Catalogue communautaire d'extensions

### Premier lancement
- [x] Fenêtre d'accueil avec autorisations à la demande
- [x] Onboarding en 6 étapes : salutation dans l'île, gestes validés sur la vraie encoche, modules avec préréglages, autorisations des seuls modules choisis, développeurs, prêt
- [x] Réglages façon Réglages Système : pages activables et ordonnables, taille, vitesse, délai de survol, activités, autorisations, masquage des captures

### Parité (audit du 27.09, docs/private/competitor-audit.md)
- [x] Batterie des AirPods et accessoires : carte qui s'ouvre dans l'île, anneaux gauche, droite, boîtier (IOBluetooth)
- [ ] Valider la batterie avec de vrais AirPods (Ruben)
- [ ] Visualiseur branché sur le vrai son (Core Audio tap)
- [ ] Signature, notarisation, mises à jour Sparkle
- [x] Choix de l'écran (encoche ou écran actif), masquage en plein écran sauf alertes
- [ ] Île flottante soignée sur les écrans sans encoche
- [x] Choix de la sortie audio dans le lecteur
- [ ] Rétroéclairage du clavier
- [x] Raccourci global ⌃⌥⌘I, balayage sur l'île fermée pour changer de piste
- [ ] Rappels, météo, mode Concentration
- [ ] Presse-papiers avec images, recherche, épingles
- [x] Garder éveillé, téléchargements en cours (option)
- [ ] Miroir des notifications, paroles, autres agents (Codex, Cursor)

### Publication
- [ ] Passer le dépôt en public (licence MIT)

## Fait

- [x] Cadrer le périmètre : parité Alcove, Atoll, boring.notch + 5 ajouts (27.09.2026)
- [x] Choisir la stack : Swift/SwiftUI natif, licence MIT
