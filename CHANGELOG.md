# Änderungen

## 1.4.0

- Sicherheitsabfrage vor dem Löschen einzelner Buchungen und automatischer Raten
- Startkapital kann gelöscht werden, ohne die Ersteinrichtung erneut auszulösen
- Automatische Raten können bearbeitet, pausiert und fortgesetzt werden
- Pausierte Tage werden nach dem Fortsetzen nicht rückwirkend gebucht
- Nächster Buchungstermin wird in der Ratenliste angezeigt
- Buchungstag bleibt ausschließlich bei monatlichen Raten sichtbar
- Kontostand wird automatisch aus der Historie berechnet
- Abweichende Altdaten werden einmalig über einen verlustfreien Bestandsübertrag migriert
- Bestehende Charakterdaten, Ratenkennungen und Buchungen bleiben erhalten

## 1.3.4

- Doppelten Animationsbutton „Benutzen“ aus der Kategorie „Allgemein“ entfernt
- „Benutzen / Craften“ bleibt als gemeinsamer Eintrag erhalten

## 1.3.3

- Reguläre Serverantwort wird passiv als charakterbezogene Animations-Freigabeliste verwendet
- Befehle, die der Server für Volk oder Klasse nicht liefert, werden automatisch ausgeblendet
- Fünf im aktuellen Worgen-Datensatz fehlende Befehle erscheinen dort nicht mehr
- Ungültige oder auffällig kleine Serverantworten werden ignoriert, damit die Liste nicht versehentlich geleert wird
- Keine aktive Serveranfrage, keine Diagnosespeicherung und kein Testfenster im Hauptaddon

## 1.3.2

- Nicht verfügbare Animationen werden vollständig aus den Kategorien ausgeblendet
- Nicht verfügbare Favoriten werden ebenfalls verborgen, bleiben aber gespeichert
- Verbleibende Animationen rücken ohne leere Lücken automatisch nach

## 1.3.1

- Nicht verfügbare Animationen bleiben sichtbar und werden deutlich ausgegraut
- Ausgegraute Animationsbuttons können keine Makros ausführen
- Favorisierte Animationen bleiben auch dann im Favoritenbereich sichtbar
- Tooltip erklärt den Grund der deaktivierten Animation

## 1.3.0

- Produktive Animationsfilterung anhand der ausgelesenen `disabledFlags` ergänzt
- Geschlecht sowie menschliche und worgenartige Worgenform werden berücksichtigt
- Animationsliste und Favoriten werden bei einem Formwechsel automatisch aktualisiert
- Geschützte Schaltflächen werden während eines Kampfes nicht verändert; die Aktualisierung wird bis zum Kampfende aufgeschoben
- Neue Serverbefehle `Benutzen`, `Salutieren dauerhaft stramm` und `Servierer 1–3` ergänzt
- Fünf weiterhin bekannte ältere Befehle bleiben aus Kompatibilitätsgründen erhalten

## 1.2.12

- Animations-Datenleser und kopierbares Diagnosefenster aus Kitar Companion entfernt
- Diagnosebefehle aus der Hilfe und dem Hauptaddon entfernt
- Testfunktionen stehen künftig ausschließlich im optionalen Addon Kitar Animation Debug bereit

## 1.2.11

- Doppelten Serverabruf der Animationsliste entfernt
- Serverantwort wird nur noch passiv für das Diagnosefenster mitgelesen
- Kollision durch erneute Registrierung von `/zuruecksetzen` und weiteren Animationsbefehlen verhindert
- `/kitar anidaten neu` löst aus Sicherheitsgründen keinen zusätzlichen Abruf mehr aus

## 1.2.10

- Eigenes kopierbares Fenster für empfangene Server-Animationsdaten ergänzt
- Datensatz wird für eine zuverlässige Ausgabe deterministisch sortiert und als Lua-Text formatiert
- Text wird beim Öffnen automatisch vollständig markiert und kann direkt mit `Strg+C` kopiert werden
- Schaltfläche „Alles markieren“ und Zeichen-/Zeilenzähler ergänzt

## 1.2.9

- Serverseitige Animationsliste wird über die optionale `C_Slops`-Schnittstelle angefordert
- Empfangene Animationsdaten werden als begrenzte, serialisierbare Diagnosekopie gespeichert
- `/kitar anidaten` zeigt den letzten empfangenen Datensatz an
- `/kitar anidaten neu` fordert die Animationsdaten erneut beim Server an
- Ohne verfügbare Serverschnittstelle arbeitet das Addon unverändert mit seiner bisherigen Animationsliste weiter

