#!/bin/sh
# Проверка собранного дистрибутива. Формирует отчёт в формате JUnit XML.
set -u

DIST="${BUILD_DIR:-dist}"
REPORTS="${REPORTS:-reports}"
VERSION=$(cat VERSION)
BUILD="${BUILD_NUMBER:-local}"

mkdir -p "$REPORTS"

PASSED=0
FAILED=0
CASES=""

check() {
    NAME="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "  [ OK ]   $NAME"
        PASSED=$((PASSED + 1))
        CASES="$CASES
    <testcase classname=\"dist\" name=\"$NAME\"/>"
    else
        echo "  [ FAIL ] $NAME"
        FAILED=$((FAILED + 1))
        CASES="$CASES
    <testcase classname=\"dist\" name=\"$NAME\"><failure message=\"проверка не пройдена\"/></testcase>"
    fi
}

has_text() { grep -q "$2" "$1"; }

echo "Запуск проверок собранного дистрибутива"

check "Каталог сборки создан"            test -d "$DIST"
check "Создана страница index.html"      test -f "$DIST/index.html"
check "Скопированы стили"                test -f "$DIST/styles.css"
check "Скопирован сценарий"              test -f "$DIST/app.js"
check "Создан файл метаданных сборки"    test -f "$DIST/build-info.json"
check "В страницу подставлена версия"    has_text "$DIST/index.html" "$VERSION"
check "В страницу подставлен номер"      has_text "$DIST/index.html" "$BUILD"
check "В метаданных указана версия"      has_text "$DIST/build-info.json" "$VERSION"

# В собранном дистрибутиве не должно остаться неподставленных меток шаблона
if grep -q "{{" "$DIST/index.html" 2>/dev/null; then
    echo "  [ FAIL ] Не осталось неподставленных меток шаблона"
    FAILED=$((FAILED + 1))
    CASES="$CASES
    <testcase classname=\"dist\" name=\"Не осталось неподставленных меток шаблона\"><failure message=\"в index.html найдены метки вида {{...}}\"/></testcase>"
else
    echo "  [ OK ]   Не осталось неподставленных меток шаблона"
    PASSED=$((PASSED + 1))
    CASES="$CASES
    <testcase classname=\"dist\" name=\"Не осталось неподставленных меток шаблона\"/>"
fi

TOTAL=$((PASSED + FAILED))

cat > "$REPORTS/tests.xml" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="dist" tests="$TOTAL" failures="$FAILED">$CASES
</testsuite>
EOF

echo ""
echo "Всего проверок: $TOTAL, пройдено: $PASSED, не пройдено: $FAILED"
echo "Отчёт сохранён: $REPORTS/tests.xml"

if [ "$FAILED" -gt 0 ]; then
    echo "Тестирование завершено с ошибками."
    exit 1
fi

echo "Все проверки пройдены."
exit 0
