# Erzeugt die Rohdaten für die Praxis-Session: zehn erfundene Bürgeranliegen
# an eine Stadtverwaltung, als "Scans" (PNG/JPG/PDF) mit Störungen, dazu ein
# Manifest (dokumente.csv) mit den Goldstandard-Angaben für die Auswertung.
#
# Muss nur einmal laufen; die Ergebnisse liegen in daten/01_rohdaten/.
# Vorhandene Scans werden nicht überschrieben (nur_neue <- TRUE), damit die
# Ergebnisse der Pipeline reproduzierbar bleiben.
# Alle Personen, Adressen und Vorgänge sind erfunden.

library(tidyverse)
library(magick)

set.seed(2026)
nur_neue <- TRUE
ziel <- "daten/01_rohdaten"
dir.create(ziel, showWarnings = FALSE, recursive = TRUE)

# Die Anliegen ---------------------------------------------------------------

anliegen <- tribble(
  ~id, ~absender, ~absender_adresse, ~datum, ~betroffener_ort, ~kategorie, ~dringlichkeit, ~text,
  "A01", "Renate Vogel", "Lindenstraße 14, 31234 Musterstadt", "03.09.2026", "Lindenstraße, Höhe Hausnummer 14",
  "Straßen und Verkehr", "hoch",
  "Sehr geehrte Damen und Herren,\n\nseit etwa drei Wochen befindet sich vor unserem Haus in der Lindenstraße 14 ein tiefes Schlagloch, das inzwischen rund 40 cm breit ist. Gestern ist ein Radfahrer gestürzt und musste vom Rettungsdienst versorgt werden. Ich bitte dringend um Ausbesserung, bevor weitere Unfälle passieren.\n\nMit freundlichen Grüßen\nRenate Vogel",
  "A02", "Familie Yilmaz", "Am Stadtpark 3, 31234 Musterstadt", "7.9.2026", "Stadtpark, Spielplatz am Teich",
  "Grünflächen und Spielplätze", "mittel",
  "Hallo liebes Grünflächenamt,\n\nam Spielplatz im Stadtpark (beim Teich) ist die Kette der großen Schaukel gerissen und hängt nur noch an einer Seite. Die Schaukel ist mit Flatterband abgesperrt, aber die Kinder nutzen sie trotzdem. Könnten Sie das bitte reparieren? Der Sandkasten müsste auch mal wieder gereinigt werden, da liegen Glasscherben.\n\nViele Grüße\nFamilie Yilmaz",
  "A03", "Dr. Hartmut Krüger", "Bergweg 22, 31234 Musterstadt", "2026-09-09", "Bergweg 20 bis 26",
  "Abfall und Sauberkeit", "niedrig",
  "Betreff: Nicht abgeholte Papiertonnen\n\nSehr geehrte Damen und Herren,\n\nam Dienstag, dem 8. September, wurden im Bergweg (Hausnummern 20 bis 26) die blauen Papiertonnen nicht geleert, obwohl sie laut Abfuhrkalender dran gewesen wären. Die Tonnen stehen seitdem am Straßenrand. Bitte holen Sie die Abfuhr nach oder teilen Sie mir einen Termin mit.\n\nHochachtungsvoll\nDr. Hartmut Krüger",
  "A04", "Sabine Oswald", "Mühlenweg 7, 31234 Musterstadt", "11.09.2026", "Mühlenweg 5 bis 9",
  "Beleuchtung", "mittel",
  "Guten Tag,\n\ndie Straßenlaterne vor dem Haus Mühlenweg 7 ist seit mindestens zwei Wochen dunkel, die Laterne gegenüber flackert. Der Gehweg ist abends stockfinster, und viele ältere Leute wohnen hier. Bitte um Reparatur.\n\nDanke und Gruß\nSabine Oswald\nTel. 0171 2345678",
  "A05", "Jonas Petersen", "Hafenstraße 41, 31234 Musterstadt", "12. September 2026", "Hafenstraße 41, Gaststätte Zum Anker",
  "Lärm", "hoch",
  "Sehr geehrtes Ordnungsamt,\n\nich wohne über der Gaststätte Zum Anker in der Hafenstraße 41. Seit der neue Pächter da ist, läuft an Freitagen und Samstagen bis nach 2 Uhr nachts laute Musik auf der Terrasse. Mehrfache Bitten an den Betreiber haben nichts gebracht. Ich habe kleine Kinder und bitte Sie, einzuschreiten. Am letzten Samstag habe ich um 1:40 Uhr die Polizei gerufen.\n\nMit freundlichen Grüßen\nJonas Petersen",
  "A06", "Gisela und Werner Brandt", "Feldstraße 2a, 31234 Musterstadt", "14.09.26", "Kreuzung Feldstraße / Bahnhofstraße",
  "Straßen und Verkehr", "mittel",
  "Sehr geehrte Damen und Herren,\n\nan der Kreuzung Feldstraße/Bahnhofstraße fehlt seit dem Sturm vom 10. September das Stoppschild, es liegt umgeknickt im Gebüsch. Autofahrer fahren jetzt einfach durch. Außerdem wäre dort ein Zebrastreifen für die Schulkinder sinnvoll, das haben wir schon 2024 angeregt.\n\nFreundliche Grüße\nGisela und Werner Brandt",
  "A07", "Nguyen Thi Mai", "Rosenallee 18, 31234 Musterstadt", "15.09.2026", "Rosenallee, Ecke Parkweg",
  "Abfall und Sauberkeit", "hoch",
  "Hallo,\n\nan der Ecke Rosenallee/Parkweg hat jemand nachts einen ganzen Anhänger voll Bauschutt, alte Farbeimer und Dämmwolle abgeladen. Es stinkt nach Chemie, und Kinder laufen dort zur Schule. Bitte schnell abholen. Ich habe Fotos gemacht und kann sie schicken.\n\nMai Nguyen",
  "A08", "Peter Lindqvist", "Kirchplatz 1, 31234 Musterstadt", "16.09.2026", "Rathaus, Bürgerbüro",
  "Sonstiges", "niedrig",
  "Sehr geehrte Frau Bürgermeisterin,\n\nich möchte mich ausdrücklich bei den Mitarbeiterinnen des Bürgerbüros bedanken. Bei der Ummeldung meines Wohnsitzes am 15. September wurde mir sehr freundlich und schnell geholfen, obwohl ich meine Unterlagen nicht vollständig hatte. Eine Anregung hätte ich dennoch: Die Öffnungszeiten am Donnerstagabend sollten besser auf der Webseite zu finden sein.\n\nMit besten Grüßen\nPeter Lindqvist",
  # Zwei Dokumente in schlechter Scanqualität: ein Fax und ein Handyfoto
  "A09", "Kleingartenverein Sonnenhügel e.V.", "Gartenweg 50, 31234 Musterstadt", "17.09.2026", "Glascontainerplatz Gartenweg / Birkenstraße",
  "Abfall und Sauberkeit", "hoch",
  "Sehr geehrte Damen und Herren,\n\nam Glascontainerplatz Gartenweg/Birkenstraße quillt der Restmüllcontainer seit über einer Woche über. Daneben stapeln sich Säcke, und wir haben mehrfach Ratten gesehen, auch tagsüber. Unsere Mitglieder trauen sich mit den Kindern kaum noch vorbei. Bitte leeren Sie den Container umgehend und prüfen Sie, ob ein zweiter Container aufgestellt werden kann.\n\nMit freundlichen Grüßen\nfür den Vorstand\nHeike Sommer",
  "A10", "Ingrid Baumann", "Ahornweg 9, 31234 Musterstadt", "18.9.2026", "Gehweg Ahornweg zwischen Hausnummer 5 und 11",
  "Straßen und Verkehr", "mittel",
  "Guten Tag,\n\ndie Wurzeln der alten Ahornbäume im Ahornweg heben die Gehwegplatten zwischen den Hausnummern 5 und 11 inzwischen um mehrere Zentimeter an. Mit meinem Rollator komme ich dort kaum noch durch, und meine Nachbarin ist letzte Woche gestürzt. Bitte lassen Sie den Gehweg richten. Die Bäume sollen natürlich stehen bleiben.\n\nFreundliche Grüße\nIngrid Baumann"
)

