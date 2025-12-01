class HandshakeRes {
  num? status;
  String? secret;
  String? msg;

  HandshakeRes({required this.status, this.secret, this.msg});

  Map<String, dynamic> toMap() {
    return {'status': status, 'secret': secret, 'msg': msg};
  }

  factory HandshakeRes.fromMap(Map<String, dynamic> map) {
    return HandshakeRes(
      status: map['status'],
      secret: map['secret'],
      msg: map['msg'],
    );
  }
}
