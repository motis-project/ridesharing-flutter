import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:progress_state_button/progress_button.dart';

import '../../util/buttons/loading_button.dart';
import '../../util/profiles/profile_widget.dart';
import '../../util/profiles/reviews/custom_rating_bar.dart';
import '../../util/profiles/reviews/custom_rating_bar_size.dart';
import '../../util/snackbar.dart';
import '../../util/supabase_manager.dart';
import '../models/profile.dart';
import '../models/review.dart';

class WriteReviewPage extends StatefulWidget {
  final Profile profile;

  const WriteReviewPage(this.profile, {super.key});

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  bool ratingChangedManually = false;
  late Review _previousReview;
  Review? _review;
  late TextEditingController _textController;
  ButtonState _state = ButtonState.idle;

  @override
  void initState() {
    loadReview();
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> loadReview() async {
    final Map<String, dynamic>? data = await supabaseManager.supabaseClient
        .from('reviews')
        .select<Map<String, dynamic>?>()
        .eq('receiver_id', widget.profile.id)
        .eq('writer_id', supabaseManager.currentProfile!.id)
        .limit(1)
        .maybeSingle();
    setState(() {
      _previousReview = data != null
          ? Review.fromJson(data)
          : Review(
              rating: 0,
              writerId: supabaseManager.currentProfile!.id!,
              receiverId: widget.profile.id!,
            );
      _review = _previousReview.copyWith();
      if (_review!.text != null) _textController.text = _review!.text!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ProfileWidget(widget.profile),
      ),
      body: Center(
        child: _review == null
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text(S.of(context).reviewOverall, style: Theme.of(context).textTheme.titleLarge),
                    CustomRatingBar(
                      size: CustomRatingBarSize.huge,
                      rating: _review!.rating,
                      onRatingUpdate: onRatingUpdate,
                      key: const Key('overallRating'),
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryReviews(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: S.of(context).pageWriteReviewReview,
                          hintText: S.of(context).pageWriteReviewReviewHint,
                          alignLabelWithHint: true,
                        ),
                        textAlignVertical: TextAlignVertical.top,
                        maxLines: 6,
                        onChanged: onTextUpdate,
                        key: const Key('reviewText'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LoadingButton(
                      onPressed: _onSubmit,
                      state: _state,
                      key: const Key('submitButton'),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryReviews() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: <Widget>[
          Text(S.of(context).reviewCategoryComfort),
          const SizedBox(width: 10),
          CustomRatingBar(
            size: CustomRatingBarSize.huge,
            rating: _review!.comfortRating,
            onRatingUpdate: onComfortRatingUpdate,
            key: const Key('comfortRating'),
          ),
          const SizedBox(height: 10),
          Text(S.of(context).reviewCategorySafety),
          const SizedBox(width: 10),
          CustomRatingBar(
            size: CustomRatingBarSize.huge,
            rating: _review!.safetyRating,
            onRatingUpdate: onSafetyRatingUpdate,
            key: const Key('safetyRating'),
          ),
          const SizedBox(height: 10),
          Text(S.of(context).reviewCategoryReliability),
          const SizedBox(width: 10),
          CustomRatingBar(
            size: CustomRatingBarSize.huge,
            rating: _review!.reliabilityRating,
            onRatingUpdate: onReliabilityRatingUpdate,
            key: const Key('reliabilityRating'),
          ),
          const SizedBox(height: 10),
          Text(S.of(context).reviewCategoryHospitality),
          const SizedBox(width: 10),
          CustomRatingBar(
            size: CustomRatingBarSize.huge,
            rating: _review!.hospitalityRating,
            onRatingUpdate: onHospitalityRatingUpdate,
            key: const Key('hospitalityRating'),
          ),
        ],
      ),
    );
  }

  void onRatingUpdate(double rating) {
    ratingChangedManually = true;
    setState(() {
      _review!.rating = rating.toInt();
    });
  }

  void _updateOverallReview() {
    if (!ratingChangedManually) {
      final List<int> givenCategoryRatings = <int?>[
        _review!.comfortRating,
        _review!.safetyRating,
        _review!.hospitalityRating,
        _review!.reliabilityRating
      ].whereType<int>().toList();
      _review!.rating = givenCategoryRatings.average.round();
    }
  }

  void onComfortRatingUpdate(double rating) {
    setState(() {
      _review!.comfortRating = rating.toInt();
      _updateOverallReview();
    });
  }

  void onSafetyRatingUpdate(double rating) {
    setState(() {
      _review!.safetyRating = rating.toInt();
      _updateOverallReview();
    });
  }

  void onReliabilityRatingUpdate(double rating) {
    setState(() {
      _review!.reliabilityRating = rating.toInt();
      _updateOverallReview();
    });
  }

  void onHospitalityRatingUpdate(double rating) {
    setState(() {
      _review!.hospitalityRating = rating.toInt();
      _updateOverallReview();
    });
  }

  void onTextUpdate(String text) {
    setState(() {
      _review!.text = text;
    });
  }

  Future<void> _onSubmit() async {
    if (_review!.rating == 0) {
      setState(() {
        _state = ButtonState.fail;
      });
      const SnackBarDurationType durationType = SnackBarDurationType.short;
      showSnackBar(
        context,
        S.of(context).pageWriteReviewRatingRequired,
        durationType: durationType,
        key: const Key('ratingRequiredSnackbar'),
      );
      await Future<void>.delayed(durationType.duration);

      setState(() {
        _state = ButtonState.idle;
      });
      return;
    }

    setState(() {
      _state = ButtonState.loading;
    });

    if (_review!.isChangedFrom(_previousReview)) {
      if (_review!.id == null) {
        await supabaseManager.supabaseClient.from('reviews').insert(_review!.toJson());
      } else {
        _review!.updatedAt = DateTime.now();
        await supabaseManager.supabaseClient.from('reviews').update(_review!.toJson()).eq('id', _review!.id);
      }
    }

    setState(() {
      _state = ButtonState.success;
    });

    if (mounted) await Navigator.of(context).maybePop();
  }
}
