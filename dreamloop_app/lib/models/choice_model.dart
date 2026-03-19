import 'package:cloud_firestore/cloud_firestore.dart';

class ChoiceModel {
  final String choiceId;
  final String eventId;
  final String userId;
  final String selectedOption;
  final DateTime chosenAt;

  ChoiceModel({
    required this.choiceId,
    required this.eventId,
    required this.userId,
    required this.selectedOption,
    DateTime? chosenAt,
  }) : chosenAt = chosenAt ?? DateTime.now();

  factory ChoiceModel.fromMap(Map<String, dynamic> map) {
    return ChoiceModel(
      choiceId: map['choice_id'] ?? '',
      eventId: map['event_id'] ?? '',
      userId: map['user_id'] ?? '',
      selectedOption: map['selected_option'] ?? '',
      chosenAt: (map['chosen_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'choice_id': choiceId,
      'event_id': eventId,
      'user_id': userId,
      'selected_option': selectedOption,
      'chosen_at': Timestamp.fromDate(chosenAt),
    };
  }
}
