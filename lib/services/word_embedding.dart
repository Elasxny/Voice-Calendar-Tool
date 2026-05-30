import 'dart:collection';

class WordEmbedding {
  final Map<String, List<double>> _wordVectors;
  final int _vectorSize;
  final List<double> _unknownVector;

  WordEmbedding({
    required Map<String, List<double>> wordVectors,
    required int vectorSize,
  })  : _wordVectors = wordVectors,
        _vectorSize = vectorSize,
        _unknownVector = List<double>.filled(vectorSize, 0.0);

  List<double> getVector(String word) {
    return _wordVectors[word.toLowerCase()] ?? _unknownVector;
  }

  List<double> sentenceToVector(String sentence, {int maxLength = 32}) {
    final words = _tokenize(sentence);
    final vectors = <List<double>>[];

    for (var i = 0; i < words.length && i < maxLength; i++) {
      vectors.add(getVector(words[i]));
    }

    while (vectors.length < maxLength) {
      vectors.add(_unknownVector);
    }

    return _flatten(vectors);
  }

  List<String> _tokenize(String text) {
    final result = <String>[];
    final regex = RegExp(r'[\u4e00-\u9fa5]+|[a-zA-Z]+|\d+');
    final matches = regex.allMatches(text);

    for (var match in matches) {
      result.add(match.group(0)!);
    }

    return result;
  }

  List<double> _flatten(List<List<double>> vectors) {
    final result = <double>[];
    for (var vector in vectors) {
      result.addAll(vector);
    }
    return result;
  }

  static WordEmbedding createDefault() {
    final wordVectors = <String, List<double>>{
      '添加': [0.1, 0.2, -0.1, 0.3, -0.2],
      '创建': [0.15, 0.18, -0.05, 0.28, -0.15],
      '新建': [0.12, 0.22, -0.08, 0.32, -0.18],
      '安排': [0.08, 0.15, 0.05, 0.2, -0.1],
      '预约': [0.05, 0.12, 0.1, 0.15, -0.05],
      '删除': [-0.2, -0.1, 0.15, -0.25, 0.1],
      '取消': [-0.18, -0.08, 0.12, -0.22, 0.08],
      '移除': [-0.15, -0.12, 0.1, -0.18, 0.12],
      '查看': [0.05, -0.1, 0.2, 0.05, 0.15],
      '查询': [0.08, -0.08, 0.18, 0.08, 0.12],
      '有什么': [0.03, -0.12, 0.22, 0.03, 0.18],
      '今天': [0.1, 0.05, -0.15, 0.2, 0.1],
      '明天': [0.08, 0.08, -0.12, 0.22, 0.08],
      '后天': [0.05, 0.1, -0.1, 0.25, 0.05],
      '本周': [-0.05, 0.15, -0.08, 0.18, -0.05],
      '下周': [-0.08, 0.18, -0.05, 0.2, -0.08],
      '提醒': [0.2, 0.05, 0.15, -0.1, 0.2],
      '闹钟': [0.18, 0.08, 0.12, -0.08, 0.22],
      '会议': [0.05, 0.15, 0.1, 0.08, -0.1],
      '日程': [0.08, 0.12, 0.08, 0.1, -0.08],
      '约会': [0.03, 0.18, 0.15, 0.05, -0.12],
      '下午': [-0.1, 0.08, 0.15, -0.05, 0.08],
      '上午': [-0.08, 0.05, 0.12, -0.08, 0.05],
      '晚上': [-0.12, 0.03, 0.18, -0.03, 0.03],
      '点': [-0.05, 0.05, 0.2, -0.1, 0.05],
      '分钟': [-0.03, 0.03, 0.15, -0.12, 0.03],
      '小时': [-0.05, 0.02, 0.18, -0.15, 0.02],
      '在': [0.02, -0.05, 0.08, 0.05, -0.05],
      '于': [0.03, -0.03, 0.05, 0.08, -0.03],
      '和': [-0.02, -0.08, 0.02, 0.02, -0.08],
      '与': [-0.03, -0.06, 0.03, 0.03, -0.06],
      '我': [0.05, -0.15, 0.02, 0.08, -0.1],
      '帮': [0.08, -0.12, 0.05, 0.1, -0.08],
      '给': [0.03, -0.1, 0.03, 0.05, -0.12],
      '为': [0.05, -0.08, 0.02, 0.08, -0.06],
    };

    return WordEmbedding(
      wordVectors: wordVectors,
      vectorSize: 5,
    );
  }
}