#!/bin/bash

# Firebaseエミュレータを起動してシードデータを自動投入するスクリプト

echo "🔥 Starting Firebase Emulators..."

# エミュレータをバックグラウンドで起動
firebase emulators:start --only auth,functions,firestore &
EMULATOR_PID=$!

echo "⏳ Waiting for emulators to start..."

# エミュレータが起動するまで待機（最大30秒）
MAX_WAIT=30
WAIT_COUNT=0

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  # Firestoreエミュレータの起動確認
  if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Emulators are ready!"
    break
  fi

  sleep 1
  WAIT_COUNT=$((WAIT_COUNT + 1))
  echo -n "."
done

echo ""

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
  echo "❌ Emulators failed to start within ${MAX_WAIT} seconds"
  kill $EMULATOR_PID 2>/dev/null
  exit 1
fi

# シードデータを投入
echo "🌱 Seeding data..."
cd emulator-seed-data && node seed.js
SEED_RESULT=$?

if [ $SEED_RESULT -eq 0 ]; then
  echo "✅ Data seeding completed successfully!"
  echo ""
  echo "📱 Emulators are running. You can now run your app with:"
  echo "   flutter run"
  echo ""
  echo "🛑 To stop emulators, press Ctrl+C or run:"
  echo "   kill $EMULATOR_PID"

  # エミュレータをフォアグラウンドに戻す
  wait $EMULATOR_PID
else
  echo "❌ Data seeding failed"
  kill $EMULATOR_PID 2>/dev/null
  exit 1
fi
