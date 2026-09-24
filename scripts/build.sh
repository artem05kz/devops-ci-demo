#!/bin/sh
# Сборка дистрибутива: подстановка сведений о сборке в шаблон и копирование ресурсов.
set -e

VERSION=$(cat VERSION)
BUILD="${BUILD_NUMBER:-local}"
DATE=$(date '+%d.%m.%Y %H:%M')
ENVIRONMENT="${DEPLOY_ENV:-staging}"
DIST="${BUILD_DIR:-dist}"

echo "Версия приложения: $VERSION"
echo "Номер сборки:      $BUILD"
echo "Каталог сборки:    $DIST"

rm -rf "$DIST"
mkdir -p "$DIST"

# Подстановка значений в шаблон страницы
sed -e "s/{{VERSION}}/$VERSION/g" \
    -e "s/{{BUILD_NUMBER}}/$BUILD/g" \
    -e "s/{{BUILD_DATE}}/$DATE/g" \
    -e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
    src/index.template.html > "$DIST/index.html"

cp src/styles.css "$DIST/styles.css"
cp src/app.js     "$DIST/app.js"

# Файл с метаданными сборки
cat > "$DIST/build-info.json" <<EOF
{
  "application": "devops-ci-demo",
  "version": "$VERSION",
  "build": "$BUILD",
  "date": "$DATE",
  "environment": "$ENVIRONMENT"
}
EOF

echo "Собрано файлов: $(ls -1 "$DIST" | wc -l)"
ls -l "$DIST"
echo "Сборка завершена успешно."
