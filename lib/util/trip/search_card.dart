import 'package:flutter_app/util/trip/ride_card.dart';
import 'package:flutter_app/util/trip/ride_card_state.dart';

class SearchCard extends RideCard {
  const SearchCard(super.trip, {super.key});
  @override
  _SearchCard createState() => _SearchCard();
}

class _SearchCard extends RideCardState<SearchCard> {
  @override
  void initState() {
    super.initState();
    setState(() {
      super.ride = widget.trip;
      super.fullyLoaded = true;
    });
  }
}
