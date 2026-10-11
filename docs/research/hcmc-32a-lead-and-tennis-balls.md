# Research: 32A CEE adapter and tennis balls in Ho Chi Minh City

Researched Sunday 11 Oct 2026. Base: BIG Hotel Trung Sơn, Bình Chánh (also Tân Mỹ / District 7).
Prices are what web listings showed on the day. Shops change prices often, so call ahead.
Note: the brief stopped partway through ("Shops sh…") and Task 2 (tennis balls) had no details,
so section 2 assumes the goal is "buy a can of normal tennis balls near the base".

---

## 1. Adapter: blue 32A CEE socket → normal Danish/EU outlet

The requirement changed: a short **adapter** that goes from the blue 32A socket (PCE Typ 1232, 2P+E, 6h, IP67) to an ordinary household outlet. No 10 m lead is needed. If you need more reach, plug a normal Danish extension cord into the adapter.

### Ready-made option (photos confirm the socket: blue, 3-pin, 32A, 6h)
- **Lazada: "Bộ Ổ Cắm Và Phích Cắm Chuyển Đổi – Phích Cắm Điện 3 Chấu 32A Chuyển Sang Ổ Cắm Schuko 2 chấu Di Động 16A"**, seller Công ty TNHH Recess (registered at Saigon Centre, Q1):
  https://www.lazada.vn/products/bo-o-cam-va-phich-cam-chuyen-doi-phich-cam-dien-3-chau-chuyen-sang-o-cam-schuko-di-dong-i2360374766.html
  This is the only exact ready-made match found. Price and stock could not be read from here: Lazada is blocked in this research environment. Check the page for "còn hàng" (in stock), a blue **3-pin** 32A plug (not 5-pin, not 16A), and delivery time.
  It most likely has no breaker inside. That is acceptable for low-power electronics, but don't run heaters or kettles through it.
- Ask the seller on Zalo:
  *"Shop còn hàng bộ chuyển phích công nghiệp 32A 3 chấu (2P+E, màu xanh) sang ổ cắm Schuko 16A không? Có aptomat bên trong không? Giao về Bình Chánh hôm nay/ngày mai được không?"*
- Backup seller: Cơ Điện Minh Hùng / sacxe.net, hotline and Zalo **0937 697 095** (Biên Hòa, ships to HCMC). They sell Schuko power boxes and EV-charging adapters and can build one to order.
- If none of these work out, build it yourself with the parts below (Chợ Dân Sinh or Phú Toàn).

### Must-have: a 16A breaker inside the adapter
The 32A socket sits behind a 32A breaker. A household outlet and the cords plugged into it are rated 13–16A. Without a breaker of their own, an overload or a fault in a 16A cord would not trip anything and the cord could overheat. European 32A→16A adapters are sold with a built-in 16A MCB for exactly this reason. Since this will be used outdoors and we don't know whether the supply has an RCD, use a **16A RCBO (30 mA)**. It combines the overcurrent breaker and the earth-leakage protection in one part.

### Which outlet: Schuko (type F), not Danish type K
- **Type F (Schuko)** has been an approved outlet in Denmark since 2008, so it counts as a normal Danish outlet. Almost every earthed appliance sold in Denmark has a type F or E/F plug, and those plugs are only properly earthed in a type F outlet. A type C (Europlug) also fits.
- A **Danish type K plug** fits a Schuko outlet, but the earth doesn't connect. That is only a problem if you're bringing a Danish power strip or device with an old K plug. In that case, bring a type K outlet from Denmark, because they aren't sold in VN.
- Schuko outlets are easy to find in HCMC. Ask for *"ổ cắm Schuko 16A"*.

### Build (keep it compact: plug → short cable → small box)

