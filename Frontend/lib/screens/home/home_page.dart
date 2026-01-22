import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/config/theme.dart';
import 'package:my_app/screens/analysis/category_detail_page.dart';
import 'package:my_app/screens/bank/bank_selection_page.dart';
import 'package:my_app/services/transaction_service.dart';
import 'package:my_app/models/home_data.dart' as models;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // API 서비스
  final TransactionService _transactionService = TransactionService();

  // 로딩 상태
  bool isLoading = false;
  String? errorMessage;

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

  // 선택된 날짜 (캘린더에서 선택한 날짜)
  DateTime? selectedDate;

  // API에서 받아온 데이터
  models.AccumulatedData? accumulatedData;
  models.DailySummary? dailySummary;
  models.WeeklyData? weeklyData;
  models.MonthlyData? monthlyData;
  List<models.CategoryData>? categories;
  models.MonthComparison? monthComparison;
  Map<int, List<models.Transaction>> dailyTransactionsCache = {};

  // 더미 데이터 (백업용)
  final Map<int, int> _dummyDailyExpenses = {
    1: -118620,
    2: -75745,
    3: -57402,
    4: -53151,
    5: 133100,
    6: -87071,
    7: -25497,
    8: -22500,
    9: -20400,
    10: -37050,
    11: -5900,
    12: -26520,
    13: -13340,
    14: 7907,
    15: -13340,
    16: -14000,
    17: -14000,
    18: -35000,
    19: 183400,
    20: -13123,
    21: 9481,
    22: -11900,
  };

  // 데이터 접근 헬퍼 메서드들
  int get thisMonthTotal => accumulatedData?.total ?? 0;
  int get lastMonthSameDay => monthComparison?.lastMonthSameDay ?? 0;
  int get weeklyAverage => weeklyData?.average ?? 0;
  int get monthlyAverage => monthlyData?.average ?? 0;
  Map<int, int> get dailyExpenses =>
      dailySummary?.expenses ?? _dummyDailyExpenses;

  List<double> get thisMonthDailyData {
    return accumulatedData?.dailyData.map((e) => e.amount).toList() ??
        _dummyThisMonthData;
  }

  List<double> get lastMonthDailyData {
    return monthComparison?.lastMonthData.map((e) => e.amount).toList() ??
        _dummyLastMonthData;
  }

  Map<String, Map<String, dynamic>> get categoryData {
    if (categories == null) return _dummyCategoryData;

    final Map<String, Map<String, dynamic>> result = {};
    for (var category in categories!) {
      result[category.name] = {
        'amount': category.amount,
        'change': category.change,
        'percent': category.percent,
        'icon': category.emoji,
        'color': category.color,
      };
    }
    return result;
  }

  // 선택된 날짜의 거래 내역 가져오기
  List<models.Transaction> _getTransactionsForDate(int day) {
    return dailyTransactionsCache[day] ?? [];
  }

  // 더미 카테고리 데이터 (백업용)
  final Map<String, Map<String, dynamic>> _dummyCategoryData = {
    '쇼핑': {
      'amount': 317918,
      'change': -235312,
      'percent': 49,
      'icon': '🛍️',
      'color': Color(0xFF4CAF50),
    },
    '이체': {
      'amount': 142562,
      'change': -146449,
      'percent': 22,
      'icon': '🏦',
      'color': Color(0xFF2196F3),
    },
    '생활': {
      'amount': 83351,
      'change': 37551,
      'percent': 13,
      'icon': '🏠',
      'color': Color(0xFFFF9800),
    },
    '식비': {
      'amount': 48812,
      'change': -15388,
      'percent': 8,
      'icon': '🍴',
      'color': Color(0xFFFFEB3B),
    },
    '카페·간식': {
      'amount': 21000,
      'change': 21000,
      'percent': 3,
      'icon': '☕',
      'color': Color(0xFF9C27B0),
    },
  };

  // 더미 누적 데이터 (백업용)
  final List<double> _dummyThisMonthData = [
    0, 15000, 35000, 58000, 85000, 120000, 145000, // 1-7일
    180000, 215000, 245000, 280000, 320000, 365000, 395000, // 8-14일
    435000, 485000, 535000, 580000, 646137, // 15-19일
  ];

  final List<double> _dummyLastMonthData = [
    0, 25000, 55000, 95000, 145000, 195000, 240000, // 1-7일
    295000, 350000, 410000, 475000, 540000, 610000, 675000, // 8-14일
    735000, 795000, 860000, 920000, 1014051, 1070000, 1125000, // 15-21일
    1180000, 1235000, 1285000, 1340000, 1395000, 1445000, 1495000, // 22-28일
    1545000, 1595000, 1660000, // 29-31일
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  // 홈 페이지 데이터 로드
  Future<void> _loadHomeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final year = selectedMonth.year;
      final month = selectedMonth.month;

      // 병렬로 모든 API 호출
      final results = await Future.wait([
        _transactionService.getAccumulatedData(year, month),
        _transactionService.getDailySummary(year, month),
        _transactionService.getWeeklyAverage(year, month),
        _transactionService.getMonthlyAverage(year, month),
        _transactionService.getCategorySummary(year, month),
        _transactionService.getMonthComparison(year, month),
      ]);

      setState(() {
        accumulatedData = results[0] as models.AccumulatedData;
        dailySummary = results[1] as models.DailySummary;
        weeklyData = results[2] as models.WeeklyData;
        monthlyData = results[3] as models.MonthlyData;
        categories = results[4] as List<models.CategoryData>;
        monthComparison = results[5] as models.MonthComparison;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '데이터를 불러오는데 실패했습니다: $e';
        isLoading = false;
      });
    }
  }

  // 특정 날짜의 거래 내역 로드
  Future<void> _loadDailyTransactions(int day) async {
    if (dailyTransactionsCache.containsKey(day)) {
      return; // 이미 캐시에 있으면 다시 로드하지 않음
    }

    try {
      final transactions = await _transactionService.getDailyTransactions(
        selectedMonth.year,
        selectedMonth.month,
        day,
      );

      setState(() {
        dailyTransactionsCache[day] = transactions;
      });
    } catch (e) {
      print('거래 내역 로드 실패: $e');
    }
  }

  // 월 선택 변경 시
  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      selectedMonth = newMonth;
      selectedDate = null;
      dailyTransactionsCache.clear();
    });
    _loadHomeData();
  }

  @override
  void dispose() {
    topPageController.dispose();
    bottomPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(errorMessage!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadHomeData,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadHomeData,
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
      ),
    );
  }

  // 상단 월 선택 헤더
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
              _onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month - 1),
              );
            },
          ),
          Text(
            '${selectedMonth.month}월',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              _onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month + 1),
              );
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
            _buildIndicator('일간', 1),
            const SizedBox(width: 24),
            _buildIndicator('주간', 2),
            const SizedBox(width: 24),
            _buildIndicator('월간', 3),
          ],
        ),
        const SizedBox(height: 16),

        // 스크롤 가능한 페이지
        SizedBox(
          height: topPageIndex == 1 ? null : 320, // 일간 뷰는 높이 제한 없음
          child: topPageIndex == 1
              ? _buildDailyView() // 일간 뷰는 직접 표시
              : SizedBox(
                  height: 320,
                  child: PageView(
                    controller: topPageController,
                    onPageChanged: (pageIndex) {
                      setState(() {
                        // PageView 인덱스를 실제 topPageIndex로 변환
                        if (pageIndex == 0) {
                          topPageIndex = 0; // 누적
                        } else if (pageIndex == 1) {
                          topPageIndex = 2; // 주간
                        } else if (pageIndex == 2) {
                          topPageIndex = 3; // 월간
                        }
                      });
                    },
                    children: [
                      _buildAccumulatedView(), // PageView 0 = 누적
                      _buildWeeklyView(), // PageView 1 = 주간
                      _buildMonthlyView(), // PageView 2 = 월간
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, int index) {
    final isSelected = topPageIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          topPageIndex = index;
        });
        if (index != 1) {
          // 일간이 아닌 경우만 PageView 이동
          int pageIndex;
          if (index == 0) {
            pageIndex = 0; // 누적 → PageView 0
          } else if (index == 2) {
            pageIndex = 1; // 주간 → PageView 1
          } else {
            pageIndex = 2; // 월간 → PageView 2
          }
          topPageController.animateToPage(
            pageIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
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

          // 텍스트 정보
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '지난달 같은 기간보다\n'),
                TextSpan(
                  text: _formatCurrency(difference),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 덜 썼어요'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 월별 데이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMonthData('1월 19일까지', thisMonthTotal, Colors.green),
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

  // 일간 뷰 (캘린더)
  Widget _buildDailyView() {
    // 해당 월의 첫날과 마지막 날
    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDay = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    // 첫날의 요일 (0: 일요일, 6: 토요일)
    final firstWeekday = firstDay.weekday % 7;

    // 달력에 필요한 총 칸 수
    final totalCells = firstWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // 요일 헤더
          Row(
            children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 13,
                      color: day == '일'
                          ? Colors.red
                          : (day == '토' ? Colors.blue : Colors.grey[700]),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // 날짜 그리드
          ...List.generate(rows, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final cellIndex = weekIndex * 7 + dayIndex;
                  final dayNumber = cellIndex - firstWeekday + 1;

                  if (cellIndex < firstWeekday || dayNumber > daysInMonth) {
                    return Expanded(child: Container());
                  }

                  final expense = dailyExpenses[dayNumber];
                  final isSelected =
                      selectedDate?.day == dayNumber &&
                      selectedDate?.month == selectedMonth.month &&
                      selectedDate?.year == selectedMonth.year;
                  final isToday =
                      DateTime.now().day == dayNumber &&
                      DateTime.now().month == selectedMonth.month &&
                      DateTime.now().year == selectedMonth.year;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final isSameDate =
                            selectedDate?.day == dayNumber &&
                            selectedDate?.month == selectedMonth.month &&
                            selectedDate?.year == selectedMonth.year;

                        if (isSameDate) {
                          // 같은 날짜를 다시 클릭하면 선택 해제
                          setState(() {
                            selectedDate = null;
                          });
                        } else {
                          // 새로운 날짜 선택 및 거래 내역 로드
                          setState(() {
                            selectedDate = DateTime(
                              selectedMonth.year,
                              selectedMonth.month,
                              dayNumber,
                            );
                          });
                          await _loadDailyTransactions(dayNumber);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              dayNumber.toString(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday ? Colors.blue : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (expense != null && expense < 0)
                              Text(
                                _formatShortCurrency(expense),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else if (expense != null && expense > 0)
                              Text(
                                '+${_formatShortCurrency(expense)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),

          const SizedBox(height: 20),

          // 선택된 날짜의 거래 내역 (애니메이션 적용)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                selectedDate != null &&
                    selectedDate!.month == selectedMonth.month &&
                    selectedDate!.year == selectedMonth.year
                ? _buildDailyTransactions()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // 선택된 날짜의 거래 내역
  Widget _buildDailyTransactions() {
    if (selectedDate == null) return Container();

    final transactions = _getTransactionsForDate(selectedDate!.day);
    final totalExpense = dailyExpenses[selectedDate!.day] ?? 0;

    // 요일 이름
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayName = weekdays[selectedDate!.weekday - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${selectedDate!.day}일 ($weekdayName)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              _formatCurrencyFull(totalExpense),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: totalExpense < 0 ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 거래 내역 리스트
        if (transactions.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                '거래 내역이 없습니다',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          )
        else
          ...transactions.asMap().entries.map((entry) {
            final index = entry.key;
            final transaction = entry.value;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // 아이콘
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: transaction.color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        transaction.icon,
                        color: transaction.color,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 거래 정보
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (transaction.currency != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              transaction.currency!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // 금액
                    Text(
                      _formatCurrencyFull(transaction.amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: transaction.amount < 0
                            ? Colors.black
                            : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatShortCurrency(int amount) {
    if (amount.abs() >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    }
    return '${(amount / 1000).toStringAsFixed(0)}천';
  }

  // 주간 평균 뷰
  Widget _buildWeeklyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
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

          // 텍스트 정보
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '일주일 평균\n'),
                TextSpan(
                  text: _formatCurrency(weeklyAverage),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 정도 썼어요'),
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
            color: isToday ? const Color(0xFF4CAF50) : const Color(0xFFE0F2F1),
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

          // 텍스트 정보
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '월 평균\n'),
                TextSpan(
                  text: _formatCurrency(monthlyAverage),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 정도 썼어요'),
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
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE0F2F1),
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
    final entries = categoryData.entries.toList();

    if (entries.isEmpty) {
      return SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '지출 내역이 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to BankSelectionPage or equivalent
                // We need the user name, but often it's stored or we can pass a default
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankSelectionPage(name: 'User'),
                  ),
                );
              },
              child: const Text('카드 연결하기'),
            ),
          ],
        ),
      );
    }

    if (selectedCategoryIndex >= entries.length) {
      selectedCategoryIndex = 0;
    }

    final selectedEntry = entries[selectedCategoryIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 메시지
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: selectedEntry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '에\n가장 많이 썼어요'),
              ],
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
          color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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
                    : const Color(0xFF4CAF50),
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
    if (categoryData.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            '비교할 데이터가 없습니다.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final topCategory = categoryData.entries.first;
    final topChange = (topCategory.value['change'] as int).abs();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 메시지
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '지난달 이맘때 대비\n'),
                TextSpan(
                  text: topCategory.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' 지출이 줄었어요'),
              ],
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
                : (label.contains('1월') ? Colors.green : Colors.grey),
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
                  ? const Color(0xFF4CAF50)
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
    return '${amount < 0 ? '-' : ''}${formatted}원';
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

    // 이번달 그래프 그리기 (초록색, 현재 날짜까지만)
    _drawMonthLine(
      canvas,
      thisMonthData,
      maxValue,
      chartWidth,
      chartHeight,
      padding,
      const Color(0xFF4CAF50),
      const Color(0xFF4CAF50).withOpacity(0.1),
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
    if (lineColor == const Color(0xFF4CAF50)) {
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
