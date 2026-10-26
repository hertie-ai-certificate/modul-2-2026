# Fallstudie OCR und Sprachmodelle: Von Scans zu Tabellen

OCR, Sprachmodelle für Bereinigung und Klassifikation, saubere Ablage in CSVs. Modul 2 „Der Daten-Lifecycle“, Session 7.

## Dateien

| Datei | Zweck |
|---|---|
| `praxis-2-ocr-llm.Rmd` | Fallstudie mit Erläuterungen (rendert zu HTML) |
| `praxis-2-ocr-llm.R` | Das reine Skript: alle Schritte in einem Durchlauf |
| `R/pipeline.R` | Die Funktionen, die Skript und Rmd gemeinsam nutzen |
| `erzeuge_rohdaten.R` | Erzeugt die zehn Beispielscans und das Manifest (muss nur einmal laufen) |
| `daten/01_rohdaten/` | Scans (PNG, JPG, PDF), `dokumente.csv` (Manifest mit Goldstandard), `originaltexte.csv` |
| `daten/02_ocr/` | Ergebnis Schritt 1: ein `.txt` je Dokument, `ocr_texte.csv` |
| `daten/03_strukturiert/` | Ergebnis Schritt 2: bereinigter Text und extrahierte Felder |
| `daten/04_klassifikation/` | Ergebnis Schritt 3: Kategorie, Dringlichkeit, Tonfall |
| `output/` | Zusammengeführte Tabelle und Auswertung gegen den Goldstandard |

## Voraussetzungen

```r
install.packages(c("tidyverse", "tesseract", "pdftools", "magick", "ellmer"))
tesseract::tesseract_download("deu")   # deutsche Sprachdaten, einmalig
```

Für die Schritte 2 und 3 braucht es ein Sprachmodell. Zwei Wege:

**A) Open Source, lokal, ohne Schlüssel (Standard).** [Ollama](https://ollama.com) installieren und ein Modell laden:

```
ollama pull gemma3:12b    # ca. 8 GB; auf einem Laptop mit 16 GB RAM lauffähig
```

Das Skript nimmt automatisch das erste installierte Modell (bevorzugt Gemma, Qwen oder Llama); mit `MODELL <- "qwen3:8b"` lässt es sich festlegen. Die Dokumente verlassen den Rechner nicht. Kleinere Modelle (`gemma3:4b`) sind schneller, halten die vorgegebene Antwortstruktur aber weniger zuverlässig ein.

**B) Cloud-Anbieter mit API-Schlüssel.** Im Skript `ANBIETER` auf `"anthropic"`, `"openai"` oder `"gemini"` setzen. Der Schlüssel gehört in die Datei `~/.Renviron` (nicht in den Code), danach R neu starten:

```
ANTHROPIC_API_KEY=...
OPENAI_API_KEY=...
GOOGLE_API_KEY=...
```

Ohne Ollama und ohne Schlüssel läuft Schritt 1 (OCR) trotzdem; die Schritte 2 und 3 werden übersprungen, sofern ihre Ergebnisse nicht schon in `daten/` liegen.

## Ablauf

1. Arbeitsverzeichnis auf diesen Ordner setzen.
2. `praxis-2-ocr-llm.R` ausführen oder `praxis-2-ocr-llm.Rmd` rendern.
3. Ergebnisse liegen in `daten/02_ocr` bis `daten/04_klassifikation` und in `output/`.

Jeder Schritt wird nur berechnet, wenn sein Ergebnis noch nicht vorliegt. Zum Neuberechnen im Skript `NEU <- TRUE` setzen oder die betreffende CSV löschen.

Alle Personen, Adressen und Vorgänge in den Beispieldaten sind erfunden.
