# Materialien zur Übung „Eine XFall-Nachricht auseinandernehmen“

Session 3, Modul 2 „Der Daten-Lifecycle“. Stand: Oktober 2026.

## Was hier liegt

| Datei / Ordner | Inhalt | Herkunft |
|---|---|---|
| `beispiel-gewerbeanmeldung_xfall-daten-4.0.0.xml` | **Übungsdatei 1**: eine vollständige, schema-valide XFall-Daten-Nachricht vom Typ `gewerbe.gewerbeanmeldung.05001002` (Gewerbeanmeldung eines Fahrradladens in Göttingen). Mit Kommentaren. | Selbst erstellt für das Modul, validiert gegen die offiziellen Schemata |
| `beispiel-container_xfall-container-3.0.0.xml` | **Übungsdatei 2**: ein XFall-Container (`application.transport.0300001`), der „Briefumschlag“ mit Absender, Empfänger, Vorgangsdaten und der Gewerbeanmeldung als Inhalt. | Selbst erstellt, validiert |
| `xfall-daten-4.0.0/xfall_4_spezifikation_xfall-daten.pdf` | Offizielle Spezifikation XFall-Daten 4.0.0 (262 Seiten, aus dem UML-Modell generiert). Kapitel 3.6 beschreibt die Gewerbemeldungen, Kapitel 4 den Baukasten. | XRepository (KoSIT) |
| `xfall-daten-4.0.0/xsd/` | Die XML-Schemata (XSD) von XFall-Daten 4.0.0: ein Baukasten (`xfall_daten_baukasten.xsd`, 143 KB) und je eine Datei pro Hauptgruppe (Gewerbe, Geburt, Elterngeld, Führungszeugnis, Fahrzeugzulassung, Berufsbildung, Straßenverkehr). | XRepository |
| `xfall-container-3.0.0/` | Spezifikationen (PDF) und Schemata (XSD) des XFall-Containers 3.0.0. | XRepository |

Quellen im XRepository:

- XFall-Daten: <https://www.xrepository.de/details/urn:xoev-de:it-plr:standard:xfall-daten>
- XFall-Container: <https://www.xrepository.de/details/urn:xoev-de:it-plr:standard:xfall-container>

## Wichtig: Status des Standards

XFall wurde 2011 bis 2015 von Niedersachsen, Hessen, Sachsen, Thüringen und der Stadt Münster entwickelt und XÖV-zertifiziert (XFall-Daten 4.0.0 am 19.03.2015). Das XRepository führt die Version 4.0.0 inzwischen mit dem Verwendungsstatus **„zur Aussonderung“**, den Container 3.0.0 als **„veraltet“**. Die Nachfolge für Online-Anträge läuft über FIM/XDatenfelder und FIT-Connect, wobei FIT-Connect XFall-Schemata weiterhin als Fachdatenschema akzeptiert.

Für die Übung ist das kein Nachteil: Die Struktur ist echt, die Schemata sind original, und der Lebenszyklus eines Standards ist selbst ein Lernpunkt. Die frühere Projektseite xfall.eu existiert nicht mehr und leitet auf eine Spam-Seite um; nicht verlinken.

## Selbst validieren

Mit `xmllint` (auf macOS und Linux vorinstalliert) im Ordner `materials/`:

```bash
xmllint --noout --schema xfall-daten-4.0.0/xsd/xfall_daten_050_gewerbe.xsd beispiel-gewerbeanmeldung_xfall-daten-4.0.0.xml
```

```bash
xmllint --noout --schema xfall-container-3.0.0/container-xsd/xsd/xfallcontainer-application.xsd beispiel-container_xfall-container-3.0.0.xml
```

Ausgabe bei Erfolg: `... validates`. Zum Ausprobieren: eine Pflichtangabe löschen (etwa `erstelltUm`), einen ungültigen Code eintragen (`<code>XX</code>` statt `NG`) oder ein Datum falsch schreiben (`27.10.2026`), und die Validierung erneut laufen lassen. Die Fehlermeldungen zeigen, was ein Schema leistet.

In R geht das Gleiche mit `xml2::xml_validate(xml2::read_xml("..."), xml2::read_xml("....xsd"))`.

## Übungsaufgaben (3er-Gruppen, 8 Minuten)

1. **Aufbau**: Öffnet `beispiel-gewerbeanmeldung_xfall-daten-4.0.0.xml` in einem Editor oder Browser. Welche Teile der Nachricht sind für **jedes** Verfahren gleich (Transport, Beteiligter), welche gehören zu jeder Gewerbemeldung, welche nur zur Anmeldung? Vergleicht mit den drei Elementen in `xfall_daten_050_gewerbe.xsd`.
2. **Codes statt Freitext**: Findet alle Stellen, an denen ein Code steht (`<code>...</code>`). Woher kommen die Codelisten? Welche sind im Schema fest definiert, welche verweisen auf externe Listen (Destatis, XRepository)? Was wäre der Nachteil von Freitext?
3. **Wiederverwendung**: Welche Bausteine (Anschrift, NatuerlichePerson, Kommunikation) würde ein Antrag aus Eurem Haus wiederverwenden? Sucht im Baukasten-Schema nach einem Typ, den Ihr bräuchtet, und einem, der fehlt.
4. **Briefumschlag und Inhalt**: Öffnet `beispiel-container_xfall-container-3.0.0.xml`. Was steht im Umschlag, was im Inhalt? Warum ist die Fachnachricht im Container als „implementation“ mit `processContents="skip"` eingebettet, also nicht mitvalidiert? Was bedeutet das für die Empfängerseite?
5. **Medienbrüche**: Wo in diesem Fluss (Portal, Container, Fachverfahren, Bescheid) entstehen in Eurem Haus heute noch Medienbrüche?

## Lizenz und Nutzung

Die Spezifikationen und Schemata stammen aus dem XRepository der Koordinierungsstelle für IT-Standards und sind dort öffentlich bereitgestellt. Die Beispielnachrichten sind für die Lehre erstellt; alle Personen, Adressen und Betriebe sind erfunden.
