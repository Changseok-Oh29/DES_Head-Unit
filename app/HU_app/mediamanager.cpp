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
    m_mediaPlayer->setVolume(m_volume * 100); // MediaPlayer uses 0-100 range
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
    
    // Initial USB scan
    refreshUsbMountsInternal();
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

// USB 관련 메서드들 (이전 UsbMedia 기능 통합)
QStringList MediaManager::listUsbMounts()
{
    refreshUsbMountsInternal();
    return m_usbMounts;
}

QStringList MediaManager::scanUsbAt(const QString& path)
{
    qDebug() << "MediaManager: Scanning USB at:" << path;
    QStringList out;
    recursiveUsbScan(path, out);
    out.removeDuplicates();
    
    // 발견된 파일들을 미디어 파일 목록에 업데이트
    m_mediaFiles = out;
    emit mediaFilesChanged();
    
    // 플레이리스트 업데이트 (재생을 위해 중요!)
    updatePlaylist();
    
    // 현재 인덱스 초기화
    m_currentIndex = -1;
    
    qDebug() << "MediaManager: Found" << out.length() << "media files in" << path;
    
    return out;
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
        
        // USB 장치 감지: 일반적인 마운트 경로나 루트가 아닌 장치 확인
        bool isUsbDevice = root.startsWith("/run/media") || 
                          root.startsWith("/media") ||
                          root.startsWith("/mnt") ||
                          (root != "/" && v.device().startsWith("/dev/sd"));
                          
        if (isUsbDevice) {
            m_usbMounts << root;
            qDebug() << "MediaManager: Found USB mount:" << root;
        }
    }
    m_usbMounts.removeDuplicates();
    emit usbMountsChanged();
}

void MediaManager::recursiveUsbScan(const QString& root, QStringList& out) const
{
    QDirIterator it(root, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString path = it.next();
        QString ext = QFileInfo(path).suffix().toLower();
        
        // 지원되는 오디오/비디오 형식 확장
        QStringList mediaExts = {
            "mp3","wav","ogg","m4a","flac","aac","wma",
            "mp4","avi","mkv","mov","webm","wmv","3gp"
        };
        
        if (mediaExts.contains(ext))
            out << path;
    }
}

void MediaManager::setVolume(qreal volume)
{
    // Clamp volume to 0.0-1.0 range
    volume = qBound(0.0, volume, 1.0);
    
    if (qAbs(m_volume - volume) > 0.01) { // Avoid unnecessary updates
        m_volume = volume;
        m_mediaPlayer->setVolume(static_cast<int>(volume * 100)); // MediaPlayer uses 0-100 range
        emit volumeChanged();
        qDebug() << "MediaManager: Volume set to:" << volume << "(" << (volume * 100) << "%)";
    }
}
