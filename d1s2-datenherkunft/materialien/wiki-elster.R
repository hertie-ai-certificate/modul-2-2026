# Tägliche Aufrufe des Wikipedia-Artikels "Elster (Software)" ---------------
# Session 2, Modul 2 "Der Daten-Lifecycle"
#
# Erzeugt ../../pics/wiki-elster.png: Beispiel für prozessproduzierte Daten.
# Die Aufrufzahlen sind ein Nebenprodukt des Wikipedia-Betriebs; die
# Steuererklärungs-Saison ist darin deutlich sichtbar.
#
# Datenquelle: Wikimedia REST API (Pageviews), verfügbar ab 1. Juli 2015.
# Der Artikel hieß bis Juni 2017 "ELSTER" und wurde dann nach
# "Elster (Software)" verschoben; der alte Titel ist seither eine
# Weiterleitung. Darum werden die Aufrufe des Artikels und aller
# Weiterleitungen zusammengezählt.
#
# Benötigte Pakete: tidyverse, httr2, jsonlite, systemfonts (Fira Sans)

library(tidyverse)
library(httr2)
library(jsonlite)

# Schriftart: Fira Sans, Fallback auf Standardschrift
font_family <- if (nrow(filter(systemfonts::system_fonts(), family == "Fira Sans")) > 0) "Fira Sans" else "sans"

artikel  <- "Elster (Software)"
projekt  <- "de.wikipedia"
start    <- "20150701"                           # frühester Tag in der Pageviews-API
ende     <- format(Sys.Date() - 1, "%Y%m%d")      # Vortag (der laufende Tag ist noch unvollständig)
ua       <- "Hertie-School-Datenkurs (munzert@hertie-school.org)"


# 1. Weiterleitungen auf den Artikel ermitteln ------------------------------

redirects <- request("https://de.wikipedia.org/w/api.php") %>%
  req_url_query(action = "query", prop = "redirects", titles = artikel,
                rdlimit = 500, format = "json") %>%
  req_user_agent(ua) %>%
  req_perform() %>%
  resp_body_json()

titel <- c(artikel,
           map_chr(redirects$query$pages[[1]]$redirects, "title"))
cat("Abgefragte Titel:", paste(titel, collapse = ", "), "\n")


# 2. Tägliche Aufrufe je Titel abrufen ---------------------------------------

hole_pageviews <- function(t) {
  url <- paste0("https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/",
                projekt, "/all-access/user/", URLencode(gsub(" ", "_", t), reserved = TRUE),
                "/daily/", start, "/", ende)
  resp <- request(url) %>% req_user_agent(ua) %>% req_error(is_error = ~ FALSE) %>% req_perform()
  if (resp_status(resp) != 200) return(tibble())   # Titel ohne Daten (z. B. jüngere Weiterleitungen)
  resp_body_json(resp)$items %>%
    map_dfr(~ tibble(titel = t, datum = ymd(substr(.x$timestamp, 1, 8)), aufrufe = .x$views))
}

pv_roh <- map_dfr(titel, hole_pageviews)

pv <- pv_roh %>%
  group_by(datum) %>%
  summarize(aufrufe = sum(aufrufe), .groups = "drop") %>%
  arrange(datum) %>%
  mutate(glatt = stats::filter(aufrufe, rep(1 / 28, 28), sides = 2) %>% as.numeric())  # 28-Tage-Mittel

write_csv(pv_roh, "wiki-elster-pageviews.csv")
cat("Zeitraum:", format(min(pv$datum)), "bis", format(max(pv$datum)), "|", nrow(pv), "Tage\n")


# 3. Abgabefristen der Einkommensteuererklärung (ohne Steuerberatung) ------
# Bis VZ 2017: 31. Mai; ab VZ 2018: 31. Juli (§ 149 AO); Corona-Verlängerungen
# für VZ 2020 bis 2023; fällt die Frist auf ein Wochenende, gilt der nächste Werktag.

fristen <- tibble(
  veranlagungszeitraum = 2015:2025,
  frist = ymd(c("2016-05-31", "2017-05-31", "2018-05-31", "2019-07-31", "2020-07-31",
                "2021-11-01", "2022-10-31", "2023-10-02", "2024-09-02", "2025-07-31", "2026-07-31")))


# 4. Grafik ------------------------------------------------------------------

plot <- ggplot(pv, aes(x = datum)) +
  geom_vline(data = fristen, aes(xintercept = frist), color = "#aa2229", linetype = "dashed", linewidth = 0.4) +
  geom_line(aes(y = aufrufe), color = "#333333", linewidth = 0.25, alpha = 0.7) +
  geom_line(aes(y = glatt), color = "#aa2229", linewidth = 1.1, na.rm = TRUE) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y", expand = expansion(mult = 0.01)) +
  scale_y_continuous(labels = scales::label_number(big.mark = ".", decimal.mark = ","), expand = expansion(mult = c(0, 0.05))) +
  coord_cartesian(ylim = c(0, quantile(pv$aufrufe, 0.995))) +   # einzelne Ausreißer nach oben abschneiden
  labs(title = "Tägliche Aufrufe des Wikipedia-Artikels „Elster (Software)“",
       subtitle = paste0(format(min(pv$datum), "%B %Y"), " bis ", format(max(pv$datum), "%B %Y"),
                         ". Rote Linie: 28-Tage-Mittel. Gestrichelt: Abgabefrist der Einkommensteuererklärung"),
       caption = "Quelle: Wikimedia REST API (Pageviews, nur menschliche Nutzer), Artikel inkl. Weiterleitungen (u. a. „ELSTER“)") +
  theme_minimal(base_family = font_family) +
  theme(text = element_text(family = font_family),
        plot.title.position = "plot",
        plot.title = element_text(size = 15, face = "bold", margin = margin(b = 5), color = "#333333"),
        plot.subtitle = element_text(face = "italic", size = 11, margin = margin(b = 10), color = "#666666"),
        plot.caption = element_text(size = 8, color = "#666666", hjust = 0),
        axis.title = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        plot.margin = margin(5, 10, 5, 5),
        plot.background = element_rect(fill = "white", color = NA))

ggsave(plot, filename = "../../pics/wiki-elster.png", width = 11, height = 4.6, unit = "in", dpi = 300)
cat("Fertig: pics/wiki-elster.png | Schriftart:", font_family, "\n")
