# Funktionen der Pipeline "Von Scans zu Tabellen" -----------------------------
# Wird vom Skript praxis-2-ocr-llm.R und vom Rmd gleichermaßen geladen.
#
# Vier Schritte, vier Ordner:
#   daten/01_rohdaten        Scans (PNG/JPG/PDF) + Manifest dokumente.csv
#   daten/02_ocr             Rohtext je Dokument (OCR) + ocr_texte.csv
#   daten/03_strukturiert    bereinigter Text + extrahierte Felder (LLM)
#   daten/04_klassifikation  Kategorie, Dringlichkeit, Tonfall (LLM)
#   output                   zusammengeführte Tabelle + Auswertung
#
# Jeder Schritt liest nur den Ordner davor und schreibt nur in seinen eigenen.
# Liegt das Ergebnis eines Schritts schon vor, wird es geladen statt neu
# berechnet (so kostet ein zweiter Lauf keine API-Aufrufe).

library(tidyverse)
library(tesseract)
library(pdftools)
library(magick)
library(ellmer)

# Hilfsfunktionen --------------------------------------------------------------

speichere_csv <- function(df, pfad) {
  dir.create(dirname(pfad), showWarnings = FALSE, recursive = TRUE)
  write_csv(df, pfad)
  message("  gespeichert: ", pfad, " (", nrow(df), " Zeilen, ", ncol(df), " Spalten)")
  invisible(df)
}

# Führt `berechne()` nur aus, wenn `pfad` noch nicht existiert (oder force = TRUE)
lade_oder_berechne <- function(pfad, berechne, force = FALSE) {
  if (file.exists(pfad) && !force) {
    message("  vorhanden, wird geladen: ", pfad)
    return(read_csv(pfad, show_col_types = FALSE))
  }
  speichere_csv(berechne(), pfad)
}

# Schritt 1: OCR -----------------------------------------------------------------

# Ein Dokument als Bild laden: PDFs werden gerendert (erste Seite), Bilder direkt gelesen
als_bild <- function(datei, dpi = 200) {
  if (str_detect(tolower(datei), "\\.pdf$")) {
    image_read(pdf_render_page(datei, page = 1, dpi = dpi))
  } else {
    image_read(datei)
  }
}

# Vorverarbeitung: Graustufen, Flecken entfernen, Schwarz-Weiß-Schwelle.
# Bei verrauschten Scans macht das den Unterschied zwischen 65% und 95% erkannten Wörtern.
bild_vorbereiten <- function(bild) {
  bild |>
    image_convert(colorspace = "gray") |>
    image_despeckle() |>
    image_threshold("white", "60%") |>
    image_threshold("black", "40%")
}

ocr_dokument <- function(datei, sprache = "deu", vorverarbeitung = TRUE) {
  engine <- tesseract(sprache)
  bild <- als_bild(datei)
  if (vorverarbeitung) bild <- bild_vorbereiten(bild)
  bild |> ocr(engine = engine) |> str_squish_lines()
}

str_squish_lines <- function(text) {
  text |> str_split("\n") |> pluck(1) |> str_squish() |> discard(~ .x == "") |> paste(collapse = "\n")
}

schritt_ocr <- function(manifest, rohdaten_ordner = "daten/01_rohdaten", ziel = "daten/02_ocr", force = FALSE) {
  message("Schritt 1: OCR")
  lade_oder_berechne(file.path(ziel, "ocr_texte.csv"), force = force, berechne = function() {
    dir.create(ziel, showWarnings = FALSE, recursive = TRUE)
    manifest |>
      mutate(ocr_text = map_chr(datei, function(d) {
        message("  OCR: ", d)
        text <- ocr_dokument(file.path(rohdaten_ordner, d))
        writeLines(text, file.path(ziel, paste0(tools::file_path_sans_ext(d), ".txt")))
        text
      })) |>
      select(id, datei, ocr_text) |>
      mutate(ocr_zeichen = nchar(ocr_text))
  })
}

# Schritt 2 und 3: Sprachmodell --------------------------------------------------

