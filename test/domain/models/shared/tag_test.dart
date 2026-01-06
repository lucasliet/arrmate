import 'package:arrmate/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tag', () {
    test('Deve criar Tag a partir de JSON', () {
      final json = {'id': 1, 'label': 'Action'};

      final tag = Tag.fromJson(json);

      expect(tag.id, 1);
      expect(tag.label, 'Action');
    });

    test('Deve serializar Tag para JSON', () {
      final tag = Tag(id: 1, label: 'Action');

      final json = tag.toJson();

      expect(json['id'], 1);
      expect(json['label'], 'Action');
    });

    test('Deve comparar Tags corretamente com Equatable', () {
      final tag1 = Tag(id: 1, label: 'Action');
      final tag2 = Tag(id: 1, label: 'Action');
      final tag3 = Tag(id: 2, label: 'Drama');

      expect(tag1, equals(tag2));
      expect(tag1, isNot(equals(tag3)));
    });

    test('Deve gerar hashCode consistente para Tags iguais', () {
      final tag1 = Tag(id: 1, label: 'Action');
      final tag2 = Tag(id: 1, label: 'Action');

      expect(tag1.hashCode, equals(tag2.hashCode));
    });
  });
}
