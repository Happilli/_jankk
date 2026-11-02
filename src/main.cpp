#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("jankk");
    app.setApplicationVersion
      (JANKK_VERSION)              ;
    app.setWindowIcon
      (QIcon(
             ":/qt/qml/Jankk/jankk.png"
             ))                    ;
    app.setDesktopFileName("jankk");

    QCommandLineParser parser      ;
    parser.setApplicationDescription
      ("GBA launcher")             ;
    parser.addHelpOption()         ;
    parser.addVersionOption()      ;
    parser.addPositionalArgument(
        "folder", "ROM folder to load",
        "[folder]")                ;
    parser.process(app)            ;

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
