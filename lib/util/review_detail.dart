import 'package:flutter/material.dart';
import 'package:flutter_app/util/profiles/profile_chip.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();

    setState(() {
      _review = widget.review;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget header = Row(children: [
      ProfileChip(_review.writer!),
      Text(DateFormat('dd.MM.yyyy').format(_review.createdAt!), style: const TextStyle(color: Colors.grey)),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: CustomRatingBarIndicator(
            rating: _review.rating.toDouble(),
            size: CustomRatingBarIndicatorSize.medium,
          ),
        ),
      ),
    ]);

    // Row categories = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    //   if (_review.comfortRating != null)
    //     Column(
    //       children: [
    //         const Text("Comfort"),
    //         Row(
    //           children: [Text(_review.comfortRating.toString()), const Icon(Icons.star)],
    //         )
    //       ],
    //     ),
    //   if (_review.safetyRating != null)
    //     Column(
    //       children: [
    //         const Text("Safety"),
    //         Row(
    //           children: [Text(_review.safetyRating.toString()), const Icon(Icons.star)],
    //         )
    //       ],
    //     ),
    //   if (_review.reliabilityRating != null)
    //     Column(
    //       children: [
    //         const Text("Reliability"),
    //         Row(
    //           children: [Text(_review.reliabilityRating.toString()), const Icon(Icons.star)],
    //         )
    //       ],
    //     ),
    //   if (_review.hospitalityRating != null)
    //     Column(
    //       children: [
    //         const Text("Hospitality"),
    //         Row(
    //           children: [Text(_review.hospitalityRating.toString()), const Icon(Icons.star)],
    //         )
    //       ],
    //     )
    // ]);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            header,
            if (_review.text?.isNotEmpty ?? false) ...[
              const SizedBox(
                height: 5,
              ),
              SizedBox(
                width: double.infinity,
                child: Text(_review.text!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
