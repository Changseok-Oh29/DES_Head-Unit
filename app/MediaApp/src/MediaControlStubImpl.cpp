#include "MediaControlStubImpl.h"
#include <QDebug>

namespace v1 {
namespace mediacontrol {

MediaControlStubImpl::MediaControlStubImpl(MediaManager* mediaManager)
    : m_mediaManager(mediaManager)
{
    qDebug() << "MediaControlStubImpl: Service initialized";
    
    // MediaManager의 volumeChanged 시그널을 vsomeip 이벤트로 연결
    if (m_mediaManager) {
        QObject::connect(m_mediaManager, &MediaManager::volumeChanged,
                        [this]() {
                            float volume = m_mediaManager->volume();
                            fireVolumeChangedEvent(volume);
                            qDebug() << "MediaControlStubImpl: Volume changed event fired:" << volume;
                        });
    }
}

MediaControlStubImpl::~MediaControlStubImpl() {
    qDebug() << "MediaControlStubImpl: Service destroyed";
}

void MediaControlStubImpl::getVolume(getVolumeReply_t _reply) {
    float currentVolume = 0.0f;
    
    if (m_mediaManager) {
        currentVolume = static_cast<float>(m_mediaManager->volume());
    }
    
    qDebug() << "MediaControlStubImpl: getVolume() called, returning:" << currentVolume;
    _reply(currentVolume);
}

void MediaControlStubImpl::fireVolumeChangedEvent(float volume) {
    // StubDefault에서 제공하는 이벤트 발송 메서드 호출
    fireVolumeChangedEvent(volume);
}

} // namespace mediacontrol
} // namespace v1
