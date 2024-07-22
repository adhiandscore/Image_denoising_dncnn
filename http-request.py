from flask import Flask, request, jsonify
import torch
from PIL import Image
import io
from model import DnCNN

app = Flask(__name__)

# Inisialisasi model dan muat checkpoint yang telah disimpan
D = 6
model = DnCNN(D)  # Sesuaikan parameter sesuai dengan model Anda
checkpoint = torch.load('checkpoint.pth.tar', map_location=torch.device('cpu'))
model.load_state_dict(checkpoint['model_state_dict'])
model.eval()

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Baca file gambar
    img = Image.open(io.BytesIO(file.read()))

    # Preprocess gambar dan lakukan inferensi
    input_data = preprocess_image(img)  # Implementasikan fungsi ini sesuai kebutuhan
    output = model(input_data)

    return jsonify({'output': output.tolist()})  # Konversi output ke list jika berupa tensor

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)