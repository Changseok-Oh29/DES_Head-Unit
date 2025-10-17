#include <SPI.h>
#include <mcp2515.h>

#define SLAVE_ID 0x0F6
#define PIN_OUT 3
#define CUSTOM_DELAY 100               // Measurement interval [ms]
#define WHEEL_CIRCUMFERENCE_CM 20.083  // Wheel circumference [cm]
#define PULSES_PER_REV 20              // Pulses per revolution

MCP2515 mcp2515(9);
volatile unsigned int pulseCount = 0;
struct can_frame canMsg;

// Interrupt function for pulse counting
void isrCount() {
  pulseCount++;
}

void setup() {
  Serial.begin(115200);

  // Initialize CAN
  mcp2515.reset();
  mcp2515.setBitrate(CAN_1000KBPS, MCP_16MHZ);
  mcp2515.setNormalMode();

  // Configure pulse input pin and interrupt
  pinMode(PIN_OUT, INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_OUT), isrCount, RISING);

  // Initialize CAN message
  canMsg.can_id = SLAVE_ID;
  canMsg.can_dlc = 8;
  memset(canMsg.data, 0x00, 8);
}

void loop() {
  // Infinite loop
  while (true) {
    unsigned long startTime = millis();
    delay(CUSTOM_DELAY);  // Wait for fixed interval

    // Copy and reset pulse count during measurement period
    noInterrupts();
    unsigned int pulses = pulseCount;
    pulseCount = 0;
    interrupts();

    // Calculate time interval
    float intervalSec = CUSTOM_DELAY / 1000.0;

    // Calculate revolutions and speed
    float revs = pulses / (float)PULSES_PER_REV;
    float rpm = (revs / intervalSec) * 60;
    float speed = revs * WHEEL_CIRCUMFERENCE_CM / intervalSec;

    // Split speed value for CAN transmission
    int int1_spd = speed;
    int int2_spd = round((speed - int1_spd) * 100);

    canMsg.data[0] = int1_spd / 256;
    canMsg.data[1] = int1_spd % 256;
    canMsg.data[2] = int2_spd;

    // Send CAN message
    mcp2515.sendMessage(&canMsg);
  }
}
