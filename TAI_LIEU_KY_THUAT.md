# Game Mecha — tài liệu kỹ thuật (nhật ký phát triển)

> Bản đăng GitHub chỉ có phần game. Các thư mục nhắc tới bên dưới như `_ban_luu/`, `nguon/`, `anh_chup/`, `video/` và file `Chạy game.bat` chỉ có trên máy người làm game.

Game bắn mecha 3D cho PC, làm bằng Godot 4.7.2. Hai phe **Liên Hiệp** (mecha xanh, phe ta) và **Đế Chế** (mecha đỏ) đánh nhau bằng mecha cao 10 m. Tên game chưa chốt.

Có 2 kiểu chơi:
- **Chiến dịch:** màn huấn luyện bắn bia (6 bài có bảng hướng dẫn), rồi 4 nhiệm vụ đi một mình trên bản đồ rộng, đánh mecha địch kiểu Iron Valiant.
- **Chiếm cứ điểm:** chơi cùng bot, giành 5 cứ điểm, hạ tàu sân bay địch.

- **Ngày tạo:** 2026-10-16
- **2026-10-16:** bản chơi được trọn vẹn (menu, mecha và vũ khí, nâng cấp có lưu tiến trình, trận trên trời, bản đồ đầy đủ cảnh vật).
- **2026-10-17:** bỏ âm thanh / nhạc tải về và bản đồ thành phố; thêm sa mạc phế tích, băng giá, rừng rậm (tạo bằng code). Game hiện **chưa có âm thanh**.
- **2026-10-19:** **ghép game thử "Thử Gameplay Mecha" vào đây** (theo yêu cầu người dùng). Có:
  - mecha mới (2 loại × 2 màu phe) và dáng chạy mới;
  - thanh nhiệt, Ctrl giữ độ cao, T rơi nhanh;
  - tay phụ Q / E, pháo nhiệt X;
  - F chém / lao chém có né / đỡ đúng lúc;
  - bảng trang bị B có hình mecha L / R và biểu tượng nút;
  - **chế độ Chiến dịch**;
  - **3 ngôn ngữ** (Anh mặc định, Nhật, Việt);
  - **đổi phím**;
  - **lưu / tải**.

  Bản cũ trước khi ghép nằm ở `_ban_luu/2026-10-19_truoc_ghep_gameplay/`. Thư mục `Thử Gameplay Mecha` vẫn giữ làm chỗ thử cơ chế mới.
- **2026-10-20:** theo yêu cầu người dùng:
  - bỏ dòng chữ hướng dẫn phím trên màn hình (và phím H); thay bằng **màn huấn luyện** bắn bia, 6 bài, trước mỗi bài game dừng và hiện bảng chữ kèm ảnh minh họa;
  - vòng ngắm hiện lại **máu của thứ đang khóa** (cung trên);
  - **bay / lướt lâu hơn** (bay liên tục 6,7 → 12,5 giây);
  - **HUD mới**: ô biểu tượng cho biết vũ khí / tay phụ / pháo nhiệt / cận chiến / lao chém dùng được chưa, dấu trúng, mũi tên hướng bị bắn, dấu trên đầu mecha, viền sáng màu phe;
  - **3 bản đồ mới** dùng 13 mẫu nhà của người dùng: thành phố đổ nát, ngoại ô, đồng quê. Bỏ sa mạc, băng giá, rừng rậm và thành phố giả lập (code cất ở `_ban_luu/2026-10-20_ban_do_cu/`).
- **2026-10-20 (chiều), góp ý sau khi chơi thử** (bản trước cất ở `_ban_luu/2026-10-20_truoc_gop_y/`):
  - **bỏ Shift + F**: địch đang khóa trong 120 m có chữ **F** cạnh nó, bấm F là tự **lao chém** cực nhanh; tốc độ lao nâng cấp được (hướng Cơ động), lao càng nhanh địch càng khó né / đỡ;
  - **giữ Shift** = lướt nhanh liên tục (85 m/s), nóng máy;
  - **khóa = địch nằm trong vòng ngắm**; khi khóa chỉ hiện máu + khoảng cách; địch chỉ được đánh dấu (trên đầu, bản đồ M, bản đồ nhỏ) sau khi đã bị khóa;
  - **tên lửa địch lọt vào vòng ngắm** có tam giác rỗng đánh dấu;
  - **báo động lao chém** thành vòng nhỏ quanh thân kẻ lao tới, báo nhanh hơn;
  - địch chiến dịch **chỉ đánh khi đã phát hiện** bạn (trong tầm + nhìn thấy), **số địch tấn công cùng lúc theo độ khó** (Dễ 1 / Thường 2 / Khó 3, chọn ở màn Chiến dịch);
  - **Esc luôn lùi một bước** (hộp thoại, bản đồ M, bảng B, cài đặt, menu tạm dừng; menu chính: quay lại, màn chính hỏi thoát);
  - **HUD gọn** học bố cục Wuthering Waves: ô kỹ năng tròn nhỏ góc dưới phải, thanh giáp mảnh giữa dưới, nhiệm vụ gọn bên trái;
  - **cắt đế vuông** dưới súng máy xoay nòng và súng pháo (`nguon/_scripts/cat_de_sung.py`), render lại 2 biểu tượng (`nguon/_scripts/ve_bieu_tuong_sung.py`);
  - màn huấn luyện **không còn điểm thưởng**.
- **2026-10-26: nâng đồ họa + dọn code** (theo yêu cầu người dùng; bản trước cất ở `_ban_luu/2026-10-26_truoc_nang_do_hoa/`):
  - mục **Chất lượng đồ họa Thấp / Vừa / Cao** ở Cài đặt (đổi là áp ngay); bóng khe hở (SSAO / SSIL), ánh sáng gián tiếp (SDFGI), phản chiếu (SSR), sương thể tích có tia nắng ở thành phố và hangar, chỉnh màu riêng từng bản đồ, bóng mặt trời mềm hơn;
  - vật liệu kim loại cho mecha, súng, tàu sân bay (mẫu Tripo gốc không kim loại, rất nhám); súng và tàu có thêm vân bề mặt;
  - vụ nổ mới: chớp sáng, quả cầu lửa, khói cuộn, mảnh vụn tóe lửa; bụi tung khi đáp đất mạnh;
  - **bỏ hẳn chế độ hạm đội** (bàn cờ xếp tàu, màn Hạm đội, bản đồ chiến hạm Tab, tàu hộ tống / pháo kích / phòng không). Trên trời chỉ còn 2 tàu sân bay như lúc đang tắt hạm đội;
  - dọn code không dùng (phế tích sa mạc cũ, hàm thừa), gộp hàm vẽ chữ, bỏ 144 câu dịch thừa.
