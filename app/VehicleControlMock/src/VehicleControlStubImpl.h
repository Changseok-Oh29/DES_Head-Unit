#ifndef VEHICLECONTROLSTUBIMPL_H
#define VEHICLECONTROLSTUBIMPL_H

#include <CommonAPI/CommonAPI.hpp>
#include <v1/vehiclecontrol/VehicleControlStubDefault.hpp>
#include <QObject>
#include <QTimer>
#include <QDebug>

using namespace v1::vehiclecontrol;

class VehicleControlStubImpl : public QObject, public VehicleControlStubDefault {
    Q_OBJECT

public:
    VehicleControlStubImpl();
    virtual ~VehicleControlStubImpl();

    // RPC method implementation
    virtual void setGearPosition(const std::shared_ptr<CommonAPI::ClientId> _client,
                                std::string _gear,
                                setGearPositionReply_t _reply) override;

private slots:
    void broadcastVehicleState();

private:
    std::string m_currentGear;
    uint16_t m_speed;
    uint8_t m_battery;
    QTimer* m_stateTimer;
};

#endif // VEHICLECONTROLSTUBIMPL_H
