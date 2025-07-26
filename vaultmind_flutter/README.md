# VaultMind - Privacy-Focused AI Assistant

VaultMind is a cross-platform Flutter application that provides a privacy-focused AI assistant experience by connecting to a laptop-hosted Ollama LLM via Tailscale. The app ensures your conversations remain private while offering a seamless AI interaction experience.

## Features

### 🔒 Privacy-First Design
- **Local AI Processing**: Connects to your own Ollama server via Tailscale
- **No Data Collection**: All conversations stay on your devices
- **Offline-First**: Graceful degradation when connection is unavailable
- **End-to-End Privacy**: Direct connection to your AI server

### 🤖 AI Capabilities
- **Multiple Model Support**: Work with any Ollama-compatible model
- **Conversation Management**: Organize and manage chat history
- **Context Awareness**: Maintains conversation context across messages
- **Real-time Responses**: Streaming responses from your AI model

### 🎙️ Voice Integration
- **Speech-to-Text**: Voice input using device speech recognition
- **Cross-Platform**: Works on both Android and iOS
- **Multiple Languages**: Support for 10+ languages
- **Permission Management**: Handles microphone permissions gracefully

### 🎨 Modern UI/UX
- **Material Design 3**: Latest Material Design components
- **Cross-Platform**: Consistent experience on Android and iOS
- **Dark/Light Mode**: Theme preferences (coming soon)
- **Responsive Design**: Adapts to different screen sizes

### ⚙️ Advanced Configuration
- **Flexible Connection**: Configure your Ollama server URL
- **Model Parameters**: Adjust temperature, top_p, and top_k
- **Network Resilience**: Automatic retry logic with exponential backoff
- **Comprehensive Logging**: Detailed logging for troubleshooting

## Architecture

VaultMind follows clean architecture principles with dependency injection:

```
lib/
├── main.dart                 # App entry point
├── ui/                      # User Interface Layer
│   ├── app.dart            # Main app widget with theme & navigation
│   ├── screens/            # Application screens
│   │   ├── splash_screen.dart
│   │   ├── chat_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/            # Reusable UI components
│       ├── chat_message_widget.dart
│       ├── chat_input_widget.dart
│       └── connection_status_widget.dart
├── services/               # Business Logic Layer
│   ├── dependency_injection.dart
│   ├── chat_service.dart
│   ├── llm_service.dart
│   ├── speech_service.dart
│   ├── settings_service.dart
│   ├── storage_service.dart
│   ├── http_service.dart
│   ├── connectivity_service.dart
│   └── logging_service.dart
├── models/                 # Data Models
│   └── llm_models.dart
└── utils/                  # Utilities & Helpers
    ├── constants.dart
    └── helpers.dart
```

## Getting Started

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.13.0 or higher
2. **Ollama Server**: Set up Ollama on your laptop/server
3. **Tailscale**: Configure Tailscale for secure networking (optional but recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vaultmind_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure permissions** (Already included in the project)
   - Android: Microphone and internet permissions in `AndroidManifest.xml`
   - iOS: Microphone and speech recognition permissions in `Info.plist`

4. **Run the app**
   ```bash
   flutter run
   ```

### Ollama Server Setup

1. **Install Ollama** on your laptop/server:
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ```

2. **Pull a model** (e.g., Llama 2):
   ```bash
   ollama pull llama2
   ```

3. **Start the server**:
   ```bash
   ollama serve
   ```

4. **Configure VaultMind** to connect to your Ollama server:
   - Open VaultMind Settings
   - Enter your Ollama server URL (e.g., `http://192.168.1.100:11434`)
   - Test the connection
   - Select your preferred model

### Tailscale Setup (Recommended)

1. **Install Tailscale** on both your server and mobile device
2. **Connect both devices** to your Tailscale network
3. **Use Tailscale IP** in VaultMind settings (e.g., `http://100.64.0.1:11434`)

This ensures secure, encrypted communication between your devices.

## Configuration

### LLM Parameters

Adjust these in Settings to fine-tune AI responses:

- **Temperature** (0.0-2.0): Controls creativity vs. consistency
- **Top P** (0.0-1.0): Nucleus sampling for diversity
- **Top K** (1-100): Limits vocabulary choices

### Speech Recognition

Supported languages:
- English (US/UK)
- Spanish, French, German, Italian
- Portuguese (Brazil)
- Japanese, Korean, Chinese (Simplified)

## Troubleshooting

### Connection Issues

1. **Check Ollama server**: Ensure it's running and accessible
2. **Verify URL**: Test connection in VaultMind settings
3. **Network connectivity**: Check WiFi/mobile data
4. **Firewall**: Ensure port 11434 is open

### Speech Recognition Issues

1. **Permissions**: Grant microphone access in device settings
2. **Language support**: Ensure your language is supported
3. **Network**: Some speech features require internet

### Performance Issues

1. **Model size**: Larger models require more resources
2. **Device specs**: Ensure adequate RAM and processing power
3. **Network speed**: Slow connections affect response times

## Privacy & Security

VaultMind is designed with privacy as the top priority:

- **No telemetry**: No usage data is collected or transmitted
- **Local storage**: All data stored locally on your device
- **Direct connection**: No intermediary servers
- **Open source**: Full transparency of functionality

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Dependencies

### Core Dependencies
- `flutter`: Cross-platform UI framework
- `provider`: State management
- `get_it`: Dependency injection
- `go_router`: Navigation

### Network & Communication
- `http`: HTTP client
- `dio`: Advanced HTTP client with interceptors
- `connectivity_plus`: Network connectivity monitoring

### Speech & Audio
- `speech_to_text`: Speech recognition
- `permission_handler`: Runtime permissions

### Storage & Data
- `hive`: Local database
- `shared_preferences`: Simple key-value storage
- `path_provider`: File system paths

### UI & Design
- `google_fonts`: Custom fonts
- `flutter_svg`: SVG support

### Utilities
- `uuid`: Unique identifier generation
- `intl`: Internationalization
- `logger`: Structured logging

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Open an issue on GitHub
- Check the troubleshooting section
- Review Ollama documentation for server-side issues

## Roadmap

- [ ] **Message Export**: Export conversations to various formats
- [ ] **Custom Themes**: Dark mode and custom color schemes
- [ ] **Model Management**: Download and manage models within the app
- [ ] **Conversation Search**: Search through chat history
- [ ] **Backup & Sync**: Secure backup options
- [ ] **Plugin System**: Extensible functionality
- [ ] **Advanced Voice**: Text-to-speech for AI responses
- [ ] **Multi-Language UI**: Localized interface

---

**VaultMind** - Your privacy, your AI, your way. 🔒🤖