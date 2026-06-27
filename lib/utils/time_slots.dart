/// Builds the preset time-chip labels for the new-appointment form from the
/// barber's working hours. Slots run from [startHour]:00 through [endHour]:00
/// inclusive at [slotMinutes] steps, each formatted "HH:mm" (e.g. "09:30").
///
/// Returns an empty list for nonsensical input (non-positive step or an end at
/// or before the start) so callers never have to guard — the "Özel" picker still
/// covers any exact time.
List<String> buildTimeSlots({
  required int startHour,
  required int endHour,
  required int slotMinutes,
}) {
  final slots = <String>[];
  if (slotMinutes <= 0 || endHour <= startHour) return slots;
  final endMinute = endHour * 60;
  for (var minute = startHour * 60; minute <= endMinute; minute += slotMinutes) {
    final h = (minute ~/ 60).toString().padLeft(2, '0');
    final m = (minute % 60).toString().padLeft(2, '0');
    slots.add('$h:$m');
  }
  return slots;
}
