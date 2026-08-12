# Armbøjnings-tracker — designgrundlag

Resultatet af en gennemarbejdning med 68 agenter: seks undersøgelsesspor, 58 foreslåede måltal
hvoraf 29 overlevede en hårdhudet gennemgang, og tre kritikere til sidst. Kritikernes indvendinger
er indarbejdet nedenfor — det her er ikke det oprindelige forslag, men det der stod tilbage.

---

## Det korte: hvad LiDAR faktisk køber os

**Ikke** centimeter. Idéen om at måle brystets højde over gulvet i absolutte centimeter blev afvist:
støjgulvet på så lav en indfaldsvinkel ligger inde i det interval, der er fagligt interessant, og et
tal med den slags usikkerhed er værre end ingenting.

Det LiDAR reelt køber os er tre ting:

1. **Tyngdeforankring.** `worldAlignment = .gravity` gør "op" til en fysisk retning frem for en
   billedretning. Højder betyder det samme, uanset hvor skævt telefonen er stillet.
2. **Metriske 3D-positioner.** Led kan projiceres ud i rummet i meter, ikke pixels — så hoftesænk
   kan skilles fra sidelæns hældning, hvilket et kamera alene ikke kan.
3. **Ægthedskontrollen.** Dybdespredning afviser spejle, plakater og skygger som "kroppe".

---

## Opstilling

Telefonen står **fra siden**, 1,0-1,5 m fra kroppen, lavt (gulvhøjde eller på en sko).

Det er ikke en anbefaling, man kan se bort fra. Fra siden lander kroppens op-ned-bevægelse i
kameraets stærke akse (billedplanet) i stedet for dets svage (dybden), og den nære side af kroppen
er aldrig skjult. Forfra eller skråt bliver hovedsignalet en dybdemåling, og så falder det hele fra
hinanden.

Gulvplanet findes og **låses** før sættet. Det gendetekteres ikke undervejs — kroppen dækker det.

---

## Signalet

**`h(t)`** — kroppens højde over gulvet langs tyngdeaksen, 15 gange i sekundet.

Pr. billede: tag skuldre og hofter fra Vision, projicér hvert led ud i 3D via `CameraGeometry` +
`DepthProbe`, transformér til verdenskoordinater, og lav et vægtet gennemsnit hvor vægten er
`synlighed × dybdegyldighed`. En skjult skulder trækker automatisk sig selv ud af regnestykket i
stedet for at forgifte gennemsnittet.

**Reservesignal:** falder Vision helt ud — hvilket den vil, kropsmodellen er trænet på oprejste
mennesker — bruges den øverste flade af LiDAR-kroppens punktsky i stedet. Groft, men holder
tællingen i live.

**Efterbehandling:** medianbaseret spidsfjernelse, derefter et Kalman-filter med tilstanden
[højde, hastighed]. Kalman frem for glidende gennemsnit af én grund: manglende billeder bliver til
et længere tidsskridt i stedet for et særtilfælde, og hastigheden falder ud gratis — den skal
bruges til tempo.

---

## Måltal i v1

| Måltal | Enhed | Forventet præcision |
|---|---|---|
| Antal reps | heltal | ~90-95 % enighed med en menneskelig optælling |
| Dybde pr. rep | lav / delvis / fuld | kun som kategori, aldrig som grader |
| Hofteflugt pr. rep | neutral / sænk / pukkel | ~±8-10° effektiv opløsning |
| Tempo (ned:op) | forhold, rundet til 0,5 | fasegrænser ±150-300 ms |
| Tid under spænding | sekunder pr. sæt | ±5-15 % |
| Studs i bunden | ja/nej | grov, men pålidelig som hændelse |
| Formen holdt N reps | sætning + rep-nummer | retningsbestemt korrekt |

**Skåret væk med vilje:** albuespredning (kræver frontalt kamera — forkert sensor, ikke et
softwareproblem), absolutte centimeter, hoftesænk i grader, skulderbladsbevægelse, vejrtrækning,
venstre/højre-symmetri (den fjerne side er skjult; at antage symmetri er direkte vildledende for
nogen med en reel skævhed), og knæ-armbøjninger og andre varianter.

---

## Tre alvorlige indvendinger — og hvad de betyder

Kritikerne fandt fejl, der ikke må gå med videre. De vigtigste:

### 1. Dybdemålet kan ikke opdage et gennemgående lavt sæt

`brøk = (top − bund_denne_rep) / (top − typisk_bund)` er normaliseret mod **dagens egne yderpunkter.**
Er man lav i første rep og lige så lav resten af sættet, sætter systemet "bunden" dér — og hver
eneste rep får at vide, at den var fuld dybde.

Målet kan altså kun spørge *"lignede den de andre i dag?"*, ikke *"var den dyb nok?"*.

**Konsekvens:** enten skal der en absolut reference til (en kalibrering hvor man én gang laver en
rep til bunds, og den gemmes på tværs af sessioner), eller også skal tallet hedde noget andet end
"dybde" — fx **"ensartethed"**. At kalde det dybde er en påstand, målingen ikke kan bære.