## 1.2.8

- Ungültige oder zukünftige `lastRunDay`-, `lastRunMonth`- und `lastRunYear`-Werte blockieren automatische Raten nicht mehr
- Beschädigte Buchungs- und Rateneinträge werden beim Laden sicher übersprungen oder normalisiert
- Lücken in gespeicherten Buchungs- und Ratenlisten werden geschlossen, ohne spätere gültige Einträge zu verlieren
- Fensteranker, Minimap-Position, Minimap-Radius und ausgewählte Finanzseite werden vor der Verwendung validiert

## 1.2.7

- Leere, ungültige oder zukünftige `lastPayout`-Werte blockieren die reguläre Rate des aktuellen Tages nicht mehr
- Offline-Nachbuchungen werden zum Schutz vor beschädigten Daten auf höchstens fünf Jahre begrenzt
- Das alte eigenständige Animationsfenster und dessen Minimap-Symbol werden bei der gemeinsamen Migration ausgeblendet

## 1.2.6

- Ein manuell zurückgesetztes `lastPayout` gilt nun tatsächlich für alle vorhandenen Raten
- Das Erstellungsdatum einer Rate blockiert die gemeinsame gewünschte Rücknachbuchung nicht mehr
- Bereits heute geprüfte Einzelraten werden im Catch-up für den aktuellen Tag nicht doppelt gebucht

## 1.2.5

- Gemeinsamen Finanz-Stichtag `lastPayout` für alle automatischen Raten eingeführt
- Der bisherige Wert `lastRateCatchup` wird beim Update automatisch migriert und anschließend entfernt
- Offline-Nachbuchungen beginnen für alle Raten am gemeinsamen Stichtag
- Das Startdatum jeder Rate verhindert weiterhin Auszahlungen für Zeiträume vor ihrer Erstellung
- Auch `/kitar nachbuchen` aktualisiert den gemeinsamen Stichtag
- Beim Festlegen des Startvermögens wird `lastPayout` auf den aktuellen Kalendertag gesetzt

## 1.2.4

- `/kitar nachbuchen` und `/kfin nachbuchen` für eine manuelle Prüfung offener automatischer Raten ergänzt
- Der neue Befehl zeigt Anzahl und Vermögensänderung der erfolgten Nachbuchungen an
- Bereits verarbeitete Ratentage werden auch bei wiederholter manueller Prüfung nicht doppelt gebucht

## 1.2.3

- Stabile interne IDs für automatische Raten ergänzt
- Gleichnamige gelöschte und neu angelegte Raten werden eindeutig unterschieden
- Bestehende direkte Ratenbuchungen erhalten beim Update nachträglich ihre eindeutige Zuordnung
- Alte Finanzmodule werden während der einmaligen Datenübernahme vor ihrem Ratenlauf stillgelegt
- Offline-Einnahmen und -Ausgaben werden bei gemischten Nachbuchungen getrennt protokolliert
- Vollständig ausgeglichene Offline-Raten bleiben dadurch in der Historie sichtbar

## 1.2.2

- Doppelte Auszahlung bereits heute gebuchter Raten beim Update verhindert
- UI-Reset behält Animationsfavoriten und Migrationsstatus bei
- UI-Reset setzt nun auch die Position des Finanzfensters zurück
- Minimierung, Kategorien und Sichtbarkeit des Animationsfensters werden beim Reset sofort aktualisiert
- Das Löschen einzelner Historieneinträge deaktiviert automatische Raten nicht mehr
- Ratenstart und Buchungshistorie verwenden einheitlich die WoW-Kalenderzeit

## 1.2.1

- Fehler behoben, durch den eine am Erstellungstag fällige Rate als geprüft markiert, aber nicht gebucht wurde
- Heute fällige neue Raten werden nun unmittelbar nach dem Anlegen gebucht
- Bereits heute angelegte und dadurch übersprungene Raten werden beim Update einmalig sicher nachgetragen
- Tageswechsel wird während einer laufenden Spielsitzung automatisch erkannt
- Ratenprüfung läuft dadurch nicht mehr ausschließlich beim Einloggen

## 1.2.0

- Sicherheitskalender mit allen 2.191 Tagen von 2026 bis einschließlich 2031 ergänzt
- Jeden Kalendertag fest einem Wochentag von Montag bis Sonntag zugeordnet
- Vollständige Kalenderprüfung beim Laden des Addons eingebaut
- Dynamische Wochentagsberechnung als Rückfalllösung außerhalb des Zeitraums oder bei einer beschädigten Datei beibehalten

