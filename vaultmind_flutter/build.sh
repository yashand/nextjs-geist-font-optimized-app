#!/bin/bash

# VaultMind Build Script
# This script helps build the VaultMind Flutter app for different platforms

set -e

echo "🚀 VaultMind Build Script"
echo "========================="

# Function to display usage
usage() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  android     Build for Android (APK)"
    echo "  ios         Build for iOS (requires macOS and Xcode)"
    echo "  web         Build for Web"
    echo "  deps        Install dependencies"
    echo "  clean       Clean build artifacts"
    echo "  test        Run tests"
    echo "  help        Show this help message"
    exit 1
}

# Function to check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter is not installed or not in PATH"
        echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    
    echo "✅ Flutter found: $(flutter --version | head -n 1)"
}

# Function to install dependencies
install_deps() {
    echo "📦 Installing dependencies..."
    flutter pub get
    echo "✅ Dependencies installed"
}

# Function to clean build artifacts
clean_build() {
    echo "🧹 Cleaning build artifacts..."
    flutter clean
    echo "✅ Build artifacts cleaned"
}

# Function to run tests
run_tests() {
    echo "🧪 Running tests..."
    flutter test
    echo "✅ Tests completed"
}

# Function to build for Android
build_android() {
    echo "🤖 Building for Android..."
    
    # Check if Android SDK is available
    if ! flutter doctor | grep -q "Android toolchain"; then
        echo "❌ Android toolchain not found"
        echo "Please set up Android development environment"
        exit 1
    fi
    
    echo "Building APK..."
    flutter build apk --release
    
    echo "✅ Android APK built successfully!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
}

# Function to build for iOS
build_ios() {
    echo "🍎 Building for iOS..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "❌ iOS builds require macOS"
        exit 1
    fi
    
    # Check if Xcode is available
    if ! command -v xcodebuild &> /dev/null; then
        echo "❌ Xcode not found"
        echo "Please install Xcode from the App Store"
        exit 1
    fi
    
    echo "Building iOS app..."
    flutter build ios --release
    
    echo "✅ iOS app built successfully!"
    echo "📱 Open ios/Runner.xcworkspace in Xcode to create IPA"
}

# Function to build for Web
build_web() {
    echo "🌐 Building for Web..."
    
    flutter build web --release
    
    echo "✅ Web app built successfully!"
    echo "🌐 Web files location: build/web/"
    echo "💡 Serve with: python -m http.server 8000 -d build/web"
}

# Main script logic
case "${1:-help}" in
    android)
        check_flutter
        install_deps
        build_android
        ;;
    ios)
        check_flutter
        install_deps
        build_ios
        ;;
    web)
        check_flutter
        install_deps
        build_web
        ;;
    deps)
        check_flutter
        install_deps
        ;;
    clean)
        check_flutter
        clean_build
        ;;
    test)
        check_flutter
        install_deps
        run_tests
        ;;
    help|*)
        usage
        ;;
esac

echo ""
echo "🎉 VaultMind build process completed!"
echo "📖 For more information, see README.md"