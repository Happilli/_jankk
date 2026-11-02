#pragma once
#include <QAbstractListModel>
#include <QString>
#include <QVector>
#include <QtQmlIntegration/qqmlintegration.h>

class GameLibrary : public QAbstractListModel {
  Q_OBJECT
  QML_ELEMENT
  Q_PROPERTY(QString folder READ folder WRITE setFolder NOTIFY folderChanged)
  Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
  Q_PROPERTY(int count READ rowCountQml NOTIFY countChanged)
  Q_PROPERTY(int total READ total NOTIFY countChanged)

public:
  enum Role {
    TitleRole = Qt::UserRole + 1,
    PathRole,
    ImageRole,
    MarqueeRole,
    ThumbRole
  }                                           ;

  explicit GameLibrary(QObject *parent
      = nullptr)                              ;

  int rowCount(const QModelIndex &parent
      = {}) const override                    ;
  QVariant data(const QModelIndex &index,
      int role) const override                ;
  QHash<int, QByteArray> roleNames()
      const override                          ;

  QString folder() const {
    return m_folder                           ;
  }
  QString filter() const {
    return m_filter                           ;
  }
  int rowCountQml() const {
    return m_games.size()                     ;
  }
  int total() const {
    return m_all.size()                       ;
  }
  void setFolder(const QString &f)            ;
  void setFilter(const QString &f)            ;
  Q_INVOKABLE QString imageAt(int row)
      const                                   ;

signals:
  void folderChanged()                        ;
  void filterChanged()                        ;
  void countChanged()                         ;

private:
  void applyFilter()                          ;

  struct Game {
    QString title, path, image, marquee, thumb;
    QString key                               ; 
  }                                           ;
  QString m_folder, m_filter                  ;
  QVector<Game> m_all                         ;
  QVector<Game> m_games                       ;
}                                             ;
