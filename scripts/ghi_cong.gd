class_name GhiCong
extends RefCounted
## Danh sách ghi công mọi tài nguyên tải từ internet (giống file GHI_CONG.md ở thư mục game).

const DANH_SACH := [
	{"ten": "The 100STYLE Dataset", "tac_gia": "Ian Mason và cộng sự (MIT / Meta / HKU)", "giay_phep": "CC BY 4.0 (bắt buộc ghi công)",
		"link": "https://www.ianxmason.com/100style/", "dung_cho": "Dáng đi / chạy của mecha (đã chuyển sang khung xương mecha và chỉnh sửa)"},
	{"ten": "Nature Kit", "tac_gia": "Kenney (www.kenney.nl)", "giay_phep": "CC0 1.0",
		"link": "https://kenney.nl/assets/nature-kit", "dung_cho": "Mỏm đá trên sườn đồi ở bản đồ Đồng quê"},
	{"ten": "Space Kit", "tac_gia": "Kenney (www.kenney.nl)", "giay_phep": "CC0 1.0",
		"link": "https://kenney.nl/assets/space-kit", "dung_cho": "Hangar, chảo radar, bệ tên lửa, phi thuyền chở hàng ở căn cứ"},
	{"ten": "Sci-Fi Shipping Crate", "tac_gia": "David W CG", "giay_phep": "CC BY 4.0 (bắt buộc ghi công)",
		"link": "https://opengameart.org/content/sci-fi-shipping-crate", "dung_cho": "Hòm tiếp tế (đã đổi tỉ lệ, đổi màu)"},
	{"ten": "Kloofendal 48d Partly Cloudy (Pure Sky)", "tac_gia": "Poly Haven", "giay_phep": "CC0 1.0",
		"link": "https://polyhaven.com/a/kloofendal_48d_partly_cloudy_puresky", "dung_cho": "Bầu trời (ngoại ô, đồng quê, bãi tập)"},
	{"ten": "Concrete Floor Worn 001", "tac_gia": "Poly Haven", "giay_phep": "CC0 1.0",
		"link": "https://polyhaven.com/a/concrete_floor_worn_001", "dung_cho": "Bê tông mặt đường, vỉa hè, quảng trường, tường đổ, cầu, sàn hangar ở menu"},
	{"ten": "Audio Studio MCP", "tac_gia": "KanaWorks_AI — 東京AI映像合同会社 (Tokyo AI Visuals LLC)", "giay_phep": "MIT",
		"link": "https://github.com/kanaworksai-hue/audio-studio-mcp", "dung_cho": "Công cụ tạo âm thanh: mọi tiếng động trong game được tạo bằng công cụ này, chạy trên máy người làm game"},
	{"ten": "Stable Audio 3 Medium", "tac_gia": "Stability AI", "giay_phep": "Stability AI Community License",
		"link": "https://huggingface.co/stabilityai/stable-audio-3-medium", "dung_cho": "Mô hình tạo âm thanh mà Audio Studio MCP dùng"},
]
