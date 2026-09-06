/// Represents a single note in the Noto app.
///
/// This is a plain Dart model — no Flutter or database imports — so it
/// stays easy to test and reason about. It includes `toMap` / `fromMap`
/// converters so the repository layer can hand it straight to `sqflite`.
///
/// SQLite has no native boolean or date types, so:
///   - `bool` flags are stored as INTEGER 0/1
///   - `DateTime` is stored as ISO-8601 TEXT and parsed back with
///     `DateTime.parse`.
class Note {
  final int? id;
  final String title;
  final String content;
  final String category; // 'Study' | 'Work' | 'Ideas' | 'Personal'
  final String color; // 'default' | 'blue' | 'green' | 'yellow' | 'purple'
  final bool isPinned;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.color,
    this.isPinned = false,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns a copy of this note with any subset of fields replaced.
  ///
  /// Useful for `UPDATE` flows where you only want to change a few fields
  /// (e.g. toggling `isPinned`) without rebuilding the whole object.
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? color,
    bool? isPinned,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes this note into a `Map<String, dynamic>` for SQLite.
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'color': color,
        'isPinned': isPinned ? 1 : 0,
        'isFavorite': isFavorite ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Builds a [Note] from a row returned by SQLite.
  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int?,
        title: map['title'] as String,
        content: map['content'] as String,
        category: map['category'] as String,
        color: map['color'] as String,
        isPinned: map['isPinned'] == 1,
        isFavorite: map['isFavorite'] == 1,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  @override
  String toString() =>
      'Note(id: $id, title: $title, category: $category, isPinned: $isPinned, isFavorite: $isFavorite)';
}
