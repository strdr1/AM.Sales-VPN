cmake_minimum_required(VERSION 3.21)

# ── Название проекта и версия ───────────────────────────────────────────
project(AmSalesVPN VERSION 0.1 LANGUAGES CXX)

# Используем C++17 (современный, но не требует свежайшего компилятора)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt автоматически генерирует часть кода (moc/rcc) — включаем это
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Ищем Qt6 (нужны модули Quick для QML-интерфейса) ────────────────────
# Если Qt6 не найдётся, CMake выдаст понятную ошибку — см. README.
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Network Concurrent QuickControls2 Widgets)

qt_standard_project_setup(REQUIRES 6.5)

# ── Собираем исполняемый файл ───────────────────────────────────────────
qt_add_executable(AmSalesVPN
    app.rc          # иконка .exe (Windows)
    src/main.cpp
    src/ZapretController.h
    src/ZapretController.cpp
    src/NetworkScanner.h
    src/NetworkScanner.cpp
    src/VlessController.h
    src/VlessController.cpp
    src/Store.h
    src/Store.cpp
    src/StatsTracker.h
    src/StatsTracker.cpp
    src/TgController.h
    src/TgController.cpp
    src/DiagController.h
    src/DiagController.cpp
    src/UpdateChecker.h
    src/UpdateChecker.cpp
    src/LogController.h
    src/LogController.cpp
)

# ── Подключаем QML-модуль (наш интерфейс) ───────────────────────────────
qt_add_qml_module(AmSalesVPN
    URI AmSalesVPN
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/StarField.qml
        qml/GlowButton.qml
        qml/GlassPanel.qml
    RESOURCES
        assets/AmSalesLogo.png
        assets/AmSalesLogoLight.png
        assets/tray.png
        assets/appicon.png
        assets/fonts/Manrope-Regular.ttf
)

# ── На Windows: не показывать чёрное консольное окно ─────────────────────
set_target_properties(AmSalesVPN PROPERTIES
    WIN32_EXECUTABLE TRUE
)

# ── Запрос прав администратора при запуске ──────────────────────────────
# Просим линкер встроить UAC-уровень requireAdministrator напрямую (без
# отдельного файла-манифеста, чтобы не конфликтовать с манифестом Qt).
# UAC спросит один раз при старте; winws и sing-box унаследуют права.
if(MSVC)
    target_link_options(AmSalesVPN PRIVATE
        "/MANIFESTUAC:level='requireAdministrator' uiAccess='false'")
endif()

# ── Линкуем нужные библиотеки Qt ────────────────────────────────────────
target_link_libraries(AmSalesVPN PRIVATE
    Qt6::Quick
    Qt6::Network
    Qt6::Concurrent
    Qt6::QuickControls2
    Qt6::Widgets
)

# ── Копируем встроенный движок (winws + WinDivert + lists + профили) ────
# рядом с собранным .exe, в подпапку engine/. Приложение запускает его оттуда.
add_custom_command(TARGET AmSalesVPN POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_SOURCE_DIR}/engine"
        "$<TARGET_FILE_DIR:AmSalesVPN>/engine"
    COMMENT "Copying bundled zapret engine next to the executable"
)
