#pragma once
#include <QImage>
#include <QString>
#include <QThread>
#include <QtQmlIntegration/qqmlintegration.h>
#include <atomic>

class QAudioSink                              ;
class AudioRing                               ;

class Emulator : public QThread {
  Q_OBJECT
  QML_ELEMENT

public: 
  explicit Emulator(QObject *parent = nullptr);
  ~Emulator() override                        ;

  Q_INVOKABLE void play(const QString &path)  ;
  Q_INVOKABLE void stop()                     ;

  Q_INVOKABLE void keyEvent(int qtKey,
      bool pressed)                           ;

signals:
  void frameReady(const QImage &frame)        ;
  void error(const QString &msg)              ;

protected:
  void run() override                         ;

private:
  QString m_path                              ;
  std::atomic<bool> m_quit{false}             ;
  std::atomic<uint32_t> m_keys{0}             ;
  QAudioSink *m_sink = nullptr                ;
  AudioRing *m_ring = nullptr                 ;

}                                             ;
