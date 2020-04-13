# Weather Challenge

***Bearbeitung der Coding Challenge von Markus Backes***

## Wahl der Tools

Ich habe mich dazu entschlossen, für die Lösung der Aufgabe *R* als Data Engine zu benutzen. Es ist sehr leichtgewichtig und vereint Methoden zur Datenmanipulation sowie -analyse. Dazu bietet es zur weiteren Bearbeitung, Reporting und Speicherung in Datenbanken sämtliche benötigten Schnittstellen.

Innerhalb von R benutze ich die packages `data.table`, `lubridate` und `tidyverse` zur einfachen und eleganten Datenmanipulation, sowie `parallel` zur Parallelisierung von Berechnungen.

## Wahl der Datenquellen

Hier habe ich mich im allgemeinen an den Angaben aus der Aufgabenstellung gehalten. In einem Punkt bin ich jedoch davon abgewichen. Anstatt der jährlichen Daten für jeweils alle Wetterstationen weltweit benutze ich die stationsbezogenen Daten aus diesem Verzeichnis: https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/all/. Diese Entscheidung basiert darauf, daß ich hier mit weitaus kleineren Datenmengen arbeiten muss, da ich gezielt nach Stationen filtern kann. Dies erhöht die Code-Performance messbar.

## Datenmodell

Als einfaches Datenmodell wähle ich eine Faktentabelle, die Wetterstation und Stadt als zusammengesetzte Primary Keys enthält, sowie das Datum und die Maximaltemperatur als Daten. 

Darum angeordnet sind die Dimensionstabellen für die Städte, Wetterstationen sowie die Entfernung zwischen diesen.

Das Datenmodell wird mittels der Datei `createDataModel.R` erstellt.

## Erstellen der Dimensionstabellen

### Import und erste Filterung

Die Daten zu deutschen Städten vom ADFC werden in der Funktion `getCityData` importiert und vorgefiltert. Als Datenpunkte wähle ich von jeder Stadt die ID, den Namen sowie die Geo-Koordinaten. Da die Liste nicht ganz sauber gepflegt ist und einige Städte mehrfach enthalten sind, setze ich auch hier den Filter, dass alle Städte, die innerhalb 0.01 Grad Breite bzw. 0.02 Grad Länge liegen, als eine Stadt identifiziert und Duplikate herausgefiltert werden. 

Der Import sowie das vorläufige Filtern der Wetterstationsdaten geschieht in der Funktion `getStationData`. Als Muster der deutschen Stationen habe ich erkannt, dß deren ID mit `GM` beginnt und konnte somit im ersten Schritt die Anzahl der infrage kommenden Wetterstationen signifikant verringern. Auch hier wähle ich als Datenpunkte die ID, den Namen der Station sowie die Längen- und Breitengrade. Für die weitere Analyse wird nicht mehr benötigt.

### Zuordnung der Städte zu den Wetterstationen

In der Funktion `calcDistance` werden nun für alle Stadt/Wetterstation-Kombinationen die Abstände zueinander berechnet und alle Kombinationen, die nicht innerhalb der vorgegebenen Abstände liegen, herausgefiltert. Die Distanzen der verbleibenden Stadt/Wetterstation-Kombinationen, die darin enthaltenen Städte sowie Wetterstationen werden als Dimensionstabellen `cities`, `stations` sowie `distanceTable` gespeichert. 

Als Wrapper für die Erstellung der Dimensionstabellen dient die Funktion `createDimensionTables`.

## Erstellen der Faktentabelle

Zuletzt wird mittels der Funktion `getFacttable` die Tabelle mit den maximalen Temperaturen der in der Tabelle `stations` enthaltenen Wetterstationen erstellt. Dazu werden alle gemessenen Daten für jede der Stationen vom Server des National Climatic Data Center geholt. 

Die Daten werden im Folgenden nach den Maximaltemperaturen gefiltert und mit folgenden Datenpunkten gespeichert: ID der Wetterstation: `ID_station`, ID der zugehörigen Stadt:  `ID_city`, Datum `date_of_day` und Maximaltemperatur `TMAX`.

## Lösung der Aufgaben

Die Lösungen für die folgenden Aufgaben werden mittels des Scripts `weatherChallenge.R` bestimmt.

### Aufgabe 1: Berechne den Median der Maximaltemperaturen für jede der Stationen für jeden Tag!

Hier ist bei den Ergebnissen zu beachten, dass bis 1884 nur eine Stadt Daten liefert (Jena) und somit die Mediantemperatur nicht sehr repräsentativ für Deutschland ist. Ab 1936 sind 11 Städte in den Daten enthalten, 1947 sind es schon 50.

Die Ergebnisse der Analyse sind in [task1.csv](https://github.com/bartholomaeus/weatherChallenge/blob/master/task1.csv) zu finden.

### Aufgabe 2: Berechne für jede der Städte das arithmetische Mittel der Maximaltemperaturen in 2019!

Die Lösung dieser Aufgabe ist recht straightforward, die Ergebnisse zeigt [task2.csv](https://github.com/bartholomaeus/weatherChallenge/blob/master/task2.csv).

### Bonusaufgabe: Erstelle ein Ranking der Städte, die für die längste zusammenhängende Periode die höchste Temperatur in Deutschland verzeichnet haben!

Hier mache ich mir die R-Funktion `rle` (run length encoding) zunutze, was die Bearbeitung der Aufgabe auch recht simpel macht. Das macht R als Data Engine sehr attraktiv, in SQL wäre diese Analyse ungleich komplizierter.

In die Statistik aufgenommen wurden hier allerdings erst Daten ab 1947. Dies geschieht, weil erst ab diesem Zeitpunkt eine signifikante Anzahl an verschiedenen Städten in den Daten vorhanden sind. 

Die Ergebnisse dieser Analyse zeigt [bonusTask.csv](https://github.com/bartholomaeus/weatherChallenge/blob/master/bonusTask.csv).
