import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/screens/analysis/category_transaction_page.dart';

class CategoryDetailPage extends StatefulWidget {
  const CategoryDetailPage({super.key});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  // 선택된 월
  DateTime selectedMonth = DateTime(2026, 2);
  
  // 선택된 카테고리 필터
  String selectedFilter = '전체';
  
  // 선택된 차트 카테고리
  int selectedCategoryIndex = 0;
  
  // 카테고리 필터 목록 (금액 높은 순으로 동적 생성)
  List<String> get categoryFilters {
    final filters = ['전체'];
    // 카테고리 데이터를 금액순으로 정렬
    final sortedCategories = List<Map<String, dynamic>>.from(categoryData)
      ..sort((a, b) => (b['amount'] as int).compareTo(a['amount'] as int));
    
    // 정렬된 카테고리 이름 추가
    filters.addAll(sortedCategories.map((data) => data['name'] as String));
    return filters;
  }
  
  // 총 지출 데이터
  final int totalSpending = 1199783;
  final int lastMonthDifference = -712939;
  
  // 카테고리별 지출 데이터
  final List<Map<String, dynamic>> categoryData = [
    {
      'name': '쇼핑',
      'icon': '🛍️',
      'amount': 345409,
      'change': -835139,
      'percent': 26,
      'color': Color(0xFF1560FF),
    },
    {
      'name': '보험·대출·기타금융',
      'icon': '💳',
      'amount': 281790,
      'change': 281790,
      'percent': 22,
      'color': Color(0xFF00BFA5),
    },
    {
      'name': '식비',
      'icon': '🍴',
      'amount': 246500,
      'change': -66100,
      'percent': 19,
      'color': Color(0xFFFFEB3B),
    },
    {
      'name': '교통',
      'icon': '🚌',
      'amount': 142182,
      'change': -515,
      'percent': 11,
      'color': Color(0xFF2196F3),
    },
    {
      'name': '의료·건강·피트니스',
      'icon': '💊',
      'amount': 30000,
      'change': 30000,
      'percent': 2,
      'color': Color(0xFF00BCD4),
    },
    {
      'name': '주거·통신',
      'icon': '🏠',
      'amount': 20900,
      'change': 0,
      'percent': 2,
      'color': Color(0xFF03A9F4),
    },
    {
      'name': '생활',
      'icon': '🛒',
      'amount': 12840,
      'change': -14900,
      'percent': 1,
      'color': Color(0xFFFF9800),
    },
    {
      'name': '카페·간식',
      'icon': '☕',
      'amount': 5500,
      'change': -26500,
      'percent': 0,
      'color': Color(0xFF795548),
    },
    {
      'name': '기타 지출',
      'icon': '➖',
      'amount': -105088,
      'change': -105088,
      'percent': 0,
      'color': Color(0xFF9E9E9E),
    },
  ];
  