## 1.1.3

- Bordeauxrot als festes Kitar-Farbschema definiert
- Gold- und Klassenfarben vollständig entfernt
- Farbauswahl aus Einstellungen, Slash-Befehlen und gespeicherten Profilen entfernt
- Einstellungsseite nach dem Entfernen der Farbauswahl kompakter angeordnet

## 1.1.2

- Datumsanzeige der Finanzhistorie auf das europäische Format `Tag.Monat.Jahr` umgestellt
- Vorhandene ISO-Zeitstempel werden nur für die Anzeige umgewandelt und bleiben intern kompatibel

## 1.1.1

- Sicheren Ratentest über `/kitar ratentest JJJJ-MM-TT` ergänzt
- Alternative Eingabe über `/kfin test TT.MM.JJJJ` ergänzt
- Testausgabe zeigt Wochentag, Fälligkeit, Betrag und Zeitplan jeder Rate
- Simulation verändert weder Vermögen noch Buchungshistorie

## 1.1.0

- Wählbare Arbeitstage von Montag bis Sonntag für tägliche Raten ergänzt
- Frei wählbaren Buchungstag von 1 bis 31 für monatliche Raten ergänzt
- Letzten Kalendertag als automatische Ausweichregel für kürzere Monate eingebaut
- Offline-Nachbuchung berücksichtigt nun die individuellen Arbeitstage und Buchungstage
- Ratenübersicht zeigt den jeweiligen Zeitplan kompakt an
- Bestehende tägliche Raten abwärtskompatibel auf alle Wochentage übernommen

## 1.0.2

- Aktionsleisten-Design vollständig aus Kitar Companion entfernt
- Zugehörige Einstellungen und gespeicherte Konfigurationswerte entfernt
- Beschreibung und Dokumentation auf Animationen und Finanzen fokussiert

## 1.0.1

- Marken-Kapsel „Kitar Companion“ in Animations- und Finanzfenster mittig ausgerichtet
- Zusätzliche Beschriftung „Finanzen“ rechts oben entfernt
- Rechte Headerseite des Finanzfensters auf den Schließen-Button reduziert

## 1.0.0 – Kitar Companion

- Addon vollständig von `SH Roleplay` zu `Kitar Companion` umbenannt
- Eigenständigen Addonordner `Kitar_Companion` und neue TOC angelegt
- Sichtbare Titel, Chatpräfix, Frames, Texturpfade und Befehle auf den neuen Namen umgestellt
- Neue Befehle `/kitar`, `/kani` und `/kfin` ergänzt
- Einstellungen aus `SHRoleplayDB` werden bei einer einmaligen gemeinsamen Anmeldung nach `KitarCompanionDB` kopiert
- Charakterbezogene Finanzdaten aus `SHFinanzenDB` werden beim Ausloggen unter Kitar Companion gespeichert
- Alte Fenster und Minimap-Symbole werden während der Migration ausgeblendet

## 0.6.5

- „Rollenspiel-Vermögen“ zu „Vermögen“ verkürzt
- Versalien in Finanzüberschriften, Formularen und Tabellen durch normale Schreibweise ersetzt
- Finanz- und Animationsfenster über die gesamte freie Fensterfläche verschiebbar gemacht
- Buttons, Eingabefelder, Animationsaktionen und Scrollbar-Griffe bleiben normal bedienbar

## 0.6.4

- Einnahme-Schaltflächen unter „Buchung“ und „Raten“ grün eingefärbt
- Ausgabe-Schaltflächen unter „Buchung“ und „Raten“ rot eingefärbt
- Eigene dezente Grund-, Hover- und Auswahlzustände für beide Buchungsarten ergänzt

## 0.6.3

- Linksklick auf das Minimap-Symbol öffnet nun die Finanzen
- Rechtsklick auf das Minimap-Symbol öffnet nun die Animationen
- Mittlere Maustaste öffnet die Einstellungen
- Eigenen Reset für charakterbezogene Finanzdaten in den Einstellungen ergänzt
- Sicherheitsabfrage vor dem Löschen von Startvermögen, Buchungen und Raten ergänzt

## 0.6.2

- Überlappung zwischen Beschreibungsfeld und Buchungsbutton behoben
- Buchungsbutton sauber rechts neben dem Beschreibungsfeld ausgerichtet
- Finanzüberschriften, Formularlabels und Tabellenspalten an das aktive SH-Farbschema gekoppelt
- Raten- und Historienbeträge ohne überflüssige Null-Einheiten kompakter dargestellt

