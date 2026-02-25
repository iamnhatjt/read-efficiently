<p align="center">
  <img src="screenshots/home.png" width="700" alt="VibeRead Dashboard" />
</p>

<h1 align="center">📖 VibeRead</h1>

<p align="center">
  <strong>Speed Read Everything.</strong><br/>
  A beautiful, cross-platform speed reading app built with Flutter
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Desktop%20%7C%20Web-orange" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License" />
  <img src="https://img.shields.io/badge/Version-1.0.0-blue" alt="Version" />
</p>

---

## ✨ What is VibeRead?

**VibeRead** is a premium speed reading application that uses **RSVP (Rapid Serial Visual Presentation)** to help you read 2–5x faster. It displays words one at a time at your chosen speed, leveraging the **Optimal Recognition Point (ORP)** technique to minimize eye movement and maximize comprehension.

Load PDFs, paste text, or fetch web articles — then speed read through them with a gorgeous, distraction-free interface. Your progress is automatically saved by content hash, so you never lose your place even if you rename or move files.

---

## 📸 Screenshots

### 🏠 Home Dashboard

The central hub with quick stats, action buttons, and recent documents.

<p align="center">
  <img src="screenshots/home.png" width="700" alt="Home Dashboard" />
</p>

### ⚙️ Settings — Interface & Font

Customize your reading experience with 9 premium fonts, adjustable font sizes, focus mode, and more.

<p align="center">
  <img src="screenshots/settings_interface.png" width="700" alt="Settings - Interface" />
</p>

### 🎨 12 Reading Color Themes

Choose your perfect reading environment from 12 hand-crafted color schemes.

<p align="center">
  <img src="screenshots/settings_themes.png" width="700" alt="Reading Themes" />
</p>

### 🚀 Reading Speed Controls

Fine-tune WPM (100–1200), words-at-a-time (1–5), and text-to-speech options.

<p align="center">
  <img src="screenshots/settings_reading.png" width="700" alt="Settings - Reading" />
</p>

### 📊 Statistics & Insights

Track your reading progress with weekly charts, streak tracking, and document-level progress.

<p align="center">
  <img src="screenshots/statistics.png" width="700" alt="Statistics Dashboard" />
</p>

---

## 🎯 Key Features

### 📖 RSVP Speed Reader

| Feature                | Description                                            |
| ---------------------- | ------------------------------------------------------ |
| **ORP Highlighting**   | The focal letter is highlighted for faster recognition |
| **Adjustable WPM**     | 100 – 1,200 words per minute                           |
| **Words at a Time**    | Display 1–5 words simultaneously                       |
| **Punctuation Pacing** | Automatic pauses at periods, commas, and brackets      |
| **Context Lines**      | Optional preview of surrounding words                  |
| **Keyboard Shortcuts** | Full keyboard control (Space, J/K/L, arrows, 1–5)      |

### 📄 PDF Reader

| Feature               | Description                                    |
| --------------------- | ---------------------------------------------- |
| **Drag & Drop**       | Drop PDF files directly into the app           |
| **Text Extraction**   | Automatic page-by-page text extraction         |
| **SHA-256 Hashing**   | Progress tracked by file content, not filename |
| **Resume Dialog**     | Smart resume prompt with progress preview      |
| **Thumbnail Sidebar** | Page navigation with text previews             |
| **Cross-platform**    | Works on desktop (file) and web (bytes)        |

### 🎨 Themes & Customization

| Theme                | Style                               |
| -------------------- | ----------------------------------- |
| 🌙 **Midnight**      | Pure black with orange accents      |
| 🌊 **Deep Ocean**    | Navy blue with cyan highlights      |
| 🌲 **Forest**        | Dark green with emerald accents     |
| 📜 **Warm Sepia**    | Brown tones for comfortable reading |
| 💜 **Purple Haze**   | Deep purple with violet highlights  |
| 🔴 **Crimson Night** | Dark red with crimson accents       |
| 🟡 **Amber Glow**    | Warm amber with golden highlights   |
| 🔘 **Slate**         | Blue-gray with silver accents       |
| 📄 **Paper White**   | Clean white with red accents        |
| 🍦 **Cream**         | Soft beige for easy reading         |
| 💻 **Terminal**      | Matrix-style green on black         |
| ❄️ **Nord**          | Arctic blue with cyan accents       |

