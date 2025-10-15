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
    , m_volume(0.8)
    , m_usbWatcher(new QFileSystemWatcher(this))
    , m_scanTimer(new QTimer(this))
    , m_mediaPlayer(new QMediaPlayer(this))
    , m_playlist(new QMediaPlaylist(this))
{
    // USB 디렉터리 감시
    m_usbWatcher->addPath("/media");
    m_usbWatcher->addPath("/mnt");
    connect(m_usbWatcher, &QFileSystemWatcher::directoryChanged,
            this, &MediaManager::onUsbDeviceChanged);
    
    // 디바운스용 타이머
    m_scanTimer->setSingleShot(true);
    m_scanTimer->setInterval(2000);
    connect(m_scanTimer, &QTimer::timeout,
            this, &MediaManager::scanForMedia);
    
    // 미디어 플레이어 설정
    m_mediaPlayer->setPlaylist(m_playlist);
    m_mediaPlayer->setVolume(m_volume * 100);
    connect(m_mediaPlayer, QOverload<QMediaPlayer::MediaStatus>::of(&QMediaPlayer::mediaStatusChanged),
            this, &MediaManager::onMediaStatusChanged);
    connect(m_mediaPlayer, &QMediaPlayer::positionChanged,
            this, &MediaManager::onPositionChanged);
    connect(m_mediaPlayer, QOverload<QMediaPlayer::State>::of(&QMediaPlayer::stateChanged),
            [this](QMediaPlayer::State state) {
                m_isPlaying = (state == QMediaPlayer::PlayingState);
                emit playbackStateChanged();
            });

    // 초기 스캔
    QTimer::singleShot(1000, this, &MediaManager::scanForMedia);
}

void MediaManager::scanForMedia()
{
    qDebug() << "MediaManager: Scanning for USB media files...";

    m_mediaFiles.clear();
    refreshUsbMountsInternal();

    for (const QString &mountPoint : m_usbMounts) {
        qDebug() << "MediaManager: Scanning USB mount:" << mountPoint;
        scanDirectory(mountPoint);
    }

    updatePlaylist();
    emit mediaFilesChanged();

    qDebug() << "MediaManager: Scan complete. Found" << m_mediaFiles.size() << "media files";

    if (!m_mediaFiles.isEmpty() && m_currentIndex < 0) {
        m_currentIndex = 0;
        updateCurrentFile();
        emit currentIndexChanged();
        qDebug() << "MediaManager: Auto-selected first media file:" << m_currentFile;
    }
}

void MediaManager::scanDirectory(const QString &path)
{
    QDir dir(path);
    if (!dir.exists()) {
        qDebug() << "MediaManager: Directory does not exist:" << path;
        return;
    }

    QDirIterator it(path, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString filePath = it.next();
        if (isMediaFile(filePath))
            m_mediaFiles.append(filePath);
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
    if (m_currentIndex < m_mediaFiles.size() - 1)
        playFile(m_currentIndex + 1);
}

void MediaManager::previous()
{
    if (m_currentIndex > 0)
        playFile(m_currentIndex - 1);
}

void MediaManager::onUsbDeviceChanged()
{
    qDebug() << "MediaManager: USB device change detected";
    m_scanTimer->start();
}

void MediaManager::onMediaStatusChanged() {}
void MediaManager::onPositionChanged(qint64 position) { Q_UNUSED(position) }

// USB 관련 메서드들
QStringList MediaManager::listUsbMounts()
{
    refreshUsbMountsInternal();
    return m_usbMounts;
}

QStringList MediaManager::scanUsbAt(const QString& path)
{
    qDebug() << "MediaManager: Scanning USB at:" << path;
    
    m_mediaFiles.clear();
    scanDirectory(path);
    
    updatePlaylist();
    emit mediaFilesChanged();
    
    if (!m_mediaFiles.isEmpty() && m_currentIndex < 0) {
        m_currentIndex = 0;
        updateCurrentFile();
        emit currentIndexChanged();
    }
    
    qDebug() << "MediaManager: Found" << m_mediaFiles.size() << "media files in" << path;
    return m_mediaFiles;
}

QStringList MediaManager::scanAllUsbMounts()
{
    qDebug() << "MediaManager: Scanning all USB mounts...";
    
    m_mediaFiles.clear();
    refreshUsbMountsInternal();
    
    for (const QString& mountPoint : m_usbMounts) {
        scanDirectory(mountPoint);
    }
    
    updatePlaylist();
    emit mediaFilesChanged();
    
    if (!m_mediaFiles.isEmpty() && m_currentIndex < 0) {
        m_currentIndex = 0;
        updateCurrentFile();
        emit currentIndexChanged();
    }
    
    qDebug() << "MediaManager: Found" << m_mediaFiles.size() << "total media files";
    return m_mediaFiles;
}

void MediaManager::refreshUsbMounts()
{
    refreshUsbMountsInternal();
}

void MediaManager::refreshUsbMountsInternal()
{
    m_usbMounts.clear();
    const auto vols = QStorageInfo::mountedVolumes();

    for (const auto& v : vols) {
        if (!v.isValid() || !v.isReady()) continue;
        QString root = v.rootPath();
        QString device = v.device();

        bool isUsbDevice = root.startsWith("/run/media") ||
                           root.startsWith("/media") ||
                           root.startsWith("/mnt") ||
                           (root != "/" && device.startsWith("/dev/sd"));

        if (isUsbDevice)
            m_usbMounts << root;
    }

    m_usbMounts.removeDuplicates();
    emit usbMountsChanged();
}

void MediaManager::setVolume(qreal volume)
{
    volume = qBound(0.0, volume, 1.0);
    if (qAbs(m_volume - volume) > 0.001) {
        m_volume = volume;
        int playerVolume = static_cast<int>(volume * 100);
        m_mediaPlayer->setVolume(playerVolume);
        emit volumeChanged();
    }
}
