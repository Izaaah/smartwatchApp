# Backend Integration Guide

Frontend sudah terhubung dengan backend! Berikut panduan untuk setup dan penggunaan.

## Setup

### 1. Install Dependencies

```bash
cd frontend
flutter pub get
```

### 2. Konfigurasi API Base URL

Edit file `lib/config/api_config.dart` dan sesuaikan `baseUrl`:

```dart
// Untuk Android Emulator
static const String baseUrl = 'http://10.0.2.2:8080';

// Untuk iOS Simulator
static const String baseUrl = 'http://localhost:8080';

// Untuk Physical Device (ganti dengan IP komputer Anda)
static const String baseUrl = 'http://192.168.1.100:8080';
```

**Cara menemukan IP komputer:**
- Windows: `ipconfig` di Command Prompt
- Mac/Linux: `ifconfig` atau `ip addr`

### 3. Pastikan Backend Berjalan

```bash
cd backend
go run cmd/server/main.go
```

Backend harus berjalan di `http://localhost:8080`

## Fitur yang Sudah Terintegrasi

### ✅ Authentication
- **Login**: Terhubung ke `/api/users/login`
- **Register**: Terhubung ke `/api/users/register`
- **Token Storage**: Token JWT disimpan di SharedPreferences
- **Auto Login**: Token tersimpan untuk session berikutnya

### ✅ Health Data
- **Dashboard**: Menampilkan data kesehatan terbaru dari API
- **Stats**: Menampilkan statistik harian dari backend
- **Real-time Data**: Data diambil dari endpoint `/api/health`

## Struktur File

```
frontend/lib/
├── config/
│   └── api_config.dart          # Konfigurasi API base URL
├── models/
│   ├── user.dart                # Model User & Request/Response
│   └── health_data.dart         # Model Health Data & Stats
├── services/
│   ├── api_service.dart         # Service untuk API calls
│   └── auth_service.dart        # Service untuk token management
└── screens/
    ├── login.dart               # ✅ Terintegrasi dengan API
    ├── register.dart            # ✅ Terintegrasi dengan API
    └── dashboard_main.dart      # ✅ Fetch data dari API
```

## Testing

### 1. Test Login
1. Buka aplikasi
2. Login dengan user yang sudah ada di database
3. Token akan tersimpan otomatis

### 2. Test Register
1. Buka aplikasi
2. Klik "Sign Up"
3. Isi semua field (termasuk username, age, gender, height, weight)
4. Submit
5. Login dengan akun baru

### 3. Test Dashboard
1. Setelah login, dashboard akan otomatis fetch data
2. Data akan ditampilkan dari backend
3. Jika tidak ada data, akan menampilkan 0 atau nilai default

## Troubleshooting

### Error: "Connection refused"
- Pastikan backend berjalan
- Cek base URL di `api_config.dart`
- Untuk physical device, pastikan IP benar dan device terhubung ke WiFi yang sama

### Error: "Failed to get health data"
- Pastikan sudah login (token tersimpan)
- Cek apakah ada data di database
- Jalankan seed data: `go run backend/scripts/seed_data.go`

### Data tidak muncul di dashboard
- Cek console untuk error
- Pastikan backend mengembalikan data dalam format yang benar
- Cek response di Network tab (jika menggunakan browser)

### Token expired
- Logout dan login lagi
- Token JWT default expire setelah 24 jam

## Next Steps

Untuk menambahkan fitur baru:

1. **Tambah endpoint baru di backend**
2. **Tambah method di `api_service.dart`**
3. **Update screen untuk menggunakan method baru**

Contoh menambah fitur create health data:

```dart
// Di api_service.dart sudah ada:
static Future<ApiResponse<HealthData>> createHealthData(
  HealthDataRequest request,
) async { ... }

// Gunakan di screen:
final response = await ApiService.createHealthData(
  HealthDataRequest(
    heartRate: 72,
    steps: 8500,
    calories: 2200.0,
    sleepHours: 7.5,
    bloodOxygen: 98,
  ),
);
```

## Catatan Penting

- **CORS**: Backend sudah dikonfigurasi untuk menerima request dari frontend
- **Authentication**: Semua endpoint health data memerlukan JWT token
- **Error Handling**: Semua API calls sudah ada error handling
- **Loading States**: UI menampilkan loading indicator saat fetch data