# Layout-Varianten: Schrift, Größe, Störung, Dateiformat ---------------------

layouts <- tribble(
  ~id,  ~font,            ~size, ~kopf,                                        ~rotation, ~noise, ~format,  ~qualitaet,
  "A01", "Helvetica",      30,    "Renate Vogel · Lindenstraße 14 · 31234 Musterstadt",  0.8,  "gaussian", "png", "normal",
  "A02", "Bradley Hand",   36,    "Fam. Yilmaz, Am Stadtpark 3, Musterstadt",            -1.5, "impulse",  "jpg", "normal",
  "A03", "Times",          30,    "Dr. Hartmut Krüger\nBergweg 22\n31234 Musterstadt",    0.3,  "gaussian", "pdf", "normal",
  "A04", "Courier",        28,    "S. Oswald, Mühlenweg 7",                              -0.6, "multiplicative", "png", "normal",
  "A05", "Helvetica",      30,    "Jonas Petersen · Hafenstraße 41 · 31234 Musterstadt", 1.2,  "gaussian", "jpg", "normal",
  "A06", "Times",          32,    "G. u. W. Brandt\nFeldstraße 2a\n31234 Musterstadt",    -0.4, "impulse",  "png", "normal",
  "A07", "Bradley Hand",   34,    "Mai Nguyen, Rosenallee 18",                           2.0,  "gaussian", "jpg", "normal",
  "A08", "Georgia",        30,    "Peter Lindqvist · Kirchplatz 1 · 31234 Musterstadt",   0.0,  "gaussian", "pdf", "normal",
  "A09", "Courier",        28,    "Kleingartenverein Sonnenhuegel e.V. - Gartenweg 50",   0.5,  "impulse",  "png", "fax",
  "A10", "Bradley Hand",   36,    "Ingrid Baumann, Ahornweg 9",                          3.5,  "poisson",  "jpg", "foto"
)

