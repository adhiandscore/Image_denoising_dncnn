Terima kasih, Thank you kepada bro @lychengrex yang sudah memberikan arahan project ini melalui akun githubnya


# denoise_app
## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## ini adalah project Penurunan Noise berbasis Android yang dibuat sebagai Tugas Akhir dan syarat kelulusan serta untuk meraih Strata Satu (S1) Program Studi Teknik Informatika Fakultas Teknik dan Ilmu komputer Universitas Sains Al Qur'an Jawa Tengah di Wonosobo

## Untuk informasi instalasi dan penggunaan aplikasi mobile penurunan noise ini bisa dilihat pada tahap - tahap dibawah ini :
Proses instalasi dibagi menjadi 3 bagian, instalasi mobile (flutter), instalasi Server menggunakan Google Colab dan instalasi menggunakan Ngrok

instalasi mobile 
1. Download flutter SDK dari www.flutter.dev kemudian install sesuai petunjuk
2. Instalasi code editor
3. buka file main.dart
4. cari file yang bernama final url = Uri.parse(
        'publicUrlAnda/endpoint'); 

instalasi server Google Colab
1. buka google colab notebook
2. sambungkan dengan runtime cpu atau GPU jika tersedia
3. siapkan file checkpoint, biasanya setelah melalui training, anda akan mendapatkan file checkpoint yang berisi bobot pelatihan,
   jika anda belum sempat untuk memulai pelatihan, anda bisa menggunakan file checkpoint yang tersedia di main folder ini 
5. jalan kan perintah berikut :
6. !git clone https://github.com/lychengr3x/Image-Denoising-with-Deep-CNNs.git,
7. cd Image-Denoising-with-Deep-CNNs,
8. cd src,
9. !pip install pyngrok
10. jalankan perintah untuk mendapatkan authtoken untuk mengakses server tunneling ngrok.

   import getpass
   from pyngrok import ngrok, conf

   print("Masukkan auth token, harus login ke   https://dashboard.ngrok.com/auth")
   conf.get_default().auth_token = getpass.getpass()

11. instalasi flask : 
   !pip install flask flask_cors

12. import checkpoint
   import torch

   checkpoint_path ='/alamat/ke/checkpoint.pth'
   checkpoinr = torch.load(checkpoint_path)

   #periksa keys untuk membuka check point
   print(checkpoint['Net'].keys())
   
   copy paste skrip flask yang ada pada main folder ini untuk menjalankan backbone model di server google colab
    

    
