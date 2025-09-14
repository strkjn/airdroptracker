import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';

class AirdropApiService {
  // --- TEMPAT ANDA MENGISI API KEY ---
  // Ganti 'YOUR_API_KEY' dengan API Key asli Anda dari CryptoRank.
  final String _apiKey = 'Y7adccaac8a483a774b8438c6b2ff1b8075d5f1622bdd63068d4b71d5ca5c';

  // --- URL UNTUK API ---
  // URL ini sudah disiapkan untuk V2, ganti jika URL sebenarnya berbeda.
  final String _baseUrl = 'https://api.cryptorank.io/v2';

  Future<List<AirdropOpportunity>> fetchAirdrops() async {
    // 1. Validasi API Key sebelum melakukan panggilan
    if (_apiKey == '7adccaac8a483a774b8438c6b2ff1b8075d5f1622bdd63068d4b71d5ca5c' || _apiKey.isEmpty) {
      throw Exception('API Key belum diatur. Silakan periksa file airdrop_api_service.dart');
    }

    try {
      // 2. Melakukan panggilan ke API
      final response = await http.get(Uri.parse('$_baseUrl?api_key=$_apiKey'));

      // 3. Menangani respons dari server
      if (response.statusCode != 200) {
        throw Exception('Gagal memuat data airdrop. Status: ${response.statusCode}');
      }

      // 4. Mengubah teks JSON menjadi data yang bisa dibaca Dart
      final List<dynamic> data = json.decode(response.body)['data'];
      
      final opportunities = <AirdropOpportunity>[];
      for (final jsonItem in data) {
        // Validasi: Hanya proses item yang memiliki nama
        if (jsonItem['name'] != null && jsonItem['name'].isNotEmpty) {
          opportunities.add(AirdropOpportunity.fromJson(jsonItem));
        }
      }
      return opportunities;

    } on SocketException {
      // 5. Menangani error jika tidak ada koneksi internet
      throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
    } catch (e) {
      // 6. Menangani semua jenis error lainnya
      throw Exception('Terjadi kesalahan saat mengambil data: $e');
    }
  }
}