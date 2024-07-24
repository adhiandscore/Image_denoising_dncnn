# denoise_app

A new Flutter project.

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

instalasi server Google Colab
1. buka google colab notebook
2. sambungkan dengan runtime cpu atau GPU jika tersedia
3. siapkan file checkpoint, biasanya setelah melalui training, anda akan mendapatkan file checkpoint yang berisi bobot pelatihan,
   jika anda belum sempat untuk memulai pelatihan, anda bisa menggunakan file checkpoint yang tersedia di main folder ini 
5. jalan kan perintah berikut :
   a. !git clone https://github.com/lychengr3x/Image-Denoising-with-Deep-CNNs.git
   b. cd Image-Denoising-with-Deep-CNNs
   c. cd src
   d. !pip install pyngrok
6. jalankan perintah untuk mendapatkan authtoken untuk mengakses server tunneling ngrok.

   import getpass
   from pyngrok import ngrok, conf

   print("Masukkan auth token, harus login ke   https://dashboard.ngrok.com/auth")
conf.get_default().auth_token = getpass.getpass()

7. instalasi flask : 
   !pip install flask flask_cors

8. import checkpoint
   import torch

   checkpoint_path ='/alamat/ke/checkpoint.pth'
   checkpoinr = torch.load(checkpoint_path)

   #periksa keys untuk membuka check point
   print(checkpoint['Net'].keys())
9. #copy paste skrip flask ini untuk menjalankan backbone model di server google colab

import os
import numpy as np
import torch
from torch import nn
from torch.nn import functional as F
from PIL import Image
from flask import Flask, request, jsonify, send_from_directory
import uuid
import torchvision.transforms as transforms
from skimage.metrics import peak_signal_noise_ratio as psnr
from werkzeug.utils import secure_filename
from logging.handlers import RotatingFileHandler
import logging
from pyngrok import ngrok

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Configure logging
handler = RotatingFileHandler('app.log', maxBytes=10000, backupCount=1)
handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
app.logger.addHandler(handler)
logging.basicConfig(level=logging.INFO)

