# Ghi công

Tệp này chỉ liệt kê tài nguyên **game đang dùng**. Thứ gì bỏ khỏi game thì ghi công cũng được xóa theo.

Màn **Ghi công** trong game hiện cùng danh sách này, ở cả ba ngôn ngữ.

Gói CC0 không bắt buộc ghi công, nhưng vẫn ghi để cảm ơn tác giả. Tài nguyên CC BY 4.0 **bắt buộc** ghi công như dưới đây.

## Mẫu của người làm game

Mọi mẫu trong `models/` do người làm game cung cấp (tạo bằng Tripo), gồm:
- 2 loại mecha, mỗi loại 2 màu phe (Liên Hiệp xanh, Đế Chế đỏ): `models/mecha/`;
- chiến hạm (`models/tau/`) và máy bay vận chuyển (`models/may_bay/`);
- súng (`models/sung_mecha/`) và ụ súng (`models/u_sung/`);
- 13 mẫu nhà (`models/nha/`): 7 tòa nhà nội thành và 6 nhà ngoại thành. Đã đổi sang mét theo thước mecha 10 m,
  giảm texture xuống 2048 px và làm thêm 2 bản đổ nát cho mỗi nhà bằng Blender (mẫu gốc không sửa).

Biểu tượng trong `models/bieu_tuong/` được render từ chính các mẫu này.
Ảnh minh họa của màn huấn luyện (`anh/huong_dan/`) chụp từ chính game.

Mặt đất 3 bản đồ (thành phố đổ nát, ngoại ô, đồng quê) và bãi tập, cách xếp nhà, cây, bia tập, hiệu ứng và giao diện
đều được tạo bằng code trong game.

## Động tác

| Tác phẩm | Tác giả | Giấy phép | Link | Dùng cho |
|---|---|---|---|---|
| **The 100STYLE Dataset** | **Ian Mason và cộng sự** (MIT / Meta / HKU) | **CC BY 4.0** | https://www.ianxmason.com/100style/ | Dáng đi / chạy của mecha |

Ghi công theo CC BY 4.0: "The 100STYLE Dataset" của Ian Mason và cộng sự, giấy phép CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), tại https://www.ianxmason.com/100style/.

**Đã thay đổi:**
- cắt một chu kỳ bước;
- chuyển sang khung xương mecha;
- chỉnh dáng chân;
- làm chậm, giảm lắc thân;
- dựng thêm dáng chạy cho mecha.

Thư viện động tác lấy từ dự án Thử Hoạt Ảnh Mecha (xem GHI_CONG.md của dự án đó).

## Mẫu 3D tải về

Mọi file nằm trong `assets_ngoai/`, tải từ trang gốc ngày 2026-10-16. Mỗi bộ Kenney chỉ giữ phần game dùng.

| Tác phẩm | Tác giả | Giấy phép | Link | Dùng cho |
|---|---|---|---|---|
| Space Kit | Kenney (www.kenney.nl) | CC0 1.0 | https://kenney.nl/assets/space-kit | Hangar, chảo radar, bệ tên lửa, phi thuyền chở hàng ở căn cứ và nền menu |
| Nature Kit | Kenney | CC0 1.0 | https://kenney.nl/assets/nature-kit | Mỏm đá trên sườn đồi ở bản đồ Đồng quê |
| **Sci-Fi Shipping Crate** | **David W CG** | **CC BY 4.0** | https://opengameart.org/content/sci-fi-shipping-crate | Hòm tiếp tế |

Ghi công theo CC BY 4.0: "Sci-Fi Shipping Crate" của David W CG, giấy phép CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/), tại https://opengameart.org/content/sci-fi-shipping-crate.

**Đã thay đổi:**
- đổi tỉ lệ cho hợp mecha cao 10 m;
- chỉnh màu theo phe.

## Bầu trời và texture

| Tác phẩm | Tác giả | Giấy phép | Link | Dùng cho |
|---|---|---|---|---|
| Kloofendal 48d Partly Cloudy (Pure Sky) | Poly Haven | CC0 1.0 | https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky | Bầu trời (ngoại ô, đồng quê, bãi tập) |
| Concrete Floor Worn 001 | Poly Haven | CC0 1.0 | https://polyhaven.com/a/concrete_floor_worn_001 | Bê tông mặt đường, vỉa hè, quảng trường, tường đổ, cầu, sàn hangar ở menu |

## Âm thanh

58 tiếng động trong `am_thanh/` (động cơ, bước chân, súng, nổ, cảnh báo…) do người làm game tự tạo trên máy của mình
rồi cắt, chỉnh âm lượng, xuất OGG. Game không dùng tiếng tải về.

| Tác phẩm | Tác giả | Giấy phép | Link | Dùng cho |
|---|---|---|---|---|
| **Audio Studio MCP** | **KanaWorks_AI** — 東京AI映像合同会社 (Tokyo AI Visuals LLC) | MIT | https://github.com/kanaworksai-hue/audio-studio-mcp | Công cụ tạo toàn bộ tiếng động trong game |
| Stable Audio 3 Medium | Stability AI | Stability AI Community License | https://huggingface.co/stabilityai/stable-audio-3-medium | Mô hình tạo âm thanh mà Audio Studio MCP dùng |

Cảm ơn KanaWorks_AI đã chia sẻ Audio Studio MCP. Tên KanaWorks_AI, logo và nhân vật Kana thuộc 東京AI映像合同会社, game không dùng hình ảnh nào của họ.

## Phần mềm

- Godot Engine 4.7 — giấy phép MIT — https://godotengine.org
- Blender — dùng để xử lý mô hình và render biểu tượng — https://www.blender.org

Cơ chế chơi (thanh nhiệt, tên lửa vai, pháo nhiệt…) học ý tưởng từ trò chơi Iron Valiant. Game không dùng tài nguyên nào của trò chơi đó.
