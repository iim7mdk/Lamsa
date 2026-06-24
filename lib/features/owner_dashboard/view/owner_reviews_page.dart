import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OwnerReviewsPage extends StatefulWidget {
  const OwnerReviewsPage({
    super.key,
    required this.salonId,
  });

  final String salonId;

  @override
  State<OwnerReviewsPage> createState() => _OwnerReviewsPageState();
}

class _OwnerReviewsPageState extends State<OwnerReviewsPage> {
  CollectionReference<Map<String, dynamic>> get _commentsRef {
    return FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('comments');
  }

  CollectionReference<Map<String, dynamic>> get _ratingsRef {
    return FirebaseFirestore.instance
        .collection('salons')
        .doc(widget.salonId)
        .collection('ratings');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _commentsStream {
    return _commentsRef.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _ratingsStream {
    return _ratingsRef.snapshots();
  }

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';

    final date = value.toDate();
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> _showReplyDialog({
    required String commentId,
    required String oldReply,
  }) async {
    final controller = TextEditingController(text: oldReply);

    final replyText = await showDialog<String>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(oldReply.isEmpty ? 'الرد على الزبونة' : 'تعديل الرد'),
            content: TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'اكتبي ردك هنا...',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, controller.text.trim());
                },
                child: const Text('حفظ الرد'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (replyText == null) return;

    if (replyText.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حفظ رد فارغ')),
      );
      return;
    }

    await _saveReply(
      commentId: commentId,
      replyText: replyText.trim(),
    );
  }