- **Ghi công:** xem [GHI_CONG.md](GHI_CONG.md). Chỉ ghi công tài nguyên đang dùng.
- **Ảnh chụp và video:**
  - `anh_chup/` (19/10: menu 3 ngôn ngữ, bảng trang bị, đổi phím, lưu / tải, trong trận; 20/10: `2026-10-20_*` — HUD mới, 3 bản đồ, bảng hướng dẫn; 20/10 chiều: `2026-10-20b_*` — HUD gọn, chữ F lao chém, vòng báo động nhỏ, tên lửa trong vòng ngắm);
  - `video/huan_luyen.mp4` (20/10: máy tự chơi màn huấn luyện).

## Cách chơi

- **Cách nhanh:** bấm đúp `Chạy game.bat`.
- **Mở bằng Godot:** chạy `D:\Dự Án Claude\Godot\Godot_v4.7.2-stable_win64.exe`, bấm **Import**, chọn file `project.godot` trong thư mục này, rồi bấm **F5**.
- Lần đầu mở, Godot cần vài phút để nạp mô hình.

**Menu chính:**
- **Bên trái:** Tiếp tục · Huấn luyện · Chiến dịch · Chiếm cứ điểm · Mecha & vũ khí · Nâng cấp · Lưu / Tải · Cài đặt · Ghi công · Chơi mới · Thoát.
- **Góc trên bên phải:** điểm công trạng và **nút ngôn ngữ** (🌐 English / 日本語 / Tiếng Việt). Bấm là đổi ngay.

**Lưu / tải:**
- Tiến trình (điểm công trạng, nâng cấp, vũ khí đã mở, trang bị, tiến độ chiến dịch, số trận, thời gian chơi) **tự động lưu** sau mỗi thay đổi, sau mỗi nhiệm vụ / trận và khi thoát.
- Ngoài ra có **3 ô lưu riêng** (Lưu / Tải ở menu chính, hoặc **Lưu game** ở menu tạm dừng Esc).
  - Mỗi ô hiện ngày giờ lưu, thời gian đã chơi, số nhiệm vụ đã xong, điểm, loại mecha.
  - Ở menu: lưu đè, tải, xóa (có hỏi trước).
- Lưu giữa nhiệm vụ: tải lại thì chơi lại nhiệm vụ đó từ đầu, với trang bị lúc lưu. Lưu giữa trận cứ điểm: chỉ lưu tiến trình.
- **Tiếp tục:** đang dở nhiệm vụ thì vào lại nhiệm vụ đó, không thì mở màn Chiến dịch.
- **Chơi mới:** xóa tiến trình đang chơi (có hỏi trước), các ô lưu riêng vẫn giữ.
- Nơi lưu: `user://tien_trinh.json` (tự động lưu), `user://ban_luu/o_1.json` … `o_3.json` (ô lưu).
- Cài đặt (ngôn ngữ, phím, âm lượng) lưu riêng ở `user://cai_dat.cfg`, dùng chung mọi ô.

## Phím (mặc định — đổi được ở Cài đặt → Điều khiển)

| Phím | Tác dụng |
|---|---|
| W A S D | **Lướt** sát mặt đất (50 m/s) |
| Shift (+ hướng) | Bấm: **bật lao** vọt đi rất nhanh (13 nhiệt). **Giữ**: **lướt nhanh** liên tục 85 m/s, nóng 8 / giây (~11 giây thì quá nhiệt). Bị địch lao chém: bấm **đúng lúc** để **né** |
| Space (giữ) | **Bay lên** (tối đa 70 m trên mặt đất), tốn nhiệt: bay liên tục được khoảng 12,5 giây |
| Ctrl | Đang bay: **giữ độ cao** (tốn nhiệt chậm). Dưới đất: đổi lướt / **chạy bộ** (20 m/s, không tốn nhiệt) |
| T | **Rơi nhanh** khi đang bay |
| Chuột trái / chuột phải (giữ) | Vũ khí tay phải / tay trái. Súng chỉ nâng lên khi bắn |
| Q / E | **Tay phụ** trái / phải (hai ổ trên tay máy sau lưng) |
| X | **Pháo nhiệt**: tên lửa đang bám mình mất khóa, lao theo pháo. 2 lượt, hồi 15 giây |
| F | **Chém** (lưỡi năng lượng cẳng tay trái). Mecha địch đang khóa trong 120 m (khung cam + chữ **F** cạnh nó): F = **lao chém** — tự lao 220 m/s tới chém, hồi 3 giây. Bị địch lao chém: bấm **đúng lúc** để **đỡ** — kẻ lao tới bị choáng 2,2 giây. Đỡ rất khó |
| B | **Bảng trang bị** (game tạm dừng). Chiến dịch: ở đâu cũng được. Chiếm cứ điểm: chỉ ở căn cứ hoặc trạm hậu cần phe ta |
| 1 / 2 / 3 / 4 | Gọi hỗ trợ từ tàu sân bay (chỉ chế độ cứ điểm): pháo kích, thả tiếp tế, quét radar, thả mecha tiếp viện |
| M | **Bản đồ lớn** (game vẫn chạy). Chiến dịch: hiện mục tiêu nhiệm vụ (dấu cam). Mecha địch chỉ hiện sau khi bạn đã khóa nó (quét radar thì thấy hết) |
| Esc | **Luôn lùi một bước**: đóng hộp thoại / cài đặt / lưu game, bản đồ M, bảng B, bản đồ chiến hạm, bảng hướng dẫn; không có gì mở thì mở / đóng **menu tạm dừng** (tiếp tục, huấn luyện: xem lại hướng dẫn, lưu game, cài đặt, rời trận / nhiệm vụ). Ở menu chính: Esc = Quay lại, màn chính hỏi thoát game. Không đổi được |

**Thanh nhiệt** (cung dưới vòng ngắm) thay thanh năng lượng:
- bật lao (13 nhiệt mỗi lần), giữ Shift lướt nhanh (8 / giây), bay lên (8 / giây), giữ độ cao (2,5 / giây) làm nóng động cơ. Từ lúc nguội: bay liên tục ~12,5 giây, lơ lửng ~40 giây, bật lao liền 7 lần;
- thôi dùng 0,5 giây thì nguội dần (32 / giây);
- đầy là **quá nhiệt**: không bay, không bật lao, không lướt, đang bay thì rơi, chỉ chạy bộ được; chờ nguội hết (khoảng 3 giây) mới dùng lại.
- (20/10: tăng năng lượng bay / lướt theo yêu cầu người dùng; số cũ: lao 21, bay 15 / giây, giữ độ cao 6 / giây — chỉnh ở `NHIET` trong `can_bang.gd`.)

