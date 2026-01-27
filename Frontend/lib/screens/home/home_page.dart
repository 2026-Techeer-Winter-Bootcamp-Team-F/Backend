import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/screens/analysis/category_detail_page.dart';
import 'package:my_app/services/transaction_service.dart';
import 'package:my_app/models/home_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 현재 선택된 월
  DateTime selectedMonth = DateTime.now();

  // 상단 스크롤 페이지 인덱스 (누적/주간/월간)
  int topPageIndex = 0;
  final PageController topPageController = PageController();

  // 하단 스크롤 페이지 인덱스 (카테고리/지난달 비교)
  int bottomPageIndex = 0;
  final PageController bottomPageController = PageController();

  // 도넛 차트 선택된 카테고리 인덱스
  int selectedCategoryIndex = 0;

  // Data Variables
  bool _isLoading = true;
  int thisMonthTotal = 0;
  int lastMonthSameDay = 0;
  int weeklyAverage = 0;
  int monthlyAverage = 0;

  List<double> thisMonthDailyData = [];
  List<double> lastMonthDailyData = [];
  Map<String, Map<String, dynamic>> categoryData = {};

  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final year = selectedMonth.year;
      final month = selectedMonth.month;

      final results = await Future.wait([
        _transactionService.getAccumulatedData(year, month), // 0
        _transactionService.getMonthComparison(year, month), // 1
        _transactionService.getWeeklyAverage(year, month), // 2
        _transactionService.getMonthlyAverage(year, month), // 3
        _transactionService.getCategorySummary(year, month), // 4
      ]);

      final accumulatedData = results[0] as AccumulatedData;
      final monthComparison = results[1] as MonthComparison;
      final weeklyData = results[2] as WeeklyData;
      final monthlyData = results[3] as MonthlyData;
      final categoryList = results[4] as List<CategoryData>;

      if (mounted) {
        setState(() {
          thisMonthTotal = accumulatedData.total;
          thisMonthDailyData = accumulatedData.dailyData
              .map((d) => d.amount)
              .toList();

          lastMonthSameDay = monthComparison.lastMonthSameDay;
          lastMonthDailyData = monthComparison.lastMonthData
              .map((d) => d.amount)
              .toList();

          weeklyAverage = weeklyData.average;
          monthlyAverage = monthlyData.average;

          // Convert CategoryData list to Map format used by UI
          categoryData = {
            for (var c in categoryList)
              c.name: {
                'amount': c.amount,
                'change': c.change,
                'percent': c.percent,
                'icon': c.emoji,
                'color': c.color,
              },
          };

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Home data fetch error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    topPageController.dispose();
    bottomPageController.dispose();
    super.dispose();
  }

  // (카드 스택은 홈 탭으로 이동됨)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 월 선택 헤더
            _buildMonthHeader(),

            // 스크롤 가능한 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // 상단 섹션 (누적/주간/월간)
                    _buildTopSection(),

                    const SizedBox(height: 32),

                    // 이번달/지난달 비교 탭
                    _buildTabButtons(),

                    const SizedBox(height: 16),

                    // 하단 섹션 (카테고리/지난달 비교)
                    _buildBottomSection(),
                    const SizedBox(height: 80), // 하단 네비게이션 바 공간
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 월 선택 헤더
  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              _fetchData(); // Fetch new data
            },
          ),
          Text(
            '${selectedMonth.month}월',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
              _fetchData(); // Fetch new data
            },
          ),
        ],
      ),
    );
  }

  // 상단 섹션 (누적/주간/월간 스크롤)
  Widget _buildTopSection() {
    return Column(
      children: [
        // 페이지 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicator('누적', 0),
            const SizedBox(width: 24),
            _buildIndicator('주간', 1),
            const SizedBox(width: 24),
            _buildIndicator('월간', 2),
          ],
        ),
        const SizedBox(height: 16),

        // 스크롤 가능한 페이지
        SizedBox(
          height: 330,
          child: PageView(
            controller: topPageController,
            onPageChanged: (index) {
              setState(() {
                topPageIndex = index;
              });
            },
            children: [
              _buildAccumulatedView(),
              _buildWeeklyView(),
              _buildMonthlyView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, int index) {
    final isSelected = topPageIndex == index;
    return GestureDetector(
      onTap: () {
        topPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  // 누적 소비 금액 뷰
  Widget _buildAccumulatedView() {
    final difference = lastMonthSameDay - thisMonthTotal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 텍스트 정보
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: '지난달 같은 기간보다\n'),
                  TextSpan(
                    text: _formatCurrency(difference),
                    style: const TextStyle(
                      color: Color(0xFF1560FF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: ' 덜 썼어요'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 차트 영역
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: LineChartPainter(
                thisMonthData: thisMonthDailyData,
                lastMonthData: lastMonthDailyData,
                currentDay: 19, // 1월 19일까지 데이터
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 월별 데이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMonthData('1월 19일까지', thisMonthTotal, Color(0xFF1560FF)),
              const SizedBox(width: 40),
              _buildMonthData('12월 19일까지', lastMonthSameDay, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthData(String label, int amount, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrencyFull(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // 주간 평균 뷰
  Widget _buildWeeklyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 텍스트 정보
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: '일주일 평균\n'),
                  TextSpan(
                    text: _formatCurrency(weeklyAverage),
                    style: const TextStyle(
                      color: Color(0xFF1560FF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: ' 정도 썼어요'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 차트 영역
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBarChart('28일', 280000, 380000),
                _buildBarChart('01.04', 380000, 380000),
                _buildBarChart('01.11', 260000, 380000),
                _buildBarChart('01.18', 90000, 380000),
                _buildBarChart('0', 0, 380000, isToday: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '지난 4주 평균  ${_formatCurrencyFull(weeklyAverage)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    String label,
    int amount,
    int maxAmount, {
    bool isToday = false,
  }) {
    final height = amount > 0 ? (amount / maxAmount * 120) : 2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${(amount / 10000).toStringAsFixed(0)}만',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        Container(
          width: 40,
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF1560FF) : const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // 월간 평균 뷰
  Widget _buildMonthlyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 텍스트 정보
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: '월 평균\n'),
                  TextSpan(
                    text: _formatCurrency(monthlyAverage),
                    style: const TextStyle(
                      color: Color(0xFF1560FF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: ' 정도 썼어요'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 차트 영역
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMonthlyBar('25.09', 140000, 1700000),
                _buildMonthlyBar('25.10', 540000, 1700000),
                _buildMonthlyBar('25.11', 1700000, 1700000),
                _buildMonthlyBar('25.12', 1400000, 1700000),
                _buildMonthlyBar(
                  '26.01',
                  660000,
                  1700000,
                  isCurrentMonth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '지난 4개월 평균  ${_formatCurrencyFull(754776)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBar(
    String label,
    int amount,
    int maxAmount, {
    bool isCurrentMonth = false,
  }) {
    final height = (amount / maxAmount * 120);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${(amount / 10000).toStringAsFixed(0)}만',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: isCurrentMonth
                ? const Color(0xFF1560FF)
                : const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // 이번달/지난달 비교 탭 버튼
  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                bottomPageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: bottomPageIndex == 0
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '이번달',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bottomPageIndex == 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: bottomPageIndex == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                bottomPageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: bottomPageIndex == 1
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '지난달 비교',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bottomPageIndex == 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: bottomPageIndex == 1 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 하단 섹션 (카테고리/지난달 비교)
  Widget _buildBottomSection() {
    return SizedBox(
      height: 700,
      child: PageView(
        controller: bottomPageController,
        onPageChanged: (index) {
          setState(() {
            bottomPageIndex = index;
          });
        },
        children: [
          SingleChildScrollView(child: _buildCategoryView()),
          SingleChildScrollView(child: _buildComparisonView()),
        ],
      ),
    );
  }

  // 소비 카테고리 뷰
  Widget _buildCategoryView() {
    final selectedEntry = categoryData.entries.toList()[selectedCategoryIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 메시지
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  height: 1.5,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  TextSpan(
                    text: selectedEntry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1560FF),
                    ),
                  ),
                  const TextSpan(text: '에\n가장 많이 썼어요'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 도넛 차트
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event is FlTapUpEvent &&
                            pieTouchResponse != null &&
                            pieTouchResponse.touchedSection != null) {
                          setState(() {
                            final touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                            if (touchedIndex >= 0 &&
                                touchedIndex < categoryData.length) {
                              selectedCategoryIndex = touchedIndex;
                            }
                          });
                        }
                      },
                    ),
                    sections: categoryData.entries.toList().asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final data = entry.value.value;
                        final isSelected = index == selectedCategoryIndex;

                        return PieChartSectionData(
                          color: data['color'] as Color,
                          value: (data['percent'] as int).toDouble(),
                          title: '',
                          radius: isSelected ? 35 : 30,
                        );
                      },
                    ).toList(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedEntry.value['icon'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedEntry.value['percent']}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedEntry.key,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 카테고리 목록
          ...categoryData.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return _buildCategoryItem(
              data.value['icon'] as String,
              data.key,
              data.value['percent'] as int,
              data.value['amount'] as int,
              data.value['change'] as int,
              data.value['color'] as Color,
              isSelected: index == selectedCategoryIndex,
              onTap: () {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
            );
          }),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryDetailPage(),
                ),
              );
            },
            child: const Text('더보기 >'),
          ),
        ],
      ),
    );
  }

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
    final isPositive = change > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(13) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: color, width: 2) : null,
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
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrencyFull(amount),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${_formatCurrencyFull(change)}',
              style: TextStyle(
                fontSize: 12,
                color: isPositive
                    ? const Color(0xFFFF5252)
                    : const Color(0xFF1560FF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 지난달 비교 뷰
  Widget _buildComparisonView() {
    final topCategory = categoryData.entries.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 메시지
          Align(
            alignment: Alignment.centerLeft,
            child: RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black,
                  height: 1.5,
                  fontWeight: FontWeight.w900,
                ),
                children: [
                  const TextSpan(text: '지난달 이맘때 대비\n'),
                  TextSpan(
                    text: '${topCategory.key} 지출이 줄었어요',
                    style: const TextStyle(color: Color(0xFF1560FF)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 카테고리별 막대 그래프
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categoryData.entries.map((entry) {
                final percent = entry.value['percent'] as int;
                final change = entry.value['change'] as int;
                final lastMonthPercent = percent + (change / 10000).round();

                return _buildComparisonBar(
                  entry.key,
                  lastMonthPercent,
                  percent,
                  entry.value['color'] as Color,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // 상세 정보
          Column(
            children: [
              _buildComparisonDetail(
                '1월 19일까지',
                '49%',
                _formatCurrencyFull(317918),
              ),
              const SizedBox(height: 8),
              _buildComparisonDetail(
                '12월 19일까지',
                '55%',
                _formatCurrencyFull(553230),
              ),
              const SizedBox(height: 8),
              _buildComparisonDetail(
                '증감',
                '-6%',
                _formatCurrencyFull(-235312),
                isChange: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(
    String label,
    int lastMonth,
    int thisMonth,
    Color color,
  ) {
    final maxHeight = 150.0;
    final lastMonthHeight = (lastMonth / 60 * maxHeight).clamp(10.0, maxHeight);
    final thisMonthHeight = (thisMonth / 60 * maxHeight).clamp(10.0, maxHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 16,
              height: lastMonthHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 16,
              height: thisMonthHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 40,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonDetail(
    String label,
    String percent,
    String amount, {
    bool isChange = false,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isChange
                ? Colors.transparent
                : (label.contains('1월') ? Color(0xFF1560FF) : Colors.grey),
            shape: BoxShape.circle,
            border: isChange ? Border.all(color: Colors.grey, width: 1) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Text(
          percent,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 100,
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isChange && amount.startsWith('-')
                  ? const Color(0xFF1560FF)
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    if (amount.abs() >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원';
  }

  String _formatCurrencyFull(int amount) {
    final formatted = amount.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '${amount < 0 ? '-' : ''}$formatted원';
  }
}

// 간단한 라인 차트 페인터
class LineChartPainter extends CustomPainter {
  final List<double> thisMonthData;
  final List<double> lastMonthData;
  final int currentDay;

  LineChartPainter({
    required this.thisMonthData,
    required this.lastMonthData,
    required this.currentDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 최대값 계산 (스케일링을 위해)
    final maxValue = lastMonthData.reduce((a, b) => a > b ? a : b);
    final padding = 10.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // 지난달 그래프 그리기 (회색, 전체 기간)
    _drawMonthLine(
      canvas,
      lastMonthData,
      maxValue,
      chartWidth,
      chartHeight,
      padding,
      Colors.grey.withOpacity(0.3),
      Colors.grey.withOpacity(0.05),
      lastMonthData.length,
    );

    // 이번달 그래프 그리기 (파란색, 현재 날짜까지만)
    _drawMonthLine(
      canvas,
      thisMonthData,
      maxValue,
      chartWidth,
      chartHeight,
      padding,
      const Color(0xFF1560FF),
      const Color(0xFF1560FF).withOpacity(0.1),
      currentDay,
    );

    // 날짜 레이블 그리기
    _drawLabels(canvas, size, chartWidth, padding);
  }

  void _drawMonthLine(
    Canvas canvas,
    List<double> data,
    double maxValue,
    double chartWidth,
    double chartHeight,
    double padding,
    Color lineColor,
    Color fillColor,
    int dataLength,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // 데이터 포인트 계산
    final pointsToUse = data.take(dataLength).toList();
    if (pointsToUse.isEmpty) return;

    // x축 간격 계산 (최대 31일 기준)
    final xStep = chartWidth / 31;

    // 첫 번째 포인트
    final firstX = padding;
    final firstY =
        padding + chartHeight - (pointsToUse[0] / maxValue * chartHeight);

    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, padding + chartHeight);
    fillPath.lineTo(firstX, firstY);

    // 나머지 포인트들 - 부드러운 곡선으로 연결
    for (int i = 1; i < pointsToUse.length; i++) {
      final x = padding + (i * xStep);
      final y =
          padding + chartHeight - (pointsToUse[i] / maxValue * chartHeight);

      if (i == 1) {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        // 베지어 곡선으로 부드럽게 연결
        final prevX = padding + ((i - 1) * xStep);
        final prevY =
            padding +
            chartHeight -
            (pointsToUse[i - 1] / maxValue * chartHeight);

        final controlX = (prevX + x) / 2;

        path.quadraticBezierTo(controlX, prevY, x, y);
        fillPath.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    // Fill path 완성
    final lastX = padding + ((pointsToUse.length - 1) * xStep);
    fillPath.lineTo(lastX, padding + chartHeight);
    fillPath.close();

    // 그리기
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // 마지막 점 표시 (이번달 데이터인 경우에만)
    if (lineColor == const Color(0xFF1560FF)) {
      final lastPointX = padding + ((pointsToUse.length - 1) * xStep);
      final lastPointY =
          padding + chartHeight - (pointsToUse.last / maxValue * chartHeight);

      final circlePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(lastPointX, lastPointY), 5, borderPaint);
      canvas.drawCircle(Offset(lastPointX, lastPointY), 3.5, circlePaint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Size size,
    double chartWidth,
    double padding,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final labelStyle = TextStyle(color: Colors.grey[600], fontSize: 10);

    // 날짜 레이블 (1일, 중간, 31일)
    final labels = [
      {'text': '1.1', 'position': 0.0},
      {'text': '1.19', 'position': 18 / 31}, // 현재 날짜
      {'text': '1.31', 'position': 1.0},
    ];

    for (final label in labels) {
      textPainter.text = TextSpan(
        text: label['text'] as String,
        style: labelStyle,
      );
      textPainter.layout();

      final x =
          padding +
          (chartWidth * (label['position'] as double)) -
          textPainter.width / 2;
      final y = size.height - 8;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.thisMonthData != thisMonthData ||
        oldDelegate.lastMonthData != lastMonthData ||
        oldDelegate.currentDay != currentDay;
  }
}
