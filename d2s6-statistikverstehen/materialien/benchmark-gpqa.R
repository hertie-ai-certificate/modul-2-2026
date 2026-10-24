# Benchmark-Grafik für Session 6: GPQA Diamond, Genauigkeit nach Erscheinungsdatum ---
# Erzeugt ../../pics/benchmark-gpqa-diamond.png
#
# Daten: Epoch AI, "Capabilities & benchmarking", https://epoch.ai/benchmarks, CC BY 4.0.
# Download vom 22.10.2026 (https://epoch.ai/data/benchmark_data.zip, Datei gpqa_diamond.csv),
# Kopie liegt als epoch-gpqa-diamond-2026-10-22.csv daneben.
# GPQA Diamond: 198 Multiple-Choice-Fragen auf Promotionsniveau (Biologie, Physik, Chemie),
# "Google-proof". Promovierte Fachleute erreichen laut GPQA-Paper rund 65% (Rein et al. 2023),
# Nicht-Fachleute mit Internetzugang rund 34%; Raten ergibt 25%.

library(tidyverse)

font_family <- if (nrow(filter(systemfonts::system_fonts(), family == "Fira Sans")) > 0) "Fira Sans" else "sans"

d <- read_csv("epoch-gpqa-diamond-2026-10-22.csv", show_col_types = FALSE) |>
  rename(modell = `Model version`, score = mean_score, datum = `Release date`, org = Organization) |>
  filter(!is.na(score), !is.na(datum)) |>
  mutate(datum = as.Date(datum), score = 100 * score)

# Pro Organisation und Monat nur das beste Modell zeigen (sonst zu dicht)
haupt_orgs <- c("OpenAI", "Google DeepMind", "Anthropic", "Meta AI", "DeepSeek", "xAI", "Alibaba")
d <- d |>
  mutate(org_gruppe = ifelse(org %in% haupt_orgs, org, "andere")) |>
  group_by(org_gruppe, monat = floor_date(datum, "month")) |>
  slice_max(score, n = 1, with_ties = FALSE) |>
  ungroup()

# Jeweils bestes Modell zu Jahresanfang/-ende beschriften
labels <- d |>
  filter(org_gruppe != "andere") |>
  group_by(jahr = year(datum)) |> slice_max(score, n = 1, with_ties = FALSE) |> ungroup() |>
  filter(jahr %in% c(2023, 2024) | score == max(score)) |>    # ab 2025 ist es oben zu dicht
  mutate(label = str_replace(modell, "_.*$", "") |> str_replace("-\\d{4}$", ""),
         versatz = ifelse(score > 88, -9, 6))   # Beschriftung unter dem Punkt, wenn oben kein Platz ist

farben <- c("OpenAI" = "#1D375B", "Google DeepMind" = "#EB811B", "Anthropic" = "#aa2229",
            "Meta AI" = "#2E8B57", "DeepSeek" = "#6A3D9A", "xAI" = "#555555", "Alibaba" = "#B8860B",
            "andere" = "grey75")

plot <- ggplot(d, aes(x = datum, y = score, color = org_gruppe)) +
  annotate("rect", xmin = min(d$datum) - 30, xmax = max(d$datum) + 60, ymin = 60, ymax = 70, fill = "grey90", alpha = 0.6) +
  annotate("text", x = min(d$datum) - 20, y = 65, label = "Promovierte Fachleute: ca. 65%", hjust = 0, size = 3.4, family = font_family, color = "grey30") +
  geom_hline(yintercept = 25, linetype = "dotted", color = "grey50") +
  annotate("text", x = min(d$datum) - 20, y = 27, label = "Raten: 25%", hjust = 0, size = 3.2, family = font_family, color = "grey40") +
  geom_point(size = 2.6, alpha = 0.85) +
  ggrepel::geom_text_repel(data = labels, aes(label = label), size = 3, family = font_family, show.legend = FALSE,
                           nudge_y = labels$versatz, segment.color = "grey60", min.segment.length = 0) +
  scale_color_manual(values = farben, breaks = c(haupt_orgs, "andere"), name = NULL) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  scale_y_continuous(breaks = seq(0, 100, 20), labels = \(x) paste0(x, "%")) +
  coord_cartesian(ylim = c(0, 100)) +
  labs(title = "Wie gut beantworten Sprachmodelle Fachfragen auf Promotionsniveau?",
       subtitle = "GPQA Diamond: 198 Multiple-Choice-Fragen aus Biologie, Physik und Chemie. Anteil richtiger Antworten je Modell, nach Erscheinungsdatum",
       caption = "Daten: Epoch AI, Capabilities & benchmarking (epoch.ai/benchmarks), CC BY 4.0, Stand 22.10.2026. Je Anbieter und Monat ist nur das beste Modell gezeigt. Expertenwert: Rein et al. (2023).") +
  theme_minimal(base_family = font_family) +
  theme(text = element_text(family = font_family),
        plot.title.position = "plot",
        plot.title = element_text(size = 15, face = "bold", margin = margin(b = 4), color = "#333333"),
        plot.subtitle = element_text(face = "italic", size = 11, margin = margin(b = 8), color = "#666666"),
        plot.caption = element_text(size = 8, color = "#666666", hjust = 0),
        legend.position = "bottom",
        axis.title = element_blank(),
        panel.grid.minor = element_blank(),
        plot.margin = margin(5, 10, 5, 5),
        plot.background = element_rect(fill = "white", color = NA)) +
  guides(color = guide_legend(nrow = 1, override.aes = list(size = 3)))

ggsave(plot, filename = "../../pics/benchmark-gpqa-diamond.png", width = 11, height = 5.4, unit = "in", dpi = 300)
cat("Fertig. Modelle in der Grafik:", nrow(d), "| Zeitraum:", format(min(d$datum)), "bis", format(max(d$datum)), "\n")
