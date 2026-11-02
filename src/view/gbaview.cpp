#include "./gbaview.h"
#include "../emu/emulator.h"
#include <QQuickWindow>
#include <QSGSimpleTextureNode>
#include <QtMath>

GbaView::GbaView(QQuickItem *parent) : QQuickItem(parent) {
  setFlag(ItemHasContents, true);
}

void GbaView::setSource(Emulator *e) {
  if (m_source == e)
    return                      ;
  if (m_source)
    disconnect(m_source,
        nullptr,
        this,
        nullptr)                ;
  m_source = e                  ;
  if (m_source)
    connect(m_source,
        &Emulator::frameReady,
        this,
        &GbaView::setFrame,
        Qt::QueuedConnection)   ;
  emit sourceChanged()          ;
}

void GbaView::setFrame(const QImage &img) {
  m_frame = img                 ;
  update()                      ;
}

QSGNode *GbaView::updatePaintNode(QSGNode *old, UpdatePaintNodeData *) {
  auto *node = static_cast<QSGSimpleTextureNode *>
    (old)                       ;
  if (m_frame.isNull() || !window()) {
    delete node                 ;
    return nullptr              ;
  }
  if (!node) {
    node = 
      new QSGSimpleTextureNode  ;
    node->setOwnsTexture(true)  ;
    node->setFiltering
      (QSGTexture::Nearest)     ;
  }
  node->setTexture(window()->
      createTextureFromImage
      (m_frame))                ;

  qreal s = qMin(width() /
      m_frame.width(), height() / 
      m_frame.height())         ;
  if (m_integer && s >= 1)
    s = qFloor(s)               ;
  const QSizeF sz(m_frame.width() 
      * s, m_frame.height() * s);
  node->setRect(QRectF((width() - sz.width()) / 2, (height() - sz.height()) / 2,
                       sz.width(),
                       sz.height()
                       ))       ;
  return node                   ;
}
