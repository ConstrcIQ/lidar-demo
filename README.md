# LiDAR Demo — iOS-app bygget fra Windows

En simpel demo-app til iPhone 17 Pro der bruger LiDAR-scanneren til to ting:

1. **Tegner rummets 3D-mesh live** som et farvet net henover kamerabilledet, mens du bevæger telefonen.
2. **Måler afstanden** til det punkt sigtekornet i midten peger på — opdateret 10 gange i sekundet, aflæst direkte fra sensorens rå dybdekort.

Grænsefladen viser status, antal mesh-brikker, antal trekanter, og har Start / Pause / Nulstil samt en kontakt der skjuler nettet, så du kan se rummet uden overlay.

---

## Sådan får du den på telefonen (uden Mac)

Apples compiler kører kun på macOS. Vi låner derfor en Mac gratis hos GitHub i de par minutter, byggeriet tager.

### Trin 1 — Læg projektet på GitHub

Opret et **offentligt** repository på github.com (offentligt er vigtigt: så er Mac-maskinerne gratis og uden minutloft). Kør derefter i denne mappe:

```bash
git init && git add -A && git commit -m "LiDAR demo" && git branch -M main && git remote add origin https://github.com/DIT-BRUGERNAVN/lidar-demo.git && git push -u origin main
```

### Trin 2 — Vent på byggeriet

Gå til fanen **Actions** i dit repo. Der kører et job der hedder "Byg usigneret IPA". Tager 3-6 minutter. Når det er grønt, ligger der en fil at hente nederst på siden: `LidarDemo-ipa`. Hent den og pak zip-filen ud — indeni ligger `LidarDemo.ipa`.

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
