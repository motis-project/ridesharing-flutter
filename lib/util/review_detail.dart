import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_app/util/profiles/profile_chip.dart';
import 'package:flutter_app/util/supabase.dart';

import '../account/models/review.dart';
import 'profiles/custom_rating_bar_indicator.dart';

class ReviewDetail extends StatefulWidget {
  final Review review;
  const ReviewDetail({super.key, required this.review});

  @override
  State<ReviewDetail> createState() => _ReviewDetailState();
}

class _ReviewDetailState extends State<ReviewDetail> {
  late Review _review;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _review = widget.review;
    });

    loadReview();
  }

  Future<void> loadReview() async {
    Map<String, dynamic> data = await supabaseClient.from('reviews').select('''
      *,
      writer: writer_id(*)
    ''').eq('id', widget.review.id).single();

    setState(() {
      _review = Review.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget stars = Row(children: [
      if (_review.writer != null) ProfileChip(_review.writer!),
      CustomRatingBarIndicator(rating: _review.rating.toDouble(), size: CustomRatingBarIndicatorSize.small)
    ]);

    Widget categories = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      if (_review.comfortRating != null)
        Column(
          children: [
            const Text("Comfort"),
            Row(
              children: [Text(_review.comfortRating.toString()), const Icon(Icons.star)],
            )
          ],
        ),
      if (_review.safetyRating != null)
        Column(
          children: [
            const Text("Safety"),
            Row(
              children: [Text(_review.safetyRating.toString()), const Icon(Icons.star)],
            )
          ],
        ),
      if (_review.reliabilityRating != null)
        Column(
          children: [
            const Text("Reliability"),
            Row(
              children: [Text(_review.reliabilityRating.toString()), const Icon(Icons.star)],
            )
          ],
        ),
      if (_review.hospitalityRating != null)
        Column(
          children: [
            const Text("Hospitality"),
            Row(
              children: [Text(_review.hospitalityRating.toString()), const Icon(Icons.star)],
            )
          ],
        )
    ]);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(5),
        child: Column(
          children: [
            stars,
            if (_review.comfortRating != null ||
                _review.safetyRating != null ||
                _review.reliabilityRating != null ||
                _review.hospitalityRating != null)
              categories,
            if (_review.text != null)
              SizedBox(
                width: double.infinity,
                child: Text(_review.text!),
              ),
          ],
        ),
      ),
    );
  }
}
