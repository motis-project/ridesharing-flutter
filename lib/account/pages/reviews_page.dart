import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/widgets/review_detail.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/buttons/button.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/aggregate_review_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/review.dart';
import 'write_review_page.dart';

class ReviewsPage extends StatefulWidget {
  final int profileId;
  final Profile? profile;

  const ReviewsPage({super.key, required this.profileId}) : profile = null;
  ReviewsPage.fromProfile(this.profile, {super.key}) : profileId = profile!.id!;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  late final int _profileId;
  Profile? _profile;
  bool _reviewable = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _profileId = widget.profileId;
      if (widget.profile != null) _profile = widget.profile!;
    });

    load();
  }

  Future<void> load() async {
    Map<String, dynamic> profileData = await SupabaseManager.supabaseClient.from('profiles').select('''
      *,
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      )''').eq('id', _profileId).single();
    List<dynamic> commonRidesData = await SupabaseManager.supabaseClient.from('rides').select('''
          *,
          drive: drives!inner(*)
        ''').eq('rider_id', SupabaseManager.getCurrentProfile()!.id).eq('drive.driver_id', _profileId);

    setState(() {
      _profile = Profile.fromJson(profileData);
      List<Ride> rides = Ride.fromJsonList(commonRidesData);
      _hasReviewed = _profile!.reviewsReceived!.any((review) => review.writer!.isCurrentUser);
      _reviewable = rides.any((ride) => ride.isFinished && ride.status == RideStatus.approved);
    });
  }

  @override
  Widget build(BuildContext context) {
    Button reviewButton = Button(
      _hasReviewed ? S.of(context).pageReviewsUpdateRating : S.of(context).pageReviewsRate,
      onPressed: () => _navigateToRatePage(),
    );
    List<Review> reviews = _profile!.reviewsReceived!..sort((a, b) => a.compareTo(b));
    AggregateReviewWidget aggregated = AggregateReview.fromReviews(reviews).widget();
    Column reviewColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        reviews.length,
        (index) => ReviewDetail(review: reviews[index]),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).pageReviewsTitle),
      ),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Column(
                    children: [
                      ProfileWidget(_profile!),
                      const SizedBox(
                        height: 20,
                      ),
                      if (_reviewable) ...[
                        reviewButton,
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                      aggregated,
                      const SizedBox(
                        height: 20,
                      ),
                      reviewColumn,
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _navigateToRatePage() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => WriteReviewPage(_profile!)),
        )
        .then((value) => load());
  }
}
