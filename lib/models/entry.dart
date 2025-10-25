class Entry {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final EntryType type;
  final String? author;

  Entry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    this.author,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'type': type.name,
      'author': author,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      type: EntryType.values.firstWhere((e) => e.name == map['type']),
      author: map['author'],
    );
  }

  Entry copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? date,
    EntryType? type,
    String? author,
  }) {
    return Entry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      type: type ?? this.type,
      author: author ?? this.author,
    );
  }
}

enum EntryType { diary, blog }
