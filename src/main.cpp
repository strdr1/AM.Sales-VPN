// ─────────────────────────────────────────────────────────────────────────
//  main.cpp — точка входа приложения AM.SALES VPN (прототип).
//
//  Здесь мы:
//    1. Создаём приложение Qt.
//    2. Регистрируем наши C++ классы (ZapretController, NetworkScanner),
//       чтобы интерфейс на QML мог ими пользоваться.
//    3. Загружаем главный QML-файл с интерфейсом.
// ─────────────────────────────────────────────────────────────────────────

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QFont>
#include <QIcon>

#include "ZapretController.h"
#include "NetworkScanner.h"
#include "VlessController.h"
#include "Store.h"
#include "StatsTracker.h"
#include "TgController.h"
#include "DiagController.h"
#include "UpdateChecker.h"

int main(int argc, char *argv[])
{
    // QApplication (не QGuiApplication) — нужно для системного трея
    // (Qt.labs.platform.SystemTrayIcon) на Windows.
    QApplication app(argc, argv);

    QApplication::setApplicationName(QStringLiteral("AM.SALES VPN"));
    QApplication::setOrganizationName(QStringLiteral("AM.SALES"));
    // Не выходим при закрытии окна — приложение живёт в трее.
    QApplication::setQuitOnLastWindowClosed(false);

    // Иконка приложения (окно + панель задач).
    QApplication::setWindowIcon(QIcon(
        QStringLiteral(":/qt/qml/AmSalesVPN/assets/appicon.png")));

    // ── Загружаем шрифт Manrope из ресурсов и делаем его шрифтом по
    //    умолчанию для всего приложения (приятная типографика). ──────────
    const int fid = QFontDatabase::addApplicationFont(
        QStringLiteral(":/qt/qml/AmSalesVPN/assets/fonts/Manrope-Regular.ttf"));
    if (fid != -1) {
        const QStringList fam = QFontDatabase::applicationFontFamilies(fid);
        if (!fam.isEmpty()) {
            QFont f(fam.first());
            f.setStyleStrategy(QFont::PreferAntialias);
            QApplication::setFont(f);
        }
    }

    QQmlApplicationEngine engine;

    // ── Создаём объекты бэкенда ─────────────────────────────────────────
    Store store;                       // JSON-хранилище (ключи, настройки, стата)
    ZapretController zapret;
    NetworkScanner scanner;
    VlessController vless(&store);      // получает доступ к хранилищу
    StatsTracker stats(&store);         // учёт сессий/трафика
    TgController tg(&store);            // встроенный Telegram-прокси
    DiagController diag;                // диагностика «почему не работает»
    UpdateChecker updater(&store);      // проверка обновлений (с хранилищем)

    // Связываем VPN-подключение со счётчиком статистики: при подключении
    // стартуем сессию, при отключении — завершаем (она пишется в Store).
    QObject::connect(&vless, &VlessController::connectedChanged,
                     &stats, [&]() {
        if (vless.connected())
            stats.sessionStart(QStringLiteral("server"));
        else
            stats.sessionEnd();
    });

    // ── Прокидываем в QML ───────────────────────────────────────────────
    engine.rootContext()->setContextProperty(QStringLiteral("Zapret"), &zapret);
    engine.rootContext()->setContextProperty(QStringLiteral("Scanner"), &scanner);
    engine.rootContext()->setContextProperty(QStringLiteral("Vpn"), &vless);
    engine.rootContext()->setContextProperty(QStringLiteral("Store"), &store);
    engine.rootContext()->setContextProperty(QStringLiteral("Stats"), &stats);
    engine.rootContext()->setContextProperty(QStringLiteral("Tg"), &tg);
    engine.rootContext()->setContextProperty(QStringLiteral("Diag"), &diag);
    engine.rootContext()->setContextProperty(QStringLiteral("Updater"), &updater);

    // ── Загружаем главный интерфейс ─────────────────────────────────────
    // Если QML не загрузится (ошибка синтаксиса) — приложение закроется.
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral("AmSalesVPN"), QStringLiteral("Main"));

    return app.exec();
}
