#ifndef MEDIAMANAGER_H
#define MEDIAMANAGER_H

#include <QObject>
#include <QStringList>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QMediaPlayer>
#include <QMediaPlaylist>
#include <QStorageInfo>

class MediaManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList mediaFiles READ mediaFiles NOTIFY mediaFilesChanged)
    Q_PROPERTY(QString currentFile READ currentFile NOTIFY currentFileChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStateChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QStringList usbMounts READ usbMounts NOTIFY usbMountsChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)

public:
    explicit MediaManager(QObject *parent = nullptr);
    
    QStringList mediaFiles() const { return m_mediaFiles; }
    QString currentFile() const { return m_currentFile; }
    bool isPlaying() const { return m_isPlaying; }
    int currentIndex() const { return m_currentIndex; }
    QStringList usbMounts() const { return m_usbMounts; }
    qreal volume() const { return m_volume; }
    void setVolume(qreal volume);

public slots:
    void scanForMedia();
    void playFile(int index);
    void play();
    void pause();
    void stop();
    void next();
    void previous();
    Q_INVOKABLE QStringList listUsbMounts();
    Q_INVOKABLE QStringList scanUsbAt(const QString& path);
    Q_INVOKABLE QStringList scanAllUsbMounts();
    Q_INVOKABLE void refreshUsbMounts();

signals:
    void mediaFilesChanged();
    void currentFileChanged();
    void playbackStateChanged();
    void currentIndexChanged();
    void usbMountsChanged();
    void volumeChanged();

private slots:
    void onUsbDeviceChanged();
    void onMediaStatusChanged();
    void onPositionChanged(qint64 position);

private:
    void scanDirectory(const QString &path);
    bool isMediaFile(const QString &filePath);
    void updateCurrentFile();
    void updatePlaylist();
    void refreshUsbMountsInternal();
    void recursiveUsbScan(const QString& root, QStringList& out) const;

    QStringList m_mediaFiles;
    QString m_currentFile;
    bool m_isPlaying;
    int m_currentIndex;
    QStringList m_usbMounts;
    qreal m_volume;
    
    QFileSystemWatcher *m_usbWatcher;
    QTimer *m_scanTimer;
    QMediaPlayer *m_mediaPlayer;
    QMediaPlaylist *m_playlist;
    
    static const QStringList s_supportedFormats;
};

#endif // MEDIAMANAGER_H