| Part | What to ask for | Price found (VND) |
|---|---|---|
| Plug | **PCE F0232-6**: 32A, 2P+E, 230V, 6h, IP67, blue | 243,600 – 325,000 |
| Cable, about 0.5–1 m | **Cadivi VCmt 3×4**. This piece sits before the 16A breaker, so it has to be rated for the 32A supply. | 41,000 – 50,800 /m |
| Breaker | **Schneider Easy9 RCBO 1P+N 16A 30mA** (EZ9D34616 / EZ9D33616) | 441,100 – 457,200 |
| Box | Small IP65 surface box with DIN rail, 2–4 modules ("hộp aptomat nổi IP65") | about 50,000 – 150,000 (estimate) |
| Outlet | Surface-mount **Schuko 16A**: Sino S68/16 or S18/16 (43–86k), Schneider E426_16_WE (124–138k), Mennekes surface IP44 (398k) | 43,000 – 398,000 |
| Cable gland and short 3×2.5 tail from breaker to outlet | Leftover 3×4 works too | about 20,000 |

**Total: about 850,000 – 1,400,000 VND** (≈ US$33–55). Most of it is the RCBO.
A plain 16A MCB costs less than the RCBO (I didn't find a price; expect about 100k), but it drops the 30 mA earth-leakage protection. Only use one if you're sure the 32A supply already has an RCD in front of it.

Phrase for the shop:
*"Tôi cần làm bộ chuyển: phích cắm công nghiệp 32A 3 chấu IP67 màu xanh (PCE F0232-6), 1 mét dây Cadivi VCmt 3x4, hộp nổi IP65, RCBO 16A 30mA 1P+N, và ổ cắm Schuko 16A."*
Many điện nước shops will also wire it for you, often for a small fee.

### Where to buy

| Shop | Where | Notes |
|---|---|---|
| **Cửa hàng Phú Toàn** (điện nước) | QL50, Bình Hưng, Bình Chánh, tel. **0907 901 750** | Closest found to Trung Sơn. Likely to have the cable, box and an MCB/RCBO. Call to ask about the 32A CEE plug and a Schuko outlet. |
| Chợ Dân Sinh | 104 Yersin, Q1 (old District 1) | Main hardware market, about 7–8 km away. Should have every part in one trip. From general knowledge, not confirmed by today's search. |
| Online: thietbidiendgp.vn (Đặng Gia Phát), shopdien.vn, bkcs.vn, baoanjsc.com.vn | HCMC dealers | Đặng Gia Phát lists both the PCE plug and Schuko outlets (Sino, Schneider). Bảo An lists the Schneider RCBO. |

Many trade shops close on Sunday or only open in the morning, so phone first.

---

## 2. Tennis balls

### Price guide (can of 4 balls)

| Ball | Price (VND) |
|---|---|
| Dunlop Pro Tour | ~105,000 |
| Head Tour XT | 140,000 – 150,000 |
| Dunlop ATP Championship | 145,000 – 160,000 |
| Dunlop AO | 155,000 – 190,000 |
| Wilson Championship | 160,000 – 180,000 |
| Wilson US Open | 195,000 – 230,000 |

Budget brands in cans of 3 sell for 80,000 – 150,000. Most shops give a lower price for a full carton of 18 cans.

### Where to buy near the base

| Shop | Address | Notes |
|---|---|---|
| **VNB Quận 7** | 39 Đường 65, Tân Phong (old D7), tel. **0899 793 965** | Racket-sports shop that lists tennis balls. Closest specialist found. |
| **Decathlon Parc Mall** | 547–549 Tạ Quang Bửu, Chánh Hưng (old D8) | About 4–5 km from Trung Sơn. Usually open 7 days a week until about 22:00 (check). Carries its own Artengo balls plus branded ones. |
| Tennis courts in Phú Mỹ Hưng (e.g. City View Tennis, Khu Nam) | PMH, D7 | They rent balls and rackets. Some court shops also sell cans. |
| Shopee / Lazada | delivery | Search "bóng tennis Dunlop ATP" or "bóng tennis Wilson". Delivery within HCMC is often next day. |

---

## Sources
- PCE F0232-6 listings: [shopdien.vn](https://shopdien.vn/f0232-6-pce-phich-cam-cong-nghiep-kin-nuoc-3p-32a-ip67-2p-e-plug), [Đặng Gia Phát](https://www.thietbidiendgp.vn/products/phich-cam-di-dong-loai-kin-nuoc-32a), [BKCS](https://www.bkcs.vn/phich-cam-cong-nghiep-3p32a240vip67-mpn0232-mpe-kep-giu-day), [codienhaiau](https://codienhaiau.com/product/phich-cam-kin-nuoc-panasonic-f0232-6-32a-3p-230v/), [thietbidienmang (MPE)](https://thietbidienmang.com/phich-cam-cong-nghiep-mpe-32a-ip67-mpn-0232)
- Cadivi VCmt 3×4: [codienhaiau](https://codienhaiau.com/product/day-dien-3-loi-cadivi-vcmt-3x4-mm2/), [capdientct](https://capdientct.com/bang-gia-day-dien-cadivi-2026/), [daycapdiencadivi.vn](https://daycapdiencadivi.vn/Content/pr/cadivi.html), [thanhthienphu](https://thanhthienphu.vn/product/vcmt-3x4/), [daycapcadivi.vn](https://daycapcadivi.vn/bang-gia-day-dien-mem-tron-vcmt-cadivi/)
- Schuko outlets: [Đặng Gia Phát – Sino](https://www.thietbidiendgp.vn/products/o-cam-schuko-16a-tiep-dat), [Đặng Gia Phát – Schneider](https://www.thietbidiendgp.vn/products/o-cam-schuko-16a-e426-16-we), [thietbidienmang – Sino S18/16](https://thietbidienmang.com/o-cam-don-schuko-sino-s18-16), [Phương Minh – S68G/16](https://www.thietbidiencongnghiep.com.vn/san-pham/o-cam-schuko-16a-s68g16/), [Phong Vũ – surface Schuko](https://www.phongvu-electric.com/products/o-cam-schuko-16a-co-nap)
- RCBO prices: [Bảo An EZ9D34616](https://baoanjsc.com.vn/products/residual-current-breaker-with-overcurrent-protection-rcbo-easy9-schneider-EZ9D34616_328072_en.aspx), [Bảo An EZ9D33616](https://baoanjsc.com.vn/products/residual-current-breaker-with-overcurrent-protection-rcbo-easy9-schneider-EZ9D33616_328067_en.aspx)
- 32A→16A adapters need their own 16A breaker: [alve.ee](https://www.alve.ee/en/product/adapter-32a-16a-c16a-with-circuit-breaker/), [Tough Leads](https://toughleads.co.uk/products/32a-to-16a-adaptor-230v-415v-options)
- Type F vs type K in Denmark: [WorldStandards – Denmark](https://www.worldstandards.eu/electricity/plug-voltage-by-country/denmark/), [WorldStandards – type K](https://www.worldstandards.eu/electricity/plugs-and-sockets/k)
- Bình Chánh electrical shops: [linhkiencongnghiep.vn](http://www.linhkiencongnghiep.vn/2023/07/cua-hang-ien-nuoc-binh-chanh-tphcm.html), [hagico.net](https://hagico.net/phan-phoi-thiet-bi-dien-binh-chanh/)
- Tennis ball prices: [Sport House](https://sporthouse.vn/san-pham/bong-tennis.html), [Trang Nguyễn](https://trangnguyen.vn/bong-tennis-wilson), [Bảo An Sport](https://baoansport.vn/bong-tennis/bong-tennis-wilson-championship-do/), [Gu Sport](https://www.gusport.com.vn/bong-tennis-wilson-championship-hop-4-qua), [Việt Thể Thao](https://vietthethao.com/san-pham/Bong-Tennis.html), [WikiSport](https://wikisport.vn/dung-cu-tennis/bong-tennis/)
- Tennis shops and courts: [VNB Quận 7](https://shopvnb.com/vnb-q7/phu-kien-tennis.html), [Decathlon blog (store list)](https://www.decathlon.vn/blog/cua-hang-do-boi-tp-hcm/), [City View Tennis PMH](https://www.facebook.com/CityViewTennisPMH/)
