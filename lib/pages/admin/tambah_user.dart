import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import '../../theme.dart';
import '../../utils/audio_helper.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class TambahUser extends StatefulWidget {
  const TambahUser({super.key});

  @override
  State<TambahUser> createState() => _TambahUserState();
}

class _TambahUserState extends State<TambahUser> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fakultasController = TextEditingController();
  final TextEditingController _prodiController = TextEditingController();

  String _selectedRole = 'mhs-guest';
  bool _isLoading = false;

  final List<String> _roles = ['mhs-guest', 'mhs-ganto', 'dosen', 'admin'];

  @override
  void dispose() {
    _namaController.dispose();
    _uidController.dispose();
    _passwordController.dispose();
    _fakultasController.dispose();
    _prodiController.dispose();
    super.dispose();
  }

  Future<void> _handleAddUser() async {
    if (_namaController.text.isEmpty ||
        _uidController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      AudioHelper.playError();
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        alignment: Alignment.topLeft,
        title: const Text("Mohon lengkapi semua data wajib"),
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newUser = UserModel(
        uid: _uidController.text.trim(),
        password: _passwordController.text.trim(),
        nama: _namaController.text.trim(),
        fotoProfil:
            "https://ui-avatars.com/api/?name=${_namaController.text.trim()}&background=random",
        bio: "Pengguna baru UNP Connect",
        fakultas: _fakultasController.text.trim(),
        prodi: _prodiController.text.trim(),
        role: _selectedRole,
        statusVerifikasiGanto: "unverified",
        listFollowers: [],
        listFollowing: [],
        listPostingan: [],
      );

      await FirestoreService().addUser(newUser);

      if (mounted) {
        AudioHelper.playSuccess();
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: const Text("User berhasil ditambahkan"),
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AudioHelper.playError();
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          alignment: Alignment.topLeft,
          title: Text("Gagal menambahkan user: $e"),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tambah User",
          style: semibold.copyWith(fontSize: 16, color: textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Nama Lengkap (Wajib)", _namaController),
              const SizedBox(height: 16),
              _buildTextField(
                "NIM / NIP (Wajib)",
                _uidController,
                isNumber: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                "Password (Wajib)",
                _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),
              _buildDropdown("Role", _roles, _selectedRole, (value) {
                setState(() {
                  _selectedRole = value!;
                });
              }),
              const SizedBox(height: 16),
              _buildTextField("Fakultas", _fakultasController),
              const SizedBox(height: 16),
              _buildTextField("Prodi", _prodiController),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAddUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Simpan User",
                          style: semibold.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: medium.copyWith(fontSize: 14, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          textCapitalization: isPassword || isNumber
              ? TextCapitalization.none
              : TextCapitalization.words,
          inputFormatters: isPassword || isNumber ? [] : [TitleCaseFormatter()],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: "Masukkan $label",
            hintStyle: regular.copyWith(color: textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: medium.copyWith(fontSize: 14, color: textPrimary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((String item) {
                String label;
                switch (item) {
                  case 'mhs-guest':
                    label = "Mahasiswa (Guest)";
                    break;
                  case 'mhs-ganto':
                    label = "Anggota Ganto";
                    break;
                  case 'dosen':
                    label = "Dosen";
                    break;
                  case 'admin':
                    label = "Admin";
                    break;
                  default:
                    label = item;
                }
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    label,
                    style: regular.copyWith(fontSize: 14, color: textPrimary),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String text = newValue.text;
    List<String> words = text.split(' ');
    List<String> capitalizedWords = [];

    for (String word in words) {
      if (word.isNotEmpty) {
        capitalizedWords.add(
          word[0].toUpperCase() + word.substring(1).toLowerCase(),
        );
      } else {
        capitalizedWords.add('');
      }
    }

    String newText = capitalizedWords.join(' ');

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