**Bị lao chém:**
- **vòng báo động nhỏ quanh thân kẻ lao tới** co dần về thân nó (chỉ hiện ~1 giây cuối; kẻ lao tới ở sau lưng thì có mũi tên nhấp nháy ở mép vòng ngắm);
- vòng chạm **vạch vàng** bấm Shift là **né**, chạm **vạch trắng** bấm F là **đỡ**; phím nhỏ hiện hai bên vòng;
- bấm sớm quá là phản ứng sai, vẫn bị chém (mỗi cú chỉ được phản ứng một lần); bấm chậm là trúng đòn;
- máy địch lấy đà 0,3 giây (trước 0,55) rồi lao 160 m/s; người chơi lấy đà 0,08 giây, lao 220 m/s.

**Tên lửa:**
- tăng tốc dần, bẻ lái có giới hạn: bật lao ngang đúng lúc là né được;
- **chỉ súng máy** (súng máy xoay nòng, súng máy vai) **bắn rơi được tên lửa**; súng trường, bắn tỉa, súng pháo thì đạn đi xuyên qua.

**Đổi phím:** Cài đặt → **Điều khiển — đổi phím**.
- Bấm vào một dòng rồi bấm phím hoặc nút chuột mới. Esc là hủy.
- Phím đang dùng cho việc khác thì hai bên **đổi chỗ** (có báo).
- Có nút **Khôi phục mặc định**.
- Phím mới hiện đúng ở ô trạng thái trên HUD, bảng hướng dẫn huấn luyện, bảng trang bị, chữ báo né / đỡ / tên lửa.
- Lao chém dùng chính phím cận chiến (khi địch đang khóa trong tầm).

## Giao diện trong trận (HUD)

Không còn dòng chữ hướng dẫn phím. Thông tin cần nhìn khi đánh nằm quanh tâm ngắm (học từ Iron Valiant / AC6); bố cục gọn học từ ảnh Wuthering Waves người dùng gửi (20/10): kỹ năng nhỏ gọn góc dưới phải, thanh máu mảnh giữa dưới, nhiệm vụ gọn bên trái.
- **Vòng ngắm:** cung dưới là **nhiệt** của bạn; cung trên là **máu của thứ đang khóa** (mecha, ụ súng, bia, công trình) kèm %, xanh → vàng → đỏ khi máu giảm.
- **Khóa = mục tiêu nằm trong vòng ngắm** (trong tầm khóa, không bị nhà che); đã khóa thì giữ tới khi ra ngoài vòng 1,3 lần. Khung khóa chỉ có **thanh máu mảnh + khoảng cách**. Khung cam + chữ **F** cạnh địch = bấm F là lao chém.
- **Tên lửa địch lọt vào vòng ngắm** (trong 700 m): **tam giác rỗng đỏ** bao quanh; bắn súng máy lúc đó là nhắm vào nó.
- **Dấu trúng:** × trắng khi đạn trúng, × đỏ to khi vừa hạ địch. **Mũi tên đỏ** quanh vòng ngắm chỉ hướng vừa bị bắn.
- **Ô kỹ năng tròn** (góc dưới phải), 6 ô: vũ khí trái, vũ khí phải, tay phụ Q, tay phụ E, pháo nhiệt, cận chiến. **Phím đang gán** ghi ngay dưới mỗi ô.
  - Viền sáng: **sẵn sàng**. Hình tối + quạt quét + số giây: **đang hồi**. Hình xám + dấu nhỏ: **chưa dùng được** (ổ khóa = tên lửa chưa khóa mục tiêu, ngọn lửa = quá nhiệt, "XA" = quá tầm). Viền vàng + cung thời gian: **đang bật** (khiên, súng máy vai).
  - Pháo nhiệt có chấm số lượt còn trên đầu ô; ô cận chiến viền cam nhấp nháy khi lao chém được, cung cam mảnh bên ngoài là thời gian hồi lao chém.
- **Giáp** (giữa dưới): thanh mảnh có số ở giữa, phần vừa mất tụt dần theo sau, nhấp nháy khi dưới 30%; dòng trạng thái chữ nhỏ ngay trên.
- **Nhiệm vụ** (chiến dịch, huấn luyện): khung gọn bên trái — tên, việc cần làm, lượt hồi sinh + thời gian.
- **Dấu trên đầu mecha:** địch **đã từng bị khóa** có tam giác đỏ nhỏ (không chữ) khi nhìn thấy; địch chưa bị khóa không có dấu (chỉ viền màu phe); quét radar thì thấy hết. Đồng đội: thoi xanh + tên.
- **Viền sáng màu phe** (mới) trên thân mecha (xanh / đỏ), mạnh dần khi ở xa, để mecha nổi lên khỏi nền.
- Cảnh báo tên lửa, bị bắn tỉa ngắm, ụ minigun khóa, bị lao chém: chữ ngắn kèm **biểu tượng phím** nên bấm.
- Menu dùng chung một kiểu nút (vạch sáng bên trái khi rê chuột / bấm).

## Bảng trang bị (B) và màn Mecha & vũ khí

- **Giữa bảng:** hình mecha **nhìn từ sau lưng** (đúng như khi chơi), chữ **L** bên trái, **R** bên phải.
- **5 ô** có đường nối tới đúng bộ phận:
  - tay phụ trái (Q) và tay phụ phải (E) ở hai ổ tên lửa trên vai;
  - vũ khí trái (chuột phải) và vũ khí phải (chuột trái) ở hai bàn tay;
  - cận chiến (F) ở cẳng tay trái.
- **Mỗi ô có biểu tượng nút bấm đang gán:** hình chuột sáng nút trái / phải, hoặc phím chữ. Đổi phím thì biểu tượng đổi theo.
- Bấm ô → hàng dưới hiện các món (biểu tượng render từ mẫu thật, tên, mô tả, giá mở khóa).
  - Bấm món là lắp.
  - Ở menu, món chưa mở thì bấm là mở bằng điểm công trạng.
- Màn **Mecha & vũ khí** ở menu dùng chung bảng này, thêm chọn loại mecha và loại mecha của đồng đội bot.

## Mecha và vũ khí

**4 loại mecha** (thang 1–5). Mẫu: loại thon (Liên Hiệp Xanh 2 / Đế Chế Đỏ 1) và loại to (Xanh 1 / Đỏ 2).

