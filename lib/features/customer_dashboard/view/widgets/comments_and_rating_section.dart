import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/service/review_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsAndRatingSection extends StatefulWidget {
  final String salonId;

  const CommentsAndRatingSection({
    super.key,
    required this.salonId,
  });

  @override
  State<CommentsAndRatingSection> createState() =>
      _CommentsAndRatingSectionState();
}

class _CommentsAndRatingSectionState extends State<CommentsAndRatingSection> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();

  late Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _eligibleBooking;

  int _selectedRating = 0;
  bool _savingComment = false;
  bool _savingRating = false;

  @override
  void initState() {
    super.initState();
    _eligibleBooking =
        _reviewService.getEligibleBookingForRating(widget.salonId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    try {
      setState(() => _savingComment = true);

      await _reviewService.addComment(
        salonId: widget.salonId,
        text: _commentController.text,
      );

      _commentController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة التعليق بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _savingComment = false);
    }
  }

  Future<void> _addRating(String bookingId) async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختاري عدد النجوم أولاً')),
      );
      return;
    }

    try {
      setState(() => _savingRating = true);

      await _reviewService.addRating(
        salonId: widget.salonId,
        bookingId: bookingId,
        rating: _selectedRating,
      );

      if (!mounted) return;

      setState(() {
        _selectedRating = 0;
        _eligibleBooking =
            _reviewService.getEligibleBookingForRating(widget.salonId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة التقييم بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _savingRating = false);
    }
  }

  String _timeAgo(dynamic value) {
    if (value == null) return 'الآن';

    DateTime date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else {
      return '';
    }

    final diff = DateTime.now().difference(date);

    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes == 1) {
      return 'قبل دقيقة';
    } else if (diff.inMinutes < 60) {
      return 'قبل ${diff.inMinutes} دقائق';
    } else if (diff.inHours == 1) {
      return 'قبل ساعة';
    } else if (diff.inHours < 24) {
      return 'قبل ${diff.inHours} ساعات';
    } else if (diff.inDays == 1) {
      return 'قبل يوم';
    } else if (diff.inDays < 7) {
      return 'قبل ${diff.inDays} أيام';
    } else if (diff.inDays < 30) {
      return 'قبل ${(diff.inDays / 7).floor()} أسابيع';
    } else if (diff.inDays < 365) {
      return 'قبل ${(diff.inDays / 30).floor()} أشهر';
    } else {
      return 'قبل ${(diff.inDays / 365).floor()} سنوات';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التقييمات والتعليقات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _reviewService.ratingsStream(widget.salonId),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            double average = 0;
            if (docs.isNotEmpty) {
              final sum = docs.fold<int>(
                0,
                    (total, doc) =>
                total + ((doc.data()['rating'] as num?)?.toInt() ?? 0),
              );
              average = sum / docs.length;
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      docs.isEmpty
                          ? 'لا توجد تقييمات بعد'
                          : '${average.toStringAsFixed(1)} من 5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('${docs.length} تقييم'),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
          future: _eligibleBooking,
          builder: (context, snapshot) {
            final booking = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (booking == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'يمكنك التقييم بعد قبول الحجز وانتهاء موعده.',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'قيّمي تجربتك',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _StarSelector(
                      value: _selectedRating,
                      onChanged: (value) {
                        setState(() => _selectedRating = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _savingRating
                            ? null
                            : () => _addRating(booking.id),
                        child: _savingRating
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('إرسال التقييم'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'اكتبي تعليقك',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingComment ? null : _addComment,
                    child: _savingComment
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('إضافة تعليق'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _reviewService.commentsStream(widget.salonId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: Text('لا توجد تعليقات بعد')),
                ),
              );
            }

            return Column(
              children: docs.map((doc) {
                final data = doc.data();
                final userName = data['userName']?.toString() ?? 'مستخدم';
                final text = data['text']?.toString() ?? '';
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                final timeText = _timeAgo(data['createdAt']);
                final commentUserId = data['userId']?.toString();
                final canDelete = currentUserId != null && currentUserId == commentUserId;
                final ownerReply = data['ownerReply'];
                String ownerReplyText = '';

                if (ownerReply is Map) {
                  ownerReplyText = ownerReply['text']?.toString() ?? '';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Text(
                                text,
                                style: const TextStyle(height: 1.4),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                timeText,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),

                              if (ownerReplyText.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.pink.shade100,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.storefront,
                                            size: 18,
                                            color: Colors.pink.shade300,
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'رد صاحبة الصالون',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        ownerReplyText,
                                        style: const TextStyle(height: 1.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (canDelete)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'حذف التعليق',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('حذف التعليق'),
                                    content: const Text(
                                      'هل أنت متأكد من حذف هذا التعليق؟',
                                    ),
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
                                  );
                                },
                              );

                              if (confirm != true) return;

                              try {
                                await _reviewService.deleteComment(
                                  salonId: widget.salonId,
                                  commentId: doc.id,
                                );

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حذف التعليق')),
                                );
                              } catch (e) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StarSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StarSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final starNumber = index + 1;

        return IconButton(
          onPressed: () => onChanged(starNumber),
          icon: Icon(
            starNumber <= value ? Icons.star : Icons.star_border,
            color: Colors.amber.shade700,
            size: 32,
          ),
        );
      }),
    );
  }
}