## 0.6.1

- Hintergrundtextur des Finanzfensters bis an den tatsächlichen unteren Fensterrand verlängert
- Verfrüht endenden ornamentalen Innenrahmen bei den Ratenkarten korrigiert
- Texturausschnitt des Startvermögen-Fensters ebenfalls angeglichen

## 0.6.0

- `SH Finanzen` als eigenständiges Modul in `SH Roleplay` integriert
- Vorhandene charakterbezogene `SHFinanzenDB`-Daten und Raten können durch eine einmalige gemeinsame Anmeldung übernommen werden
- Altes Finanzfenster und altes Minimap-Symbol werden während dieser Migration ausgeblendet
- Modernes Finanzfenster mit Übersicht, Buchungen, Historie und Ratenverwaltung ergänzt
- Startvermögen sowie tägliche und monatliche automatische Raten beibehalten
- Offline-Nachbuchung für verpasste Raten übernommen
- `/shfin`, `/shrp finanzen`, Einstellungsbutton und Umschalt-Linksklick auf das Minimap-Symbol ergänzt

## 0.5.3

- Separate „Animationen“-Kapsel aus dem Header entfernt
- Zusätzliche freie Drag-Fläche im Header geschaffen

## 0.5.2

- Durchgehende massive Headerleiste entfernt
- „SH Roleplay“ und „Animationen“ in zwei getrennte kompakte Kapseln aufgeteilt
- Header-Icons stehen nun als eigenständige Schaltflächen
- Transparenter Zwischenraum bleibt als Drag-Fläche nutzbar

## 0.5.1

- Lua-Fehler beim Initialisieren der abgerundeten Header-Knöpfe behoben
- Rundungs-Texturdaten und internes Kennzeichen verwenden nun getrennte Felder

## 0.5.0

- Header als abgerundete, halbtransparente 9-Slice-Fläche neu gestaltet
- Reset-, Minimieren-, Erweitern- und Schließen-Symbole als eigene TGA-Assets ergänzt
- Header-Schaltflächen abgerundet und mit Theme-Hover versehen
- Tooltips für alle Header-Schaltflächen ergänzt

## 0.4.1

- Kategorien und Favoritenkopf mit sieben Pixel Radius abgerundet
- Eigene weichgezeichnete TGA-Eckmasken für WoW 9.2.7 ergänzt
- Hover- und Theme-Farben an die neuen Rundungen angebunden

## 0.4.0

- Neue Kategorie „Favoriten“ oberhalb von „Alltag“ ergänzt
- Kontur- und Goldstern neben jeder Animation hinzugefügt
- Favoriten lassen sich aus normalen Kategorien und aus der Favoritenliste umschalten
- Auswahl wird dauerhaft in `SHRoleplayDB` gespeichert
- Favoriten behalten die ursprüngliche Kategorienreihenfolge
- Leerer Favoritenbereich zeigt einen kurzen Bedienhinweis

## 0.3.1

- Kategorien und Aktionsknöpfe rechts um 18 Pixel gekürzt
- Festen Sicherheitsabstand zwischen Inhalt und eigener Scrollleiste ergänzt

## 0.3.0

- Ornamentalen Rahmen durch ein minimalistisches V3-Panel ersetzt
- Außenabstände und Header kompakter gestaltet
- Titeltypografie beruhigt und rote Akzente deutlich reduziert
- Eigene schmale Scrollbar mit Mausrad-, Klick- und Drag-Bedienung ergänzt
- Kategorien als zurückhaltende Karten mit Hover-Zustand überarbeitet
- Mehr nutzbare Fläche für die Animationsliste geschaffen

## 0.2.0

- Eigenes modernes Dark-Fantasy-Panel generiert und als Power-of-Two-TGA integriert
- Animationsfenster auf ein breiteres, kompakteres Layout umgestellt
- Standard-Blizzard-Knöpfe durch eigene dunkle Buttons mit Theme-Hover ersetzt
- Header, Scrollbereich und Kategorien optisch vereinheitlicht

## 0.1.0

- Erstes installierbares RP-Gesamtpaket für WoW 9.2.7
- Aktionsleisten-Theme mit drei Farbschemata
- `SH_Animations` als eigenes Modul integriert
- Zeichencodierung der deutschen Texte korrigiert
- Fensterzustände und aufgeklappte Kategorien speicherbar gemacht
- Minimap-Steuerung und Einstellungsseite ergänzt
- Kompatiblen Befehl `/shani` beibehalten
