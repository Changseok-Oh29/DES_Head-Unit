#include "CameraStreamer.h"
#include <QDebug>
#include <QFile>
#include <QDir>

CameraStreamer::CameraStreamer(QObject *parent)
    : QObject(parent)
    , m_gstProcess(nullptr)
    , m_streaming(false)
    , m_initialized(false)
    , m_targetHost("192.168.1.101")  // Default Jetson IP
    , m_targetPort(DEFAULT_PORT)
    , m_width(DEFAULT_WIDTH)
    , m_height(DEFAULT_HEIGHT)
    , m_framerate(DEFAULT_FRAMERATE)
    , m_bitrate(DEFAULT_BITRATE)
{
}

CameraStreamer::~CameraStreamer()
{
    stopStreaming();
    if (m_gstProcess) {
        delete m_gstProcess;
        m_gstProcess = nullptr;
    }
}

bool CameraStreamer::initialize()
{
    if (m_initialized) {
        return true;
    }

    // Check if gst-launch-1.0 is available
    QProcess checkProcess;
    checkProcess.start("which", QStringList() << "gst-launch-1.0");
    checkProcess.waitForFinished(5000);

    if (checkProcess.exitCode() != 0) {
        qCritical() << "gst-launch-1.0 not found in PATH";
        return false;
    }

    // Check if camera is available
    if (!checkCameraAvailable()) {
        qWarning() << "Camera not detected, streaming may not work";
        // Don't fail initialization, camera might be connected later
    }

    m_gstProcess = new QProcess(this);

    connect(m_gstProcess, &QProcess::started,
            this, &CameraStreamer::onProcessStarted);
    connect(m_gstProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &CameraStreamer::onProcessFinished);
    connect(m_gstProcess, &QProcess::errorOccurred,
            this, &CameraStreamer::onProcessError);
    connect(m_gstProcess, &QProcess::readyReadStandardError,
            this, &CameraStreamer::onReadyReadStandardError);

    m_initialized = true;
    qDebug() << "CameraStreamer initialized";
    qDebug() << "  Target:" << m_targetHost << ":" << m_targetPort;
    qDebug() << "  Resolution:" << m_width << "x" << m_height << "@" << m_framerate << "fps";
    qDebug() << "  Bitrate:" << m_bitrate << "kbps";

    return true;
}

void CameraStreamer::setTargetHost(const QString& host)
{
    if (!m_streaming) {
        m_targetHost = host;
    }
}

void CameraStreamer::setTargetPort(int port)
{
    if (!m_streaming && port > 0 && port < 65536) {
        m_targetPort = port;
    }
}

void CameraStreamer::setResolution(int width, int height)
{
    if (!m_streaming && width > 0 && height > 0) {
        m_width = width;
        m_height = height;
    }
}

void CameraStreamer::setFramerate(int fps)
{
    if (!m_streaming && fps > 0 && fps <= 60) {
        m_framerate = fps;
    }
}

void CameraStreamer::setBitrate(int kbps)
{
    if (!m_streaming && kbps > 0) {
        m_bitrate = kbps;
    }
}

QString CameraStreamer::buildGStreamerPipeline() const
{
    // Build GStreamer pipeline for libcamera on Raspberry Pi
    // Pipeline: libcamerasrc -> x264enc -> h264parse -> rtph264pay -> udpsink
    // Stack: libcamerasrc, GStreamer, RTP, UDP, H264 encoding, ethernet

    QString pipeline = QString(
        "libcamerasrc ! "
        "video/x-raw,width=%1,height=%2,framerate=%3/1 ! "
        "x264enc tune=zerolatency bitrate=%4 speed-preset=ultrafast ! "
        "h264parse config-interval=1 ! "
        "rtph264pay pt=96 ! "
        "udpsink host=%5 port=%6 sync=false async=false"
    ).arg(m_width).arg(m_height).arg(m_framerate)
     .arg(m_bitrate).arg(m_targetHost).arg(m_targetPort);

    return pipeline;
}

bool CameraStreamer::checkCameraAvailable() const
{
    // Check for libcamera devices
    QProcess camCheck;
    camCheck.start("libcamera-hello", QStringList() << "--list-cameras");
    camCheck.waitForFinished(5000);

    QString output = camCheck.readAllStandardOutput();
    return output.contains("Available cameras");
}

void CameraStreamer::startStreaming()
{
    if (!m_initialized) {
        qWarning() << "CameraStreamer not initialized";
        emit streamingError("Not initialized");
        return;
    }

    if (m_streaming) {
        qDebug() << "Already streaming";
        return;
    }

    QString pipeline = buildGStreamerPipeline();
    qDebug() << "Starting camera stream with pipeline:";
    qDebug() << "  " << pipeline;

    QStringList args;
    args << "-v" << "-e" << pipeline;

    m_gstProcess->start("gst-launch-1.0", args);
}

void CameraStreamer::stopStreaming()
{
    if (!m_streaming || !m_gstProcess) {
        return;
    }

    qDebug() << "Stopping camera stream...";

    // Send SIGINT for graceful shutdown
    m_gstProcess->terminate();

    // Wait for process to finish
    if (!m_gstProcess->waitForFinished(3000)) {
        qWarning() << "GStreamer process did not stop gracefully, killing...";
        m_gstProcess->kill();
        m_gstProcess->waitForFinished(1000);
    }
}

void CameraStreamer::onProcessStarted()
{
    m_streaming = true;
    qDebug() << "Camera streaming started to" << m_targetHost << ":" << m_targetPort;
    emit streamingStarted();
}

void CameraStreamer::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    m_streaming = false;

    if (exitStatus == QProcess::CrashExit) {
        qWarning() << "GStreamer process crashed with exit code:" << exitCode;
        emit streamingError(QString("Process crashed with code %1").arg(exitCode));
    } else {
        qDebug() << "Camera streaming stopped (exit code:" << exitCode << ")";
    }

    emit streamingStopped();
}

void CameraStreamer::onProcessError(QProcess::ProcessError error)
{
    QString errorMsg;
    switch (error) {
        case QProcess::FailedToStart:
            errorMsg = "Failed to start gst-launch-1.0";
            break;
        case QProcess::Crashed:
            errorMsg = "GStreamer process crashed";
            break;
        case QProcess::Timedout:
            errorMsg = "Process timeout";
            break;
        case QProcess::WriteError:
            errorMsg = "Write error";
            break;
        case QProcess::ReadError:
            errorMsg = "Read error";
            break;
        default:
            errorMsg = "Unknown error";
            break;
    }

    qCritical() << "CameraStreamer error:" << errorMsg;
    m_streaming = false;
    emit streamingError(errorMsg);
}

void CameraStreamer::onReadyReadStandardError()
{
    QString stderr = m_gstProcess->readAllStandardError();
    if (!stderr.isEmpty()) {
        // Filter out verbose GStreamer messages, only show warnings/errors
        QStringList lines = stderr.split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            if (line.contains("WARN") || line.contains("ERROR") || line.contains("CRITICAL")) {
                qWarning() << "GStreamer:" << line;
            }
        }
    }
}
