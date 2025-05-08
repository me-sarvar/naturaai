# NaturaAI

**NaturaAI** is a relaxing soundscape generator built with Flutter. It allows users to mix natural ambient sounds like rain, fire, birds, and wind. Ideal for focus, sleep, and mindfulness.

![Flutter](https://img.shields.io/badge/Flutter-3.29.3-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.7-blue?logo=dart)
[![CI](https://github.com/me-sarvar/naturaai/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/me-sarvar/naturaai/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](.github/CONTRIBUTING.md)

---

## Features

- Toggle multiple ambient sounds with individual volume sliders
- Animated backgrounds that match the selected sound
- Light and dark theme switcher
- Email/password authentication (Firebase)
- Localization support (English, Korean, etc.)
- Shared Preferences for saving state
- Modern and minimal UI using Riverpod and GoRouter


## Getting Started

### Prerequisites

- Flutter 3.29+
- Dart 3.7+
- Firebase project (Web/iOS/Android)
- `flutterfire configure` for Firebase setup

### Installation

```bash
git clone https://github.com/me-sarvar/naturaai.git
cd naturaai
flutter pub get
flutter run
```

---

## Folder Structure

```
lib/
├── core/             # Theme, constants, firebase config
├── features/         # App features: auth, home, splash
├── router/           # GoRouter configuration
├── shared/           # Reusable providers and widgets
└── main.dart
```

---

## Development

Run tests:

```bash
flutter test
```

Format code:

```bash
flutter format .
```

---

## Contributing

We welcome contributions! See [CONTRIBUTING.md](.github/CONTRIBUTING.md)

---

## Security

To report a vulnerability, please see [SECURITY.md](.github/SECURITY.md)

---

## License

This project is licensed under the MIT License â see the [LICENSE](LICENSE) file for details.