  Future<void> _saveReply({
    required String commentId,
    required String replyText,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    try {
      await _commentsRef.doc(commentId).update({
        'ownerReply': {
          'text': replyText,
          'ownerId': currentUser.uid,
          'repliedAt': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الرد بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ الرد: $e')),
      );
    }
  }

  Future<void> _deleteReply(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف الرد'),
            content: const Text('هل أنتِ متأكدة من حذف الرد؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm != true) return;

    try {
      await _commentsRef.doc(commentId).update({
        'ownerReply': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الرد')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف الرد: $e')),
      );
    }
  }

  double _calculateAverage(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return 0;

    final total = docs.fold<int>(0, (sum, doc) {
      final rating = doc.data()['rating'];
      return sum + ((rating as num?)?.toInt() ?? 0);
    });

    return total / docs.length;
  }

  Map<int, int> _ratingDistribution(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final result = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    for (final doc in docs) {
      final rating = (doc.data()['rating'] as num?)?.toInt();

      if (rating != null && rating >= 1 && rating <= 5) {
        result[rating] = (result[rating] ?? 0) + 1;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7FA),
        appBar: AppBar(
          title: const Text('التعليقات والتقييمات'),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ratingsStream,
          builder: (context, ratingSnapshot) {
            if (ratingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final ratingDocs = ratingSnapshot.data?.docs ?? [];
            final average = _calculateAverage(ratingDocs);
            final distribution = _ratingDistribution(ratingDocs);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _commentsStream,
              builder: (context, commentsSnapshot) {
                if (commentsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (commentsSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'حدث خطأ أثناء تحميل التعليقات:\n${commentsSnapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final comments = commentsSnapshot.data?.docs ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _HeaderCard(
                        average: average,
                        ratingCount: ratingDocs.length,
                        commentsCount: comments.length,
                      ),
                      const SizedBox(height: 14),

                      _RatingDistributionCard(
                        distribution: distribution,
                        total: ratingDocs.length,
                      ),
                      const SizedBox(height: 20),

                      const _SectionTitle(
                        title: 'تعليقات الزبونات',
                        subtitle: 'يمكنك الرد على كل تعليق يظهر هنا',
                        icon: Icons.chat_bubble_outline,
                      ),
                      const SizedBox(height: 10),

                      if (comments.isEmpty)
                        const _EmptyCommentsCard()
                      else
                        ...comments.map((doc) {
                          final data = doc.data();

                          final userName =
                          data['userName']?.toString().trim().isNotEmpty ==
                              true
                              ? data['userName'].toString()
                              : 'زبونة';

                          final text = data['text']?.toString() ?? '';

                          final createdAtText = _formatDate(data['createdAt']);

                          final ownerReply = data['ownerReply'];
                          String ownerReplyText = '';
                          String ownerReplyDate = '';

                          if (ownerReply is Map) {
                            ownerReplyText =
                                ownerReply['text']?.toString() ?? '';
                            ownerReplyDate =
                                _formatDate(ownerReply['repliedAt']);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CommentCard(
                              userName: userName,
                              text: text,
                              createdAtText: createdAtText,
                              ownerReplyText: ownerReplyText,
                              ownerReplyDate: ownerReplyDate,
                              onReply: () {
                                _showReplyDialog(
                                  commentId: doc.id,
                                  oldReply: ownerReplyText,
                                );
                              },
                              onDeleteReply: ownerReplyText.isEmpty
                                  ? null
                                  : () => _deleteReply(doc.id),
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.average,
    required this.ratingCount,
    required this.commentsCount,
  });

  final double average;
  final int ratingCount;
  final int commentsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.shade300,
            Colors.pink.shade100,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.90),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ratingCount == 0 ? '-' : average.toStringAsFixed(1),
                  style: TextStyle(
                    color: Colors.pink.shade400,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'من 5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'متوسط تقييم الصالون',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                _StarsView(value: average),
                const SizedBox(height: 8),
                Text(
                  '$ratingCount تقييم · $commentsCount تعليق',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDistributionCard extends StatelessWidget {
  const _RatingDistributionCard({
    required this.distribution,
    required this.total,
  });

  final Map<int, int> distribution;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [5, 4, 3, 2, 1].map((star) {
            final count = distribution[star] ?? 0;
            final value = total == 0 ? 0.0 : count / total;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade700,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.pink.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$count',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.userName,
    required this.text,
    required this.createdAtText,
    required this.ownerReplyText,
    required this.ownerReplyDate,
    required this.onReply,
    required this.onDeleteReply,
  });

  final String userName;
  final String text;
  final String createdAtText;
  final String ownerReplyText;
  final String ownerReplyDate;
  final VoidCallback onReply;
  final VoidCallback? onDeleteReply;

  @override
  Widget build(BuildContext context) {
    final hasReply = ownerReplyText.trim().isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink.shade50,
                  child: Icon(
                    Icons.person,
                    color: Colors.pink.shade300,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (createdAtText.isNotEmpty)
                  Text(
                    createdAtText,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),

            if (hasReply)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storefront,
                          color: Colors.pink.shade300,
                          size: 19,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'رد صاحبة الصالون',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        if (ownerReplyDate.isNotEmpty)
                          Text(
                            ownerReplyDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ownerReplyText,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReply,
                    icon: Icon(hasReply ? Icons.edit : Icons.reply),
                    label: Text(hasReply ? 'تعديل الرد' : 'الرد على التعليق'),
                  ),
                ),
                if (hasReply) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDeleteReply,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'حذف الرد',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.pink.shade50,
          child: Icon(
            icon,
            color: Colors.pink.shade300,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarsView extends StatelessWidget {
  const _StarsView({
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starNumber = index + 1;

        IconData icon;

        if (value >= starNumber) {
          icon = Icons.star_rounded;
        } else if (value >= starNumber - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_border_rounded;
        }

        return Icon(
          icon,
          color: Colors.amber.shade700,
          size: 25,
        );
      }),
    );
  }
}

class _EmptyCommentsCard extends StatelessWidget {
  const _EmptyCommentsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 58,
              color: Colors.pink.shade100,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد تعليقات بعد',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ستظهر تعليقات الزبونات هنا عند إضافتها من صفحة الصالون.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}