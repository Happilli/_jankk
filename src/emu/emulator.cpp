#include "./emulator.h"
#include <QElapsedTimer>
#include <cstdarg>
#include <vector>

extern "C" {
#include <mgba/core/core.h>
#include <mgba/core/log.h>
}

static void quietLog(mLogger *, int, mLogLevel, const char *, va_list) {}
static mLogger quiet = { quietLog, nullptr };

enum GbaKey {
  KEY_A      = 0,
  KEY_B      = 1,
  KEY_SELECT = 2,
  KEY_START  = 3,
  KEY_RIGHT  = 4,
  KEY_LEFT   = 5,
  KEY_UP     = 6,
  KEY_DOWN   = 7,
  KEY_R      = 8,
  KEY_L      = 9
}                                           ;

Emulator::Emulator(QObject *parent) : QThread(parent) {}

Emulator::~Emulator() {
  stop()                                    ;
}

void Emulator::play(const QString &path) {
  stop()                                    ;
  m_path = path                             ;
  m_quit = false                            ;
  m_keys = 0                                ;
  start()                                   ;
}

void Emulator::stop() {
  if (!isRunning()) 
    return                                  ;
  m_quit = true                             ;
  wait()                                    ;
}

void Emulator::run() {
  mLogSetDefaultLogger(&quiet)              ;

  const QByteArray path = m_path.toUtf8()   ;
  mCore *core = mCoreFind(path.constData()) ;
  if (!core) {
    emit error("no core for this file")     ;
    return                                  ;
  }

  core->init(core);
  mCoreInitConfig(core, "jankk")            ;

  unsigned w = 0, h = 0;
  core->desiredVideoDimensions(core, &w, &h);
  std::vector<uint32_t> buf(w * h)          ;
  core->setVideoBuffer(core, 
      reinterpret_cast<color_t *>(buf.data()),
      w)                                    ;

  if (!mCoreLoadFile(core, path.constData())) {
    emit error("failed to load rom")        ;
    core->deinit(core)                      ;
    return                                  ;
  }
  mCoreAutoloadSave(core)                   ;
  core->reset(core)                         ;

  const qint64 frameNs = 
    qint64(1e9 / 59.7275)                   ;
  QElapsedTimer clock                       ;
  clock.start()                             ;
  qint64 next = frameNs                     ;

  int frames = 0                            ;
  qint64 lastReport = 0                     ;

  while (!m_quit) {
    core->setKeys(core, m_keys.load())      ;
    core->runFrame(core)                    ;

    QImage img(reinterpret_cast<uchar *>(buf.data()), w, h, w * 4,
               QImage::Format_RGBX8888)     ;
    emit frameReady(img.copy())             ;

    ++frames;
    const qint64 now = clock.nsecsElapsed();
    if (now - lastReport >= 1000000000) {
      qInfo("emulator fps: %d", frames)     ;
      frames = 0                            ;
      lastReport = now                      ;
    }

    const qint64 remain =
      next - clock.nsecsElapsed()           ;
    if (remain > 0)
      QThread::usleep(remain / 1000)        ;
    next += frameNs                         ;
  }

  core->deinit(core)                        ;
}

static int gbaKeyFor(int qtKey) {
  switch (qtKey) {
    case Qt::Key_A:
      return KEY_A                          ;
    case Qt::Key_B:
      return KEY_B                          ;
    case Qt::Key_X:
      return KEY_L                          ;
    case Qt::Key_Y:
      return KEY_R                          ;
    case Qt::Key_Return:
    case Qt::Key_Enter:
      return KEY_START                      ;
    case Qt::Key_Space:
      return KEY_SELECT                     ;
    case Qt::Key_Up:
      return KEY_UP                         ;
    case Qt::Key_Down:
      return KEY_DOWN                       ;
    case Qt::Key_Left:
      return KEY_LEFT                       ;
    case Qt::Key_Right:
      return KEY_RIGHT                      ;
    default:
      return -1                             ;
  }
}
void Emulator::keyEvent(int qtKey, bool pressed) {
  const int k = gbaKeyFor(qtKey)            ;
  if (k < 0)
    return                                  ;
  const uint32_t bit = 1u << k              ;
  if (pressed)
    m_keys.fetch_or(bit)                    ;
  else
    m_keys.fetch_and(~bit)                  ;
}

