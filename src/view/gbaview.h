#pragma once
#include <QImage>
#include <QQuickItem>
#include <QtQmlIntegration/qqmlintegration.h>

class Emulator                    ;

class GbaView : public QQuickItem {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(Emulator *source READ source WRITE setSource NOTIFY sourceChanged)
  Q_PROPERTY(bool integerScale MEMBER m_integer NOTIFY integerScaleChanged)

public:
  explicit GbaView(QQuickItem *parent
      = nullptr)                  ;

  Emulator *source() const { 
    return m_source               ;
  }
  void setSource(Emulator *e)     ;

signals:
  void sourceChanged()            ;
  void integerScaleChanged()      ;

protected:
  QSGNode *updatePaintNode(QSGNode *old, 
      UpdatePaintNodeData *) 
      override                    ;

private:
  void setFrame(const QImage
      &img)                       ;

  Emulator *m_source = nullptr    ;
  QImage m_frame                  ;
  bool m_integer = false          ;
}                                 ;
