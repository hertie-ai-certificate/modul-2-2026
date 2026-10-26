# Erzeugt den synthetischen Datensatz für die Übung "Klassifikation validieren":
# 560 kurze, erfundene Bürgerschreiben an die Stadt Musterstadt, jeweils mit
# Themenbereich (Goldstandard), Dringlichkeit und einer Markierung, ob das
# Schreiben zwischen zwei Bereichen liegt (mehrdeutig).
#
# Muss nur einmal laufen; Ergebnis: daten/buergerschreiben.csv
# Alle Namen, Orte und Vorgänge sind erfunden. Das Beispiel knüpft an die
# Fallstudie "Von Scans zu Tabellen" (praxis-ocr-llm) an.

library(tidyverse)
set.seed(7)
dir.create("daten", showWarnings = FALSE)

kategorien <- c("Straßen und Verkehr", "Grünflächen und Spielplätze", "Abfall und Sauberkeit",
                "Beleuchtung", "Lärm", "Sonstiges")

# Bausteine ------------------------------------------------------------------------

# Nur weibliche Straßennamen, damit "in der {ort}" immer passt
strassen <- c("Lindenstraße", "Bergstraße", "Mühlengasse", "Hafenstraße", "Feldstraße", "Rosenallee", "Kirchgasse",
              "Ahornallee", "Gartenstraße", "Birkenstraße", "Bahnhofstraße", "Schulstraße", "Marktstraße", "Wiesenstraße",
              "Hauptstraße", "Parkallee", "Brunnenstraße", "Talstraße", "Ringstraße", "Mozartstraße", "Kastanienallee")
ort <- function(n = 1) paste0(sample(strassen, n, replace = TRUE), " ", sample(1:60, n, replace = TRUE))

anreden <- c("Sehr geehrte Damen und Herren,", "Guten Tag,", "Hallo,", "Sehr geehrtes Team vom Bürgerservice,",
             "Liebe Stadtverwaltung,", "Sehr geehrte Frau Bürgermeisterin,", "Hallo zusammen,")
gruesse <- c("Mit freundlichen Grüßen", "Viele Grüße", "Freundliche Grüße", "Danke und Gruß", "Beste Grüße",
             "Mit besten Grüßen", "Hochachtungsvoll")
nachnamen <- c("Vogel", "Yilmaz", "Krüger", "Oswald", "Petersen", "Brandt", "Nguyen", "Lindqvist", "Sommer", "Baumann",
               "Schäfer", "Kowalski", "Fischer", "Öztürk", "Hartmann", "Weber", "Rossi", "Becker", "Haddad", "Lehmann")
seit <- c("seit gestern", "seit etwa einer Woche", "seit drei Wochen", "seit dem Wochenende", "seit Monaten",
          "seit dem letzten Sturm", "schon länger", "seit Anfang des Monats")

