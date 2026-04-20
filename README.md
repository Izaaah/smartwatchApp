# 🧠 Smartwatch Health Monitoring with GRU (On-Device AI)

A wearable-based health monitoring application that utilizes **smartwatch sensors and Android devices** combined with **machine learning (GRU)** to detect user conditions in real-time such as **relax (baseline), stress, and amusement**.

This system implements **on-device inference**, meaning all analysis is performed directly on the Android device without relying on a remote server.

---

## 🚀 Key Features

* 📊 Real-time **Heart Rate Monitoring**
* 🏃 Physical activity tracking using **Accelerometer (X, Y, Z)**
* 🧠 User condition prediction using **GRU Model**
* ⚡ **On-device inference** (no server required)
* ☁️ Data synchronization with **Firebase Cloud Firestore**
* 📈 Data visualization (charts & health status)
* 🔔 Adaptive health recommendation notifications

---

## 🏗️ System Architecture

```text
Smartwatch (Sensors)
        ↓
Wear OS Data Layer API
        ↓
Android Application
        ↓
Data Preprocessing
        ↓
GRU Model (TensorFlow Lite)
        ↓
User Interface (Charts & Notifications)
        ↓
Firebase Firestore (Storage)
```

---

## 🧪 Technologies Used

* **Android (Kotlin / Flutter)**
* **Wear OS Data Layer API**
* **TensorFlow Lite (GRU Model)**
* **Firebase Cloud Firestore**
* **Machine Learning (Time-Series Analysis)**

---

## 📊 Dataset

The GRU model is trained using a public dataset:

* **WESAD (Wearable Stress and Affect Detection Dataset)**
* Includes physiological signals such as heart rate, accelerometer, etc.
* Used for pretraining before deployment to the mobile application

---

## ⚙️ System Workflow

1. The smartwatch collects sensor data (heart rate & accelerometer)
2. Data is sent to the Android app via Wear OS Data Layer
3. The app performs data preprocessing
4. The GRU model analyzes the data in real-time
5. Predictions are displayed to the user
6. Data and results are stored in Firebase

---

## 🧠 Machine Learning Model

* Model: **Gated Recurrent Unit (GRU)**
* Input:

  * Heart Rate
  * Accelerometer (X, Y, Z)
* Output:

  * Relax (Baseline)
  * Stress
  * Amusement

### Advantages:

* Suitable for **time-series data**
* Lighter and more efficient than LSTM
* Optimized for **mobile / on-device inference**

---

## 📦 Project Structure

```text
📁 smartwatch-app
📁 android-app
📁 model
   ├── training (Python)
   ├── model.tflite
📁 firebase
📄 README.md
```

---

## 🔐 Privacy & Security

* Data is processed locally on the device (**on-device inference**)
* No dependency on external servers for analysis
* Firebase is used only for storing user history
* All data collection requires user consent

---

## 📌 Use Cases

* Daily health monitoring
* Early stress detection
* Activity recognition
* AI-based wearable health system

---

## 📈 Future Improvements

* Additional sensors (SpO2, EDA, body temperature)
* More advanced models (Hybrid / Transformer-based)
* Integration with digital health platforms
* Personalized models per user

---

## 👨‍💻 Author

Developed by: **Izaaah**
Project: Undergraduate Thesis / Research on Wearable Health Monitoring

---

## ⭐ Notes

This project is developed for research purposes in wearable health monitoring and AI-based systems.
