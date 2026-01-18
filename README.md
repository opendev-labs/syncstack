# GH Sync Desktop - Flutter Edition

<div align="center">

![Version](https://img.shields.io/badge/version-2.0.0-00FF41?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-000000?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)

**Enterprise GitHub Desktop Client**

Converted from Electron to Flutter with a modern Anti-Gravity IDE aesthetic.

</div>

## ✨ Features

- 🔐 **Secure Authentication** - GitHub Personal Access Token integration
- 📦 **Repository Management** - View, clone, and sync your repositories
- 🔄 **Intelligent Sync** - Python-powered Git operations with conflict detection
- 🎨 **Premium UI** - Black & Green Anti-Gravity theme with glassmorphism
- ⚡ **Smooth Animations** - Micro-interactions and fluid transitions
- 🖥️ **Cross-Platform** - Linux, macOS, and Windows support

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.0.0 or higher)
- **Python 3** (for Git operations)
- **Git** (command-line tool)

### Installation

1. **Clone this repository**
   ```bash
   cd /home/cube/Gh-sync/opendev-labs/gh-sync-flutter
   ```

2. **Install Python dependencies**
   ```bash
   pip install requests
   ```

3. **Get Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the application**
   ```bash
   # For Linux
   flutter run -d linux
   
   # For macOS
   flutter run -d macos
   
   # For Windows
   flutter run -d windows
   ```

## 🎨 Design Philosophy

This application follows the **Anti-Gravity IDE** aesthetic:

- **Pure Black Background** (#000000) for maximum contrast
- **Neon Green Accents** (#00FF41) for visual hierarchy
- **Glassmorphism** for modern, premium feel
- **Space Grotesk & Inter** fonts for professional typography
- **Micro-animations** for enhanced user experience

## 🛠️ Architecture

```
lib/
├── main.dart              # App entry point
├── theme/
│   └── app_theme.dart     # Anti-Gravity theme & glassmorphism
├── providers/
│   └── auth_provider.dart # Authentication state management
├── services/
│   └── gh_service.dart    # Python bridge for Git operations
└── screens/
    ├── login_screen.dart      # Authentication UI
    └── dashboard_screen.dart  # Main repository view

assets/
└── scripts/
    └── gh_engine.py       # Python Git automation engine
```

## 🔧 Python Engine

The app uses a Python backend (`gh_engine.py`) for Git operations:

- **Repository cloning** via authenticated URLs
- **Intelligent sync** with conflict detection
- **Branch management** and safety snapshots
- **Status introspection** for repository health

## 📝 Usage

1. **Launch the app** and enter your GitHub credentials
   - Username: Your GitHub handle
   - Token: Personal Access Token with `repo` scope

2. **Browse repositories** in the main dashboard

3. **Sync repositories** by clicking the sync icon on any repo card

## 🎯 Key Differences from Electron Version

| Feature | Electron | Flutter |
|---------|----------|---------|
| **Framework** | React + Vite | Flutter |
| **Bundle Size** | ~200MB | ~50MB |
| **Startup Time** | 2-3s | <1s |
| **UI Theme** | Basic dark | Anti-Gravity aesthetic |
| **Animations** | CSS | Flutter Animate |
| **Python Integration** | IPC | Process.run |

## 🤝 Contributing

This is a personal project for enterprise use. Feel free to fork and customize for your needs.

## 📄 License

MIT License - See LICENSE file for details

## 🙏 Credits

- Original Electron app architecture
- Anti-Gravity IDE design inspiration
- Flutter community for excellent documentation

---

<div align="center">

**Built with ❤️ using Flutter**

`v2.0.0 // ENTERPRISE EDITION`

</div>
