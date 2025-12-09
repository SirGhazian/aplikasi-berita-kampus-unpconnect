import 'package:cloud_firestore/cloud_firestore.dart';

class PostinganModel {
  final String id;
  final String judul;
  final String thumbnail;
  final String deskripsi;
  final String uidPengunggah;
  final String? fakultas;
  final String? prodi;
  final String? tag;
  final int createdAt;
  final int views;
  final List<String> viewedBy;

  PostinganModel({
    required this.id,
    required this.judul,
    required this.thumbnail,
    required this.deskripsi,
    required this.uidPengunggah,
    this.fakultas,
    this.prodi,
    this.tag,
    required this.createdAt,
    this.views = 0,
    this.viewedBy = const [],
  });

  factory PostinganModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostinganModel(
      id: doc.id,
      judul: data['judul'] ?? '',
      thumbnail: data['thumbnail'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      uidPengunggah: data['uidPengunggah'] ?? '',
      fakultas: data['fakultas'],
      prodi: data['prodi'],
      tag: data['tag'],
      createdAt: data['createdAt'] ?? 0,
      views: data['views'] ?? 0,
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'judul': judul,
      'thumbnail': thumbnail,
      'deskripsi': deskripsi,
      'uidPengunggah': uidPengunggah,
      'createdAt': createdAt,
      'views': views,
      'viewedBy': viewedBy,
    };

    if (fakultas != null) map['fakultas'] = fakultas;
    if (prodi != null) map['prodi'] = prodi;
    if (tag != null) map['tag'] = tag;

    return map;
  }
}
