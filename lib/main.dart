import 'dart:io';
import 'dart:core';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImagePickerScreen(),
    );
  }
}

class ImagePickerScreen extends StatefulWidget {
  @override
  _ImagePickerScreenState createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? _selectedImage;
  String _uploadStatus = '';
  String _processedImageUrl = '';
  double _originalPsnr = 0.0;
  double _processedPsnr = 0.0;
  bool _showProcessedMessage = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _uploadStatus = ''; // Clear upload status when new image is picked
        _processedImageUrl = ''; // Clear processed image URL
        _originalPsnr = 0.0; // Clear PSNR value
        _processedPsnr = 0.0; // Clear PSNR value
        _showProcessedMessage = false; // Hide processed message
      });

      // Log image dimensions
      final image =
          await decodeImageFromList(await _selectedImage!.readAsBytes());
      print('Selected image dimensions: ${image.width} x ${image.height}');
    } else {
      print('No image selected.');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      setState(() {
        _uploadStatus = 'Error: No image selected';
      });
      return;
    }

    final url = Uri.parse(
        'https://0106-35-245-125-75.ngrok-free.app/upload'); // Replace with your ngrok URL
    final request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      _selectedImage!.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Response data: $responseData'); // Log response data

        if (responseData != null && responseData is Map) {
          String? publicUrl = responseData['public_url'];
          double? originalPsnrValue = responseData['original_psnr'] != null
              ? (responseData['original_psnr'] as num).toDouble()
              : null;
          double? processedPsnrValue = responseData['processed_psnr'] != null
              ? (responseData['processed_psnr'] as num).toDouble()
              : null;

          if (publicUrl != null &&
              originalPsnrValue != null &&
              processedPsnrValue != null) {
            setState(() {
              _uploadStatus = 'Image uploaded successfully';
              _processedImageUrl = publicUrl;
              _originalPsnr = originalPsnrValue;
              _processedPsnr = processedPsnrValue;
              _showProcessedMessage = true;
            });
          } else {
            setState(() {
              _uploadStatus = 'Error: Null values in response';
              _processedImageUrl = '';
              _originalPsnr = 0.0;
              _processedPsnr = 0.0;
            });
            print(
                'Null values: public_url = $publicUrl, original_psnr = $originalPsnrValue, processed_psnr = $processedPsnrValue');
          }
        } else {
          setState(() {
            _uploadStatus = 'Error: Invalid response structure';
            _processedImageUrl = '';
            _originalPsnr = 0.0;
            _processedPsnr = 0.0;
          });
          print('Invalid response structure: $responseData');
        }
      } else {
        setState(() {
          _uploadStatus = 'Image upload failed';
          _processedImageUrl = '';
          _originalPsnr = 0.0;
          _processedPsnr = 0.0;
        });
        print('Image upload failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: $e';
        _processedImageUrl = '';
        _originalPsnr = 0.0;
        _processedPsnr = 0.0;
      });
      print('Error uploading image: $e');
    }
  }

  Future<void> _downloadProcessedImage() async {
    if (_processedImageUrl.isEmpty) {
      setState(() {
        _uploadStatus = 'Error: No processed image available for download';
      });
      return;
    }

    try {
      // Get the directory to save the file
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        setState(() {
          _uploadStatus = 'Error: Unable to access storage directory';
        });
        return;
      }

      // Create directory if it does not exist
      final processedDir = Directory('${directory.path}/Download');
      if (!await processedDir.exists()) {
        await processedDir.create(recursive: true);
      }

      // Download the image
      final response = await http.get(Uri.parse(_processedImageUrl));
      if (response.statusCode == 200) {
        final filePath = '${processedDir.path}/processed_image.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _uploadStatus = 'Image downloaded successfully to $filePath';
        });
      } else {
        setState(() {
          _uploadStatus = 'Error: Failed to download image';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: $e';
      });
      print('Error downloading image: $e');
    }
  }

  void _reset() {
    setState(() {
      _selectedImage = null;
      _uploadStatus = '';
      _processedImageUrl = '';
      _originalPsnr = 0.0;
      _processedPsnr = 0.0;
      _showProcessedMessage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MIDA, Mobile Image Denoiser App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.gallery),
                child: Text('Pilih Gambar dari Galeri'),
              ),
              ElevatedButton(
                onPressed: () => _pickImage(ImageSource.camera),
                child: Text('Ambil Gambar dari Kamera'),
              ),
              SizedBox(height: 20),
              _selectedImage != null
                  ? Column(
                      children: [
                        Text('Gambar Sebelum'),
                        SizedBox(height: 10),
                        Image.file(
                          _selectedImage!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(height: 10),
                        _originalPsnr != 0.0
                            ? Text('PSNR Awal: $_originalPsnr')
                            : Container(),
                      ],
                    )
                  : Container(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Gambar'),
              ),
              SizedBox(height: 20),
              _showProcessedMessage
                  ? Column(
                      children: [
                        _processedPsnr != 0.0
                            ? Text('PSNR Setelah Pemrosesan: $_processedPsnr')
                            : Container(),
                        SizedBox(height: 10),
                        _processedImageUrl.isNotEmpty
                            ? Column(
                                children: [
                                  Text('Gambar Setelah'),
                                  SizedBox(height: 10),
                                  Image.network(
                                    _processedImageUrl,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _downloadProcessedImage,
                                    child: Text('Download Gambar'),
                                  ),
                                ],
                              )
                            : Container(),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _reset,
                          child: Text('OK'),
                        ),
                      ],
                    )
                  : Container(),
              SizedBox(height: 20),
              Text(_uploadStatus),
            ],
          ),
        ),
      ),
    );
  }
}
