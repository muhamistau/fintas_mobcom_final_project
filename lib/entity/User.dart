class User {
  User(this.id, this.name, this.isCheckedIn, this.token, this.status);

  final String id;
  final String name;
  final bool isCheckedIn;
  final String token;
  final status;

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        isCheckedIn = json['isCheckedIn'],
        token = json['token'],
        status = json['success'];
}