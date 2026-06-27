import 'package:flutter_contacts/flutter_contacts.dart';

/// A name + phone pair chosen from the device address book.
class PickedContact {
  const PickedContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Thrown when the user denies access to contacts. [message] is a user-facing
/// Turkish string safe to show directly.
class ContactsPermissionException implements Exception {
  const ContactsPermissionException();

  String get message => 'Rehbere erişim izni verilmedi.';

  @override
  String toString() => 'ContactsPermissionException: $message';
}

/// Address-book integration. Keeps `flutter_contacts` out of the UI so screens
/// only deal with a tiny [PickedContact] / a plain name + phone.
abstract final class ContactsService {
  /// Reading name + phone from the native picker needs READ_CONTACTS on Android
  /// (permissionless on iOS, but requesting up front is harmless and Faz 5 will
  /// need access anyway).
  static const Set<ContactProperty> _pickerFields = {
    ContactProperty.name,
    ContactProperty.phone,
  };

  /// Opens the OS contact picker and returns the chosen contact's name and
  /// first phone number. Returns null if the user cancels; throws
  /// [ContactsPermissionException] if access is denied.
  static Future<PickedContact?> pick() async {
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    final granted = status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
    if (!granted) throw const ContactsPermissionException();

    final contact =
        await FlutterContacts.native.showPicker(properties: _pickerFields);
    if (contact == null) return null; // cancelled

    final phone =
        contact.phones.isEmpty ? '' : contact.phones.first.number.trim();
    return PickedContact(
      name: (contact.displayName ?? '').trim(),
      phone: phone,
    );
  }

  /// Opens the OS "new contact" screen pre-filled with [name] and [phone] so the
  /// user confirms and saves. Going through the native UI means no write
  /// permission of our own is needed. Returns whether a contact was saved
  /// (false if the user cancelled). The name's first word becomes the first
  /// name, the rest the last name.
  static Future<bool> save({
    required String name,
    required String phone,
  }) async {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    final number = phone.trim();
    final contact = Contact(
      name: Name(
        first: words.isEmpty ? '' : words.first,
        last: words.length > 1 ? words.sublist(1).join(' ') : '',
      ),
      phones: number.isEmpty ? const [] : [Phone(number: number)],
    );

    // The native creator returns the new contact's id, or null if cancelled.
    final createdId = await FlutterContacts.native.showCreator(contact: contact);
    return createdId != null;
  }
}
