<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="branding/steady-wordmark-dark.svg">
    <img src="branding/steady-wordmark-light.svg" alt="Steady" width="300">
  </picture>
</p>

<p align="center">
  Gewichtstrend statt Tageszahl · SwiftUI · iOS 26
</p>

<p align="center">
  <a href="docs/Steady%20-%20Case%20Studie%20Notes.md"><b>Fallstudie</b></a> ·
  <a href="#die-rechnung">Die Rechnung</a> ·
  <a href="#das-lineal">Das Lineal</a> ·
  <a href="#gesundheitsdaten">Gesundheitsdaten</a> ·
  <a href="#gestaltung">Gestaltung</a> ·
  <a href="#bauen">Bauen</a>
</p>

---

Eine Waage-App, die die Zahl auf der Waage nicht für das Ergebnis hält — und die
keinen Account will, nur um jeden Morgen vier Ziffern zu speichern.

Das Körpergewicht schwankt an einem einzigen Tag um rund zwei Kilo: Salz,
Kohlenhydrate, Wasser, Darminhalt. Wer tatsächlich abnimmt, verliert dabei etwa
400 Gramm Fett pro Woche. Das Signal ist also rund fünfmal kleiner als das
Rauschen, das darauf sitzt. Jede andere App zeichnet das Rauschen und überlässt
das Filtern dem Nutzer — man hat alles richtig gemacht, die Zahl ist trotzdem
gestiegen, und man muss sich das selbst ausreden. Genau da entsteht die
Entmutigung.

Steady filtert. Man zieht ein Lineal auf sein Gewicht, es landet in Apple Health,
und zu sehen ist eine geglättete Linie. Zwei Bildschirme, **Log** und **Trend**.
Keine Einstellungen, keine Verlaufsliste, kein Konto, keine Serie, die man
verteidigen muss. Wiegen dauert vier Sekunden; die App soll auch vier Sekunden
dauern.

|  |  |
|---|---|
| **Trend** | EWMA mit α = 0,18 — Halbwertszeit 3,5 Tage, Schwerpunkt 4,6 Tage |
| **Eingabe** | Ziehbares Lineal, 0,1 kg je Rasterschritt, ein Haptik-Tick pro Schritt |
| **Speicher** | Ausschliesslich HealthKit — kein Backend, kein Konto, kein Netzwerkcode |
| **Bildschirme** | Zwei, dazu neun Zustände. Kein Einstellungsbildschirm |
| **Abhängigkeiten** | Keine. Kein SPM-Paket, kein CocoaPods |
| **Lizenz** | Source-available — eigener Gebrauch ja, Weiterverkauf nein |

Warum die App so aussieht, wie sie aussieht — das Lineal statt eines Ziffernblocks,
warum der Trend die 64-pt-Zahl bekommt und das heutige Gewicht nicht, warum es
genau eine Akzentfarbe gibt und kein Grün für Abnahme — steht in der
**[Fallstudie](docs/Steady%20-%20Case%20Studie%20Notes.md)**.

## Die Rechnung

### Warum kein gleitender Durchschnitt

Der naheliegende Weg wäre ein 7-Tage-Mittel. Er ist aus zwei konkreten Gründen
schlechter.

Er **gewichtet einen Messwert von vor sechs Tagen genauso stark wie den von heute
Morgen**. Eine echte Richtungsänderung wird deshalb erst sichtbar, wenn sie das
Fenster halb gefüllt hat — bei einem Menschen, der etwas verändert hat, fühlt sich
das an, als sei die App kaputt.

Und er **springt**. In dem Moment, in dem ein Ausreisser hinten aus dem Fenster
fällt, hüpft der Durchschnitt. In der Linie steht dann ein sichtbarer Knick, dem
im Leben des Nutzers nichts entspricht.

### EWMA, α = 0,18

Ein exponentiell gewichteter gleitender Durchschnitt hat beide Probleme nicht.
Jeder neue Messwert schiebt die Linie um einen festen Anteil — sie ist stetig,
und ihre Reaktion ist glatt.

```
e[0] = v[0]
e[i] = 0,18 · v[i] + 0,82 · e[i−1]
```

α = 0,18 legt den Charakter der Linie fest:

- **Halbwertszeit ln(0,5) / ln(0,82) ≈ 3,5 Tage.** Eine echte Gewichtsänderung ist
  nach dreieinhalb Tagen zur Hälfte aufgenommen und nach zwei Wochen praktisch
  vollständig.
- **Schwerpunkt (1 − α) / α ≈ 4,6 Tage.** Das Gedächtnis der Linie reicht etwa
  fünf Tage zurück, gewichtet zum Jüngeren hin.
- Eine einmalige Salzspitze von 1,5 kg verschiebt die Linie um 0,18 · 1,5 =
  **0,27 kg** und klingt von dort ab. Der Messwert steht als Punkt weit neben der
  Linie, die Linie nimmt kaum Notiz.

Kleineres α (0,10) ergibt eine wunderschön ruhige Linie, die einen echten
Durchbruch aber über eine Woche zu spät zeigt. Grösseres α (0,30) folgt so eng,
dass die Linie genau das Rauschen erbt, dessentwegen es sie gibt. 0,18 ist der
Wert, gegen den der freigegebene Entwurf gezeichnet wurde.