| Loại | Mẫu | Tốc độ | Giáp | Hỏa lực | Chiếm | Khả năng tự có |
|---|---|---|---|---|---|---|
| Cơ bản | thon | 3 | 3 | 3 | 3 | Cân bằng |
| Cơ động | thon, nhỏ hơn 5% | 5 | 1 | 3 | 5 | **Lướt kép**: bật lao lần hai ngay sau (trong 0,8 giây) không tốn nhiệt |
| Hạng nặng | to, to hơn 10% | 1 | 5 | 5 | 2 | **Khiên dày**: khiên năng lượng chặn hết đạn phía trước (loại khác 75%) |
| Hỗ trợ | to | 3 | 3 | 2 | 3 | **Kỹ sư**: đặt được 2 ụ minigun (loại khác 1), tay phụ hồi nhanh hơn 20% |

**Vũ khí tay.** Hai tay lắp tự do, món nào cũng lắp được tay nào:

| Vũ khí | Ghi chú |
|---|---|
| Súng máy xoay nòng | Bắn nhanh, **chặn được tên lửa** |
| Súng trường | Bắn chậm, chính xác |
| Súng bắn tỉa | Tầm rất xa. Bản của máy địch chiếu laser đỏ 1,1 giây trước khi bắn |
| Súng pháo | Nổ lan 10 m (mở khóa 250) |
| Pháo plasma | Đạn bay chậm thấy được, nổ. Bản của máy địch có laser báo trước |
| Súng tia năng lượng | Tia mạnh, làm nóng địch +12 (mở khóa 300) |
| Súng EMP | Sát thương thấp, làm nóng địch +40, dễ đẩy địch quá nhiệt (mở khóa 250) |

**Tay phụ (Q / E):**

| Món | Ghi chú |
|---|---|
| Tên lửa (2 quả) | Cần khóa mục tiêu |
| Tên lửa loạt (6 quả nhỏ) | Mở khóa 300 |
| Súng máy vai | Tự bắn rơi tên lửa trong 5 giây. Mở khóa 250 |
| Khiên năng lượng | 4 giây, đạn phía trước chỉ còn 25% |
| Ụ minigun | Ụ chỉ bắn mecha địch đang bay, còi báo 1 giây trước |

**Cận chiến (F):**
- **kiếm plasma**: chém rộng;
- **thương xuyên**: sát thương cao nhất, xuyên khiên năng lượng, trúng hẹp; mở khóa 200;
- **đấm EMP**: sát thương thấp, địch choáng 1,5 giây và nóng thêm 40; mở khóa 200.

Lưỡi năng lượng ở cẳng tay trái đổi hình và màu theo kiểu đang chọn.

**Nâng cấp mecha** (màn Nâng cấp, 3 hướng). Hướng **Cơ động** gồm:
- +4% tốc độ;
- +8% thanh nhiệt và tốc độ nguội;
- **nới cửa sổ né +0,03 giây và đỡ +0,015 giây mỗi nút** (người dùng dặn: nâng cấp để né / đỡ dễ hơn);
- **lao chém nhanh hơn 8% mỗi nút** (người dùng dặn 20/10: lao nhanh hơn thì địch khó chặn / đỡ hơn — xác suất né / đỡ của máy nhân với 220 / tốc độ lao).

## Chiến dịch

Đi một mình trên bản đồ rộng, đánh mecha Đế Chế (kiểu Iron Valiant).
- Địch tuần tra (đội săn thì đi tuần khắp vùng), **chỉ tấn công và bám theo khi đã phát hiện bạn**: bạn trong tầm phát hiện (tuần tra 380 m, đội săn 450 m, phục kích 170 m, xạ thủ gấp đôi) **và nhìn thấy** (không bị nhà che), hoặc bạn bắn trúng nó. Mất dấu 10 giây thì quay về tuần.
- **Số địch tấn công cùng lúc theo độ khó** (chọn ở màn Chiến dịch, dùng chung với chế độ cứ điểm): Dễ 1, Thường 2, Khó 3. Con đã phát hiện mà chưa tới lượt thì đứng cách ~380 m, không bắn; bạn bắn trúng nó thì nó đánh trả ngay.
- Ụ súng và mecha chỉ huy (mục tiêu nhiệm vụ) hiện dấu cam trên la bàn, màn hình và bản đồ M; mecha địch thường chỉ có dấu sau khi bạn đã khóa nó.
- Mỗi nhiệm vụ có **2 lần hồi sinh** (rơi từ tàu xuống). Hết lượt là thất bại.
- Hoàn thành thì nhận điểm công trạng (huấn luyện không có) và mở nhiệm vụ kế. Chơi lại nhiệm vụ đã xong được 40% điểm.

| # | Bản đồ | Nhiệm vụ | Thưởng |
|---|---|---|---|
| 1 | Bãi tập | **Huấn luyện**: 6 bài bắn bia có bảng hướng dẫn, rồi bài thi (xem dưới) | không |
| 2 | Đồng quê | **Trạm tên lửa**: phá 6 ụ tên lửa ở 3 làng, mỗi trạm một mecha canh, trạm giữa có xạ thủ bắn tỉa | 300 |
| 3 | Ngoại ô | **Đội săn**: 3 mecha đi tuần khắp vùng (có xạ thủ laser), phát hiện bạn thì lao vào; 2 mecha nữa rơi xuống khi đợt đầu bị hạ | 350 |
| 4 | Thành phố đổ nát | **Phục kích**: lần lượt tới 3 quảng trường (A, C, E), mỗi nơi 2 mecha nấp sau nhà | 400 |
| 5 | Thành phố đổ nát | **Chỉ huy**: mecha chỉ huy ở quảng trường giữa (máu ×2,5, né / đỡ giỏi hơn) + 3 hộ vệ + 2 ụ súng | 500 |

Số liệu từng nhiệm vụ nằm trong `CHIEN_DICH` của `scripts/can_bang.gd`. Địch và ụ đặt ở quảng trường cứ điểm hoặc trên đại lộ — những chỗ bản đồ luôn để trống.

**Đo bằng máy tự chơi** (`--thu_chien_dich`, máy lái liều, không biết nấp, độ khó Thường) — 20/10 chiều, sau khi địch chỉ đánh khi phát hiện + tối đa 2 con tấn công cùng lúc:
- Huấn luyện: thắng sau 119 giây · Trạm tên lửa: 165 giây, không chết · Đội săn: 90 giây, chết 1 lần · Phục kích: 148 giây, chết 1 lần · Chỉ huy: thắng 99 giây, chết 2 lần.

Lần đo trước (20/10 sáng, trên bản đồ mới):
- Huấn luyện: qua 6 bài và bài thi sau 120 giây (ở bãi tập không thể bị hạ).
- Trạm tên lửa (đồng quê): thắng sau 150 giây, không chết.
- Đội săn (ngoại ô): thắng sau 84 giây, chết 2 lần.
- Phục kích (thành phố): thắng sau 142 giây, chết 1 lần.
- Chỉ huy (thành phố): thắng 2 / 4 lần (94–106 giây, chết 2 lần), 2 lần còn lại hết lượt hồi sinh — nhiệm vụ khó nhất. Đã chỉnh cho hợp bản đồ thành phố (quảng trường trống trải, đại lộ thẳng): xuất phát cách quảng trường 650 m, 2 ụ súng thay 4, xạ thủ đứng ở ngã tư cạnh quảng trường, sát thương địch ×0,32.