class DUDnCNN(nn.Module):
    def __init__(self, D, C=64):
        super(DUDnCNN, self).__init__()
        self.D = D

        k = [0]
        k.extend([i for i in range(D//2)])
        k.extend([k[-1] for _ in range(D//2, D+1)])
        l = [0 for _ in range(D//2+1)]
        l.extend([i for i in range(D+1-(D//2+1))])
        l.append(l[-1])

        holes = [2**(kl[0]-kl[1])-1 for kl in zip(k, l)]
        dilations = [i+1 for i in holes]

        self.conv = nn.ModuleList()
        self.conv.append(nn.Conv2d(3, C, 3, padding=dilations[0], dilation=dilations[0]))
        self.conv.extend([nn.Conv2d(C, C, 3, padding=dilations[i+1], dilation=dilations[i+1]) for i in range(D)])
        self.conv.append(nn.Conv2d(C, 3, 3, padding=dilations[-1], dilation=dilations[-1]))

        for i in range(len(self.conv[:-1])):
            nn.init.kaiming_normal_(self.conv[i].weight.data, nonlinearity='relu')

        self.bn = nn.ModuleList()
        self.bn.extend([nn.BatchNorm2d(C, C) for _ in range(D)])
        for i in range(D):
            nn.init.constant_(self.bn[i].weight.data, 1.25 * np.sqrt(C))

    def forward(self, x):
        D = self.D
        h = F.relu(self.conv[0](x))
        h_buff = []

        for i in range(D//2 - 1):
            torch.backends.cudnn.benchmark = True
            h = self.conv[i+1](h)
            torch.backends.cudnn.benchmark = False
            h = F.relu(self.bn[i](h))
            h_buff.append(h)

        for i in range(D//2 - 1, D//2 + 1):
            torch.backends.cudnn.benchmark = True
            h = self.conv[i+1](h)
            torch.backends.cudnn.benchmark = False
            h = F.relu(self.bn[i](h))

        for i in range(D//2 + 1, D):
            j = i - (D//2 + 1) + 1
            torch.backends.cudnn.benchmark = True
            h = self.conv[i+1]((h + h_buff[-j]) / np.sqrt(2))
            torch.backends.cudnn.benchmark = False
            h = F.relu(self.bn[i](h))

        y = self.conv[D+1](h) + x
        return y

    def criterion(self, y, d):
        return nn.MSELoss()(y, d)

model = DUDnCNN(D=6, C=64)
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = model.to(device)
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

checkpoint_path = '/content/Image-Denoising-with-Deep-CNNs/src/(nama checkpoint anda).pth.tar'
checkpoint = torch.load(checkpoint_path, map_location=device)
model.load_state_dict(checkpoint['Net'])
optimizer.load_state_dict(checkpoint['Optimizer'])

model.eval()

def preprocess_image(img):
    # Resize image to 1024x1024
    img = img.resize((1024, 1024), Image.BILINEAR)

    # Perform center cropping to 1024x1024
    transform = transforms.Compose([
        transforms.CenterCrop(1024),  # Center crop to 1024x1024
        transforms.ToTensor(),  # Convert PIL image to PyTorch tensor
        transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
    ])
    # Apply transformations to the image
    img_tensor = transform(img)

    # Unsqueeze to add the batch dimension
    img_tensor = img_tensor.unsqueeze(0).to(device)

    return img_tensor
    return img_tensor



def denormalize(tensor):
    # Inverse of the normalization process
    inv_normalize = transforms.Normalize(
        mean=[-1, -1, -1],
        std=[2, 2, 2]
    )
    return inv_normalize(tensor[0]).clamp(0, 1)

@app.route('/upload', methods=['POST'])
def upload_file():
    try:
        app.logger.info('Upload file endpoint called')
        if 'file' not in request.files:
            return jsonify({'status': 'failed', 'message': 'No file part'}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({'status': 'failed', 'message': 'No selected file'}), 400

        filename = secure_filename(file.filename)
        file_path = os.path.join(UPLOAD_FOLDER, filename)
        file.save(file_path)

        image = Image.open(file_path).convert('RGB')
        app.logger.info(f'Input image dimensions: {image.size}')

        # Resize image to the smallest dimension to ensure the center crop is valid
        min_dimension = min(image.size)
        image = image.resize((min_dimension, min_dimension), Image.BILINEAR)

        # Preprocess image for model input using center cropping
        image_tensor = preprocess_image(image)

        # Perform inference
        with torch.no_grad():
            output = model(image_tensor)

        # Denormalize the output tensor
        output_image_tensor = denormalize(output.cpu().detach())

        # Convert denormalized tensor back to PIL image
        output_image = transforms.ToPILImage()(output_image_tensor)

        processed_filename = str(uuid.uuid4()) + '.png'
        processed_file_path = os.path.join(UPLOAD_FOLDER, processed_filename)
        output_image.save(processed_file_path)

        # Crop the original image to 512x512 to match the processed image size
        original_cropped = transforms.CenterCrop(1024)(image)

        # Calculate PSNR for original image with itself
        original_psnr = psnr(np.array(original_cropped), np.array(original_cropped))
        if np.isinf(original_psnr) or original_psnr > 30:
            original_psnr = 30  # Set to maximum allowed PSNR value if it's infinite or greater than 30

        # Calculate PSNR between the original cropped image and the processed image
        processed_psnr = psnr(np.array(original_cropped), np.array(output_image))
        if np.isinf(processed_psnr) or processed_psnr > 30:
            processed_psnr = 30  # Set to maximum allowed PSNR value if it's infinite or greater than 30

        public_url = request.host_url + 'uploads/' + processed_filename

        return jsonify({
            'status': 'success',
            'message': 'File successfully uploaded and processed',
            'public_url': public_url,
            'original_psnr': original_psnr,
            'processed_psnr': processed_psnr
        }), 200

    except Exception as e:
        app.logger.error(f'Error during file upload: {str(e)}')
        return jsonify({'status': 'failed', 'message': str(e)}), 500

@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)


if __name__ == '__main__':
    public_url = ngrok.connect(5000).public_url
    app.logger.info(f"ngrok tunnel opened at {public_url}")
    print(f" * ngrok tunnel \"{public_url}\" -> \"http://127.0.0.1:5000\"")
    app.run()



 