Der EWMA läuft **einmal über die gesamte Historie**, von alt nach neu. Die Bereiche
werden hinten abgeschnitten, nicht je Bereich neu gerechnet — ein Tag zeigt im
Monatschart denselben Trendwert wie im Jahreschart.

### Zwei Ausnahmen, beide Absicht

| Bereich | Punkte | Linie |
|---|---|---|
| Woche | letzte 7 Tageswerte | **Ausgleichsgerade** durch die sieben Messwerte |
| Monat | letzte 30 Tageswerte | die EWMA-Reihe |
| Jahr | 52 Wochenmittel | diese Mittel durch einen **zweiten EWMA, α = 0,3** |

Beides korrigiert, was ein EWMA an den Enden der Fensterlänge tut. Über sieben
Punkte trägt er noch fast das gesamte Rauschen — ein Wochenchart zeigte zwei
zappelige Linien und sagte nichts. Die Gerade gibt der Woche das Einzige, was sich
über sieben Tage seriös sagen lässt: die Richtung. Über ein Jahr ist es umgekehrt.
Wochenmittel sind bereits so glatt, dass der EWMA jedem einzelnen folgte; der
zweite Durchgang hält die Linie ruhiger als die Punkte, durch die sie gezeichnet
ist.

**Fehlende Tage werden nicht interpoliert.** Der EWMA läuft über die Messwerte, die
es gibt, in Datumsreihenfolge. Eine Lücke lässt die Linie in Kalendertagen
langsamer reagieren — das ist ehrlich. Ein Halbjahr ohne Messung ist kein Tag mit
null Kilo.

Referenzimplementierung: [`design/reference-weight.js`](design/reference-weight.js).
Der Swift-Port muss sie exakt reproduzieren.

## Das Lineal

Die einzige Eingabe. **Kein Ziffernblock, kein Picker-Rad, kein Textfeld.**

Gewogen wird halb wach, einhändig, vor dem ersten Kaffee. Vier Zeichen zu tippen
heisst, sie anschliessend zurückzulesen, um sie zu prüfen. Ein Zug landet mit einer
Geste auf der richtigen Zahl und braucht keinen Kontrollblick. Der Preis: ein
Sprung über mehrere Kilo dauert länger — was bei jemandem, der sich täglich wiegt,
praktisch nie vorkommt.

Die Geometrie kommt aus dem Entwurf und ist nicht verhandelbar: **25 Striche** im
Abstand von **14,2 pt**, jeder fünfte lang. Die Nadel steht fest in der Mitte, das
Band zieht darunter durch. Das sichtbare Fenster ist 2,4 kg breit und überspannt 24
Intervalle — daraus folgt die einzige Konstante, die das Steuerelement braucht:

```
14,2 pt = 0,1 kg
```

Der Wert rastet immer auf 0,1 kg. Er wird nie feiner gehalten, angezeigt oder
gespeichert. **Pro überfahrenem Rasterschritt feuert genau ein Haptik-Tick** —
vorbereitet beim Start der Geste, ausgelöst beim Überschreiten, nie mehrmals für
denselben Strich und niemals je Frame. Das ist das Detail, das aus einem Slider ein
Instrument macht; ein Zug, der durchgehend vibriert, und einer, der gar nicht
vibriert, wirken gleichermassen kaputt.

Die Knöpfe **−** und **+** daneben schrittweise 0,1 kg, zum Nachjustieren nach dem
Zug. Startwert ist der gestrige Messwert.

## Gesundheitsdaten

HealthKit **ist** die Datenbank. Kein lokaler Cache, kein Core Data, keine Kopie in
`UserDefaults`. Kein Backend, kein Konto, keine Analytik, kein Crash-Reporting und
kein Netzwerkcode — die App funktioniert dauerhaft im Flugmodus. Gelesen und
geschrieben wird `bodyMass` in Kilogramm, sonst nichts.

Drei Dinge, an denen man sich verletzt:

**HealthKit sagt bei Lesezugriffen nicht die Wahrheit.** `authorizationStatus`
liefert für einen Lesetyp `.sharingAuthorized`, auch wenn der Nutzer das Lesen
abgelehnt hat — mit Absicht, damit Apps eine Ablehnung nicht erkennen können. Wer
darauf verzweigt, zeigt jemandem mit zehn Jahren Messwerten ein leeres Diagramm.
Der Zustand „kein Zugriff" wird deshalb nicht abgefragt, sondern aus einer leeren
Abfrage bei gleichzeitig fehlender Schreibfreigabe erschlossen.

**Ein Tag ist ein Wert**, und zwar der früheste Messwert des Kalendertags. Es geht
um das Morgengewicht unter gleichen Bedingungen. Wer ein zweites Mal loggt,
ersetzt — es entsteht kein zweiter Eintrag.

**Gelöscht wird nur, was Steady selbst geschrieben hat.** Kommt der heutige Wert von
einer Funkwaage, funktioniert *Aktualisieren*, *Löschen* ist deaktiviert. Ein
Knopf, der still fehlschlägt, ist schlimmer als ein Knopf, den es nicht gibt.