## Màn huấn luyện

Nút **HUẤN LUYỆN** ở menu chính (cũng là nhiệm vụ 1 của chiến dịch). Bãi tập bê tông ~1,1 km, có vạch bắn, làn bắn, bệ đáp, sàn đấu.
- **Trước mỗi bài game dừng** và hiện bảng: tiêu đề, **ảnh minh họa chụp từ chính game** có mũi tên chỉ chỗ cần nhìn, lời giải thích, việc cần làm, hàng **biểu tượng phím đang gán**. Bấm **BẮT ĐẦU** (Enter / Space / Esc) hoặc "Bỏ qua bài này". Trong bài, menu tạm dừng (Esc) có **Xem lại hướng dẫn**.
- Ở bãi tập giáp không xuống dưới 1 (không thể bị hạ). Trang bị cố định: súng trường + súng máy, 2 tên lửa, kiếm.

| Bài | Việc phải làm |
|---|---|
| 1. Di chuyển & nhiệt | Bật lao 2 lần, bay qua 3 vòng sáng, giữ độ cao 3 giây, rơi nhanh xuống bệ đáp (bảng có nói giữ Shift = lướt nhanh) |
| 2. Nhắm bắn | Hạ 4 bia đứng, rồi 3 bia chạy ngang |
| 3. Khóa & tên lửa | Hạ 3 bia bay (drone) bằng tên lửa |
| 4. Pháo nhiệt | Sống sót qua 3 loạt tên lửa không trúng quả nào (pháo nhiệt hoặc súng máy bắn rơi) |
| 5. Né & đỡ | Mecha tập lao chém: né 2 lần, đỡ 1 lần. Cửa sổ né / đỡ rộng gấp đôi và thời gian chậm lại lúc sắp tới vạch (mới) |
| 6. Cận chiến & bài thi | Chém trúng 1 lần, lao chém trúng 1 lần (F khi địch có chữ F); rồi hạ 2 mecha + 2 ụ tên lửa |

- Bia, bia bay, bệ phóng làm bằng code (`scripts/bia.gd`); bia nhận đạn như ụ súng nên khóa, tên lửa, cung máu chạy như với địch thật.
- Ảnh minh họa `anh/huong_dan/bai_<1..6>_<en|ja|vi>.png`: mỗi ngôn ngữ một bộ (chữ trên HUD trong ảnh khớp ngôn ngữ đang chọn). Chụp lại bằng `--chup_huong_dan=<thư mục> --ngon_ngu=<en|ja|vi>` rồi thu nhỏ 960 × 540.

## Ngôn ngữ

- **Tiếng Anh mặc định** khi mở game lần đầu. Đổi sang **日本語** hoặc **Tiếng Việt** bằng nút góc trên bên phải menu chính, hoặc ở Cài đặt.
- Mọi chữ trong game đều dịch: menu, HUD, thông báo, tên và mô tả vũ khí, nhiệm vụ, gợi ý, ghi công.
- **Bảng dịch:** `ngon_ngu/dich.csv`, mở được bằng Excel. Mỗi dòng một câu: cột `vi` (câu gốc trong code), `en`, `ja`.
  - Hiện có 637 câu.
  - Sửa câu dịch thì giữ nguyên các chỗ `%s`, `%d` và thứ tự của chúng.
  - Ô để trống thì hiện câu tiếng Việt.
- Tiếng Anh và tiếng Nhật do Claude dịch. **Nên nhờ người bản ngữ xem lại tiếng Nhật trước khi phát hành.**
- Chữ Nhật dùng font tiếng Nhật có sẵn trong Windows (Yu Gothic / Meiryo).

## Trận trên trời

Mỗi phe một **tàu sân bay** đứng yên trên cao phía trên căn cứ (bàn cờ xếp tàu, tàu hộ tống / pháo kích / phòng không đã bỏ hẳn ngày 26/10/2026 — code cũ ở `_ban_luu/2026-10-26_truoc_nang_do_hoa/`).
- Hai tàu bắn nhau mỗi 8 giây, sát thương hai bên ngang nhau (60 mỗi loạt), nên tự chúng không phân thắng thua.
- Tàu sân bay: 45000 giáp + 15000 khiên; khiên hồi rất chậm sau 10 giây không bị bắn. Bị hạ là thua.
- Người chơi giúp tàu ta bằng cách giữ **Trạm tên lửa** (bắn tàu sân bay địch) và **Trạm hậu cần** (sửa tàu ta).
- **EMP** (hướng nâng cấp của trạm tên lửa): tàu địch tê liệt 10 giây — ngừng bắn, khiên không hồi, không thả được tiếp viện.
- Các hỗ trợ 1–4 gọi từ tàu sân bay (pháo kích cũng bắn từ tàu sân bay).
- Mẫu 3D: tàu sân bay là chiến hạm to nhất mỗi phe. Hai mẫu tàu đổ bộ (thân ngắn, có buồng lái) là **máy bay vận chuyển** (dài 26 m), dùng cho máy bay chở quân và máy bay hậu cần.

**Độ dài trận** (đo bằng mô phỏng `--thu_troi`): không giữ trạm nào thì hết 15 phút cả hai tàu còn 89% (hòa); 1 trạm tên lửa: tàu địch còn 34% khi hết giờ; 2 trạm: hạ tàu địch sau khoảng 12 phút; 3 trạm: khoảng 9 phút.

## Cứ điểm

5 cứ điểm: **A, B** gần phe ta (Liên Hiệp), **C** ở giữa, **D, E** gần phe Đế Chế. Lúc đầu trận đều trống.

**Chiếm:**
- Mecha đứng trong vòng bán kính 55 m. Một mecha thường mất 12 giây.
- Nhiều mecha thì nhanh hơn (tối đa ×2). Cơ động chiếm nhanh hơn, Hạng nặng chậm hơn.
- Hai phe cùng có mặt thì thanh chiếm đứng yên.
- Cứ điểm của địch phải kéo thanh về 0 trước: lúc đó **mọi công trình bị phá sạch**.

**Chọn loại:**
- Phe ta chiếm xong thì game tạm dừng để chọn loại.
- Phe Đế Chế tự chọn theo bảng ưu tiên.
- Máy bay chở quân bay xuống, rồi ụ súng mọc lên lần lượt.

