/// Common form validators used across the app.
/// Keeps validation logic out of widgets.
///
/// Premium SaaS additions:
/// - Better email regex handling
/// - Optional validators (min/max length)
/// - Combined validators
/// - Stronger password option (toggleable)
class Validators {
  /// Required field validator
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Email validator
  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';

    // A practical email regex (not overly strict)
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    if (!emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Password validator (Firebase-friendly)
  /// If [strong] is true, it enforces upper/lower/number.
  static String? password(
    String? value, {
    int minLength = 6,
    bool strong = false,
  }) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (strong) {
      final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
      final hasLower = RegExp(r'[a-z]').hasMatch(v);
      final hasNumber = RegExp(r'\d').hasMatch(v);
      if (!hasUpper || !hasLower || !hasNumber) {
        return 'Use upper, lower and a number';
      }
    }

    return null;
  }

  /// Positive number validator (costs, amounts)
  static String? positiveNumber(
    String? value, {
    String fieldName = 'Value',
    bool requiredField = false,
  }) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return requiredField ? '$fieldName is required' : null;
    }

    final number = num.tryParse(v);
    if (number == null) return '$fieldName must be a number';
    if (number < 0) return '$fieldName must be a positive number';
    return null;
  }

  /// Max length validator
  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'Value',
  }) {
    final v = value ?? '';
    if (v.length > max) return '$fieldName must be at most $max characters';
    return null;
  }

  /// Min length validator
  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'Value',
  }) {
    final v = value ?? '';
    if (v.isEmpty) return null; // leave required() to handle emptiness
    if (v.length < min) return '$fieldName must be at least $min characters';
    return null;
  }

  /// Combine multiple validators cleanly:
  /// validator: Validators.combine([ (v)=>..., (v)=>... ])
  static String? Function(String?) combine(
    List<String? Function(String?)> rules,
  ) {
    return (value) {
      for (final rule in rules) {
        final result = rule(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