Ein App Intent bringt Shortcut, Home-Bildschirm, Sperrbildschirm und Actionbutton
direkt auf den Log-Bildschirm, Lineal bereit. Eine parametrisierte Variante
schreibt einen Wert, ohne die Oberfläche überhaupt zu öffnen.

Ein Gewicht wird **nie** protokolliert — nicht in `os_log`, nicht in einem
vergessenen `print`. Das sind Gesundheitsdaten.

## Gestaltung

Massgeblich ist [`design/steady-design-reference.md`](design/steady-design-reference.md).
Jede Zahl darin ist wörtlich gemeint. Sie stammt aus dem freigegebenen Entwurf,
nicht aus einer Interpretation davon.

Ein Abstandsraster, Basis 14, jeder Schritt ×1,68: **5 · 8 · 14 · 24 · 40 · 67**.
Radien 28, 24 und Pille. Helvetica Neue in genau zwei Schnitten, Tracking negativ
und mit der Grösse wachsend. Jede Ziffer, die sich zur Laufzeit ändert, steht in
Tabellenziffern — ohne das zappelt das Layout beim Zählen, und das ist die
sichtbarste Art, diesen Entwurf falsch zu bauen.

**Eine Akzentfarbe.** Blau heisst „bedienbar" oder „das ist der Trend". Kein Grün
für Abnahme, kein Rot für Zunahme. Gewicht farbig zu codieren macht aus einer
Messung ein Urteil, und nach oben ist kein Versagen, wenn man für Kraftaufbau die
Makros anpasst.

Die Akzente sind in **OKLCH** gesetzt, nicht in Hex, damit hell und dunkel
wahrnehmungsgleich bleiben. Und die Textfarbe auf dem Akzent ist im Dunkelmodus
**nicht** Weiss, sondern das fast schwarze `#0a1015` — der dunkle Akzent ist ein
helles Blau. Hell und Dunkel folgen ausschliesslich dem System. Es gibt keinen
Umschalter, weil es keine Einstellungen gibt.

## Architektur

```
Steady/
  Theme/         Palette, Typografie, Masse — die einzige Quelle für Farbe und Abstand
  Model/         TrendEngine, ChartGeometry — reine Werte, kein UI, kein HealthKit
  Health/        HealthService — die einzige Datei, die HealthKit importiert
  Features/      ein Ordner je Bildschirm, dazu Shared
  Intents/       App Intents für Shortcuts
design/          Entwurfsreferenz und Referenzimplementierung der Rechnung
```

**Der Rechenkern kennt keine Datenbank.** `TrendEngine` und `ChartGeometry`
arbeiten auf reinen Werten. Deshalb lässt sich der EWMA gegen von Hand gerechnete
Zahlen testen — ohne Simulator, ohne Gesundheitsdatenbank, in Millisekunden.

**Keine Ansicht importiert HealthKit.** Alles läuft über `HealthService` hinter
einem Protokoll, damit der Speicher im Test ersetzbar ist.

**Die Diagramme sind von Hand gezeichnet**, mit `Canvas` und `Path` statt Swift
Charts. Der Entwurf schreibt Strichstärken, Zeichenreihenfolge und je Bereich
unterschiedliche Punktradien vor. Von Hand gezeichnete Geometrie ist
deterministisch und überlebt das nächste OS-Update.

## Bauen

Vorausgesetzt ist Xcode 26. `xcode-select` zeigt auf vielen Rechnern auf die
CommandLineTools — die können kein iOS-Projekt bauen. Entweder dauerhaft umstellen
(`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`) oder je Aufruf
voranstellen:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Steady.xcodeproj -scheme Steady \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

HealthKit braucht etwas zum Lesen — ein echtes Gerät oder einen Simulator, in den
man Gewichtsdaten eingetragen hat. Beim ersten Start fragt die App Lese- und
Schreibzugriff auf `bodyMass` an; ohne sie erscheint der Zustand „kein Zugriff"
statt eines Diagramms.

Das Projekt nutzt synchronisierte Ordner — neue Dateien unter `Steady/` landen ohne
Zutun im Target. **`project.pbxproj` wird nicht von Hand um Quelldateien
ergänzt.**

## Credits

**Creator und Maintainer**

[**Julius Grimm**](https://github.com/justthatrandomcoder) — Idee, Design,
Rechenkern, App Store. [Levo Studio](https://levo-studio.com)

## Lizenz

Source-available. Der Code ist offen: lesen, klonen, ändern, selbst bauen, auf den
eigenen Geräten benutzen — privat und nichtkommerziell, so weit man mag.

Nicht erlaubt sind Verkauf und jede entgeltliche Weitergabe, Unterlizenzierung, das
Umlizenzieren unter andere Bedingungen und das Neuverpacken als fremdes Produkt oder
fremder Dienst. Steady ist und bleibt ein Produkt von Levo Studio.

Der vollständige Text steht in [`LICENSE`](LICENSE) — PolyForm Noncommercial
License 1.0.0.

© 2026 Levo Studio
