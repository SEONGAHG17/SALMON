import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main.dart'; // 전역 navigatorKey 참조

class ScreenshotWatcher extends StatefulWidget {
  final Widget child;
  final Function(File screenshotFile)? onAnalyze;

  const ScreenshotWatcher({
    super.key,
    required this.child,
    this.onAnalyze,
  });

  @override
  State<ScreenshotWatcher> createState() => _ScreenshotWatcherState();
}

class _ScreenshotWatcherState extends State<ScreenshotWatcher> {
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer; // 5초 자동 닫힘 타이머
  bool _isProcessing = false;
  String? _lastDetectedId;

  @override
  void initState() {
    super.initState();
    _initDetector();
  }

  Future<void> _initDetector() async {
    // 런타임 권한 요청
    await [Permission.photos, Permission.notification].request();

    // photo_manager의 실시간 갤러리/스크린샷 변경 감지기 등록
    PhotoManager.addChangeCallback(_onGalleryChanged);
    PhotoManager.startChangeNotify();
  }

  void _onGalleryChanged(MethodCall call) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // OS 갤러리 파일 인덱싱 대기
      await Future.delayed(const Duration(milliseconds: 500));

      final File? file = await _getLatestScreenshot();
      if (file != null && mounted) {
        debugPrint("📸 [스크린샷 감지 및 최신 파일 확보]: ${file.path}");
        _showTopOverlay(file);
      }
    } catch (e) {
      debugPrint("❌ [스크린샷 처리 에러]: $e");
    } finally {
      _isProcessing = false;
    }
  }

  Future<File?> _getLatestScreenshot() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    if (!state.isAuth && !state.hasAccess) return null;

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (albums.isEmpty) return null;

    final List<AssetEntity> mediaList = await albums.first.getAssetListRange(
      start: 0,
      end: 1,
    );
    if (mediaList.isEmpty) return null;

    final AssetEntity latest = mediaList.first;

    // 중복 호출 방지
    if (_lastDetectedId == latest.id) return null;

    // 생성 시간이 최근 10초 이내인 사진만 스크린샷 캡처로 판단
    final now = DateTime.now();
    final diff = now.difference(latest.createDateTime).inSeconds.abs();
    if (diff > 10) return null;

    _lastDetectedId = latest.id;
    return await latest.file;
  }

  // 스크린샷 감지 시에만 띄우고 5초 뒤 자동 종료되는 오버레이
  void _showTopOverlay(File file) {
    _removeOverlay();

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      debugPrint("❌ [Overlay 에러]: overlayState를 찾을 수 없습니다.");
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "방금 찍은 스크린샷",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "분석하시겠습니까?",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _removeOverlay();
                    if (widget.onAnalyze != null) {
                      widget.onAnalyze!(file);
                    }
                  },
                  child: const Text("분석"),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: _removeOverlay,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);

    // 5초 뒤 자동으로 말풍선 제거
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    PhotoManager.removeChangeCallback(_onGalleryChanged);
    PhotoManager.stopChangeNotify();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}