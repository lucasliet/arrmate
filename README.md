# Arrmate: A Companion App for Radarr and Sonarr 📺
Arrmate is a comprehensive companion app designed to work seamlessly with Radarr and Sonarr, offering a streamlined and user-friendly experience for managing your media library. With Arrmate, you can easily browse, search, and manage your movies and series, all in one convenient place. The app is built using Flutter and utilizes the Riverpod state management library to ensure a smooth and efficient user experience.

## 🚀 Features
* **Library Management**: Browse, search, filter, and manage your movie and series libraries with a native mobile experience.
* **Interactive Release Search**: Find and download specific torrents or NZBs directly from the app.
* **Activity & Queue Monitoring**: Track active downloads and historical events like grabs, imports, and failures.
* **Notifications**: Stay updated with local push notifications powered by periodic background polling.
* **Multi-Instance Support**: Manage multiple Radarr and Sonarr server instances simultaneously.
* **Advanced Monitoring**: View real-time system logs, health checks, and quality profiles.
* **Auto-Updater**: Support for automatic and manual in-app updates via GitHub Releases.

## 🛠️ Tech Stack
* **Flutter**: Framework used to build the seamless and efficient native mobile experience.
* **Riverpod**: Utilized for robust and efficient state management throughout the application.
* **Dio**: Used for making high-performance HTTP requests to Radarr and Sonarr APIs.
* **SharedPreferences**: Employs local persistence for settings, filters, and notification state.
* **Workmanager**: Native background task scheduling for periodic activity polling.
* **Flutter Local Notifications**: Handles local push notifications for download and system events.
* **Go Router**: Utilizes a declarative routing system for smooth navigation between features.
* **Package Info Plus & OTA Update**: Powering the automated in-app update system.

## 📦 Installation
To get started with Arrmate, follow these steps:
Download the latest release from the [releases page](https://github.com/lucasliet/arrmate/releases).

## 💻 Usage
To use Arrmate, follow these steps:
1. **Configure Connections**: Enter your Radarr and Sonarr API keys and server URLs in the settings to sync your media library.
2. **Explore Media**: Browse through your movies and series with posters, metadata, and status indicators.
3. **Search & Filter**: Use the search functionality to find specific titles or filter content by availability and quality.
4. **Remote Management**: Update monitoring status, trigger searches, and manage your library settings directly from the app.

## 📂 Project Structure
```markdown
arrmate/
|-- lib/
|    |-- app.dart
|    |-- main.dart
|    |-- data/
|    |    |-- api/
|    |    |-- repositories/
|    |-- core/
|    |    |-- network/
|    |    |-- utils/
|    |-- domain/
|    |    |-- repositories/
|    |-- presentation/
|    |    |-- router/
|    |    |-- screens/
|-- pubspec.yaml
```

## 🤝 Contributing
To contribute to Arrmate, please follow these steps:
1. **Fork the Repository**: Fork the Arrmate repository using Git.
2. **Create a Branch**: Create a new branch for your feature or bug fix.
3. **Make Changes**: Make the necessary changes to the code.
4. **Submit a Pull Request**: Submit a pull request to the main repository.

## 📝 License
Arrmate is licensed under the [MIT License](./LICENSE).