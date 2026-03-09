class FormResultModel {
  final String answerText;
  final dynamic answerValue;
  final List<dynamic>? answerFile;
  final ResultMapper? resultMapper;

  FormResultModel({
    required this.answerText,
    this.answerValue,
    this.answerFile,
    this.resultMapper,
  });

  factory FormResultModel.fromJson(Map<String, dynamic> json) {
    return FormResultModel(
      answerText: json['answerText'] ?? '',
      answerValue: json['answerValue'],
      answerFile: json['answerFile'] as List<dynamic>?,
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
    if (answerFile != null) {
      data['answerFile'] = answerFile;
    }
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
