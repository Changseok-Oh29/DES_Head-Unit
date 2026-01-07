#ifndef BEEPCONTROLLER_H
#define BEEPCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QProcess>
#include <QString>

/**
 * @brief BeepController - Controls beep sounds based on distance
 *
 * Distance zones and beep patterns:
 * - >50cm: No beep (safe zone)
 * - 30-50cm: Slow beep (green zone) - beep every 1000ms
 * - 15-30cm: Fast beep (yellow zone) - beep every 500ms
 * - <15cm: Continuous beep (red zone) - beep every 200ms
 *
 * Beeps are produced using terminal bell (\a) via SSH to the speaker device
 */
class BeepController : public QObject
{
    Q_OBJECT

public:
    explicit BeepController(QObject *parent = nullptr);
    virtual ~BeepController();

    // Configuration
    void setSpeakerHost(const QString& host);
    void setSpeakerUser(const QString& user);

    // Distance thresholds (cm)
    static const int GREEN_THRESHOLD = 50;   // 30-50cm
    static const int YELLOW_THRESHOLD = 30;  // 15-30cm
    static const int RED_THRESHOLD = 15;     // <15cm

    // Beep intervals (ms)
    static const int GREEN_INTERVAL = 1000;  // Slow beep
    static const int YELLOW_INTERVAL = 500;  // Fast beep
    static const int RED_INTERVAL = 200;     // Continuous beep

public slots:
    void onGearChanged(const QString& gear);
    void onDistanceChanged(int distance);
    void setEnabled(bool enabled);

private slots:
    void triggerBeep();

private:
    enum class BeepZone {
        Safe,    // >50cm - no beep
        Green,   // 30-50cm - slow beep
        Yellow,  // 15-30cm - fast beep
        Red      // <15cm - continuous beep
    };

    BeepZone determineZone(int distance);
    void updateBeepPattern();
    void sendBeep();

    // SSH configuration
    QString m_speakerHost;
    QString m_speakerUser;

    // Current state
    QString m_currentGear;
    int m_currentDistance;
    BeepZone m_currentZone;
    bool m_enabled;
    bool m_isReverseGear;

    // Beep timer
    QTimer* m_beepTimer;
};

#endif // BEEPCONTROLLER_H
