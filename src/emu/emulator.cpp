#include "./emulator.h"
#include <QAudioFormat>
#include <QAudioSink>
#include <QElapsedTimer>
#include <QIODevice>
#include <QMediaDevices>
#include <QMutex>
#include <cstdarg>
#include <cstring>
#include <vector>

extern "C" {
#include <mgba/core/blip_buf.h>
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

class AudioRing : public QIODevice {
public:
  explicit AudioRing(QObject *parent = nullptr)
    : QIODevice(parent) {}

  void push(const int16_t *samples, int frames) {
    QMutexLocker l(&m_mutex)                ;
    m_buf.append(reinterpret_cast<const char *>(samples), frames * 4);
    if (m_buf.size() > kMaxBytes)
      m_buf.remove(0, m_buf.size() - kMaxBytes);
  }

  void clear() {
    QMutexLocker l(&m_mutex)                ;
    m_buf.clear()                           ;
  }

  bool isSequential() const override {
    return true                             ;
  }
  qint64 bytesAvailable() const override {
    return (1 << 20) + QIODevice::bytesAvailable();
  }

protected:
  qint64 readData(char *data, qint64 len) override {
    QMutexLocker l(&m_mutex)                ;
    const qint64 take = qMin<qint64>(len, m_buf.size());
    if (take > 0) {
      std::memcpy(data, m_buf.constData(), take);
      m_buf.remove(0, take)                 ;
    }
    if (take < len)
      std::memset(data + take, 0, len - take);
    return len                              ;
  }
  qint64 writeData(const char *, qint64) override {
    return 0                                ;
  }

private:
  static constexpr int kMaxBytes = 44100 * 4 / 5;
  QByteArray m_buf                          ;
  QMutex m_mutex                            ;
}                                           ;

Emulator::Emulator(QObject *parent) : QThread(parent) {}

Emulator::~Emulator() {
  stop()                                    ;
  if (m_sink)
    m_sink->stop()                          ;
}

void Emulator::play(const QString &path) {
  stop()                                    ;

  if (!m_sink) {
    m_ring = new AudioRing(this)            ;
    m_ring->open(QIODevice::ReadOnly)       ;

    QAudioFormat fmt                        ;
    fmt.setSampleRate(44100)                ;
    fmt.setChannelCount(2)                  ;
    fmt.setSampleFormat(QAudioFormat::Int16);

    m_sink = new QAudioSink(
        QMediaDevices::defaultAudioOutput(),
        fmt, this)                          ;
    m_sink->setBufferSize(8192)             ;
    m_sink->start(m_ring)                   ;
  }
  m_ring->clear()                           ;

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

  core->init(core)                          ;
  core->setAudioBufferSize(core, 2048)      ;
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

  blip_t *left = core->getAudioChannel(core, 0);
  blip_t *right = core->getAudioChannel(core, 1);
  blip_set_rates(left, core->frequency(core), 44100);
  blip_set_rates(right, core->frequency(core), 44100);
  std::vector<int16_t> audio                ;

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

    const int avail = blip_samples_avail(left);
    if (avail > 0) {
      audio.resize(avail * 2)               ;
      blip_read_samples(left, audio.data(), avail, 1);
      blip_read_samples(right, audio.data() + 1, avail, 1);
      m_ring->push(audio.data(), avail)     ;
    }

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
