#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setWindowIcon
      (QIcon(
             ":/qt/qml/Jankk/jankk.png"
             ))                    ;
    app.setDesktopFileName("jankk");

    QQmlApplicationEngine engine   ;
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { 
        QCoreApplication::exit(-1) ; 
        }, Qt::QueuedConnection)   ;

    engine.loadFromModule("Jankk",
        "Main")                    ;
    return app.exec()              ;
}
