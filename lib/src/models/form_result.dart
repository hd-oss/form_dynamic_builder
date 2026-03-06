class FormResultModel {
  final String answerText;
  final dynamic answerValue;
  final ResultMapper? resultMapper;

  FormResultModel({
    required this.answerText,
    this.answerValue,
    this.resultMapper,
  });

  factory FormResultModel.fromJson(Map<String, dynamic> json) {
    return FormResultModel(
      answerText: json['answerText'] ?? '',
      answerValue: json['answerValue'],
      resultMapper: json['resultMapper'] != null
          ? ResultMapper.fromJson(json['resultMapper'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'answerText': answerText,
      'answerValue': answerValue,
    };
    if (resultMapper != null) {
      data['resultMapper'] = resultMapper!.toJson();
    }
    return data;
  }
}

class ResultMapper {
  final String destinationTbl;
  final String destinationColl;

  ResultMapper({
    required this.destinationTbl,
    required this.destinationColl,
  });

  factory ResultMapper.fromJson(Map<String, dynamic> json) {
    return ResultMapper(
      destinationTbl: json['destinationTbl'] ?? '',
      destinationColl: json['destinationColl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destinationTbl': destinationTbl,
      'destinationColl': destinationColl,
    };
  }
}
