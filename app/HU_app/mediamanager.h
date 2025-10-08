#ifndef MEDIAMANAGER_H
#define MEDIAMANAGER_H

#include <QObject>
#include <QStringList>
#include <QFileSystemWatcher>
#include <QTimer>
#include <QMediaPlayer>
#include <QMediaPlaylist>

class MediaManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList mediaFiles READ mediaFiles NOTIFY mediaFilesChanged)
    Q_PROPERTY(QString currentFile READ currentFile NOTIFY currentFileChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY playbackStateChanged)
    Q_PROPERTY(int currentIndex READ currentIndex NOTIFY currentIndexChanged)

public:
    explicit MediaManager(QObject *parent = nullptr);
    
    QStringList mediaFiles() const { return m_mediaFiles; }
    QString currentFile() const { return m_currentFile; }
    bool isPlaying() const { return m_isPlaying; }
    int currentIndex() const { return m_currentIndex; }

public slots:
    void scanForMedia();
    void playFile(int index);
    void play();
    void pause();
    void stop();
    void next();
    void previous();

signals:
    void mediaFilesChanged();
    void currentFileChanged();
    void playbackStateChanged();
    void currentIndexChanged();

private slots:
    void onUsbDeviceChanged();
    void onMediaStatusChanged();
    void onPositionChanged(qint64 position);

private:
    void scanDirectory(const QString &path);
    bool isMediaFile(const QString &filePath);
    void updateCurrentFile();
    void updatePlaylist();

    QStringList m_mediaFiles;
    QString m_currentFile;
    bool m_isPlaying;
    int m_currentIndex;
    
    QFileSystemWatcher *m_usbWatcher;
    QTimer *m_scanTimer;
    QMediaPlayer *m_mediaPlayer;
    QMediaPlaylist *m_playlist;
    
    static const QStringList s_supportedFormats;
};

#endif // MEDIAMANAGER_H
