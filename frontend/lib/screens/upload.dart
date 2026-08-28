import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../constants/constants.dart';
import '../styles/app_theme.dart';
import 'detail.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint("❌ [이미지 선택 에러]: $e");
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_selectedImage == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final uri = Uri.parse('$baseUrl/api/v1/analyze/');
      final request = http.MultipartRequest('POST', uri);

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: _selectedImage!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('file', _selectedImage!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // 백엔드 AnalysisResponse 구조에서 상세 화면에 맞게 아이템 맵 구성
        final analysis = data['analysis'] ?? {};
        final Map<String, dynamic> historyItem = data['item'] ?? {
          'id': data['item_id'] ?? analysis['id'],
          'status': data['status'],
          'is_valid': analysis['is_valid'],
          'category': analysis['category'] ?? '기타',
          'summary': analysis['summary'] ?? '',
          'action_type': analysis['action_type'] ?? '해당없음',
          'action_data': analysis['action_data'] ?? '',
          'error_reason': analysis['error_reason'] ?? '',
          'image_url': data['image_url'],
          'places': analysis['places'] ?? [],
          'schedules': analysis['schedules'] ?? [],
          'created_at': DateTime.now().toIso8601String(),
        };

        // 💡 isFromUpload: true를 전달하여 홈 이동 버튼 활성화
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(
              item: historyItem,
              isFromUpload: true,
            ),
          ),
        );

        // 상세 화면에서 복귀했을 때 업로드 상태 초기화
        if (mounted) {
          setState(() {
            _selectedImage = null;
          });
        }
      } else {
        if (mounted) {
          _showErrorDialog("AI 분석 서버 통신 장애: ${response.statusCode}\n${response.body}");
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("오류가 발생했습니다: $e");
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('분석 실패', style: AppTypography.titleBold),
        content: Text(message, style: AppTypography.body),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 스크린샷 분석'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => _showImageSourceActionSheet(context),
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: _selectedImage != null ? AppColors.brand : AppColors.border,
                    width: _selectedImage != null ? 2 : 1,
                  ),
                  boxShadow: AppShadows.card,
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl - 2),
                        child: kIsWeb
                            ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.brandLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: AppColors.brand,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            '스크린샷 이미지를 등록해주세요',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '탭하여 갤러리 또는 카메라에서 선택',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_selectedImage != null)
              OutlinedButton.icon(
                onPressed: () => _showImageSourceActionSheet(context),
                icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                label: const Text('다른 이미지로 변경', style: TextStyle(color: AppColors.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
              ),
            if (_selectedImage != null) const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: (_selectedImage == null || _isAnalyzing) ? null : _uploadAndAnalyze,
              child: _isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Text('AI가 스크린샷을 분석하고 있습니다...'),
                      ],
                    )
                  : const Text('AI 분석 시작', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.brand),
                title: const Text('앨범에서 선택', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.brand),
                title: const Text('카메라로 촬영', style: AppTypography.bodyMedium),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
