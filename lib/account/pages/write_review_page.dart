import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:motis_mitfahr_app/util/buttons/loading_button.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_size.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:progress_state_button/progress_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  void loadReview() async {
    Map<String, dynamic>? data = await SupabaseManager.supabaseClient
        .from('reviews')
        .select('*')
        .eq('receiver_id', widget.profile.id)
        .eq('writer_id', SupabaseManager.getCurrentProfile()!.id!)
        .limit(1)
        .maybeSingle();
    setState(() {
      _review = data != null
          ? Review.fromJson(data)
          : Review(
              rating: 0,
              writerId: SupabaseManager.getCurrentProfile()!.id!,
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
                  children: [
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
        children: [
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

  Widget _buildCategoryReviewRow(String category, int? rating, Function(double) onRatingUpdate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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

  void _onSubmit() async {
    if (_review!.rating == 0) {
      setState(() {
        _state = ButtonState.fail;
      });
      Duration duration = const Duration(seconds: 1);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).pageWriteReviewRatingRequired),
        duration: duration,
      ));
      await Future.delayed(duration);
      setState(() {
        _state = ButtonState.idle;
      });
      return;
    }

    setState(() {
      _state = ButtonState.loading;
    });
    if (_review!.id == null) {
      await SupabaseManager.supabaseClient.from('reviews').insert(_review!.toJson());
    } else {
      await SupabaseManager.supabaseClient.from('reviews').update(_review!.toJson()).eq('id', _review!.id);
    }
    setState(() {
      _state = ButtonState.success;
    });

    if (mounted) Navigator.of(context).maybePop();
  }
}
