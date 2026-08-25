# 🌐 WebBar - macOS Menu Bar Web & AI Browser

> **WebBar** là ứng dụng trình duyệt native siêu nhẹ dành riêng cho thanh **Menu Bar** của macOS, lấy cảm hứng và cải tiến từ phong cách của **MenuBarX**. Thiết kế tối giản, hỗ trợ đa tab, AI Launcher, ghim cửa sổ (Pin on Top) và chuyển đổi linh hoạt giữa các chế độ kích thước Mobile / Desktop.

---

## ✨ Tính Năng Nổi Bật

- 🚀 **Siêu nhẹ & Native macOS**: Xây dựng hoàn toàn bằng **Swift 6, SwiftUI, AppKit và WebKit**. Dung lượng binary chỉ **~1.2 MB**, khởi động tức thì và tiêu tốn cực ít RAM/CPU.
- 🎵 **Hỗ Trợ TikTok & Media Tối Ưu**: Tích hợp sẵn TikTok với chế độ hiển thị video dọc mượt mà.
- ⏸️ **Tự Động Dừng Video/Nhạc Khi Ẩn Cửa Sổ (Smart Auto-Pause)**: Khi bạn click ra ngoài hoặc ẩn cửa sổ `WebBar`, tất cả video clip trên TikTok, YouTube, Facebook... sẽ **tự động tạm dừng (pause) ngay lập tức**, không bị phát âm thanh ngầm gây phiền toái.
- 📱 **Chuyển Đổi Kích Thước Theo Thiết Bị (Device Viewport)**: Chuyển đổi nhanh giao diện và User-Agent giữa **iPhone SE (375x667), iPhone 16 Pro (393x800), iPad Mini (744x850), Desktop Compact (800x600), Desktop Wide (1050x720) hoặc Custom Size** trực tiếp từ Menu Bar hoặc Settings!
- ⚡ **Thanh Tìm Kiếm Nhỏ Gọn (Compact Spotlight Search Bar - 68px)**: Khi ở màn hình New Tab hoặc tìm kiếm, cửa sổ tự động thu gọn thành một thanh Spotlight nhỏ gọn (`440x68px`) nằm ngay sát dưới Menu Bar.
- 🚀 **Tự Động Mở Rộng Kích Thước Tiêu Chuẩn Khi Tìm Xong**: Ngay khi bạn nhập link web / tìm kiếm và nhấn `Return ↵`, cửa sổ sẽ **tự động bung mượt mà (smooth animation)** về kích thước tiêu chuẩn để hiển thị trọn vẹn trang web tràn viền!
- 🚀 **Khởi Động Cùng macOS (Launch at Login)**: Tùy chọn tự động chạy nền và xuất hiện sẵn trên Menu Bar ngay khi bật máy hoặc restart Mac.
- 🔔 **Nhận Thông Báo Từ Website (Web Push Notifications)**: Tích hợp cầu nối HTML5 Notification với Trung tâm thông báo macOS (`UserNotifications`). Nhận thông báo tin nhắn mới từ Zalo, Facebook Messenger, YouTube... kèm âm thanh và click mở ngay tab liên quan!
- 🎯 **Multi-Icon Trên Menu Bar (MenuBarX Style)**: Mỗi Tab mở ra sẽ tạo **một icon độc lập riêng biệt trực tiếp trên Menu Bar**. Bạn có thể ghim đồng thời Messenger, ChatGPT, YouTube, Zalo... cạnh nhau trên thanh trạng thái macOS!
- 🎨 **Tự Động Chuyển Favicon Sang Dạng Monochrome (Template)**: Tự động trích xuất logo/favicon của website hiện tại và chuyển thành ảnh đơn sắc (Monochrome Template) hòa hợp hoàn hảo với Dark/Light theme của macOS.
- 🤖 **AI Hub & Quick Apps**: Tích hợp sẵn launcher cho các mô hình AI và công cụ hàng đầu:
  - *Chat & Messaging*: **Zalo Web (`chat.zalo.me`), Messenger, Telegram Web, X (Twitter), Reddit**.
  - *AI Assistants*: **ChatGPT, Claude, Google Gemini, Perplexity, DeepSeek**.
  - *Dev & Productivity*: **Google Translate, GitHub, Notion, Google Calendar**.
  - *Social & Media*: **X (Twitter), YouTube, Reddit, Telegram Web**.
  - *Search & Knowledge*: **Google Search, Wikipedia, Hacker News**.
