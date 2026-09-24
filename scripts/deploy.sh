#!/bin/sh
# Имитация развёртывания собранного дистрибутива в указанное окружение.
set -e

ENVIRONMENT="${1:-staging}"
DIST="${BUILD_DIR:-dist}"
TARGET="deploy/$ENVIRONMENT"
BUILD="${BUILD_NUMBER:-local}"
VERSION=$(cat VERSION)

echo "Окружение развёртывания: $ENVIRONMENT"

if [ ! -d "$DIST" ]; then
    echo "ОШИБКА: каталог сборки '$DIST' не найден. Развёртывание невозможно."
    exit 1
fi

echo "Подготовка целевого каталога: $TARGET"
rm -rf "$TARGET"
mkdir -p "$TARGET"

echo "Копирование файлов дистрибутива"
cp -r "$DIST"/. "$TARGET"/

echo "$(date '+%d.%m.%Y %H:%M') версия $VERSION сборка $BUILD развёрнута в $ENVIRONMENT" >> "$TARGET/deploy.log"

# Проверка после развёртывания: файлы на месте и содержат нужную версию
echo "Проверка развёрнутого приложения"
if [ ! -f "$TARGET/index.html" ]; then
    echo "ОШИБКА: после развёртывания отсутствует index.html"
    exit 1
fi

if ! grep -q "$VERSION" "$TARGET/index.html"; then
    echo "ОШИБКА: в развёрнутой странице не найдена версия $VERSION"
    exit 1
fi

echo "Развёрнуто файлов: $(ls -1 "$TARGET" | wc -l)"
echo "Развёртывание в окружение '$ENVIRONMENT' выполнено успешно."
