String? requiredFieldValidator(String? value, {String fieldName = 'This field'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required.';
  }

  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required.';
  }

  final email = value.trim();
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  if (!emailRegex.hasMatch(email)) {
    return 'Please enter a valid email address.';
  }

  return null;
}

String? positiveNumberValidator(String? value, {String fieldName = 'Value'}) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required.';
  }

  final parsed = double.tryParse(value);
  if (parsed == null || parsed <= 0) {
    return '$fieldName must be greater than zero.';
  }

  return null;
}