### 2. Hoftesænk forfalsker dybden — de to tal er ikke uafhængige

Begge udledes af den samme skulderhøjde. Sænker man ryggen i stedet for at bøje albuerne — den
klassiske snyd — falder skulderen, og systemet registrerer **både større dybde og hoftesænk.**

En rapport der siger "fuld dybde, betydeligt hoftesænk" ligner to uafhængige kendsgerninger for en
træner. Det er én fejl, der producerer begge tal, og dybdetallet er falsk.

**Konsekvens:** dybden skal beregnes ud fra skulderens højde **i forhold til hoften**, ikke over
gulvet. Ellers belønner appen snyd.

### 3. Historikken bryder appens eget løfte

Forsiden lover, at tallene betyder det samme fra uge til uge. Men kalibreringen er per session og
selvrefererende. Så "fuld" tirsdag og "fuld" torsdag kan være to forskellige bevægelser — og
alligevel viser historikskærmen "+3 reps siden sidste tirsdag".

**Konsekvens:** enten en fast kalibrering på tværs af sessioner, eller også må historikken kun vise
det, der faktisk er sammenligneligt: antal reps og tempo. Ikke formkvalitet.

---

## Lyd — den eneste kanal der virker

Man ligger med ansigtet i gulvet. Skærmen findes ikke.

**Budget: højst én lyd pr. rep, og de fleste reps får ingen ord.** Stilhed betyder "du er fin".

- **Opstilling:** et tikkende signal der bliver hurtigere, når billedet er rigtigt. Man holder
  telefonen, man læser ikke.
- **Før start:** *"Jeg kan se dig. Om 3, 2, 1, gå."* Eller én præcis rettelse: *"Ryk tilbage,
  jeg kan ikke se dine fødder."* Aldrig begynde at tælle ind i et ødelagt billede.
- **Pr. rep:** et lavt "tok" uden ord. Tal siges kun ved 5, 10, 15.
- **Rettelser:** 2-4 ord, kun ved en reel overskridelse, kun i pausen *efter* en rep — aldrig
  midt i. Én rettelse ad gangen, den værste. Aldrig samme rettelse to reps i træk.
- **Slut:** inden for ét sekund, under fire: *"Fjorten reps. Tolv med god form. Godt sæt."*

---

## Data

SwiftData til det strukturerede, flade filer til de rå spor. Aldrig 256×192 dybdekort pr. billede —
det er lagringsmæssigt uholdbart.

Pr. rep gemmes: tid ned, tid op, dybdebrøk, kvalitet, hoftekategori, studs, og et flag hvis
segmentet var usikkert. Pr. sæt: antallet, tiden under spænding, og hældningen på formens forfald.
Hver post skal bære et **versionsnummer på scoringsmodellen** — ellers bliver historikken
usammenlignelig, den dag algoritmen ændres.

Rå spor: 30 dages rullende opbevaring. Afledte tal: for altid, de fylder ingenting.

**Om privatliv:** ingen billeder forlader telefonen, og det er en ægte fordel. Men bevægelsesdata
fra en krop er stadig biometri-nært — det skal ikke markedsføres som anonymt.

---

## Det største praktiske problem, og løsningen

Kritikernes vigtigste fund handlede ikke om algoritmen, men om **arbejdsgangen**.

Hele designet hviler på at finde de rigtige tærskler og filterindstillinger. Gør man det på
telefonen, koster hver eneste justering: ret Swift → skub → vent på Apples Mac → signér igen →
gå hen til telefonen → lav et sæt armbøjninger → kig. **15-30 minutter pr. parameter.**

Sådan konvergerer man ikke et Kalman-filter. Sådan dør projektet stille.

### Derfor bygges det i denne rækkefølge

**1. Optagelses-tilstand på telefonen.** Ikke tælling. Bare: log `h`, alle led, synlighed og
dybdegyldighed pr. billede til en fil — små tal, ikke billeder — og få filen over på PC'en.

**2. Afspilnings-værktøj i Python på Windows.** Hele signalbehandlingen — filter, Schmitt-trigger,
rep-opdeling — skrives først som et Python-script, der kører på de optagne spor. Så tager en
justering **sekunder** i stedet for en halv time.

**3. Først når kurven er ren:** flyt algoritmen til Swift.

Det er den eneste vej, hvor det her bliver færdigt.

### Sådan ved vi, at grundlaget holder

Optag 10-15 rigtige sæt med forskellige placeringer, heriblandt nogle med bevidst dårlig form.
Tegn `h(t)` op ved siden af en manuel optælling.

Kravet er ikke først og fremmest, at tællingen rammer. Det er, at **kurven har rene, tydeligt
adskilte toppe og bunde uden uforklarlige spring i bunden af bevægelsen** — netop dér hvor kroppen
dækker mest for sig selv.

Er kurven ren, kan alt det andet bygges ovenpå. Er den ikke, er der ingen grund til at skrive en
eneste linje om hoftesænk endnu.
