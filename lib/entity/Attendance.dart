class Attendance {
  Attendance(this.id, this.status, this.time);

  final String id;
  final bool status;
  final String time;

  Attendance.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        status = json['isCheckedIn'],
        time = json['createdAt'];
}
