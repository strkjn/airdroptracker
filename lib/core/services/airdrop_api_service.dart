import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:airdrop_flow/core/models/airdrop_opportunity_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- IMPORT BARU

class AirdropApiService {
  // Ambil API Key dari environment variables
  final String _apiKey = dotenv.env['CRYPTO_RANK_API_KEY'] ?? '';

  final String _baseUrl = 'https://api.cryptorank.io/v2/airdrops'; // URL diperbarui

  Future<List<AirdropOpportunity>> fetchAirdrops() async {
    if (_apiKey.isEmpty) {
      throw Exception('API Key tidak ditemukan. Pastikan file .env sudah benar.');
    }

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'api_key': _apiKey, // API Key dikirim sebagai header
        },
      );

      if (response.statusCode != 200) {
        // Coba parsing pesan error dari API jika ada
        final errorBody = json.decode(response.body);
        final errorMessage = errorBody['status']?['error_message'] ?? 'Status: ${response.statusCode}';
        throw Exception('Gagal memuat data airdrop: $errorMessage');
      }

      final List<dynamic> data = json.decode(response.body)['data'];
      
      final opportunities = <AirdropOpportunity>[];
      for (final jsonItem in data) {
        if (jsonItem['name'] != null && jsonItem['name'].isNotEmpty) {
          opportunities.add(AirdropOpportunity.fromJson(jsonItem));
        }
      }
      return opportunities;

    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }
}