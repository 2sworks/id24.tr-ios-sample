#!/bin/sh

# Check if Homebrew needs update and update it
#echo "🔄 Updating Homebrew..."
#brew update

# Check if CocoaPods is installed
#if brew list cocoapods &>/dev/null; then
#    echo "🔄 Updating CocoaPods..."
#    brew upgrade cocoapods
#else
#    echo "📦 Installing CocoaPods..."
#    brew install cocoapods
#fi

# Clean CocoaPods cache
#echo "🧹 Cleaning CocoaPods cache..."
#pod cache clean --all

# Deployment target'ı ayarla
#echo "🎯 Setting deployment target to iOS 14.0..."
#xcrun xcodebuild -project NewTest.xcodeproj -scheme NewTest - Development -configuration Release IPHONEOS_DEPLOYMENT_TARGET=14.0

# Install dependencies
#echo "📦 Installing Pod dependencies..."
#pod install