# Eindeutige Probleme je Bereich: (Problem-Satz mit {ort}, mögliche Bitte)
probleme <- tribble(
  ~kategorie, ~problem, ~bitte,
  "Straßen und Verkehr", "ist in der {ort} ein tiefes Schlagloch, das immer größer wird", "Bitte bessern Sie die Fahrbahn aus.",
  "Straßen und Verkehr", "fehlt an der Kreuzung {ort} das Stoppschild", "Bitte stellen Sie das Schild wieder auf.",
  "Straßen und Verkehr", "ist die Ampel an der {ort} ausgefallen und blinkt nur noch gelb", "Bitte lassen Sie die Ampel reparieren.",
  "Straßen und Verkehr", "parken Lieferwagen in der {ort} regelmäßig auf dem Radweg", "Bitte kontrollieren Sie das Halteverbot.",
  "Straßen und Verkehr", "ist die Fahrbahnmarkierung in der {ort} kaum noch zu erkennen", "Bitte erneuern Sie die Markierung.",
  "Straßen und Verkehr", "ist der Gullydeckel in der {ort} lose und klappert bei jedem Auto", "Bitte befestigen Sie den Deckel.",
  "Straßen und Verkehr", "wird in der {ort} viel zu schnell gefahren, obwohl Tempo 30 gilt", "Bitte prüfen Sie Geschwindigkeitskontrollen oder eine Schwelle.",
  "Straßen und Verkehr", "ist der Bordstein in der {ort} am Übergang nicht abgesenkt", "Bitte senken Sie den Bordstein für Rollstühle und Kinderwagen ab.",
  "Straßen und Verkehr", "steht das Verkehrsschild in der {ort} schief und verdeckt die Sicht", "Bitte richten Sie das Schild.",
  "Straßen und Verkehr", "ist die Brücke über den Mühlbach in der {ort} für Fußgänger gesperrt, ohne Umleitung", "Bitte weisen Sie eine Umleitung aus.",
  "Grünflächen und Spielplätze", "ist am Spielplatz {ort} die Kette der Schaukel gerissen", "Bitte reparieren Sie die Schaukel.",
  "Grünflächen und Spielplätze", "ist die Hecke am Spielplatz {ort} so hoch, dass man die Kinder nicht mehr sieht", "Bitte schneiden Sie die Hecke zurück.",
  "Grünflächen und Spielplätze", "wurde der Rasen im Park an der {ort} seit Wochen nicht gemäht", "Bitte mähen Sie die Wiese.",
  "Grünflächen und Spielplätze", "hängt ein abgebrochener Ast über dem Weg in der Grünanlage {ort}", "Bitte entfernen Sie den Ast.",
  "Grünflächen und Spielplätze", "ist die Rutsche auf dem Spielplatz {ort} gerissen und hat scharfe Kanten", "Bitte sperren und reparieren Sie die Rutsche.",
  "Grünflächen und Spielplätze", "sind die Bänke im Park {ort} morsch und wackeln", "Bitte tauschen Sie die Bänke aus.",
  "Grünflächen und Spielplätze", "ist die Wippe am Spielplatz {ort} abgebaut und nicht ersetzt worden", "Wann kommt ein neues Gerät?",
  "Grünflächen und Spielplätze", "ist das Beet am Kreisverkehr {ort} völlig verwildert", "Bitte pflegen Sie das Beet.",
  "Grünflächen und Spielplätze", "ist der Baum vor dem Haus {ort} nach dem Sturm angebrochen", "Bitte prüfen Sie den Baum auf Standsicherheit.",
  "Grünflächen und Spielplätze", "fehlt auf dem Spielplatz {ort} der Sand im Sandkasten", "Bitte füllen Sie Sand nach.",
  "Abfall und Sauberkeit", "wurde die blaue Tonne in der {ort} nicht geleert", "Bitte holen Sie die Abfuhr nach.",
  "Abfall und Sauberkeit", "quillt der Papierkorb an der Bushaltestelle {ort} über", "Bitte leeren Sie den Papierkorb öfter.",
  "Abfall und Sauberkeit", "hat jemand in der {ort} Bauschutt und alte Farbeimer abgeladen", "Bitte lassen Sie den Müll abholen.",
  "Abfall und Sauberkeit", "liegen am Glascontainer {ort} Flaschen und Scherben herum", "Bitte reinigen Sie den Containerplatz.",
  "Abfall und Sauberkeit", "stehen in der {ort} seit Tagen Sperrmüllreste auf dem Gehweg", "Bitte veranlassen Sie die Abholung.",
  "Abfall und Sauberkeit", "ist der Hundekotbeutelspender in der {ort} seit Wochen leer", "Bitte füllen Sie den Spender nach.",
  "Abfall und Sauberkeit", "liegt in der {ort} ein alter Kühlschrank am Straßenrand", "Bitte entsorgen Sie das Gerät.",
  "Abfall und Sauberkeit", "ist der Abfuhrkalender für die {ort} online falsch", "Bitte korrigieren Sie die Termine.",
  "Abfall und Sauberkeit", "wurden in der {ort} nach dem Fest die Straßen nicht gereinigt", "Bitte schicken Sie die Straßenreinigung.",
  "Abfall und Sauberkeit", "sind die Mülltonnen im Hinterhof {ort} voller Maden und stinken", "Bitte reinigen Sie die Tonnen oder tauschen Sie sie.",
  "Beleuchtung", "ist die Straßenlaterne vor dem Haus {ort} dunkel", "Bitte reparieren Sie die Laterne.",
  "Beleuchtung", "flackert die Laterne in der {ort} die ganze Nacht", "Bitte tauschen Sie das Leuchtmittel.",
  "Beleuchtung", "sind in der {ort} gleich drei Laternen hintereinander ausgefallen", "Bitte stellen Sie die Beleuchtung wieder her.",
  "Beleuchtung", "brennt die Straßenbeleuchtung in der {ort} auch tagsüber", "Bitte prüfen Sie die Zeitschaltung.",
  "Beleuchtung", "ist die Unterführung an der {ort} abends stockdunkel", "Bitte installieren Sie Beleuchtung.",
  "Beleuchtung", "leuchtet die neue LED-Laterne in der {ort} direkt in unser Schlafzimmer", "Bitte richten Sie die Leuchte anders aus.",
  "Beleuchtung", "ist der Lichtmast in der {ort} verrostet und hat ein offenes Kabelfach", "Bitte sichern Sie den Mast.",
  "Beleuchtung", "geht die Beleuchtung am Fußweg {ort} erst eine Stunde nach Einbruch der Dunkelheit an", "Bitte stellen Sie den Dämmerungsschalter neu ein.",
  "Lärm", "läuft in der Gaststätte {ort} an den Wochenenden bis nach 2 Uhr laute Musik", "Bitte schreiten Sie ein.",
  "Lärm", "beginnt die Baustelle in der {ort} jeden Morgen um 6 Uhr mit Presslufthammer", "Bitte prüfen Sie die erlaubten Arbeitszeiten.",
  "Lärm", "feiern Jugendliche nachts auf dem Parkplatz {ort} mit lauter Musik aus Autos", "Bitte sorgen Sie für nächtliche Kontrollen.",
  "Lärm", "dröhnt die Lüftungsanlage des Supermarkts in der {ort} die ganze Nacht", "Bitte messen Sie den Lärm.",
  "Lärm", "schreit der Hund im Nachbargarten {ort} stundenlang, auch nachts", "Bitte sprechen Sie mit den Haltern.",
  "Lärm", "hält sich die Kneipe in der {ort} nicht an die Sperrzeit", "Bitte kontrollieren Sie die Sperrzeit.",
  "Lärm", "bläst der Laubbläser des Hausmeisters in der {ort} sonntags um 8 Uhr", "Bitte weisen Sie auf die Ruhezeiten hin.",
  "Lärm", "fahren Motorräder nachts mit Vollgas durch die {ort}", "Bitte prüfen Sie eine Lärmkontrolle.",
  "Sonstiges", "möchte ich mich bei den Mitarbeiterinnen des Bürgerbüros {ort} bedanken", "Bitte geben Sie das Lob weiter.",
  "Sonstiges", "sind die Öffnungszeiten des Bürgerbüros auf der Webseite falsch angegeben", "Bitte aktualisieren Sie die Webseite.",
  "Sonstiges", "habe ich seit sechs Wochen keine Antwort auf meinen Antrag auf Wohngeld", "Bitte teilen Sie mir den Bearbeitungsstand mit.",
  "Sonstiges", "funktioniert das Online-Formular für die Ummeldung nicht", "Bitte beheben Sie den Fehler.",
  "Sonstiges", "ist der Aufzug im Rathaus seit zwei Wochen außer Betrieb", "Bitte lassen Sie ihn reparieren.",
  "Sonstiges", "ist die Telefonhotline des Bürgeramts nie erreichbar", "Bitte verbessern Sie die Erreichbarkeit.",
  "Sonstiges", "wurde mein Hinweis auf dem Mängelmelder nach drei Wochen noch nicht beantwortet", "Bitte geben Sie eine Rückmeldung.",
  "Sonstiges", "fehlt im Stadtteil {ort} ein Briefkasten, seit der alte abgebaut wurde", "Bitte setzen Sie sich für einen neuen Briefkasten ein."
)

