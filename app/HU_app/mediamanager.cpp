#include "mediamanager.h"
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QDebug>
#include <QUrl>

const QStringList MediaManager::s_supportedFormats = {
    "mp3", "wav", "flac", "m4a", "aac", "ogg", "wma"
};

MediaManager::MediaManager(QObject *parent)
    : QObject(parent)
    , m_isPlaying(false)
    , m_currentIndex(-1)
    , m_usbWatcher(new QFileSystemWatcher(this))
    , m_scanTimer(new QTimer(this))
    , m_mediaPlayer(new QMediaPlayer(this))
    , m_playlist(new QMediaPlaylist(this))
{
    // Setup USB monitoring
    m_usbWatcher->addPath("/media");
    m_usbWatcher->addPath("/mnt");
    connect(m_usbWatcher, &QFileSystemWatcher::directoryChanged,
            this, &MediaManager::onUsbDeviceChanged);
    
    // Setup scan timer (debounce rapid USB events)
    m_scanTimer->setSingleShot(true);
    m_scanTimer->setInterval(2000); // 2 seconds delay
    connect(m_scanTimer, &QTimer::timeout,
            this, &MediaManager::scanForMedia);
    
    // Setup media player
    m_mediaPlayer->setPlaylist(m_playlist);
    connect(m_mediaPlayer, QOverload<QMediaPlayer::MediaStatus>::of(&QMediaPlayer::mediaStatusChanged),
            this, &MediaManager::onMediaStatusChanged);
    connect(m_mediaPlayer, &QMediaPlayer::positionChanged,
            this, &MediaManager::onPositionChanged);
    connect(m_mediaPlayer, QOverload<QMediaPlayer::State>::of(&QMediaPlayer::stateChanged),
            [this](QMediaPlayer::State state) {
                m_isPlaying = (state == QMediaPlayer::PlayingState);
                emit playbackStateChanged();
            });
    
    // Initial scan
    QTimer::singleShot(1000, this, &MediaManager::scanForMedia);
}

void MediaManager::scanForMedia()
{
    qDebug() << "MediaManager: Scanning for media files...";
    
    QStringList newMediaFiles;
    
    // Scan common USB mount points
    QStringList scanPaths = {
        "/media",
        "/mnt", 
        "/run/media",
        QStandardPaths::writableLocation(QStandardPaths::MusicLocation)
    };
    
    for (const QString &basePath : scanPaths) {
        QDir baseDir(basePath);
        if (!baseDir.exists()) continue;
        
        // Look for mounted USB devices
        QStringList subDirs = baseDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &subDir : subDirs) {
            QString fullPath = baseDir.absoluteFilePath(subDir);
            scanDirectory(fullPath);
        }
    }
    
    // Also scan music directory if it exists
    QString musicPath = QStandardPaths::writableLocation(QStandardPaths::MusicLocation);
    if (QDir(musicPath).exists()) {
        scanDirectory(musicPath);
    }
    
    if (m_mediaFiles != newMediaFiles) {
        m_mediaFiles = newMediaFiles;
        updatePlaylist();
        emit mediaFilesChanged();
        qDebug() << "MediaManager: Found" << m_mediaFiles.size() << "media files";
    }
}

void MediaManager::scanDirectory(const QString &path)
{
    QDirIterator it(path, QDir::Files, QDirIterator::Subdirectories);
    
    while (it.hasNext()) {
        it.next();
        QString filePath = it.filePath();
        
        if (isMediaFile(filePath)) {
            m_mediaFiles.append(filePath);
        }
    }
}

bool MediaManager::isMediaFile(const QString &filePath)
{
    QFileInfo fileInfo(filePath);
    QString suffix = fileInfo.suffix().toLower();
    return s_supportedFormats.contains(suffix);
}

void MediaManager::updatePlaylist()
{
    m_playlist->clear();
    for (const QString &filePath : m_mediaFiles) {
        m_playlist->addMedia(QUrl::fromLocalFile(filePath));
    }
}

void MediaManager::updateCurrentFile()
{
    if (m_currentIndex >= 0 && m_currentIndex < m_mediaFiles.size()) {
        QString newCurrentFile = m_mediaFiles.at(m_currentIndex);
        if (m_currentFile != newCurrentFile) {
            m_currentFile = newCurrentFile;
            emit currentFileChanged();
        }
    } else {
        if (!m_currentFile.isEmpty()) {
            m_currentFile.clear();
            emit currentFileChanged();
        }
    }
}

void MediaManager::playFile(int index)
{
    if (index >= 0 && index < m_mediaFiles.size()) {
        m_currentIndex = index;
        m_playlist->setCurrentIndex(index);
        m_mediaPlayer->play();
        updateCurrentFile();
        emit currentIndexChanged();
    }
}

void MediaManager::play()
{
    if (m_playlist->mediaCount() > 0) {
        if (m_currentIndex < 0) {
            m_currentIndex = 0;
            m_playlist->setCurrentIndex(0);
            updateCurrentFile();
            emit currentIndexChanged();
        }
        m_mediaPlayer->play();
    }
}

void MediaManager::pause()
{
    m_mediaPlayer->pause();
}

void MediaManager::stop()
{
    m_mediaPlayer->stop();
    m_currentIndex = -1;
    updateCurrentFile();
    emit currentIndexChanged();
}

void MediaManager::next()
{
    if (m_currentIndex < m_mediaFiles.size() - 1) {
        playFile(m_currentIndex + 1);
    }
}

void MediaManager::previous()
{
    if (m_currentIndex > 0) {
        playFile(m_currentIndex - 1);
    }
}

void MediaManager::onUsbDeviceChanged()
{
    qDebug() << "MediaManager: USB device change detected";
    m_scanTimer->start(); // Debounce the scan
}

void MediaManager::onMediaStatusChanged()
{
    // Handle media status changes if needed
}

void MediaManager::onPositionChanged(qint64 position)
{
    // Handle position changes for progress updates
    Q_UNUSED(position)
}
