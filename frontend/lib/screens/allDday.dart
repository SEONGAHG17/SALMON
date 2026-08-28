import 'package:flutter/material.dart';
import '../styles/app_theme.dart';
import '../styles/categorycolor.dart';
import 'calender.dart';

class AllDdayScreen extends StatefulWidget {
  final List<Map<String, dynamic>> deadlineItems;
  final String initialFilter;

  const AllDdayScreen({
    super.key,
    required this.deadlineItems,
    this.initialFilter = '전체',
  });

  @override
  State<AllDdayScreen> createState() => _AllDdayScreenState();
}

class _AllDdayScreenState extends State<AllDdayScreen> {
  late String _selectedFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, Color> _getDDayStyle(int dDay) {
    if (dDay <= 3) {
      return {'bg': const Color(0xFFFFE5E2), 'fg': const Color(0xFFE53935)};
    } else if (dDay <= 7) {
      return {'bg': const Color(0xFFFFF0D6), 'fg': const Color(0xFFB87700)};
    } else {
      return {'bg': const Color(0xFFE2F3E7), 'fg': const Color(0xFF2E7D32)};
    }
  }

  List<Map<String, dynamic>> _getFilteredList() {
    return widget.deadlineItems.where((item) {
      final dDay = item['dDay'] as int;
      final title = (item['title'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      bool matchesFilter = true;
      if (_selectedFilter == '오늘·내일') {
        matchesFilter = (dDay == 0 || dDay == 1);
      } else if (_selectedFilter == '이번주') {
        matchesFilter = (dDay >= 0 && dDay <= 7);
      } else if (_selectedFilter == '이후') {
        matchesFilter = (dDay > 7);
      }

      final matchesQuery = q.isEmpty || title.contains(q) || category.contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _getFilteredList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '전체 마감 일정 (${widget.deadlineItems.length}건)',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1E),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. 검색창
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: '일정 제목 또는 카테고리 검색',
                  hintStyle: const TextStyle(color: Color(0xFFA1A1A6), fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFA1A1A6), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: Color(0xFFA1A1A6)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 2. 필터 탭 바
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['전체', '오늘·내일', '이번주', '이후'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1A1A1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF1A1A1E) : const Color(0xFFE5E5E7),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF6B6B70),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E5E7)),

          // 3. 전체 리스트
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text(
                      '해당 조건의 일정이 없습니다.',
                      style: TextStyle(color: Color(0xFFA1A1A6), fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildFullDeadlineCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullDeadlineCard(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final category = item['category'] as String;
    final dateStr = item['dateStr'] as String;
    final dDay = item['dDay'] as int;
    final imgUrl = item['image_url'];

    final catColors = CategoryColorManager().getColor(category);
    final dDayStyle = _getDDayStyle(dDay);
    final periodSubtitle = dDay == 0 ? "유효기간 오늘까지" : "마감 $dateStr";
    final dDayText = dDay == 0 ? "D-Day" : "D-$dDay";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              color: catColors['bg'],
              child: imgUrl != null
                  ? Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.event, color: catColors['fg'], size: 22),
                    )
                  : Icon(Icons.event, color: catColors['fg'], size: 22),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: catColors['bg'],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  category,
                  style: TextStyle(color: catColors['fg'], fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(periodSubtitle, style: const TextStyle(fontSize: 12, color: Color(0xFFA1A1A6))),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: dDayStyle['bg'],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dDayText,
              style: TextStyle(color: dDayStyle['fg'], fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import '../styles/app_theme.dart';
// import '../styles/categorycolor.dart';
// import 'calender.dart';

// class AllDdayScreen extends StatefulWidget {
//   final List<Map<String, dynamic>> deadlineItems;
//   final String initialFilter;

//   const AllDdayScreen({
//     super.key,
//     required this.deadlineItems,
//     this.initialFilter = '전체',
//   });

//   @override
//   State<AllDdayScreen> createState() => _AllDdayScreenState();
// }

// class _AllDdayScreenState extends State<AllDdayScreen> {
//   late String _selectedFilter;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void initState() {
//     super.initState();
//     _selectedFilter = widget.initialFilter;
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   Map<String, Color> _getDDayStyle(int dDay) {
//     if (dDay <= 3) {
//       return {'bg': const Color(0xFFFFE5E2), 'fg': const Color(0xFFE53935)};
//     } else if (dDay <= 7) {
//       return {'bg': const Color(0xFFFFF0D6), 'fg': const Color(0xFFB87700)};
//     } else {
//       return {'bg': const Color(0xFFE2F3E7), 'fg': const Color(0xFF2E7D32)};
//     }
//   }

//   List<Map<String, dynamic>> _getFilteredList() {
//     return widget.deadlineItems.where((item) {
//       final dDay = item['dDay'] as int;
//       final title = (item['title'] ?? '').toString().toLowerCase();
//       final category = (item['category'] ?? '').toString().toLowerCase();
//       final q = _searchQuery.toLowerCase();

//       bool matchesFilter = true;
//       if (_selectedFilter == '오늘·내일') {
//         matchesFilter = (dDay == 0 || dDay == 1);
//       } else if (_selectedFilter == '이번주') {
//         matchesFilter = (dDay >= 0 && dDay <= 7);
//       } else if (_selectedFilter == '이후') {
//         matchesFilter = (dDay > 7);
//       }

//       final matchesQuery = q.isEmpty || title.contains(q) || category.contains(q);
//       return matchesFilter && matchesQuery;
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredList = _getFilteredList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFFAFAFB),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A1E)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           '전체 마감 일정 (${widget.deadlineItems.length}건)',
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF1A1A1E),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           // 1. 검색바
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//             child: Container(
//               height: 44,
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF2F2F4),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (val) => setState(() => _searchQuery = val),
//                 decoration: InputDecoration(
//                   hintText: '일정 제목 또는 카테고리 검색',
//                   hintStyle: const TextStyle(color: Color(0xFFA1A1A6), fontSize: 13.5),
//                   prefixIcon: const Icon(Icons.search, color: Color(0xFFA1A1A6), size: 20),
//                   suffixIcon: _searchQuery.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.clear, size: 18, color: Color(0xFFA1A1A6)),
//                           onPressed: () {
//                             _searchController.clear();
//                             setState(() => _searchQuery = '');
//                           },
//                         )
//                       : null,
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 12),
//                 ),
//               ),
//             ),
//           ),

//           // 2. 필터 탭
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.only(bottom: 12),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: ['전체', '오늘·내일', '이번주', '이후'].map((filter) {
//                   final isSelected = _selectedFilter == filter;
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 8),
//                     child: GestureDetector(
//                       onTap: () => setState(() => _selectedFilter = filter),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
//                         decoration: BoxDecoration(
//                           color: isSelected ? const Color(0xFF1A1A1E) : Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: isSelected ? const Color(0xFF1A1A1E) : const Color(0xFFE5E5E7),
//                           ),
//                         ),
//                         child: Text(
//                           filter,
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//                             color: isSelected ? Colors.white : const Color(0xFF6B6B70),
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//           const Divider(height: 1, color: Color(0xFFE5E5E7)),

//           // 3. 전체 일정 리스트
//           Expanded(
//             child: filteredList.isEmpty
//                 ? const Center(
//                     child: Text(
//                       '해당 조건의 일정이 없습니다.',
//                       style: TextStyle(color: Color(0xFFA1A1A6), fontSize: 14),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     itemCount: filteredList.length,
//                     itemBuilder: (context, index) {
//                       final item = filteredList[index];
//                       return _buildFullDeadlineCard(item);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFullDeadlineCard(Map<String, dynamic> item) {
//     final title = item['title'] as String;
//     final category = item['category'] as String;
//     final dateStr = item['dateStr'] as String;
//     final dDay = item['dDay'] as int;
//     final imgUrl = item['image_url'];

//     final catColors = CategoryColorManager().getColor(category);
//     final dDayStyle = _getDDayStyle(dDay);
//     final periodSubtitle = dDay == 0 ? "유효기간 오늘까지" : "마감 $dateStr";
//     final dDayText = dDay == 0 ? "D-Day" : "D-$dDay";

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: const Color(0xFFE5E5E7)),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(18),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(18),
//           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: Container(
//                     width: 48,
//                     height: 48,
//                     color: catColors['bg'],
//                     child: imgUrl != null
//                         ? Image.network(
//                             imgUrl,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) =>
//                                 Icon(Icons.event, color: catColors['fg'], size: 22),
//                           )
//                         : Icon(Icons.event, color: catColors['fg'], size: 22),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//                         decoration: BoxDecoration(
//                           color: catColors['bg'],
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: Text(
//                           category,
//                           style: TextStyle(
//                             color: catColors['fg'],
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         title,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF1A1A1E),
//                         ),
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         periodSubtitle,
//                         style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1A6)),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   width: 64,
//                   height: 34,
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     color: dDayStyle['bg'],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     dDayText,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: dDayStyle['fg'],
//                       fontWeight: FontWeight.w800,
//                       fontSize: 13,
//                       letterSpacing: -0.3,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }