🧠 Smartwatch Health Monitoring with GRU (On-Device AI)
A smartwatch and Android-based health monitoring app that uses machine learning (GRU) to detect the user’s condition in real time, such as relaxation (baseline), stress, and amusement.
This system employs on-device inference, so the analysis process is performed directly on the Android device without relying on a server.
🚀 Key Features
📊 Real-time heart rate monitoring
🏃 Physical activity tracking (Accelerometer X, Y, Z)
🧠 User condition prediction using the GRU Model
⚡ On-device inference (serverless)
☁️ Data synchronization to Firebase Cloud Firestore
📈 Data visualization (graphs & health status)
🔔 Adaptive health recommendation notifications
🏗️ System Architecture
Smartwatch (Sensor)
        ↓
Wear OS Data Layer API
        ↓
Android App
        ↓
Data Preprocessing
        ↓
GRU Model (TensorFlow Lite)
        ↓
UI (Graphs & Notifications)
        ↓
Firebase Firestore (Storage)
🧪 Technologies Used
Android (Kotlin / Flutter)
Wear OS Data Layer API
TensorFlow Lite (GRU Model)
Firebase Cloud Firestore
Machine Learning (Time Series Analysis)


Translated with DeepL.com (free version)
