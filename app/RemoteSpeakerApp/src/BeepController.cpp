#include "BeepController.h"
#include <QDebug>
#include <QProcess>
#include <iostream>
#include <fstream>

BeepController::BeepController(QObject *parent)
    : QObject(parent)
    , m_speakerHost("192.168.1.102")  // Default speaker device IP
    , m_speakerUser("root")           // Default SSH user
    , m_currentGear("P")
    , m_currentDistance(200)
    , m_currentZone(BeepZone::Safe)
    , m_enabled(true)
    , m_isReverseGear(false)
    , m_beepTimer(new QTimer(this))
{
    connect(m_beepTimer, &QTimer::timeout, this, &BeepController::triggerBeep);
    qDebug() << "[BeepController] Created";
}

BeepController::~BeepController()
{
    m_beepTimer->stop();
    qDebug() << "[BeepController] Destroyed";
}

void BeepController::setSpeakerHost(const QString& host)
{
    m_speakerHost = host;
    qDebug() << "[BeepController] Speaker host set to:" << host;
}

void BeepController::setSpeakerUser(const QString& user)
{
    m_speakerUser = user;
    qDebug() << "[BeepController] Speaker user set to:" << user;
}

void BeepController::onGearChanged(const QString& gear)
{
    m_currentGear = gear;
    m_isReverseGear = (gear == "R");

    qDebug() << "[BeepController] Gear changed to:" << gear
             << "- Reverse:" << m_isReverseGear;

    updateBeepPattern();
}

void BeepController::onDistanceChanged(int distance)
{
    m_currentDistance = distance;
    BeepZone newZone = determineZone(distance);

    // Only log and update if zone changed
    if (newZone != m_currentZone) {
        m_currentZone = newZone;

        QString zoneName;
        switch (m_currentZone) {
            case BeepZone::Safe:   zoneName = "SAFE (>50cm)"; break;
            case BeepZone::Green:  zoneName = "GREEN (30-50cm)"; break;
            case BeepZone::Yellow: zoneName = "YELLOW (15-30cm)"; break;
            case BeepZone::Red:    zoneName = "RED (<15cm)"; break;
        }

        qDebug() << "[BeepController] Distance:" << distance << "cm - Zone:" << zoneName;
        updateBeepPattern();
    }
}

void BeepController::setEnabled(bool enabled)
{
    m_enabled = enabled;
    qDebug() << "[BeepController] Enabled:" << enabled;
    updateBeepPattern();
}

BeepController::BeepZone BeepController::determineZone(int distance)
{
    if (distance > GREEN_THRESHOLD) {
        return BeepZone::Safe;
    } else if (distance > YELLOW_THRESHOLD) {
        return BeepZone::Green;
    } else if (distance > RED_THRESHOLD) {
        return BeepZone::Yellow;
    } else {
        return BeepZone::Red;
    }
}

void BeepController::updateBeepPattern()
{
    // Stop current beep pattern
    m_beepTimer->stop();

    // Only beep if enabled, in reverse gear, and not in safe zone
    if (!m_enabled || !m_isReverseGear || m_currentZone == BeepZone::Safe) {
        if (!m_isReverseGear) {
            qDebug() << "[BeepController] Beep disabled - not in reverse gear";
        } else if (m_currentZone == BeepZone::Safe) {
            qDebug() << "[BeepController] Beep disabled - safe zone (>50cm)";
        }
        return;
    }

    // Set beep interval based on zone
    int interval = 0;
    switch (m_currentZone) {
        case BeepZone::Green:
            interval = GREEN_INTERVAL;
            break;
        case BeepZone::Yellow:
            interval = YELLOW_INTERVAL;
            break;
        case BeepZone::Red:
            interval = RED_INTERVAL;
            break;
        default:
            return;
    }

    qDebug() << "[BeepController] Starting beep pattern with interval:" << interval << "ms";

    // Start with immediate beep, then continue at interval
    triggerBeep();
    m_beepTimer->start(interval);
}

void BeepController::triggerBeep()
{
    sendBeep();
}

void BeepController::sendBeep()
{
    // Write bell character to /dev/tty to trigger terminal bell sound
    // This is the same sound as when pressing Tab with no completions
    std::ofstream tty("/dev/tty");
    if (tty.is_open()) {
        tty << '\a' << std::flush;
        tty.close();
    }
}