# Mehrdeutige Probleme: liegen zwischen zwei Bereichen. gold = unsere Entscheidung, alternative = ebenso vertretbar.
mehrdeutig <- tribble(
  ~kategorie, ~alternative, ~problem, ~bitte,
  "Straßen und Verkehr", "Grünflächen und Spielplätze", "heben die Wurzeln der alten Bäume in der {ort} die Gehwegplatten an", "Bitte richten Sie den Gehweg, ohne die Bäume zu fällen.",
  "Grünflächen und Spielplätze", "Abfall und Sauberkeit", "liegen im Sandkasten des Spielplatzes {ort} Glasscherben und Zigarettenkippen", "Bitte reinigen Sie den Sandkasten.",
  "Beleuchtung", "Grünflächen und Spielplätze", "ist die Laterne am Spielplatz {ort} kaputt, abends ist es dort stockdunkel", "Bitte reparieren Sie die Laterne.",
  "Lärm", "Straßen und Verkehr", "ist der Verkehrslärm in der {ort} seit der Umleitung unerträglich", "Bitte prüfen Sie Tempo 30 oder eine andere Umleitung.",
  "Abfall und Sauberkeit", "Grünflächen und Spielplätze", "liegt im Park an der {ort} überall Müll vom Wochenende, die Körbe sind voll", "Bitte stellen Sie mehr Abfallkörbe auf.",
  "Grünflächen und Spielplätze", "Straßen und Verkehr", "wachsen die Sträucher an der Einmündung {ort} so weit in die Straße, dass man nichts sieht", "Bitte schneiden Sie die Sträucher zurück.",
  "Lärm", "Grünflächen und Spielplätze", "wird auf dem Bolzplatz {ort} bis Mitternacht Fußball gespielt und gegrölt", "Bitte setzen Sie Nutzungszeiten durch.",
  "Straßen und Verkehr", "Beleuchtung", "ist der Zebrastreifen in der {ort} nachts unbeleuchtet und kaum zu sehen", "Bitte beleuchten Sie den Übergang.",
  "Abfall und Sauberkeit", "Straßen und Verkehr", "ist der Gehweg in der {ort} voller Laub und rutschig", "Bitte lassen Sie den Gehweg kehren.",
  "Sonstiges", "Straßen und Verkehr", "frage ich, ob für das Straßenfest in der {ort} eine Sperrung beantragt werden muss", "Bitte teilen Sie mir mit, welches Formular ich brauche.",
  "Lärm", "Sonstiges", "ist das Glockenläuten der Kirche am {ort} um 6 Uhr morgens für die Nachbarschaft sehr laut", "Bitte vermitteln Sie ein Gespräch mit der Gemeinde.",
  "Beleuchtung", "Sonstiges", "ist die Weihnachtsbeleuchtung in der {ort} schon im Februar noch an", "Bitte schalten Sie sie ab."
)

