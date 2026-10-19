# DrumBuddy

Ein SwiftUI-Begleiter für Schlagzeug-Warm-ups auf iPhone und iPad. Die Oberfläche ist auf Deutsch und Englisch verfügbar. Spracheinstellungen bleiben lokal; Konten, Gruppen, Warm-ups und Fortschritt werden über das Amplify-Backend synchronisiert.

## Warm-ups

- Fünf Sets werden auf Stufe 1, 3, 5, 7 und 9 freigeschaltet.
- Jedes Set hat sieben Tagesfolgen. Montag bis Sonntag erscheinen unterschiedliche Muster und Reihenfolgen; die Folge bleibt am selben Tag stabil.
- Eine Folge besteht aus fünf Blöcken à 50 Sekunden. Zwischen den Blöcken liegen jeweils zehn Sekunden Pause inklusive Einzählen; zusammen dauert die Folge etwa fünf Minuten. Jeder Block zeigt genau zwei Takte, die bis zum nächsten Block wiederholt werden.
- Zu Beginn zählt der Metronomklick bei aktuellem Tempo vier Schläge ein. In den Pausen erscheinen die nächsten zwei Takte zuerst ohne Klick; die letzten vier Schläge werden bei aktuellem Tempo eingezählt. Die Einzählzahl steht klein neben den Noten.
- Die Notenmarkierung folgt dem hörbaren Klick. Schlag eins nach dem Einzählen startet den jeweiligen Block.
- Das Metronomtempo lässt sich während einer laufenden Einheit per Regler oder in 5-BPM-Schritten zwischen 60 und 280 BPM ändern. Der Klick startet beim Tempowechsel neu auf Schlag eins.
- Pausieren hält die Übungszeit an. Beim Verlassen der App wird eine laufende Einheit pausiert. XP werden nur für eine vollständig abgeschlossene Folge vergeben.

Die Sets und Muster stehen in `DrumBuddy/Models/WarmUp.swift`. Dort können die Pattern, Stufen und Blocklängen angepasst werden. Die älteren Einzelübungsdaten in `Exercise.swift` bleiben zur Kompatibilität mit gespeichertem Fortschritt erhalten.

## Starten

`DrumBuddy.xcodeproj` in Xcode öffnen, ein iPhone- oder iPad-Ziel auswählen und auf „Ausführen“ drücken. Mindestziel: iOS 17.0. Für die Online-Funktionen muss die Produktionsdatei `amplify_outputs.json` aus dem Amplify-Backend im App-Bundle liegen. Die App verwendet Amplify Swift und RevenueCat.
