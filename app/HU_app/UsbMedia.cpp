#include "UsbMedia.h"
#include <QStorageInfo>
#include <QDirIterator>
#include <QFileInfo>

static const QStringList mediaExts = {
    "mp3","wav","ogg","m4a","flac","aac",
    "mp4","avi","mkv","mov","webm"
};

UsbMedia::UsbMedia(QObject* parent) : QObject(parent) {}

void UsbMedia::refreshMounts() {
    m_mounts.clear();
    const auto vols = QStorageInfo::mountedVolumes();
    for (const auto& v : vols) {
        if (!v.isValid() || !v.isReady()) continue;
        QString root = v.rootPath();
        
        // USB 장치 감지: 일반적인 마운트 경로나 루트가 아닌 장치 확인
        bool isUsbDevice = root.startsWith("/run/media") || 
                          root.startsWith("/media") ||
                          root.startsWith("/mnt") ||
                          (root != "/" && v.device().startsWith("/dev/sd"));
                          
        if (isUsbDevice)
            m_mounts << root;
    }
    m_mounts.removeDuplicates();
    emit mountsChanged();
}

QStringList UsbMedia::listMounts() {
    refreshMounts();
    return m_mounts;
}

void UsbMedia::recursiveScan(const QString& root, QStringList& out) const {
    QDirIterator it(root, QDir::Files, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        QString path = it.next();
        QString ext = QFileInfo(path).suffix().toLower();
        if (mediaExts.contains(ext))
            out << path;
    }
}

QStringList UsbMedia::scanAt(const QString& path) {
    QStringList out;
    recursiveScan(path, out);
    out.removeDuplicates();
    return out;
}

QStringList UsbMedia::scanAll() {
    refreshMounts();
    QStringList out;
    for (const auto& root : m_mounts)
        recursiveScan(root, out);
    out.removeDuplicates();
    return out;
}
