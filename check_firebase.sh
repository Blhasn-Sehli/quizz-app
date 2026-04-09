#!/bin/bash

# Firebase Connection Test Script

echo "=================================="
echo "🔍 Firebase Connection Diagnostic"
echo "=================================="
echo ""

# 1. Check Firebase packages
echo "1️⃣ Checking Firebase packages..."
flutter pub deps | grep firebase
echo ""

# 2. Check firebase_options.dart exists
echo "2️⃣ Checking Firebase config file..."
if [ -f lib/firebase_options.dart ]; then
    echo "✅ lib/firebase_options.dart exists"
    echo "   Config:"
    grep -E "apiKey|projectId|appId" lib/firebase_options.dart | head -3
else
    echo "❌ lib/firebase_options.dart NOT FOUND"
fi
echo ""

# 3. Run the app with verbose logging
echo "3️⃣ Running app with debug logging..."
echo "   Look for these messages in the console:"
echo "   ✅ 'Firebase initialized: true'"
echo "   ❌ 'Firebase not available, using mock mode'"
echo ""
echo "   Starting flutter run in 3 seconds..."
echo "   (Press 'r' for hot reload, 'q' to quit)"
sleep 3

flutter run
