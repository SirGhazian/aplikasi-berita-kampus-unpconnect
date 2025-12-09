class UserModel {
  final String uid;
  final String password;
  final String nama;
  final String fotoProfil;
  final String bio;
  final String fakultas;
  final String prodi;

  final String role;
  final String statusVerifikasiGanto;

  final String? buktiKeanggotaan;

  final List<dynamic> listFollowers;
  final List<dynamic> listFollowing;
  final List<dynamic> listPostingan;

  UserModel({
    required this.uid,
    required this.password,
    required this.nama,
    required this.fotoProfil,
    required this.bio,
    required this.fakultas,
    required this.prodi,
    required this.role,
    required this.statusVerifikasiGanto,
    this.buktiKeanggotaan,
    required this.listFollowers,
    required this.listFollowing,
    required this.listPostingan,
  });

  int get followers => listFollowers.length;
  int get following => listFollowing.length;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"] ?? "",
      password: map["password"] ?? "",
      nama: map["nama"] ?? "",
      fotoProfil: map["fotoProfil"] ?? "",
      bio: map["bio"] ?? "",
      fakultas: map["fakultas"] ?? "",
      prodi: map["prodi"] ?? "",
      role: map["role"] ?? "",
      statusVerifikasiGanto: map["statusVerifikasiGanto"] ?? "",
      buktiKeanggotaan: map["buktiKeanggotaan"],
      listFollowers: map["listFollowers"] ?? [],
      listFollowing: map["listFollowing"] ?? [],
      listPostingan: map["listPostingan"] ?? [],
    );
  }
  UserModel copyWith({
    String? uid,
    String? password,
    String? nama,
    String? fotoProfil,
    String? bio,
    String? fakultas,
    String? prodi,
    String? role,
    String? statusVerifikasiGanto,
    String? buktiKeanggotaan,
    List<dynamic>? listFollowers,
    List<dynamic>? listFollowing,
    List<dynamic>? listPostingan,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      password: password ?? this.password,
      nama: nama ?? this.nama,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      bio: bio ?? this.bio,
      fakultas: fakultas ?? this.fakultas,
      prodi: prodi ?? this.prodi,
      role: role ?? this.role,
      statusVerifikasiGanto:
          statusVerifikasiGanto ?? this.statusVerifikasiGanto,
      buktiKeanggotaan: buktiKeanggotaan ?? this.buktiKeanggotaan,
      listFollowers: listFollowers ?? this.listFollowers,
      listFollowing: listFollowing ?? this.listFollowing,
      listPostingan: listPostingan ?? this.listPostingan,
    );
  }
}
