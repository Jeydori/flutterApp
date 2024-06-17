class Review {
  final String userId;
  final int rating;
  final String comment;
  final DateTime timestamp;

  Review(
      {required this.userId,
      required this.rating,
      required this.comment,
      required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