umbrechen <- function(text, breite) {
  text |> str_split("\n") |> pluck(1) |> map_chr(~ paste(str_wrap(.x, breite), collapse = "\n")) |> paste(collapse = "\n")
}

erzeuge_scan <- function(zeile, layout) {
  img <- image_blank(1654, 2339, color = "white")              # A4 bei 200 dpi
  img <- image_annotate(img, layout$kopf, font = layout$font, size = layout$size - 4,
                        color = "gray20", location = "+150+160")
  img <- image_annotate(img, paste0("Stadt Musterstadt\nBürgerservice / Mängelmelder\nRathausplatz 1\n31234 Musterstadt"),
                        font = layout$font, size = layout$size, color = "black", location = "+150+420")
  img <- image_annotate(img, paste0("Musterstadt, ", zeile$datum), font = layout$font, size = layout$size,
                        color = "black", gravity = "northeast", location = "+150+720")
  img <- image_annotate(img, umbrechen(zeile$text, 70), font = layout$font, size = layout$size,
                        color = "black", location = "+150+880")
  img <- image_annotate(img, paste0("Eingang: ", format(as.Date("2026-09-18"), "%d.%m.%Y"), "   Az. BS-2026-", sample(1000:9999, 1)),
                        font = "Courier", size = 22, color = "firebrick", gravity = "southeast", location = "+120+120")
  # Scan-Störungen: Drehung, Rauschen, leichte Unschärfe, Grau
  img <- image_rotate(img, layout$rotation) |> image_crop("1654x2339+30+40")
  img <- image_noise(img, layout$noise) |> image_blur(0, 0.6) |> image_modulate(brightness = 97)
  img <- image_quantize(img, 64, colorspace = "gray")
  # Zwei Stufen schlechter: Fax (grobe Auflösung, harte Kontraste, Streifen) und
  # Handyfoto (schief, unscharf, ungleichmäßig belichtet)
  if (layout$qualitaet == "fax") {
    img <- img |> image_resize("55%") |> image_resize("1624x2299!") |>
      image_threshold("white", "60%") |> image_threshold("black", "40%") |> image_noise("impulse")
    img <- image_draw(img)
    abline(h = seq(80, 2299, by = 230), col = "white", lwd = 10)   # Übertragungsstreifen
    dev.off()
  }
  if (layout$qualitaet == "foto") {
    schatten <- image_blank(1624, 2299, "white") |> image_fx("p*(0.80+0.20*i/w)")   # links dunkel, rechts hell
    img <- image_composite(img, schatten, operator = "multiply") |>
      image_blur(0, 0.8) |> image_modulate(brightness = 95) |> image_noise("gaussian")
  }
  datei <- file.path(ziel, paste0(zeile$id, "_anliegen.", layout$format))
  if (nur_neue && file.exists(datei)) return(datei)
  image_write(img, datei, format = layout$format, density = 200)
  datei
}

dateien <- map2_chr(seq_len(nrow(anliegen)), seq_len(nrow(layouts)), \(i, j) erzeuge_scan(anliegen[i, ], layouts[j, ]))

# Manifest mit Goldstandard (für die Auswertung der Pipeline) ---------------

anliegen |>
  mutate(datei = basename(dateien), .after = id) |>
  select(-text) |>
  write_csv(file.path(ziel, "dokumente.csv"))

# Der Originaltext bleibt getrennt abgelegt (nur für die OCR-Auswertung)
anliegen |> select(id, text) |> write_csv(file.path(ziel, "originaltexte.csv"))

cat("Erzeugt:", length(dateien), "Dokumente in", ziel, "\n")