| Loại | Công trình | Tác dụng |
|---|---|---|
| Mọi cứ điểm | 2 ụ súng máy, 6 lính | Ụ súng bắn mecha địch trong 360 m |
| Pháo đài | + 2 ụ súng máy đôi, + 2 ụ pháo, + 6 lính | Địch chiếm lại chậm gấp đôi |
| Trạm tên lửa | + 2 ụ tên lửa | Mỗi 30 giây mỗi ụ phóng 1 tên lửa lên tàu địch (550 / quả). Ụ cũng bắn tên lửa đuổi mecha địch đến gần |
| Trạm hậu cần | — | Mỗi 30 giây gửi máy bay hậu cần sửa tàu sân bay (+700). Mecha phe ta trong vòng được sửa giáp và **đổi trang bị (B)** |

## Hỗ trợ, Điểm Chỉ Huy, nâng cấp

**Hỗ trợ từ chiến hạm (phím 1–4):**
- Thả tiếp tế và quét radar: miễn phí, chỉ có thời gian hồi.
- Pháo kích (60) và thả mecha tiếp viện (80): tốn **Điểm Chỉ Huy**.
- Điểm Chỉ Huy kiếm trong trận: hạ mecha +20, chiếm cứ điểm +40, bắn rơi máy bay địch +15.

**Điểm công trạng** (sau trận):
- Thắng +400, hòa +220, thua +150.
- Thêm +15 mỗi mecha tự tay hạ, +30 mỗi cứ điểm phe ta chiếm.
- Lúc bắt đầu có 300 điểm.

**Nâng cấp** (màn Nâng cấp, 3 thẻ Tàu sân bay / Mecha / Cứ điểm):
- Tàu sân bay, mỗi loại mecha, mỗi loại cứ điểm có **cấp 1–5**. Lên cấp tốn 150 × cấp hiện tại.
- Mỗi cấp cho 2 điểm kỹ năng. Điểm chia vào **3 hướng**, mỗi hướng 4 nút.
- Tối đa 10 điểm cho 12 nút, nên phải chọn hướng. Nút **Chia lại** lấy lại điểm bất cứ lúc nào.
- Phe địch có nâng cấp theo độ khó: Dễ 0, Thường 1, Khó 2 nút mỗi hướng.
- Danh sách hướng và hiệu quả từng nút nằm trong `CAY_KY_NANG` của `can_bang.gd`.

## Bản đồ

Chọn bản đồ ở màn **Vào trận** (hàng BẢN ĐỒ). Ba bản đồ 3,2 × 3,2 km dùng chung vị trí căn cứ, 5 cứ điểm và đại lộ nối (bot đi theo các đại lộ), nên luật và cân bằng như nhau. Nhà là **13 mẫu của người dùng** (`models/nha/`), còn mặt đất, cách xếp nhà, cây, xe cháy, hố bom… đều **tạo bằng code**, sinh theo hạt giống cố định.

Mecha cao 10 m nên mọi vật làm theo thước đó: tòa nhà nội thành cao 40–90 m (mecha ngang 3 tầng nhà), nhà vườn 12–16 m (ngang mái), cây 12–24 m.

**Thành phố đổ nát** (`dung_thanh_pho.gd`, shader `mat_thanh_pho`):
- phố ô bàn cờ cách nhau 150 m (phố rộng 28 m, vỉa hè), đại lộ chéo rộng 56 m nối căn cứ – cứ điểm, quảng trường lát đá quanh cứ điểm;
- khoảng 640 tòa nhà, ~57% đổ nát (càng gần giữa bản đồ càng nhiều): cụt phần trên, gạch vụn, ám khói; khe giữa các tòa đủ cho mecha lách qua;
- đống gạch, hố bom cháy đen, xe cháy, hàng rào bê tông, chông sắt chống tăng, 9 cột khói và lửa; tường bê tông đổ quanh cứ điểm làm chỗ nấp;
- rìa bản đồ: dãy nhà cao làm đường chân trời; trời âm u, khói bụi vàng xám.

**Ngoại ô** (`dung_ngoai_o.gd`, shader `mat_ngoai_o`):
- đồi thoải; phố cong đông–tây cách nhau 230 m và phố nối bắc–nam; đường chính nối căn cứ – cứ điểm;
- nhà vườn hai bên phố (cách tim phố 21 m), hàng rào gỗ / bờ cây xanh, nhà kính và cây ở vườn sau, vài nhà trúng đạn;
- khu thấp cạnh mỗi cứ điểm, tháp ăng-ten trên đỉnh đồi, rừng cây ở rìa.

**Đồng quê** (`dung_dong_que.gd`, shader `mat_dong_que`):
- đồi lượn cao tới ~38 m, ruộng chia ô 150 m (lúa mì vàng, ruộng xanh có luống, đất cày, cỏ), bờ cây dọc bờ ruộng, cuộn rơm;
- hai con sông uốn lượn (nước sâu ~3 m), cầu bê tông chỗ đường đất qua sông;
- trang trại (nhà + nhà kính), làng nhỏ quanh cứ điểm, khu thấp cạnh C, tháp ăng-ten trên đồi cao, mỏm đá trên sườn đồi (Kenney Nature Kit);
- tầm nhìn xa, ít chỗ nấp.

**Bãi tập** (`dung_bai_tap.gd`, shader `mat_bai_tap`): chỉ dùng cho màn huấn luyện.

**Mẫu nhà** (`models/nha/<tên>.glb`, `scripts/mau_nha.gd`): đổi từ FBX bằng Blender (`nguon/_scripts/nha_glb.py`), đúng cỡ mét, texture 2048 px. Mỗi file có 3 bản `nguyen`, `do_1`, `do_2`; file `.json` ghi hộp va chạm từng bản.

**Để thấy rõ mecha:** mặt đất màu trung tính tương phản với mecha xanh / đỏ, viền sáng màu phe trên thân mecha, dấu trên đầu.

**Đo thử (6 đấu 6, bot tự chơi):** cả ba bản đồ giữ khoảng 60 khung hình/giây, bot chiếm cứ điểm bình thường. Bản đồ dựng mất 2–3,5 giây.

## Âm thanh

**Hiện chưa có âm thanh và nhạc** (đã xóa bộ tải về theo ý người dùng ngày 2026-10-17).
- Hệ thống âm thanh vẫn giữ nguyên trong `scripts/am_thanh.gd`. Mọi chỗ cần tiếng đã gọi sẵn: súng, nổ, chém, đỡ đòn, né, động cơ, bước chân, còi báo, menu, nhạc menu / trận / thắng / thua.
- Có file âm thanh mới thì chỉ cần khai báo vào bảng `KHO` và `NHAC` trong file đó. Danh sách tên đang được gọi ghi ngay trên bảng.
- Âm lượng tổng / nhạc / hiệu ứng vẫn chỉnh được trong Cài đặt, dùng khi có âm thanh trở lại.

