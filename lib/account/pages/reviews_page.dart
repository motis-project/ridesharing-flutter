import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/models/ride.dart';
import '../../util/buttons/button.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/profiles/reviews/aggregate_review_widget.dart';
import '../../util/supabase.dart';
import '../models/profile.dart';
import '../models/review.dart';
import '../widgets/review_detail.dart';
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
    List<Map<String, dynamic>> commonRidesData = await SupabaseManager.supabaseClient.from('rides').select('''
          *,
          drive: drives!inner(*)
        ''').eq('rider_id', SupabaseManager.getCurrentProfile()!.id).eq('drive.driver_id', _profileId);

    setState(() {
      _profile = Profile.fromJson(profileData);
      List<Ride> rides = Ride.fromJsonList(commonRidesData);
      _hasReviewed = _profile!.reviewsReceived!.any((Review review) => review.writer!.isCurrentUser);
      _reviewable = rides.any((Ride ride) => ride.isFinished && ride.status == RideStatus.approved);
    });
  }

  @override
  Widget build(BuildContext context) {
    Button reviewButton = Button(
      _hasReviewed ? S.of(context).pageReviewsUpdateRating : S.of(context).pageReviewsRate,
      onPressed: () => _navigateToRatePage(),
    );
    List<Review> reviews = _profile!.reviewsReceived!..sort((Review a, Review b) => a.compareTo(b));
    AggregateReviewWidget aggregated = AggregateReviewWidget(AggregateReview.fromReviews(reviews));
    Column reviewColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: List<ReviewDetail>.generate(
        reviews.length,
        (int index) => ReviewDetail(review: reviews[index]),
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
                    children: <Widget>[
                      ProfileWidget(_profile!),
                      const SizedBox(
                        height: 20,
                      ),
                      if (_reviewable) ...<Widget>[
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
        .push(MaterialPageRoute<void>(builder: (BuildContext context) => WriteReviewPage(_profile!)))
        .then((_) => load());
  }
}
