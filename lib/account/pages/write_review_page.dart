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
      _review = data != null
          ? Review.fromJson(data)
          : Review(
              rating: 0,
              writerId: supabaseManager.currentProfile!.id!,
              receiverId: widget.profile.id!,
            );
      if (_review!.text != null) _textController.text = _review!.text!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: ProfileWidget(widget.profile),
      ),
      body: Center(
        child: _review == null
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    CustomRatingBar(
                      size: CustomRatingBarSize.huge,
                      rating: _review!.rating,
                      onRatingUpdate: onRatingUpdate,
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryReviews(),
                    const SizedBox(height: 10),
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
                        maxLines: 5,
                        onChanged: onTextUpdate,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LoadingButton(
                      onPressed: _onSubmit,
                      state: _state,
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
          _buildCategoryReviewRow(
            S.of(context).reviewCategoryComfort,
            _review!.comfortRating,
            onComfortRatingUpdate,
          ),
          _buildCategoryReviewRow(
            S.of(context).reviewCategorySafety,
            _review!.safetyRating,
            onSafetyRatingUpdate,
          ),
          _buildCategoryReviewRow(
            S.of(context).reviewCategoryReliability,
            _review!.reliabilityRating,
            onReliabilityRatingUpdate,
          ),
          _buildCategoryReviewRow(
            S.of(context).reviewCategoryHospitality,
            _review!.hospitalityRating,
            onHospitalityRatingUpdate,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryReviewRow(String category, int? rating, void Function(double) onRatingUpdate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(child: SizedBox(width: 100, child: Text(category))),
        const SizedBox(width: 10),
        CustomRatingBar(size: CustomRatingBarSize.large, rating: rating, onRatingUpdate: onRatingUpdate),
      ],
    );
  }

  void onRatingUpdate(double rating) {
    setState(() {
      _review!.rating = rating.toInt();
    });
  }

  void onComfortRatingUpdate(double rating) {
    setState(() {
      _review!.comfortRating = rating.toInt();
    });
  }

  void onSafetyRatingUpdate(double rating) {
    setState(() {
      _review!.safetyRating = rating.toInt();
    });
  }

  void onReliabilityRatingUpdate(double rating) {
    setState(() {
      _review!.reliabilityRating = rating.toInt();
    });
  }

  void onHospitalityRatingUpdate(double rating) {
    setState(() {
      _review!.hospitalityRating = rating.toInt();
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
      showSnackBar(context, S.of(context).pageWriteReviewRatingRequired, durationType: durationType);
      await Future<void>.delayed(durationType.duration);

      setState(() {
        _state = ButtonState.idle;
      });
      return;
    }

    setState(() {
      _state = ButtonState.loading;
    });
    if (_review!.id == null) {
      await supabaseManager.supabaseClient.from('reviews').insert(_review!.toJson());
    } else {
      await supabaseManager.supabaseClient.from('reviews').update(_review!.toJson()).eq('id', _review!.id);
    }
    setState(() {
      _state = ButtonState.success;
    });

    if (mounted) await Navigator.of(context).maybePop();
  }
}
