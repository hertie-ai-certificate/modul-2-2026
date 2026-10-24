# Praxis-Session II: Von Scans zu Tabellen ---------------------------------------
# OCR, Sprachmodelle für Bereinigung und Klassifikation, saubere Ablage in CSVs
#
# Modul 2 "Der Daten-Lifecycle", Session 7. Simon Munzert, Hertie School.
#
# So läuft es:
#   1. Arbeitsverzeichnis auf diesen Ordner setzen (RStudio: Session > Set Working Directory).
#   2. Sprachmodell bereitstellen. Standard ist Ollama (ollama.com): installieren, dann im
#      Terminal `ollama pull gemma3:12b` (oder ein anderes Modell; das Skript nimmt das erste
#      installierte). Alternativ ein Cloud-Anbieter mit Schlüssel in ~/.Renviron,
#      z. B. ANTHROPIC_API_KEY=..., und ANBIETER entsprechend setzen.
#      Ohne Modell läuft nur Schritt 1 (OCR); Schritt 2 und 3 werden übersprungen,
#      sofern ihre Ergebnisse nicht schon in daten/ liegen.
#   3. Skript ausführen. Jeder Schritt schreibt seine Ergebnisse in einen eigenen Ordner.
#
# Die Dokumentation mit Erläuterungen steht in praxis-2-ocr-llm.Rmd.

source("R/pipeline.R")

# Einstellungen --------------------------------------------------------------------

ANBIETER <- "ollama"      # "ollama" (lokal, ohne Schlüssel), "anthropic", "openai" oder "gemini"
MODELL   <- NULL          # NULL = Standardmodell des Anbieters; bei Ollama z. B. "gemma3:12b" oder "qwen3:8b"
NEU      <- FALSE         # TRUE = alles neu berechnen, auch wenn Ergebnisse vorliegen

# Schritt 0: Was liegt vor? --------------------------------------------------------

manifest <- read_csv("daten/01_rohdaten/dokumente.csv", show_col_types = FALSE)
message("Dokumente im Eingang: ", nrow(manifest))

# Schritt 1: OCR ---------------------------------------------------------------------

ocr <- schritt_ocr(manifest, force = NEU)

# Zwischenblick: Wie gut war die Texterkennung?
originale <- read_csv("daten/01_rohdaten/originaltexte.csv", show_col_types = FALSE)
ocr_guete <- ocr |>
  left_join(originale, by = "id") |>
  mutate(worttrefferquote = map2_dbl(ocr_text, text, worttrefferquote)) |>
  select(id, datei, ocr_zeichen, worttrefferquote)
speichere_csv(ocr_guete, "output/ocr_guete.csv")
print(ocr_guete)

# Schritt 2 und 3: Sprachmodell ------------------------------------------------------

llm_ok <- llm_schluessel_vorhanden(ANBIETER)
ergebnisse_da <- file.exists("daten/04_klassifikation/anliegen_klassifiziert.csv")

if (!llm_ok && !ergebnisse_da) {
  message("Kein Sprachmodell erreichbar (", ANBIETER, "). Schritte 2 bis 4 werden übersprungen.")
} else {
  chat <- if (llm_ok) erzeuge_chat(ANBIETER, MODELL, system_prompt_verwaltung) else NULL
  strukturiert  <- schritt_strukturieren(ocr, chat, force = NEU)
  klassifiziert <- schritt_klassifizieren(strukturiert, chat, force = NEU)

  # Schritt 4: Zusammenführen und auswerten ---------------------------------------

  message("Schritt 4: Zusammenführen und auswerten")
  final <- manifest |>
    select(id, datei, gold_kategorie = kategorie, gold_dringlichkeit = dringlichkeit) |>
    left_join(strukturiert |> select(-datei), by = "id") |>
    left_join(klassifiziert, by = "id") |>
    relocate(kategorie, dringlichkeit, tonfall, .after = datei)
  speichere_csv(final, "output/anliegen_final.csv")

  auswertung <- final |>
    summarize(
      n = n(),
      kategorie_korrekt     = mean(kategorie == gold_kategorie),
      dringlichkeit_korrekt = mean(dringlichkeit == gold_dringlichkeit),
      datum_erkannt         = mean(!is.na(datum_iso) & datum_iso != ""))
  speichere_csv(auswertung, "output/auswertung.csv")
  print(auswertung)

  final |>
    select(id, kategorie, gold_kategorie, dringlichkeit, gold_dringlichkeit, zusammenfassung) |>
    print(n = Inf, width = Inf)
}
