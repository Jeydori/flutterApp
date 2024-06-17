import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'review_model.dart';

class FirebaseReviewsService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> submitReview(String driverId, int rating, String comment) async {
    User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    Review review = Review(
      userId: currentUser.uid,
      rating: rating,
      comment: comment,
      timestamp: DateTime.now(),
    );

    await _dbRef
        .child('Drivers')
        .child(driverId)
        .child('reviews')
        .push()
        .set(review.toJson());
    print("Review submitted successfully under driver ID: $driverId");
  }
}
