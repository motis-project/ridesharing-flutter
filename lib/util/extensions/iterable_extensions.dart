// Sourced from https://github.com/dart-lang/collection
// Just porting the one function I need for now.

extension IterableExtension<E> on Iterable<E> {
  /// The first element satisfying [test], or `null` if there are none.
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
