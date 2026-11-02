#include "./gamelibrary.h"
#include <QChar>
#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QUrl>

static QString fold(const QString &s) {
  const QString d = s.normalized
    (QString::NormalizationForm_D)            ;
  QString out;
  out.reserve(d.size())                       ;
  for (const QChar c : d)
    if (c.category() != QChar::Mark_NonSpacing)
      out.append(c)                           ;
  return out.toCaseFolded()                   ;
}

GameLibrary::GameLibrary(QObject *parent) : QAbstractListModel(parent) {}

int GameLibrary::rowCount(const QModelIndex &parent) const {
  return parent.isValid() ? 0 : m_games.size();
}

QVariant GameLibrary::data(const QModelIndex &index, int role) const {
  if (!index.isValid() || index.row() >= m_games.size())
    return {}                                 ;
  const Game &g = m_games.at(index.row())     ;
  switch (role) {
    case TitleRole:
      return g.title                          ;
    case PathRole:
      return g.path                           ;
    case ImageRole:
      return g.image                          ;
    case MarqueeRole:
      return g.marquee                        ;
    case ThumbRole:
      return g.thumb                          ;
  }
  return {}                                   ;
}

QHash<int, QByteArray> GameLibrary::roleNames() const {
  return {
    { TitleRole, "title" },
    { PathRole, "path" },
    { ImageRole, "image" },
    { MarqueeRole, "marquee" },
    { ThumbRole, "thumb" },
  }                                           ;
}

void GameLibrary::setFolder(const QString &f) {
  if (m_folder == f)
    return                                    ;
  m_folder = f                                ;

  QString dirPath = f                         ;
  if (dirPath.startsWith('~'))
    dirPath.replace(0, 1, QDir::homePath())   ;
  const QDir dir(dirPath)                     ;

  static const QRegularExpression tags(R"(\s*[\(\[][^\)\]]*[\)\]])");
  static const QRegularExpression article(R"(^(.*), The(.*)$)");

  auto art = [&](const QString &base, const char *kind) {
    const QString p =
      dir.filePath("images/" + base + "-" + kind + ".png");
    return QFileInfo::exists(p)
      ? QUrl::fromLocalFile(p).toString()
      : QString()                             ;
  }                                           ;

  m_all.clear()                               ;

  const QStringList roms = dir.entryList(
      { "*.gba" }, QDir::Files,
      QDir::Name | QDir::IgnoreCase)          ;
  for (const QString &rom : roms) {
    if (rom.contains("(MB2GBA)"))
      continue                                ;

    const QString base =
      QFileInfo(rom).completeBaseName()       ;
    QString title = base                      ;
    title.remove(tags)                        ;
    title = title.trimmed()                   ;
    title.replace(article, "The \\1\\2")      ;

    m_all.push_back({
      title,
      dir.filePath(rom),
      art(base, "image"),
      art(base, "marquee"),
      art(base, "thumb"),
      fold(title + " " + base),
    })                                        ;
  }

  applyFilter()                               ; 
  emit folderChanged()                        ;
}

void GameLibrary::setFilter(const QString &f) {
  if (m_filter == f)
    return                                    ;
  m_filter = f                                ;
  applyFilter()                               ;
  emit filterChanged()                        ;
}

void GameLibrary::applyFilter() {
  static const QRegularExpression spaces(R"(\s+)");
  const QStringList words =
    fold(m_filter).split(spaces, Qt::SkipEmptyParts);

  beginResetModel()                           ;
  m_games.clear()                             ;
  for (const Game &g : std::as_const(m_all)) {
    bool ok = true                            ;
    for (const QString &w : words) {
      if (!g.key.contains(w)) {
        ok = false                            ;
        break                                 ;
      }
    }
    if (ok)
      m_games.push_back(g)                    ;
  }
  endResetModel()                             ;

  emit countChanged()                         ;
}
