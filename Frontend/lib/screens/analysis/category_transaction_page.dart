import 'package:flutter/material.dart';
import 'transaction_detail_page.dart';

class CategoryTransactionPage extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final int amount;
  final int change;
  final int percent;
  final Color color;

  const CategoryTransactionPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.change,
    required this.percent,
    required this.color,
  });

  @override
  State<CategoryTransactionPage> createState() =>
      _CategoryTransactionPageState();
}

class _CategoryTransactionPageState extends State<CategoryTransactionPage> {
  // 정렬 옵션
  String selectedSort = '최신순';
  final List<String> sortOptions = ['최신순', '고액순'];

  // 거래 내역 데이터 (날짜별 그룹화)
  final Map<String, List<Map<String, dynamic>>> transactions = {
    '17일 (토)': [
      {
        'name': 'Apple Inc',
        'detail': '카카오페이 머니',
        'amount': -14000,
        'paymentMethod': '결제',
        'icon': '🛍️',
        'time': '1건',
      },
      {
        'name': '쿠팡',
        'detail': '토스뱅크 통장',
        'amount': -13340,
        'paymentMethod': '출금',
        'icon': '🛍️',
        'time': '1건',
      },
    ],
    '15일 (목)': [
      {
        'name': '쿠팡',
        'detail': '토스뱅크 통장',
        'amount': -13340,
        'paymentMethod': '출금',
        'icon': '🛍️',
        'time': '1건',
      },
    ],
    '13일 (화)': [
      {
        'name': '올리브영',
        'detail': 'Npay 머니',
        'amount': -26520,
        'paymentMethod': '결제',
        'icon': '🛍️',
        'time': '1건',
      },
    ],
    '10일 (토)': [
      {
        'name': '신세계백화점진천이마전',
        'detail': '토스뱅크 체크카드',
        'amount': -37050,
        'paymentMethod': '일시불',
        'icon': '🛍️',
        'time': '1건',
      },
    ],
  };

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
      body: Column(
        children: [
          // 카테고리 헤더
          _buildCategoryHeader(),

          // 정렬 옵션
          _buildSortOptions(),

          // 거래 내역 리스트
          Expanded(
            child: _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  // 카테고리 헤더
  Widget _buildCategoryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리명 + 퍼센트
          Row(
            children: [
              Text(
                widget.categoryName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.percent}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 금액
          Text(
            _formatCurrencyFull(widget.amount),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // 지난달 대비
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                children: [
                  const TextSpan(text: '지난달 같은 기간보다 '),
                  TextSpan(
                    text: _formatCurrencyFull(widget.change),
                    style: TextStyle(
                      color: widget.change < 0
                          ? const Color(0xFF1560FF)
                          : const Color(0xFFFF5252),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 정렬 옵션
  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ...sortOptions.map((option) {
            final isSelected = selectedSort == option;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedSort = option;
                  });
                },
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[500],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 거래 내역 리스트
  Widget _buildTransactionList() {
    // 정렬 적용
    List<MapEntry<String, List<Map<String, dynamic>>>> sortedEntries;
    
    if (selectedSort == '고액순') {
      // 모든 거래를 하나의 리스트로 합치고 금액순으로 정렬
      final allTransactions = <Map<String, dynamic>>[];
      transactions.forEach((date, items) {
        for (var item in items) {
          allTransactions.add({...item, 'date': date});
        }
      });
      
      // 금액 절댓값 기준으로 내림차순 정렬
      allTransactions.sort((a, b) {
        final amountA = (a['amount'] as int).abs();
        final amountB = (b['amount'] as int).abs();
        return amountB.compareTo(amountA);
      });
      
      // 날짜별로 다시 그룹화
      final Map<String, List<Map<String, dynamic>>> regrouped = {};
      for (var item in allTransactions) {
        final date = item['date'] as String;
        if (!regrouped.containsKey(date)) {
          regrouped[date] = [];
        }
        final itemCopy = Map<String, dynamic>.from(item);
        itemCopy.remove('date');
        regrouped[date]!.add(itemCopy);
      }
      
      sortedEntries = regrouped.entries.toList();
    } else {
      // 최신순 (기본)
      sortedEntries = transactions.entries.toList();
    }
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: sortedEntries.map((entry) {
        return _buildDateGroup(entry.key, entry.value);
      }).toList(),
    );
  }

  // 날짜별 그룹
  Widget _buildDateGroup(String date, List<Map<String, dynamic>> items) {
    // 해당 날짜의 총 금액 계산
    final totalAmount = items.fold<int>(
      0,
      (sum, item) => sum + (item['amount'] as int).abs(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_formatCurrencyFull(-totalAmount)} · ${items.length}건',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),

        // 거래 항목들
        ...items.map((transaction) => _buildTransactionItem(transaction)),

        const SizedBox(height: 8),
      ],
    );
  }

  // 거래 항목
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailPage(
              merchantName: transaction['name'] as String,
              categoryIcon: widget.categoryIcon,
              amount: transaction['amount'] as int,
              paymentMethod: transaction['detail'] as String,
              color: widget.color,
            ),
          ),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                widget.categoryIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 거래 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['name'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['detail'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 금액 및 결제수단
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrencyFull(transaction['amount'] as int),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction['paymentMethod'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
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
