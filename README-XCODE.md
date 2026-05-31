# Как собрать ZametkiGraph в Xcode (МакБук + айфон)

## 0. Получить проект на МакБук (через Git — как с Composer's Notebook)
Первый раз — клонировать:
```
git clone https://github.com/rusvtiem/ZametkiGraph.git ~/Desktop/ZametkiGraph && cd ~/Desktop/ZametkiGraph && xcodegen generate
```
Дальше при любом обновлении:
```
cd ~/Desktop/ZametkiGraph && git pull && xcodegen generate
```
`.xcodeproj` не лежит в репозитории — его создаёт `xcodegen generate` (как раньше).

## 1. Mac-версия (на МакБуке)
1. Открой `ZametkiGraph.xcodeproj` (двойной клик).
2. Вверху рядом с ▶︎ выбери схему **ZametkiGraph-macOS**.
3. Нажми ▶︎ (⌘R). Приложение запустится, само создаст папку с заметками.

> Intel-МакБук тянет это без проблем — обычное SwiftUI-приложение, не игра.
> Если Xcode закешировал старое: `rm -rf ZametkiGraph.xcodeproj && xcodegen generate`
> → в Xcode ⌘⇧K (Clean) → ⌘R.

## 2. iPhone-версия (на твоём айфоне)
1. Схему вверху смени на **ZametkiGraph-iOS**.
2. Открой слева синий значок проекта → таргет **ZametkiGraph-iOS** →
   вкладка **Signing & Capabilities**.
3. В **Team** выбери свой Apple ID (если нет — «Add an Account…», входишь Apple ID;
   бесплатного хватает, чтобы поставить на свой телефон).
4. Подключи айфон кабелем, разреши «Доверять» на телефоне.
5. Вверху выбери свой айфон как устройство → ▶︎ (⌘R).
6. Первый запуск: на айфоне зайди **Настройки → Основные → VPN и управление устройством**
   → выбери свой профиль разработчика → «Доверять». После этого приложение откроется.

> Бесплатная подпись живёт 7 дней — потом пересобрать тем же ⌘R. Это норма для теста.

## Что внутри
- `Sources/Shared/` — весь код (общий для Mac и iPhone).
- `project.yml` — конфиг проекта (из него xcodegen генерит `.xcodeproj`).
- `BUILD-STATUS.md` — что готово и как собиралось у Уолтера.
