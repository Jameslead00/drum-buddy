# DrumBuddy

Ein spielerischer SwiftUI-Übungsbegleiter für junge Schlagzeugerinnen und Schlagzeuger. Das MVP läuft auf iPhone und iPad, speichert den Fortschritt lokal und führt mit einem integrierten Taktgeber durch die Übungen.

## Enthalten

- Zehn Übungsstufen: Grundschläge, Paradiddle-Varianten, Viertelpausen und Akzente
- Geführte Ein-Minuten-Einheiten mit animierten Handzeichen
- Sample-genauer 4/4-Taktgeber mit einem hohen und drei tiefen Viertel-Klicks
- Einstellbares Übungstempo von 40–200 BPM
- Umschaltbare deutsche und englische Oberfläche; die gewählte Sprache wird lokal gespeichert
- Reines Audio-Metronom ohne Vibration
- XP, Stufen, Freischaltungen, Übungsanzahl und der persönliche Tempo-Rekord jeder Übung lokal in `UserDefaults`
- Flexible Darstellung für iPhone und iPad inklusive Bedienungshilfen

## Übungen bearbeiten

Die Übungen stehen direkt in `DrumBuddy/Models/Exercise.swift` im Array `Exercise.all`; es gibt aktuell keine JSON-Datei. Jede Übung definiert dort:

- deutsche und englische Texte
- das Notenmuster mit `.r`, `.l`, `.pause`, `.accentR` und `.accentL`
- die benötigte Stufe und die XP-Belohnung
- Farbe und Symbol

Eine neue Übung wird einfach als weiterer `Exercise(...)`-Eintrag im Array ergänzt. Die Stufe wird automatisch über `requiredLevel` freigeschaltet.

## Starten

`DrumBuddy.xcodeproj` in Xcode öffnen, einen iPhone- oder iPad-Simulator auswählen und auf „Ausführen“ drücken.

Das Mindestziel ist iOS 17.0. Das Projekt benötigt weder externe Abhängigkeiten noch ein Backend.
