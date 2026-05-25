class CardModel {
  final int id;
  final String number;
  final int balance; // не используется на карте, но может быть в БД
  final bool blocked;
  final String ownerName;
  final int keyId;

  CardModel({
    required this.id,
    required this.number,
    required this.balance,
    required this.blocked,
    required this.ownerName,
    required this.keyId,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'],
      number: json['number'],
      balance: json['balance'],
      blocked: json['blocked'] == 1,
      ownerName: json['owner_name'],
      keyId: json['key_id'],
    );
  }
}