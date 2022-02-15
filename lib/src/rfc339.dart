RegExp pattern = RegExp(
    r"^(\d{4})-(\d{2})-(\d{2})[tT](\d{2}):(\d{2}):(\d{2})(\.\d+)?([zZ]|((\+|-)(\d{2}):(\d{2})))$");

bool isRFC3339(String s) {
  RegExpMatch? matches = pattern.firstMatch(s);

  if (matches == null) {
    return false;
  }

  int year = int.parse(matches[1].toString());
  int month = int.parse(matches[2].toString());
  int day = int.parse(matches[3].toString());
  int hour = int.parse(matches[4].toString());
  int minute = int.parse(matches[5].toString());
  int second = int.parse(matches[6].toString());

  if (month > 12) {
    return false;
  }

  if (day > maxDay(year, month)) {
    return false;
  }

  if (hour > 23) {
    return false;
  }

  if (minute > 59) {
    return false;
  }

// A value of 60 is permissible as a leap second.
  if (second > 60) {
    return false;
  }

  return true;
}

int maxDay(int year, int month) {
  if (month == 2) {
    return isLeapYear(year) ? 29 : 28;
  }

  return MONTH_LENGTHS[month];
}

bool isLeapYear(int n) {
  return n % 4 == 0 && (n % 100 != 0 || n % 400 == 0);
}

const MONTH_LENGTHS = [
  0, // months are 1-indexed, this is a dummy element
  31,
  0, // Feb is handled separately
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31,
];
