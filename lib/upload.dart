import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploader extends StatefulWidget {
  const CloudinaryUploader({super.key});

  @override
  CloudinaryUploaderState createState() => CloudinaryUploaderState();
}

class CloudinaryUploaderState extends State<CloudinaryUploader> {
  String? uploadedUrl;
  String? statusMessage;
  bool isUploading = false;

  // Cloudinary credentials
  final String cloudName = 'dxl7h8j1a';
  final String uploadPreset = 'talkgym_audio';

  Future<void> uploadAssetAudio() async {
    setState(() {
      isUploading = true;
      statusMessage = 'Loading asset...';
      uploadedUrl = null;
    });

    try {
      // Load audio file from assets
      final ByteData data = await rootBundle.load('assets/audio/recording.m4a');
      final Uint8List audioBytes = data.buffer.asUint8List();

      setState(() {
        statusMessage = 'Uploading to Cloudinary...';
      });

      // Upload to Cloudinary
      var uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', audioBytes, filename: 'recording.m4a'),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var resString = await response.stream.bytesToString();
        var data = jsonDecode(resString);
        setState(() {
          uploadedUrl = data['secure_url'];
          statusMessage = 'Upload successful!';
          isUploading = false;
        });
        debugPrint('✓ Upload successful: ${data['secure_url']}');
      } else {
        setState(() {
          statusMessage = 'Upload failed: HTTP ${response.statusCode}';
          isUploading = false;
        });
        debugPrint('✗ Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error: $e';
        isUploading = false;
      });
      debugPrint('✗ Error uploading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloudinary Upload Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Upload assets/audio/recording.m4a to Cloudinary',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: isUploading ? null : uploadAssetAudio,
              child: Text(isUploading ? 'Uploading...' : 'Upload Audio'),
            ),
            const SizedBox(height: 20),
            if (statusMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            if (uploadedUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Uploaded URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      uploadedUrl!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}