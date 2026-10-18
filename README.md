
# 🌤️ IoT Weather Station

An end-to-end **IoT Environmental Monitoring & Automated Alert System** developed by **Aswin S Pillai**. 

This project reads real-time environmental data (Temperature and Humidity) using an ESP32 microcontroller, transmits sensor readings over Wi-Fi to a cloud platform, displays live metrics and historical trend graphs, and triggers immediate multi-channel alerts (Email & Push Notifications) when thresholds are breached.

---

## 📌 Project Features

* **Real-Time Data Acquisition:** Continuous sensing of ambient temperature and humidity.
* **Wi-Fi & Cloud Telemetry:** Live data transmission to cloud dashboards via Wi-Fi.
* **Interactive Dashboards:** Visual trend graphs for temperature and humidity tracking.
* **Automated Alert Engine:** Instant automated email notifications and alert history logging when threshold conditions are triggered.
* **Virtual Simulation:** Simulated circuit design tested via Wokwi.

---

## 🛠️ Hardware & Software Stack

### Hardware & Circuit Components
* **Microcontroller:** ESP32 / Arduino Wi-Fi-enabled board
* **Sensors:** DHT Series (DHT11/DHT22) Temperature & Humidity Sensor
* **Wiring & Peripherals:** Breadboard, Connecting Jumpers, Power Supply

### Software & Cloud
* **Embedded Software:** Arduino C++ (`Source Code.ino`)
* **Simulation Platform:** Wokwi Circuit Simulator
* **Cloud & Telemetry:** Cloud Transmission & Visual Analytics Engine
* **Notification Service:** Email Alert Trigger System[cite: 28]

---

## 📊 System Architecture & Workflow

```text
  +------------------+         Wi-Fi          +-----------------------+
  |  DHT Sensor      |  ------------------->  |  Cloud Telemetry      |
  |  (Temp & Hum)    |                        |  & Storage            |
  +--------+---------+                        +-----------+-----------+
           |                                              |
           v                                              v
  +------------------+                        +-----------------------+
  |  ESP32 Board     |                        |  Dashboard Visuals    |
  |  (Read & Process)|                        |  (Graphs & Analytics) |
  +--------+---------+                        +-----------+-----------+
           |                                              |
           +-----------> [ Breached? ] ------------------+
                             | (Yes)
                             v
                  +---------------------+
                  | Email Alert Trigger |
                  +---------------------+