# Ein Chat-Objekt für den gewählten Anbieter. Der Schlüssel kommt aus der
# Umgebungsvariable (GOOGLE_API_KEY, ANTHROPIC_API_KEY oder OPENAI_API_KEY),
# nie aus dem Code. "ollama" braucht keinen Schlüssel: ein lokal laufendes
# Open-Source-Modell (https://ollama.com, z. B. `ollama pull gemma3:12b`).
erzeuge_chat <- function(anbieter = c("gemini", "anthropic", "openai", "ollama"), modell = NULL, system_prompt = NULL) {
  anbieter <- match.arg(anbieter)
  switch(anbieter,
    gemini    = chat_google_gemini(system_prompt = system_prompt, model = modell, echo = "none"),
    anthropic = chat_anthropic(system_prompt = system_prompt, model = modell, echo = "none"),
    openai    = chat_openai(system_prompt = system_prompt, model = modell, echo = "none"),
    ollama    = chat_ollama(system_prompt = system_prompt, model = modell %||% ollama_standardmodell(), echo = "none"))
}

# Welche Modelle sind bei Ollama lokal installiert? (leer, wenn Ollama nicht läuft)
ollama_modelle <- function() {
  tryCatch({
    httr2::request(Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434")) |>
      httr2::req_url_path("/api/tags") |> httr2::req_timeout(2) |> httr2::req_perform() |>
      httr2::resp_body_json() |> purrr::pluck("models") |> purrr::map_chr("name")
  }, error = function(e) character())
}

# Ohne Angabe: das erste installierte Modell, bevorzugt eine Gemma-, Qwen- oder Llama-Variante
ollama_standardmodell <- function() {
  m <- ollama_modelle()
  if (length(m) == 0) stop("Ollama läuft, aber es ist kein Modell installiert. Z. B.: ollama pull gemma3:12b")
  bevorzugt <- m[str_detect(m, "^(gemma|qwen|llama)")]
  modell <- if (length(bevorzugt) > 0) bevorzugt[1] else m[1]
  message("  Ollama-Modell: ", modell)
  modell
}

# Ist der Anbieter nutzbar? Bei den Cloud-Anbietern: Schlüssel gesetzt; bei Ollama: Server läuft
llm_schluessel_vorhanden <- function(anbieter = "gemini") {
  if (anbieter == "ollama") {
    return(tryCatch({ httr2::request(Sys.getenv("OLLAMA_BASE_URL", "http://localhost:11434")) |>
                        httr2::req_timeout(2) |> httr2::req_perform(); TRUE }, error = function(e) FALSE))
  }
  var <- c(gemini = "GOOGLE_API_KEY", anthropic = "ANTHROPIC_API_KEY", openai = "OPENAI_API_KEY")[[anbieter]]
  nzchar(Sys.getenv(var)) || (anbieter == "gemini" && nzchar(Sys.getenv("GEMINI_API_KEY")))
}

system_prompt_verwaltung <- paste(
  "Du unterstützt den Bürgerservice einer deutschen Stadtverwaltung bei der Erfassung",
  "eingehender Schreiben. Du arbeitest nur mit dem gelieferten Text, erfindest keine",
  "Angaben und kennzeichnest Unsicheres ausdrücklich. Antworte auf Deutsch.")

# Antwortstrukturen: Das Modell MUSS genau diese Felder liefern ("structured output")
typ_bereinigung <- type_object(
  "Bereinigte Fassung eines OCR-Textes",
  text_bereinigt   = type_string("Der Text mit korrigierten OCR-Fehlern (Buchstabendreher, falsche Zeichen, zerrissene Wörter). Inhalt und Wortlaut sonst unverändert lassen; nichts hinzufügen."),
  ocr_qualitaet    = type_enum(c("gut", "mittel", "schlecht"), "Wie gut war der OCR-Text lesbar?"),
  unsichere_stellen = type_string("Stellen, die trotz Korrektur unsicher bleiben, durch Semikolon getrennt; leer, wenn keine.")
)

typ_struktur <- type_object(
  "Kerndaten eines Bürgerschreibens",
  absender            = type_string("Name der absendenden Person(en), wie im Schreiben"),
  absender_adresse    = type_string("Postanschrift der absendenden Person, falls angegeben; sonst leer", required = FALSE),
  datum_iso           = type_string("Datum des Schreibens im Format JJJJ-MM-TT; leer, wenn nicht erkennbar", required = FALSE),
  betroffener_ort     = type_string("Ort oder Adresse, auf die sich das Anliegen bezieht"),
  zusammenfassung     = type_string("Das Anliegen in einem Satz, maximal 25 Wörter"),
  gewuenschte_massnahme = type_string("Was die Person konkret von der Verwaltung erwartet, in wenigen Worten"),
  telefon             = type_string("Telefonnummer, falls angegeben; sonst leer", required = FALSE)
)

kategorien <- c("Straßen und Verkehr", "Grünflächen und Spielplätze", "Abfall und Sauberkeit",
                "Beleuchtung", "Lärm", "Sonstiges")

typ_klassifikation <- type_object(
  "Einordnung eines Bürgerschreibens",
  kategorie     = type_enum(kategorien, "Zuständiger Themenbereich"),
  dringlichkeit = type_enum(c("hoch", "mittel", "niedrig"), "hoch = Gefahr für Personen oder akuter Schaden; mittel = sollte zeitnah behoben werden; niedrig = kein Zeitdruck, Hinweis oder Lob"),
  tonfall       = type_enum(c("sachlich", "verärgert", "dankbar"), "Grundton des Schreibens"),
  begruendung   = type_string("Ein Satz, warum diese Einordnung")
)

# Mehrere Texte parallel an das Modell schicken, Ergebnis als Tabelle
# Lokale Modelle (Ollama) bearbeiten eine Anfrage nach der anderen; Cloud-Anbieter vier parallel.
llm_batch <- function(chat, anweisung, texte, typ) {
  prompts <- map(texte, ~ paste0(anweisung, "\n\n--- TEXT ---\n", .x, "\n--- ENDE ---"))
  lokal <- any(grepl("Ollama", class(chat$get_provider())))
  parallel_chat_structured(chat, prompts, type = typ, max_active = if (lokal) 1 else 4) |> as_tibble()
}

schritt_strukturieren <- function(ocr_df, chat, ziel = "daten/03_strukturiert", force = FALSE) {
  message("Schritt 2: Bereinigen und strukturieren (LLM)")
  lade_oder_berechne(file.path(ziel, "anliegen_strukturiert.csv"), force = force, berechne = function() {
    bereinigt <- llm_batch(chat, "Korrigiere die OCR-Fehler in diesem Schreiben.", ocr_df$ocr_text, typ_bereinigung)
    felder    <- llm_batch(chat, "Extrahiere die Kerndaten dieses Schreibens.", bereinigt$text_bereinigt, typ_struktur)
    bind_cols(ocr_df |> select(id, datei), bereinigt, felder)
  })
}

schritt_klassifizieren <- function(strukturiert_df, chat, ziel = "daten/04_klassifikation", force = FALSE) {
  message("Schritt 3: Klassifizieren (LLM)")
  lade_oder_berechne(file.path(ziel, "anliegen_klassifiziert.csv"), force = force, berechne = function() {
    klassen <- llm_batch(chat, "Ordne dieses Schreiben ein.", strukturiert_df$text_bereinigt, typ_klassifikation)
    bind_cols(strukturiert_df |> select(id), klassen)
  })
}

# Schritt 4: Auswertung gegen den Goldstandard -----------------------------------

# Worttrefferquote: Anteil der Wörter des Originals (ab 3 Buchstaben), die im OCR-Text
# wiedergefunden werden. 1 = alle Wörter erkannt. Einfach, aber für den Vergleich ausreichend.
woerter <- function(x) x |> str_to_lower() |> str_extract_all("[a-zäöüß]{3,}") |> pluck(1) |> unique()
worttrefferquote <- function(ocr_text, original) {
  o <- woerter(original)
  if (length(o) == 0) return(NA_real_)
  mean(o %in% woerter(ocr_text))
}