## Cấu trúc thư mục

| Đường dẫn | Nội dung |
|---|---|
| `scenes/menu_chinh.tscn` | Cảnh chạy đầu tiên: menu |
| `scenes/ban_do_thu.tscn` | Cảnh trận chiếm cứ điểm |
| `scenes/chien_dich.tscn` | Cảnh một nhiệm vụ chiến dịch |
| `scripts/can_bang.gd` | **Bảng cân bằng**: mọi con số (nhiệt, mecha, vũ khí, tay phụ, cận chiến, tàu, cứ điểm, nâng cấp, thưởng, độ khó, nhiệm vụ chiến dịch) |
| `scripts/tien_trinh.gd` | Lưu / đọc tiến trình, 3 ô lưu, tiến độ chiến dịch, cài đặt |
| `scripts/do_hoa.gd` | **Đồ họa**: mức chất lượng Thấp / Vừa / Cao, môi trường (SSAO, SSIL, SDFGI, SSR, sương thể tích, chỉnh màu, bóng), vật liệu kim loại cho mecha / súng / tàu |
| `scripts/ngon_ngu.gd`, `ngon_ngu/dich.csv` | Ngôn ngữ (Anh / Nhật / Việt) và bảng dịch (mở bằng Excel) |
| `scripts/phim.gd` | Phím mặc định, phím người chơi đổi, tên phím để hiện |
| `scripts/am_thanh.gd` | Hệ thống âm thanh và nhạc (kho đang trống) |
| `scripts/menu/` | Các màn menu (chính, chiến dịch, chiếm cứ điểm, mecha & vũ khí, nâng cấp, cài đặt, đổi phím `man_phim.gd`, lưu / tải `man_luu_tai.gd`, ghi công), menu tạm dừng, bảng trang bị `bang_trang_bi.gd`, bản đồ M, màn kết quả |
| `scripts/mecha.gd`, `tron_hoat_anh.gd`, `hoat_anh/` | Mecha (di chuyển, nhiệt, vũ khí, tay phụ, cận chiến, pháo nhiệt) và hoạt ảnh: thư viện động tác + bộ trộn của dự án Thử Hoạt Ảnh Mecha |
| `scripts/dieu_khien_nguoi_choi.gd`, `dieu_khien_bot.gd`, `luot_tan_cong.gd` | Điều khiển người chơi (theo phím đã gán, khóa mục tiêu trong vòng ngắm) và bot (chiếm cứ điểm, tuần tra, đi tuần lang thang, phát hiện bằng tầm + tầm nhìn, chờ lượt tấn công, né / đỡ lao chém, pháo nhiệt); `LuotTanCong` giới hạn số địch tấn công cùng lúc |
| `scripts/ten_lua.gd`, `phao_nhiet.gd`, `dan_plasma.gd` | Tên lửa bám (né được, súng máy bắn rơi được), pháo nhiệt, đạn plasma |
| `scripts/tran_tren_troi.gd`, `tau_chien.gd` | Hai tàu sân bay trên trời bắn nhau, tên lửa từ trạm dưới đất |
| `scripts/ban_do_thu.gd` | Trận chiếm cứ điểm (cũng là nền cho trận chiến dịch) |
| `scripts/tran_chien_dich.gd` | Nhiệm vụ chiến dịch (mục tiêu, tuần tra, đợt hai, điểm đến, lượt hồi sinh) |
| `scripts/huan_luyen.gd`, `bia.gd`, `menu/bang_huong_dan.gd`, `scenes/huan_luyen.tscn` | Màn huấn luyện (6 bài, mecha tập, bệ phóng), bia tập, bảng hướng dẫn có ảnh |
| `scripts/dia_hinh.gd`, `dung_ban_do.gd` | Địa hình (thành phố / ngoại ô / đồng quê / bãi tập); lớp gốc dựng cảnh: căn cứ, đặt nhà, tường đổ, khói lửa, xe cháy |
| `scripts/dung_thanh_pho.gd`, `dung_ngoai_o.gd`, `dung_dong_que.gd`, `dung_bai_tap.gd` | Dựng 3 bản đồ và bãi tập |
| `scripts/mau_nha.gd`, `models/nha/` | Mẫu nhà của người dùng (3 bản nguyên / đổ nát, hộp va chạm) |
| `scripts/trong_cay.gd`, `cay_rung.gd`, `phe_tich.gd` | Cây, bụi (code); khối bê tông, tường đổ (code) |
| `scripts/mat_*.gdshader`, `vien_phe.gdshader` | Mặt đất từng bản đồ; viền sáng màu phe trên mecha |
| `scripts/menu/ve_bieu_tuong.gd` | Vẽ biểu tượng món và phím (dùng chung HUD, bảng B, bảng hướng dẫn) |
| `scripts/menu/giao_dien.gd` | Kiểu nút / khung dùng chung, đổi ngôn ngữ, **Esc lùi một bước** (`lop_esc`, `lui_lop_tren`) |
| `anh/huong_dan/` | Ảnh minh họa màn huấn luyện (chụp từ game) |
| `scripts/cu_diem.gd`, `u_sung.gd`, `u_minigun.gd`, `may_bay.gd` | Cứ điểm, ụ súng, ụ minigun, máy bay |
| `scripts/ho_tro.gd`, `hud.gd` | Hỗ trợ chiến hạm, giao diện trong trận |
| `scripts/anh_ban_do.gd`, `ban_do_nho.gd` | Ảnh nền bản đồ (vẽ từ địa hình thật lúc vào trận), bản đồ nhỏ góc màn hình |
| `scripts/tu_kiem_tra.gd`, `menu/thu_menu.gd`, `thu_troi.gd` | Các chế độ tự kiểm tra |
| `models/` | Mô hình mecha (`mecha/`: 2 loại × 2 màu phe, file `.json` ghi đáy chân, ổ tên lửa, 3 đế phụ), tàu, máy bay, súng, ụ súng (do người làm game cung cấp). `bieu_tuong/`: biểu tượng vũ khí và hình mecha nhìn từ sau (render bằng Blender; `sung_may.png`, `sung_phao.png` render lại bằng `nguon/_scripts/ve_bieu_tuong_sung.py`). `sung_mecha/minigun.glb`, `sung_phao.glb` đã cắt đế vuông bằng `nguon/_scripts/cat_de_sung.py`. Ụ minigun dùng `u_sung/u_sung_may_doi.glb`. Máy bay vận chuyển (`may_bay/`) làm từ hai mẫu tàu đổ bộ bằng `nguon/_scripts/lam_may_bay.py` |
| `_ban_luu/` | Bản sao lưu trước các lần sửa lớn; `2026-10-19_truoc_ghep_gameplay/khong_dung/` chứa mẫu không còn dùng; `2026-10-20_ban_do_cu/` code 3 bản đồ cũ và thành phố giả lập; `2026-10-20_truoc_gop_y/` code, bảng dịch, 2 mẫu súng còn đế, ảnh hướng dẫn trước khi sửa theo góp ý chiều 20/10 |
| `assets_ngoai/` | Mẫu 3D (căn cứ, đá), hòm tiếp tế, bầu trời, texture tải về (xem GHI_CONG.md) |
| `nguon/` | File gốc `.blend`, script Blender. Godot bỏ qua thư mục này |

