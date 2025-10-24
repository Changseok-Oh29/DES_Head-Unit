#ifndef MEDIACONTROLSTUBIMPL_H
#define MEDIACONTROLSTUBIMPL_H

#include <v1/mediacontrol/MediaControlStubDefault.hpp>
#include <CommonAPI/CommonAPI.hpp>
#include "mediamanager.h"

namespace v1 {
namespace mediacontrol {

/**
 * MediaControl Service Implementation
 * 
 * MediaApp이 제공하는 vsomeip 서비스
 * - getVolume() RPC 처리
 * - volumeChanged 이벤트 발송
 */
class MediaControlStubImpl : public MediaControlStubDefault {
public:
    MediaControlStubImpl(MediaManager* mediaManager);
    virtual ~MediaControlStubImpl();

    // RPC Method Implementation
    virtual void getVolume(getVolumeReply_t _reply) override;

    // Event Firing
    void fireVolumeChangedEvent(float volume);

private:
    MediaManager* m_mediaManager;  // 기존 MediaManager 활용
};

} // namespace mediacontrol
} // namespace v1

#endif // MEDIACONTROLSTUBIMPL_H