  // 나이 대비 비교 데이터
  final List<Map<String, dynamic>> ageComparisonData = [
    {
      'name': '쇼핑',
      'icon': '🏛️',
      'difference': 950000,
      'isHigher': true,
    },
    {
      'name': '식비',
      'icon': '🍽️',
      'difference': 200000,
      'isHigher': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '카테고리별 지출',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 월 선택기
            _buildMonthSelector(),
            
            const SizedBox(height: 16),
            
            // 카테고리 필터
            _buildCategoryFilters(),
            
            const SizedBox(height: 24),
            
            // 총 지출 및 카테고리 섹션
            _buildSpendingSection(),
            
            const SizedBox(height: 32),
            
            // 나이 대비 비교 섹션
            _buildAgeComparisonSection(),
            
            const SizedBox(height: 24),
            
            // 카드 분석 배너
            _buildCardAnalysisBanner(),
            
            const SizedBox(height: 100), // 하단 네비게이션 공간
          ],
        ),
      ),
    );
  }

  // 월 선택기
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            '${selectedMonth.month}월',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(
                  selectedMonth.year,
                  selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  // 카테고리 필터
  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categoryFilters.length,
        itemBuilder: (context, index) {
          final filter = categoryFilters[index];
          final isSelected = selectedFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                // '전체'가 아닌 카테고리를 선택한 경우 거래 내역 페이지로 이동
                if (filter != '전체' && selected) {
                  // 필터명으로 카테고리 찾기
                  final categoryIndex = categoryData.indexWhere(
                    (data) => data['name'] == filter
                  );
                  
                  if (categoryIndex != -1) {
                    final selectedData = categoryData[categoryIndex];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryTransactionPage(
                          categoryName: selectedData['name'] as String,
                          categoryIcon: selectedData['icon'] as String,
                          amount: selectedData['amount'] as int,
                          change: selectedData['change'] as int,
                          percent: selectedData['percent'] as int,
                          color: selectedData['color'] as Color,
                        ),
                      ),
                    );
                  }
                } else {
                  // '전체' 선택 시 현재 화면 유지
                  setState(() {
                    selectedFilter = filter;
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 14,
              ),
              side: BorderSide(
                color: isSelected ? Colors.black : Colors.grey[300]!,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
        },
      ),
    );
  }

  // 총 지출 및 카테고리 섹션
  Widget _buildSpendingSection() {
    // 인덱스 범위 체크
    if (selectedCategoryIndex >= categoryData.length) {
      selectedCategoryIndex = 0;
    }
    final selectedCategory = categoryData[selectedCategoryIndex];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 총 지출 금액 (centered, large)
          Text(
            _formatCurrencyFull(totalSpending),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF394A63),
            ),
          ),

          const SizedBox(height: 8),

          // 지난달 대비 메시지 (centered)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              children: [
                const TextSpan(text: '지난달 같은 기간보다 '),
                TextSpan(
                  text: _formatCurrencyFull(lastMonthDifference.abs()),
                  style: const TextStyle(
                    color: Color(0xFF1560FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' 덜 썼어요'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 도넛 차트 (larger)
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 70,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event is FlTapUpEvent &&
                            pieTouchResponse != null &&
                            pieTouchResponse.touchedSection != null) {
                          final touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          if (touchedIndex >= 0 && touchedIndex < categoryData.length) {
                            setState(() {
                              selectedCategoryIndex = touchedIndex;
                            });
                          }
                        }
                      },
                    ),
                    sections: categoryData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      final isSelected = index == selectedCategoryIndex;

                      return PieChartSectionData(
                        color: data['color'] as Color,
                        value: (data['percent'] as int).toDouble(),
                        title: '',
                        radius: isSelected ? 44 : 38,
                      );
                    }).toList(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedCategory['icon'] as String,
                        style: const TextStyle(fontSize: 36),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${selectedCategory['percent']}%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedCategory['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // 카테고리 목록
          ...categoryData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return _buildCategoryItem(
              data['icon'] as String,
              data['name'] as String,
              data['percent'] as int,
              data['amount'] as int,
              data['change'] as int,
              data['color'] as Color,
              isSelected: index == selectedCategoryIndex,
              onTap: () {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // 카테고리 아이템
  Widget _buildCategoryItem(
    String icon,
    String name,
    int percent,
    int amount,
    int change,
    Color color, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final changeText = change == 0
        ? '지난달과 같아요'
        : '${change > 0 ? '+' : ''}${_formatCurrencyFull(change)}';
    final changeColor = change == 0
        ? Colors.grey
        : (change > 0 ? const Color(0xFFFF5252) : const Color(0xFF1560FF));
    
    return GestureDetector(
      onTap: () {
        if (onTap != null) onTap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryTransactionPage(
              categoryName: name,
              categoryIcon: icon,
              amount: amount,
              change: change,
              percent: percent,
              color: color,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,2))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? Border.all(color: color, width: 1.5) : null,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    changeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatCurrencyFull(amount),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  // 나이 대비 비교 섹션
  Widget _buildAgeComparisonSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '김용진 님은',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            '20대 평균보다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: _buildComparisonCard(
                  ageComparisonData[0]['icon'] as String,
                  ageComparisonData[0]['name'] as String,
                  ageComparisonData[0]['difference'] as int,
                  ageComparisonData[0]['isHigher'] as bool,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildComparisonCard(
                  ageComparisonData[1]['icon'] as String,
                  ageComparisonData[1]['name'] as String,
                  ageComparisonData[1]['difference'] as int,
                  ageComparisonData[1]['isHigher'] as bool,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 비교 카드
  Widget _buildComparisonCard(
      String icon, String name, int difference, bool isHigher) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(difference / 10000).toStringAsFixed(0)}만원',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isHigher ? const Color(0xFFFF5252) : const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                isHigher ? '높아요' : '낮아요',
                style: TextStyle(
                  fontSize: 14,
                  color: isHigher ? const Color(0xFFFF5252) : const Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          Icon(
            isHigher ? Icons.arrow_upward : Icons.arrow_downward,
            color: isHigher ? const Color(0xFFFF5252) : const Color(0xFF2196F3),
            size: 20,
          ),
        ],
      ),
    );
  }

  // 카드 분석 배너
  Widget _buildCardAnalysisBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card,
              color: Color(0xFFFF5252),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '쇼핑에 ${_formatCurrencyFull(345409)} 지출하셨네요!',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '용진님의 카드를 분석해봤어요!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  String _formatCurrencyFull(int amount) {
    final formatted = amount.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '${amount < 0 ? '-' : ''}$formatted원';
  }
}
