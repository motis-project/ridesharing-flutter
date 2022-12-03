import 'package:flutter/material.dart';
import 'package:flutter_app/util/search/address_search_delegate.dart';
import 'package:flutter_app/util/search/address_suggestion.dart';

class AddressSearchField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final String validatorEmptyText;
  final TextEditingController controller;

  const AddressSearchField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.validatorEmptyText,
    required this.controller,
  });

  factory AddressSearchField.start({
    required TextEditingController controller,
  }) {
    return AddressSearchField(
      labelText: 'Start',
      hintText: 'Enter your starting Location',
      validatorEmptyText: 'Please enter a starting location',
      controller: controller,
    );
  }

  factory AddressSearchField.destination({
    required TextEditingController controller,
  }) {
    return AddressSearchField(
      labelText: 'Destination',
      hintText: 'Enter your destination',
      validatorEmptyText: 'Please enter a destination',
      controller: controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validatorEmptyText;
        }
        return null;
      },
      onTap: () async {
        final AddressSuggestion? addressSuggestion = await showSearch(
          context: context,
          delegate: AddressSearchDelegate(),
          query: controller.text,
        );

        if (addressSuggestion != null) {
          controller.text = addressSuggestion.name;
        }
      },
    );
  }
}

// class AddressSearchFieldState extends State<AddressSearchField> {
//   final FocusNode _focusNode = FocusNode();
//   late OverlayEntry _overlayEntry;
//   final LayerLink _layerLink = LayerLink();

//   bool _isSearching = false;
//   List<AddressSuggestion> _suggestions = [];

//   @override
//   void initState() {
//     super.initState();
//     widget.controller.addListener(_onTextChanged);
//     _focusNode.addListener(_onFocusChanged);
//   }

//   void _onTextChanged() async {
//     if (widget.controller.text.isEmpty) {
//       setState(() {
//         _isSearching = false;
//         _suggestions = [];
//       });
//     } else {
//       setState(() {
//         _isSearching = true;
//       });
//       List<AddressSuggestion> suggestions =
//           await MotisHandler.getAddressSuggestions(widget.controller.text);

//       print(suggestions.map((e) => e.name));
//       //print(suggestions.first.name);
//       setState(() {
//         _isSearching = false;
//         _suggestions = suggestions.take(5).toList();
//       });
//     }
//   }

//   void _onFocusChanged() {
//     if (_focusNode.hasFocus) {
//       _overlayEntry = _createOverlayEntry();
//       Overlay.of(context)!.insert(_overlayEntry);
//     } else {
//       _overlayEntry.remove();
//     }
//   }

//   OverlayEntry _createOverlayEntry() {
//     RenderBox renderBox = context.findRenderObject() as RenderBox;
//     var size = renderBox.size;
//     var offset = renderBox.localToGlobal(Offset.zero);

//     return OverlayEntry(
//       builder: (context) => Positioned(
//         left: offset.dx,
//         top: offset.dy,
//         width: size.width,
//         child: CompositedTransformFollower(
//           link: _layerLink,
//           showWhenUnlinked: false,
//           offset: Offset(0.0, size.height + 5.0),
//           child: Material(
//             elevation: 4.0,
//             child: _isSearching
//                 ? Container(
//                     padding: const EdgeInsets.all(16.0),
//                     child: const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//                   )
//                 : ListView.separated(
//                     shrinkWrap: true,
//                     itemCount: _suggestions.length,
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     itemBuilder: (context, index) {
//                       return ListTile(
//                         title: Text(_suggestions[index].name),
//                         onTap: () {
//                           widget.controller.text = _suggestions[index].name;
//                           _focusNode.unfocus();
//                         },
//                       );
//                     },
//                     separatorBuilder: (context, index) {
//                       return const Divider();
//                     },
//                   ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CompositedTransformTarget(
//       link: _layerLink,
//       child: TextFormField(
//         decoration: InputDecoration(
//           border: const OutlineInputBorder(),
//           labelText: widget.labelText,
//           hintText: widget.hintText,
//         ),
//         controller: widget.controller,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return widget.validatorEmptyText;
//           }
//           return null;
//         },
//         focusNode: _focusNode,
//         onChanged: (_v) => setState(() {
//           _isSearching = true;
//         }),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     widget.controller.removeListener(_onTextChanged);
//     _focusNode.removeListener(_onFocusChanged);
//     _overlayEntry.remove();
//     super.dispose();
//   }
// }