## Kiểm tra tự động

```
Godot_v4.7.2-stable_win64_console.exe --path . -- --autotest=D:/thu_muc_anh
```

- `--autotest=<thư mục>`: vào thẳng trận cứ điểm, thử từng cơ chế (55 phép: nhiệt, bay liên tục ≥ 12 giây, giữ độ cao, rơi nhanh, chạy bộ, **giữ Shift lướt nhanh + nóng máy (phím thật)**, pháo nhiệt, súng máy chặn tên lửa, tay phụ, lao chém, 5 trường hợp bị lao chém, kiểu cận chiến, súng làm nóng, khiên, ụ minigun, bảng B, khả năng các loại mecha, hồi sinh, chiếm cứ điểm, **địch chỉ đánh khi phát hiện + giới hạn số con tấn công + bị bắn thì đánh trả**, bia khóa được, cung máu mục tiêu, ô trạng thái, **chữ F + bấm F thật là lao chém**, **Esc đóng bản đồ M / bảng B / mở-lùi-đóng menu tạm dừng**), in `[kiem] DAT / KHONG DAT` và chụp ảnh.
- `--kiem_ma`: nạp mọi file code để bắt lỗi, in số câu trong bảng dịch.
- `--thu_chien_dich=<thư mục> --nhiem_vu=<0..4>`: máy tự chơi một nhiệm vụ chiến dịch, in thắng / thua, thời gian, số lần chết, chụp ảnh mỗi 20 giây. Nhiệm vụ 0 (huấn luyện): máy tự đóng bảng và làm lần lượt 6 bài.
- `--chup_huong_dan=<thư mục>`: dựng từng bài huấn luyện, chụp ảnh minh họa cho bảng hướng dẫn và ảnh chính bảng hướng dẫn.
- `--ngon_ngu=ja` (hoặc `en`, `vi`): chạy với ngôn ngữ đó (không lưu vào cài đặt).
- Thêm `--quansat=150`: chỉ đứng xem bot hai phe tự chơi 150 giây. Mỗi 10 giây in tình hình cứ điểm, % tàu sân bay, số khung hình mỗi giây (FPS) và bot nào có thể bị kẹt. Thêm `--quanso=6` để xem 6 đấu 6.
- `--thu_menu=<thư mục>`: tự bấm qua các màn menu ở cả 3 ngôn ngữ, thử mở khóa và lắp vũ khí ở bảng trang bị, đổi phím (kể cả hoán đổi), lưu vào ô rồi tải lại, chọn độ khó chiến dịch, Esc (màn con → màn chính, đổi phím → cài đặt → màn chính, màn chính → hỏi thoát → đóng hỏi).
- `--chup_ban_do` (kèm `--autotest`): chụp bản đồ từ trên cao và vài góc dưới đất.
- `--ban_do=thanh_pho`, `ngoai_o` hoặc `dong_que` (kèm `--autotest`, `--quansat`): thử trên bản đồ đó (mặc định là bản đồ chọn lần cuối, chế độ tự kiểm tra thì là thành phố).
- `--thu_troi`: mô phỏng nhanh trận trên trời (x20), in thời gian hạ tàu sân bay theo số trạm tên lửa / hậu cần mỗi phe giữ.
- `--do_hoa=thap|vua|cao` (kèm `--autotest`, `--quansat`, `--chup_ban_do`): chạy với mức chất lượng đó (không lưu). `--do_hoa=cu`: ánh sáng / vật liệu như trước 26/10, chỉ để chụp ảnh so sánh.
- Chế độ tự kiểm tra dùng file lưu riêng (`user://tien_trinh_thu.json`, `user://ban_luu_thu/`), không ghi đè phím và ngôn ngữ đã chọn, không đụng vào tiến trình thật.

## Lộ trình

1. ✅ Lái mecha, bắn, khóa mục tiêu, cận chiến, phản đòn, gọi hỗ trợ.
2. ✅ Bot mecha biết đánh, chiếm cứ điểm, dùng kỹ năng.
3. ✅ Cứ điểm: chiếm, phá sạch, xây dần, 3 loại, EMP.
4. ✅ Tầng trời: chiến hạm có giáp / khiên, tường chắn, tên lửa, bắn chặn, thắng khi hạ tàu sân bay.
5. ✅ Chuẩn bị trước trận: mecha và vũ khí, cây kỹ năng, điểm công trạng (hạm đội trên bàn cờ đã bỏ 26/10).
6. ✅ (2026-10-19) Ghép cơ chế game thử: thanh nhiệt, tay phụ, pháo nhiệt, lao chém né / đỡ, bảng B; chế độ Chiến dịch; 3 ngôn ngữ; đổi phím; lưu / tải.
6b. ✅ (2026-10-20) Màn huấn luyện có bảng hướng dẫn; HUD ô trạng thái; 3 bản đồ mới với mẫu nhà của người dùng.
6c. ✅ (2026-10-20 chiều) Góp ý sau khi chơi thử: F lao chém, giữ Shift, khóa trong vòng ngắm, địch phát hiện + giới hạn tấn công theo độ khó, Esc lùi một bước, HUD gọn kiểu Wuthering Waves, cắt đế 2 mẫu súng.
7. Ra lệnh cho nhóm bot, AI chỉ huy phe địch thông minh hơn; bot biết nấp.
8. Thay ổ tên lửa dính trên lưng mecha bằng mẫu vũ khí khác (cắt ổ khỏi lưới, gắn vào 3 đế phụ ghi trong file .json).
9. Âm thanh; phi công ra khỏi mecha, hầm ngầm cứ điểm.
10. Chơi online (PvP).

Ghi chú:
- Người dùng báo trận kéo dài quá (2026-10-16). Đã sửa bằng giới hạn 15 phút và trận trên trời. Cần người chơi thử lại cảm giác.
- Lính đồn trú hiện chỉ đứng gác.