# Dringlichkeit: Zusatzsätze, die den Ton setzen
dringlich_hoch <- c("Gestern ist dort jemand gestürzt und musste versorgt werden.", "Hier laufen jeden Morgen Schulkinder vorbei.",
                    "Das ist eine echte Gefahr, es muss sofort etwas passieren.", "Ich habe große Sorge, dass bald etwas Schlimmes passiert.",
                    "Meine Nachbarin ist letzte Woche deswegen gestürzt.", "Wir haben mehrfach Ratten gesehen, auch tagsüber.",
                    "Ich habe bereits zweimal die Polizei gerufen.")
dringlich_mittel <- c("Das sollte zeitnah behoben werden.", "Es wäre gut, wenn sich das in den nächsten Tagen jemand ansieht.",
                      "Ich habe das schon einmal gemeldet, bisher ohne Reaktion.", "Viele ältere Leute wohnen hier.",
                      "Es wird von Woche zu Woche schlimmer.", "")
dringlich_niedrig <- c("Es eilt nicht, aber irgendwann sollte sich jemand kümmern.", "Das ist nur ein Hinweis, kein Notfall.",
                       "Vielleicht lässt sich das bei Gelegenheit erledigen.", "Ich wollte das nur einmal angemerkt haben.",
                       "Vielen Dank für Ihre Arbeit.", "")

