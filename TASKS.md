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
- [ ] Actions Raccourcis (App Intents)
- [x] Poste de contrôle Claude Code : sessions, état, autoriser ou refuser depuis l'encoche (testé de bout en bout)
- [ ] Codex et autres agents
- [ ] Brancher les hooks sur le Mac de Ruben (`islet hooks install`), avec son accord

### Lot 5 · Outils
- [x] Agenda (EventKit, bouton Rejoindre les visios), étagère + AirDrop (glisser sur l'encoche), presse-papiers en mémoire seulement, minuteur (compte à rebours dans les ailes), pipette, miroir caméra
- [ ] Vue double musique + agenda côte à côte (réglage)

### Lot 6 · Écran verrouillé
- [ ] Widgets : musique, minuteur, charge, météo, Bluetooth

### Lot 7 · Système, vie privée, sans encoche
- [ ] Moniteur CPU, GPU, mémoire, réseau, disque
- [x] Vie privée : quelle app utilise le micro, caméra active
- [ ] Bouton pour couper le micro depuis l'île
- [ ] Île flottante sur Mac sans encoche et écrans externes

### Lot 8 · Extensions
- [ ] Format de plugin (manifeste + script) et partage communautaire

### Publication
- [ ] Passer le dépôt en public (licence MIT)

## Fait

- [x] Cadrer le périmètre : parité Alcove, Atoll, boring.notch + 5 ajouts (27.09.2026)
- [x] Choisir la stack : Swift/SwiftUI natif, licence MIT