### 📊 Statistics

- **Total Words Read** — lifetime counter
- **Reading Time** — cumulative with per-session averages
- **Streak Tracking** — current and longest streaks
- **Weekly Chart** — daily reading bar graph
- **Document Progress** — per-document completion tracking

### 💾 Data Management

- **Auto-save** — progress saved every 10 seconds
- **Export/Import** — JSON backup of all data
- **Content Hash** — rename/move files without losing progress
- **Clear All** — one-click data reset

---

## ⌨️ Keyboard Shortcuts

| Key           | Action                   |
| ------------- | ------------------------ |
| `Space` / `K` | ▶️ Play / ⏸️ Pause       |
| `J`           | ⏪ Seek back 10 words    |
| `L`           | ⏩ Seek forward 10 words |
| `←` / `→`     | Previous / Next word     |
| `↑` / `↓`     | Adjust WPM by ±25        |
| `1` – `5`     | Set words-at-a-time      |
| `H`           | Toggle UI visibility     |
| `Esc`         | Exit reader              |

---

## 🛠️ Tech Stack

| Layer                | Technology                 |
| -------------------- | -------------------------- |
| **Framework**        | Flutter 3.x                |
| **Language**         | Dart 3.x                   |
| **State Management** | Riverpod                   |
| **Navigation**       | go_router                  |
| **PDF Engine**       | pdfrx                      |
| **Storage**          | Hive                       |
| **Typography**       | Google Fonts               |
| **File Handling**    | file_picker + desktop_drop |
| **Window Control**   | window_manager (desktop)   |
| **Hashing**          | crypto (SHA-256)           |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- Dart SDK (included with Flutter)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/viberead.git
cd viberead

# Install dependencies
flutter pub get

# Run on desktop (Linux/macOS/Windows)
flutter run -d linux    # or macos / windows

# Run on web
flutter create --platforms=web .  # first time only
flutter run -d chrome
```

### Build for production

```bash
# Desktop
flutter build linux    # or macos / windows

# Web
flutter build web
```

---

## 📁 Project Structure

```
lib/
├── main.dart                           # App entry point
├── platform/
│   ├── desktop_window.dart             # Desktop window manager
│   └── web_window.dart                 # Web stub (no-op)
├── core/
│   ├── constants/app_constants.dart     # App-wide constants
│   ├── services/storage_service.dart    # Hive persistence layer
│   ├── theme/app_theme.dart             # Dark theme + 12 reading schemes
│   └── utils/app_utils.dart             # Text processing, ORP, hashing
├── models/
│   ├── app_settings.dart                # User preferences
│   ├── reading_progress.dart            # Progress persistence
│   └── reading_stats.dart               # Reading analytics
├── providers/
│   └── app_providers.dart               # Riverpod state management
├── widgets/
│   └── shared_widgets.dart              # GlassCard, GradientButton, etc.
└── features/
    ├── home/home_screen.dart            # Dashboard
    ├── reader/reader_screen.dart        # RSVP speed reader
    ├── pdf_reader/pdf_reader_screen.dart # PDF reader with resume
    ├── settings/settings_screen.dart    # 4-tab settings
    └── statistics/statistics_screen.dart # Analytics dashboard
```

---

## 🧠 How RSVP Works

**Rapid Serial Visual Presentation** displays words one at a time at a fixed point, eliminating the need for eye movement across lines. VibeRead enhances this with:

1. **ORP (Optimal Recognition Point)** — Each word has one letter your eye naturally fixates on. VibeRead highlights this letter in the accent color, allowing your brain to recognize words faster.

2. **Punctuation Pacing** — Sentences endings (`.` `!` `?`) get a 2× pause. Commas and semicolons get 1.5×. This mimics natural reading rhythm.

3. **Context Lines** — Optional display of surrounding words above and below the focal word, providing reading context without requiring eye movement.

```
         ↓ ORP (highlighted letter)
    accel e ration
          ↑
    Focal point for fastest recognition
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Made with ❤️ and Flutter<br/>
  <strong>Speed Read Everything.</strong>
</p>
