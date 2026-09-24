#!/bin/sh
# Статический анализ исходных файлов перед упаковкой.
set -u

REPORTS="${REPORTS:-reports}"
mkdir -p "$REPORTS"

PROBLEMS=0

echo "Проверка исходного кода"

# Сам анализатор исключается из проверки: он содержит искомые образцы
# в виде аргументов grep и иначе находил бы сам себя.
SELF="scripts/analyze.sh"

# 1. Незавершённые участки кода
FOUND_MARKS=$(grep -RIn -e "TODO" -e "FIXME" src scripts 2>/dev/null | grep -v "^$SELF:")
MARKS=$(printf '%s' "$FOUND_MARKS" | grep -c . )
echo "  Незавершённых пометок TODO/FIXME: $MARKS"
if [ "$MARKS" -gt 0 ]; then
    printf '%s
' "$FOUND_MARKS"
    PROBLEMS=$((PROBLEMS + 1))
fi

# 2. Возможные секреты в коде
FOUND_SECRETS=$(grep -RIn -e "password" -e "secret" -e "api_key" src 2>/dev/null)
SECRETS=$(printf '%s' "$FOUND_SECRETS" | grep -c . )
echo "  Подозрительных строк с секретами: $SECRETS"
if [ "$SECRETS" -gt 0 ]; then
    printf '%s
' "$FOUND_SECRETS"
    PROBLEMS=$((PROBLEMS + 1))
fi

# 3. Обязательные файлы репозитория
for FILE in Jenkinsfile VERSION README.md src/index.template.html; do
    if [ -f "$FILE" ]; then
        echo "  Файл на месте: $FILE"
    else
        echo "  ОТСУТСТВУЕТ обязательный файл: $FILE"
        PROBLEMS=$((PROBLEMS + 1))
    fi
done

# 4. Сводка по объёму кода
LINES=$(find src scripts -type f 2>/dev/null | xargs wc -l 2>/dev/null | tail -n 1)
echo "  Объём исходного кода:$LINES"

{
    echo "Отчёт статического анализа"
    echo "Пометок TODO/FIXME: $MARKS"
    echo "Подозрительных строк: $SECRETS"
    echo "Обнаружено проблем: $PROBLEMS"
} > "$REPORTS/analyze.txt"

if [ "$PROBLEMS" -gt 0 ]; then
    echo "Статический анализ выявил проблемы: $PROBLEMS"
    exit 1
fi

echo "Статический анализ пройден без замечаний."
exit 0
