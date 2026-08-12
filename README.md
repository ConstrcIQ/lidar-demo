# LiDAR Demo — iOS-app bygget fra Windows

En simpel demo-app til iPhone 17 Pro der bruger LiDAR-scanneren til to ting:

1. **Tegner rummets 3D-mesh live** som et farvet net henover kamerabilledet, mens du bevæger telefonen.
2. **Måler afstanden** til det punkt sigtekornet i midten peger på — opdateret 10 gange i sekundet, aflæst direkte fra sensorens rå dybdekort.

Grænsefladen viser status, antal mesh-brikker, antal trekanter, og har Start / Pause / Nulstil samt en kontakt der skjuler nettet, så du kan se rummet uden overlay.

---

## Sådan får du den på telefonen (uden Mac)

Apples compiler kører kun på macOS. Vi låner derfor en Mac gratis hos GitHub i de par minutter, byggeriet tager.

### Trin 1 — Skub ændringer op

Repoet ligger på https://github.com/ConstrcIQ/lidar-demo (offentligt — det er dét, der gør Mac-maskinerne gratis og uden minutloft). Efter en ændring:

```bash
git add -A && git commit -m "beskriv ændringen" && git push
```

### Trin 2 — Vent på byggeriet

Hvert push starter jobbet "Byg usigneret IPA" under fanen **Actions**. Tager 3-6 minutter. Når det er grønt, ligger `LidarDemo-ipa` klar nederst på siden. Eller hent den direkte:

```bash
gh run download -n LidarDemo-ipa -D "$HOME/Desktop/LidarDemo"
```

### Trin 3 — Installér på iPhone

Hent [Sideloadly](https://sideloadly.io) til Windows. Slut din iPhone til med kabel, træk `LidarDemo.ipa` ind i Sideloadly, indtast dit **almindelige, gratis Apple-ID** og tryk Start.

Første gang skal du godkende dig selv på telefonen: **Indstillinger → Generelt → VPN og enhedsadministration → tryk på dit Apple-ID → Stol på**.

### Det du skal vide om gratis-signering

- Appen **udløber efter 7 dage**. Kør Sideloadly igen for at forny — dine data bevares.
- Du kan have **højst 3 sideloadede apps** ad gangen på samme Apple-ID.
- Det koster ingenting. En Apple-udviklerkonto ($99/år) fjerner 7-dages-grænsen, men er ikke nødvendig for at teste.

---

## Filerne

| Fil | Hvad den gør |
|---|---|
| `project.yml` | Opskriften på Xcode-projektet. XcodeGen bygger `.xcodeproj` ud fra den, så vi ikke behøver Xcode for at redigere projektet. |
| `Sources/LidarDemoApp.swift` | Appens indgang. |
| `Sources/ContentView.swift` | Hele grænsefladen. |
| `Sources/ScanSession.swift` | Motoren: starter AR-sessionen, tænder for mesh-opbygning og dybdedata, tæller geometri, aflæser afstanden i midten. |
| `Sources/ARViewContainer.swift` | Limen mellem RealityKits kameravisning og SwiftUI. |
| `.github/workflows/build-ipa.yml` | Opskriften GitHubs Mac følger. |

Vil du ændre noget i appen: ret Swift-filerne her på PC'en, `git push`, og hent en ny `.ipa` fem minutter senere.

## Krav

iPhone 12 Pro eller nyere Pro-model / iPad Pro med LiDAR. iOS 17 eller nyere. Appen viser en pæn fejlskærm på enheder uden LiDAR i stedet for at gå ned.
