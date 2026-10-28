# Rendert die xaringan-Decks per Chrome headless nach PDF (ersetzt den manuellen Druck aus Chrome).
#
# Aufruf im Terminal, aus dem Repo-Ordner:
#   Rscript render-pdfs.R                      # alle Decks
#   Rscript render-pdfs.R d1s1-ueberblick      # nur ein Deck (Ordnername)
#
# Voraussetzungen: Pakete chromote und jsonlite, Google Chrome unter /Applications.
# Hinweis: Zwischenzustände von `--`-Pausen werden wie im Chrome-Druck ausgeblendet,
# das PDF enthält also je Folie nur den Endzustand.

library(chromote)
Sys.setenv(CHROMOTE_CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

decks <- c("d1s1-ueberblick", "d1s2-datenherkunft", "d1s3-datengewinnung", "d1s4-web-scraping",
           "d2s5-big-data-probleme", "d2s6-statistikverstehen",
           "d2s8-kommunikation", "d3s9-rekrutierung", "d3s11-wrapup")
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) decks <- args

render_pdf <- function(html, out) {
  b <- ChromoteSession$new()
  on.exit(b$close(), add = TRUE)
  b$Page$navigate(paste0("file://", normalizePath(html)))
  b$Page$loadEventFired(timeout_ = 60)
  Sys.sleep(3)  # remark.js, Schriften und Bilder laden lassen
  n <- 0
  for (i in 1:20) {
    n <- b$Runtime$evaluate("typeof slideshow !== 'undefined' ? slideshow.getSlideCount() : 0")$result$value
    if (n > 0) break
    Sys.sleep(0.5)
  }
  b$Emulation$setEmulatedMedia(media = "print")
  Sys.sleep(1)
  # Als Stream übertragen: große PDFs sprengen sonst die Websocket-Nachricht
  pdf <- b$Page$printToPDF(printBackground = TRUE, preferCSSPageSize = TRUE,
                           marginTop = 0, marginBottom = 0, marginLeft = 0, marginRight = 0,
                           transferMode = "ReturnAsStream")
  con <- file(out, "wb")
  repeat {
    chunk <- b$IO$read(handle = pdf$stream, size = 4e6)
    writeBin(jsonlite::base64_dec(chunk$data), con)
    if (isTRUE(chunk$eof)) break
  }
  close(con)
  b$IO$close(handle = pdf$stream)
  message(sprintf("%s: %d Folien -> %s (%.1f MB)", basename(html), n, out, file.size(out) / 1e6))
}

for (d in decks) {
  html <- file.path(d, paste0(d, ".html"))
  if (!file.exists(html)) { message("übersprungen (kein HTML): ", html); next }
  render_pdf(html, file.path(d, paste0(d, ".pdf")))
}
