<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/user-attachments/assets/5e8e7a00-fb0d-4f77-b3b5-35b25f44d6fc">
  <source media="(prefers-color-scheme: light)" srcset="https://github.com/user-attachments/assets/bd3ab72c-a642-49b1-82c2-9f9e661f0bfa">
  <img alt="Header" height="80" >
</picture>
</div>

<img src="https://github.com/user-attachments/assets/d37a62f7-650a-4886-81c9-d3809d3ddeed" width="100%" height="2px"/>
<p/>

**UNP Connect** adalah aplikasi mobile berbasis Flutter yang dirancang sebagai platform berita dan sosial untuk Universitas Negeri Padang. Aplikasi ini memungkinkan mahasiswa, dosen, dan admin untuk berbagi informasi, berita kampus, dan artikel mahasiswa, serta berinteraksi melalui sistem follow.

## 📱 Fitur Utama

-   **Autentikasi & Otorisasi**: Login aman dengan validasi role (Mahasiswa, Dosen, Admin, Tamu).
-   **Berita Kampus & Mahasiswa**:
    -   *Dosen* dapat memposting berita resmi kampus.
    -   *Mahasiswa Ganto* dapat memposting artikel mahasiswa.
    -   Semua pengguna dapat membaca, mencari, dan melihat detail postingan.
-   **Sistem Sosial**:
    -   Melihat profil pengguna lain.
    -   Follow/Unfollow pengguna.
    -   Melihat daftar Followers dan Following.
-   **Manajemen Profil**: Edit foto profil, ubah informasi pribadi.
-   **Admin Dashboard**: Statistik pengguna dan postingan (khusus role Admin).

## 🛠️ Tech Stack

-   **Frontend**: Flutter (Dart)
-   **Backend**: Firebase (Firestore Database)
-   **Storage**: Cloudinary (Image Storage)
-   **State Management**: `setState` & `StreamBuilder` (Architecture Simplicity)

---

## 🚀 Panduan Instalasi & Setup

Ikuti langkah-langkah berikut untuk menjalankan aplikasi ini di lokal.

### 1. Clone & Install Dependencies

```bash
git clone https://github.com/username/unp-connect.git
cd unp_connect
flutter pub get
```

### 2. Setup Firebase

Aplikasi ini menggunakan Firebase sebagai backend utama.

1.  Buka [Firebase Console](https://console.firebase.google.com/).
2.  Buat project baru.
3.  **Firestore Database**: Koneksikan Firestore Database sesuai instruksi yang ada di Firebase.

### 3. Setup Cloudinary

Aplikasi ini menggunakan Cloudinary untuk menyimpan gambar (foto profil, thumbnail postingan).

1.  Daftar akun di [Cloudinary](https://cloudinary.com/).
2.  Dapatkan **Cloud Name** Anda dari dashboard (misal: `bv7w23nXX`).
3.  Pergi ke **Settings** -> **Upload** -> **Upload presets**.
4.  Buat **4 Unsigned Upload Preset** dengan konfigurasi berikut:

| Preset Name | Folder | Keterangan |
| :--- | :--- | :--- |
| `user-foto-profil` | `unp-connect/user-foto-profil` | Foto profil pengguna |
| `unp-connect_berita-dosen` | `unp-connect/berita-kampus` | Berita dari Dosen |
| `unp-connect_berita-mahasiswa` | `unp-connect/berita-mahasiswa` | Berita dari Mahasiswa Ganto |
| `pengajuan-ganto` | `unp-connect/pengajuan-ganto` | Bukti pendaftaran Ganto |

**Setting Detail untuk Setiap Preset:**
-   **Signing Mode**: `Unsigned`
-   **Use filename or external ID as public ID**: `Off` (False)
-   **Unique filename**: `Off` (False)
-   **Use filename as display name**: `On` (True)
-   **Asset Folder Pattern**: Sesuai tabel di atas (misal: `unp-connect/user-foto-profil`)

### 4. Konfigurasi Environment Variables (.env)

Buat file `.env` di root direktori project (sejajar dengan `pubspec.yaml`) dan masukkan konfigurasi berikut (sesuaikan dengan `cloud_name` dari dashboard Cloudinary Anda, misal: `bv7w23nXX`):

```env
CLOUDINARY_CLOUD_NAME=nama_cloud_kamu_disini
```

> **Catatan**: Pastikan `.env` sudah terdaftar di `pubspec.yaml` di bagian assets (sudah dikonfigurasi secara default di repo ini).

### 5. Jalankan Aplikasi

Pastikan emulator atau device fisik terhubung.

```bash
flutter run
```

---

## 📂 Struktur Folder

-   `lib/main.dart`: Entry point aplikasi.
-   `lib/home.dart`: Halaman utama dengan Bottom Navigation Bar.
-   `lib/auth/`: Halaman autentikasi (`HalamanLogin`).
-   `lib/models/`: Data model (`UserModel`, `PostinganModel`).
-   `lib/pages/`: Halaman-halaman konten (Beranda, Profil, Postingan Kampus/Mahasiswa).
-   `lib/postingan/`: Halaman detail & aksi postingan (Tambah, Lihat, Edit).
-   `lib/services/`: Logic backend (`FirestoreService`, `UserSession`, `CloudinaryService`).
-   `lib/utils/`: Widget reusable (Card, TextFields).
-   `lib/theme.dart`: Konfigurasi warna, font, dan style.

---

## 📁 Struktur Dokumen Firebase

Aplikasi ini menggunakan Cloud Firestore dengan struktur koleksi dan dokumen sebagai berikut:

### 1. Struktur Dokumen (Format Tabel)

| Nama Koleksi | Deskripsi | Field Utama (Document Fields) |
| :--- | :--- | :--- |
| `users` | Data profil pengguna | `uid`, `nama`, `password`, `fotoProfil`, `bio`, `fakultas`, `prodi`, `role`, `statusVerifikasiGanto`, `buktiKeanggotaan`, `listFollowers`, `listFollowing`, `listPostingan` |
| `berita_kampus` | Berita resmi dari Dosen | `id`, `judul`, `thumbnail`, `deskripsi`, `uidPengunggah`, `createdAt`, `views`, `viewedBy`, `tag` |
| `berita_mahasiswa` | Artikel dari Mahasiswa | `id`, `judul`, `thumbnail`, `deskripsi`, `uidPengunggah`, `createdAt`, `views`, `viewedBy`, `fakultas`, `prodi` |

---

## 👥 Role Pengguna

1.  **Admin (`admin`)**: Akses dashboard statistik.
2.  **Dosen (`dosen`)**: Posting ke `berita_kampus`.
3.  **Mahasiswa Ganto (`mhs-ganto`)**: Posting ke `berita_mahasiswa`, verifikasi otomatis.
4.  **Mahasiswa Guest (`mhs-guest`)**: User biasa, read-only untuk postingan (bisa follow & edit profil).

---

Dibuat dalam rangka pemenuhan tugas akhir mata kuliah Interaksi Manusia Komputer Universitas Negeri Padang.
