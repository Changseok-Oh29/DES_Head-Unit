#ifndef CAMERASTREAMER_H
#define CAMERASTREAMER_H

#include <QObject>
#include <QProcess>
#include <QString>

class CameraStreamer : public QObject
{
    Q_OBJECT

public:
    explicit CameraStreamer(QObject *parent = nullptr);
    ~CameraStreamer();

    bool initialize();

    void setTargetHost(const QString& host);
    void setTargetPort(int port);
    void setResolution(int width, int height);
    void setFramerate(int fps);
    void setBitrate(int kbps);

    bool isStreaming() const { return m_streaming; }
    QString targetHost() const { return m_targetHost; }
    int targetPort() const { return m_targetPort; }

public slots:
    void startStreaming();
    void stopStreaming();

signals:
    void streamingStarted();
    void streamingStopped();
    void streamingError(const QString& error);

private slots:
    void onProcessStarted();
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessError(QProcess::ProcessError error);
    void onReadyReadStandardError();

private:
    QString buildGStreamerPipeline() const;
    bool checkCameraAvailable() const;

    QProcess* m_gstProcess;
    bool m_streaming;
    bool m_initialized;

    // Streaming configuration
    QString m_targetHost;
    int m_targetPort;
    int m_width;
    int m_height;
    int m_framerate;
    int m_bitrate;  // kbps

    // Default values
    static constexpr int DEFAULT_WIDTH = 1280;
    static constexpr int DEFAULT_HEIGHT = 720;
    static constexpr int DEFAULT_FRAMERATE = 30;
    static constexpr int DEFAULT_BITRATE = 4000;  // 4 Mbps
    static constexpr int DEFAULT_PORT = 5000;
};

#endif // CAMERASTREAMER_H
