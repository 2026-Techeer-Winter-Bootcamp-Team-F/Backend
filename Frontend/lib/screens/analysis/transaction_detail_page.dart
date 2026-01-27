import 'package:flutter/material.dart';

class TransactionDetailPage extends StatefulWidget {
  final String merchantName;
  final String categoryIcon;
  final int amount;
  final String paymentMethod;
  final Color color;

  const TransactionDetailPage({
    super.key,
    required this.merchantName,
    required this.categoryIcon,
    required this.amount,
    required this.paymentMethod,
    required this.color,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  // 최근 3개월 거래 내역
  final List<Map<String, dynamic>> recentTransactions = [
    {
      'date': '15일 (목)',
      'name': '쿠팡',
      'detail': '토스뱅크 통장',
      'amount': -13340,
      'paymentMethod': '출금',
    },
    {
      'date': '2025년 12월 29일 (월)',
      'name': '쿠팡와우월회비',
      'detail': 'KB중금통장-자축예금',
      'amount': -7890,
      'paymentMethod': '출금',
    },
    {
      'date': '2025년 12월 21일 (일)',
      'name': '쿠팡',
      'detail': '토스뱅크 통장',
      'amount': -9000,
      'paymentMethod': '출금',
    },
    {
      'date': '2025년 12월 19일 (금)',
      'name': '쿠팡',
      'detail': '토스뱅크 통장',
      'amount': -21500,
      'paymentMethod': '출금',
    },
  ];

  int get totalTransactionCount => recentTransactions.length;
  
  int get totalAmount => recentTransactions.fold<int>(
    0,
    (sum, transaction) => sum + (transaction['amount'] as int),
  );

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
          '상세 내역',
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
            // 거래 정보 헤더
            _buildTransactionHeader(),

            const SizedBox(height: 24),

            // 최근 거래 통계
            _buildRecentStatistics(),

            const SizedBox(height: 24),

            // 거래 내역 리스트
            _buildTransactionList(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // 거래 정보 헤더
  Widget _buildTransactionHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 카테고리 아이콘과 이름
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.categoryIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.merchantName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 금액 (수정 가능 아이콘 포함)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatCurrencyFull(widget.amount),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.edit_outlined,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 최근 거래 통계
  Widget _buildRecentStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이 가맹점에서',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            '최근 3개월동안 거래한 내역',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem('거래횟수', '$totalTransactionCount회'),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _buildStatItem('총 금액', _formatCurrencyFull(totalAmount)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 거래 내역 리스트
  Widget _buildTransactionList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = recentTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  // 거래 항목
  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            transaction['date'] as String,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),

        // 거래 정보 카드
        Container(
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction['detail'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
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
      ],
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