gross <- function(x) paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))   # nur den ersten Buchstaben

baue_text <- function(problem, bitte, dringlichkeit, kategorie) {
  zusatz <- switch(dringlichkeit, hoch = sample(dringlich_hoch, 1), mittel = sample(dringlich_mittel, 1), niedrig = sample(dringlich_niedrig, 1))
  einleitung <- if (kategorie == "Sonstiges" && str_detect(problem, "^(möchte|habe|frage)"))
    paste0(gross(str_replace(problem, "\\{ort\\}", ort())), ".")
  else
    paste0(gross(sample(seit, 1)), " ", str_replace(problem, "\\{ort\\}", ort()), ".")
  paste(c(sample(anreden, 1), "", str_squish(paste(c(einleitung, zusatz, bitte), collapse = " ")), "", sample(gruesse, 1),
          paste(sample(c("A.", "B.", "C.", "D.", "E.", "F.", "H.", "J.", "K.", "L.", "M.", "N.", "P.", "R.", "S.", "T."), 1), sample(nachnamen, 1))),
        collapse = "\n")
}

# Zusammenstellen: Ungleichgewicht gewollt (Straßen häufig, Sonstiges selten) --------

n_je_kategorie <- c("Straßen und Verkehr" = 150, "Grünflächen und Spielplätze" = 105, "Abfall und Sauberkeit" = 120,
                    "Beleuchtung" = 70, "Lärm" = 75, "Sonstiges" = 40)
anteil_mehrdeutig <- 0.12

ziehe <- function(kat, n) {
  n_md <- round(n * anteil_mehrdeutig)
  eind <- probleme |> filter(kategorie == kat) |> slice_sample(n = n - n_md, replace = TRUE) |> mutate(alternative = NA_character_)
  md   <- mehrdeutig |> filter(kategorie == kat) |> slice_sample(n = n_md, replace = TRUE)
  bind_rows(eind, md)
}

daten <- imap(n_je_kategorie, \(n, kat) ziehe(kat, n)) |> list_rbind() |>
  mutate(
    dringlichkeit = case_when(
      kategorie == "Sonstiges" ~ sample(c("hoch", "mittel", "niedrig"), n(), replace = TRUE, prob = c(.1, .3, .6)),
      kategorie %in% c("Lärm", "Beleuchtung") ~ sample(c("hoch", "mittel", "niedrig"), n(), replace = TRUE, prob = c(.25, .5, .25)),
      TRUE ~ sample(c("hoch", "mittel", "niedrig"), n(), replace = TRUE, prob = c(.35, .45, .2))),
    text = pmap_chr(list(problem, bitte, dringlichkeit, kategorie), baue_text),
    mehrdeutig = !is.na(alternative)) |>
  slice_sample(prop = 1) |>
  mutate(id = sprintf("B%03d", row_number()), .before = 1) |>
  select(id, text, kategorie, alternative, mehrdeutig, dringlichkeit)

write_csv(daten, "daten/buergerschreiben.csv")
cat("Erzeugt:", nrow(daten), "Schreiben;", sum(daten$mehrdeutig), "davon mehrdeutig\n")
print(count(daten, kategorie, sort = TRUE))