- 📱 **Chuyển Đổi Viewport Linh Hoạt**:
  - `iPhone SE` (375 × 667)
  - `iPhone 16 Pro` (393 × 800)
  - `iPad Mini` (744 × 850)
  - `Desktop Compact` (800 × 600)
  - `Desktop Wide` (1050 × 720)
  - `Custom`: Tự do co giãn kích thước theo ý muốn.
  - *Tự động cập nhật User-Agent tương ứng cho từng chế độ để website hiển thị chuẩn xác nhất.*
- 📌 **Pin on Top & Detach Window**:
  - Ghim cửa sổ luôn nổi trên cùng màn hình khi làm việc.
  - Tách rời khỏi Menu Bar thành một cửa sổ nổi độc lập di chuyển tự do.
- 🪟 **Điều Chỉnh Độ Trong Suốt (Opacity)**:
  - Thanh trượt điều chỉnh từ 20% đến 100% giúp vừa lướt web vừa theo dõi nội dung phía dưới.
- 📑 **Đa Tab Độc Lập**:
  - Mở nhiều tab cùng lúc, dễ dàng chuyển đổi hoặc đóng tab.
- 🛡️ **Tối Ưu & Chặn Quảng Cáo**:
  - Tích hợp AdBlock và Banner Cleaner tự động.
  - Tùy chọn ép buộc **Dark Mode** cho các trang web chưa có giao diện tối.
  - Hỗ trợ chu kỳ **Auto-Refresh** tự động làm mới trang (10s, 30s, 1m, 5m).

---

## ⌨️ Phím Tắt Tiện Lợi (Shortcuts)

| Phím Tắt | Chức Năng |
|---|---|
| `⌥ ⌘ B` | **Toggle mở/ẩn nhanh cửa sổ WebBar** (Toàn cục) |
| `⌘ +` / `⌘ =` | **Phóng to trang web (Zoom In +10%)** |
| `⌘ -` | **Thu nhỏ trang web (Zoom Out -10%)** |
| `⌘ 0` | **Đặt lại kích thước trang gốc 100% (Reset Zoom)** |
| `⌘ \` hoặc `⇧ ⌘ H` | **Bật/Tắt chế độ Zen Mode (Ẩn toàn bộ thanh tìm kiếm & tab)** |
| `⌘ T` | Mở Tab mới |
| `⌘ W` | Đóng Tab hiện tại |
| `⌘ R` | Tải lại trang (Reload) |
| `⌘ L` | Focus con trỏ vào thanh địa chỉ URL |
| `⇧ ⌘ P` | Ghim cửa sổ luôn nổi trên cùng (Pin on Top) |
| `⌘ 1` - `⌘ 9` | Chuyển nhanh qua Tab số 1 đến 9 |
| `⌘ [` / `⌘ ]` | Quay lại (Back) / Tiến tới (Forward) |

---

## 🛠️ Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Khởi chạy ứng dụng ngay lập tức:
```bash
open WebBar.app
```

### 2. Biên dịch lại từ mã nguồn (Build & Package):
```bash
./build.sh --run
```

Hoặc dùng Swift Package Manager để debug:
```bash
swift run
```

---

## 📁 Cấu Trúc Dự Án

```
MyMemuApp/
├── Package.swift               # Định nghĩa SPM Package
├── build.sh                    # Script tự động build & tạo file WebBar.app
├── Resources/
│   └── Info.plist              # Cấu hình macOS App (LSUIElement = true)
├── Sources/
│   └── WebBar/
│       ├── Main.swift          # Entry point (NSApplicationDelegate)
│       ├── AppState.swift      # Quản lý State toàn cục (Tabs, Viewports, Settings)
│       ├── Models/
│       │   ├── ViewportPreset.swift # Kích thước màn hình & User-Agent
│       │   ├── QuickApp.swift  # Danh mục AI Hub & Quick Apps
│       │   └── TabItem.swift   # Cấu trúc dữ liệu Tab
│       ├── Services/
│       │   ├── AdBlockManager.swift # CSS & Script injection
│       │   └── HotkeyManager.swift  # Xử lý phím tắt toàn cục & nội bộ
│       ├── Views/
│       │   ├── ContentView.swift    # Giao diện chính bọc kính mờ
│       │   ├── NavigationBarView.swift # Thanh điều khiển & Omnibox
│       │   ├── TabBarView.swift     # Quản lý đa tab
│       │   ├── QuickAppsGrid.swift  # Màn hình AI Launcher & Apps Grid
│       │   ├── SettingsView.swift   # Drawer cài đặt
│       │   └── WebKitView.swift     # WKWebView Native Representable
│       └── Window/
│           ├── FloatingPanel.swift  # NSPanel tuỳ biến bo tròn & nổi
│           └── MenuBarController.swift # Quản lý icon trên macOS Menu Bar
```
