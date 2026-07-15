// 一次性数据生成器：把书籍与章节正文导出成 assets/books.json。
//
// 运行： dart run tool/gen_books.dart
//
// 之所以单独放在 tool/ 且为纯 Dart（不依赖 Flutter），是为了能直接跑并把
// 生成的内容落盘成 JSON —— 之后 App 只从 assets/books.json 读取数据，
// 本文件仅在需要「重新生成/调整模拟内容」时使用。
import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, dynamic> data = <String, dynamic>{
    'books': <Map<String, dynamic>>[
      _book(1, '山海行记', '云中鹤',
          '一部关于少年离乡、跨越山海寻找归途的长篇故事。翻开它，便随主角踏上未知的旅程。',
          '5B7B9A', 24, _seedA),
      _book(2, '长夜将明', '沈砚秋',
          '战火与星光交织的年代，一群普通人如何在长夜里守住微弱却不灭的光。',
          '8A5B6B', 18, _seedB),
      _book(3, '城南旧巷', '林知微',
          '青石板路、旧书铺与巷口的老槐树，记录着一座城里几代人温柔的悲欢。',
          '5B8A6B', 30, _seedA),
      _book(4, '心', '夏目漱石',
          '「先生」与「我」在镰仓海边相遇，一段忘年之交牵出深埋心底的往事、孤独与愧疚。日本国民作家探问人心的代表作。',
          '3F5B78', 16, _seedKokoro),
      _book(5, '人间失格', '太宰治',
          '一个畏惧人世、以滑稽伪装示人的男子留下的三则手记，是无赖派文学关于自我与羞耻的绝唱。',
          '4A4A55', 12, _seedNingen),
      _book(6, '雪国', '川端康成',
          '穿过县界长长的隧道，便是雪国。旅人岛村与温泉乡艺伎之间徒劳而唯美的情感，诺贝尔文学奖名作。',
          '6B7E8A', 14, _seedYukiguni),
    ],
  };

  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  final File out = File('assets/books.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(encoder.convert(data));
  stdout.writeln('已生成 ${out.path}（${(data['books'] as List).length} 本书）');
}

Map<String, dynamic> _book(int id, String title, String author, String intro,
    String coverColor, int chapterCount, List<String> seed) {
  final List<Map<String, dynamic>> chapters = <Map<String, dynamic>>[];
  for (int i = 0; i < chapterCount; i++) {
    chapters.add(<String, dynamic>{
      'id': id * 1000 + i,
      'index': i,
      'title': '第${_cn(i + 1)}章  ${_titleWords[i % _titleWords.length]}',
      'paragraphs': _paragraphs(seed, i),
    });
  }
  return <String, dynamic>{
    'id': id,
    'title': title,
    'author': author,
    'intro': intro,
    'coverColor': coverColor,
    'chapters': chapters,
  };
}

List<String> _paragraphs(List<String> seed, int chapter) {
  final int count = 12 + (chapter % 6) * 2;
  final List<String> result = <String>[];
  for (int p = 0; p < count; p++) {
    final StringBuffer sb = StringBuffer();
    final int sentences = 3 + ((chapter + p) % 4);
    for (int s = 0; s < sentences; s++) {
      sb.write(seed[(chapter * 7 + p * 3 + s) % seed.length]);
    }
    result.add(sb.toString());
  }
  return result;
}

const List<String> _titleWords = <String>[
  '启程', '故人', '风起', '夜行', '归途', '抉择', '暗涌', '重逢',
  '迷雾', '灯火', '远方', '旧约', '裂痕', '黎明', '潮声', '落雪',
  '孤舟', '春信', '登高', '别离', '拂晓', '余晖', '同行', '尘埃',
  '惊蛰', '守望', '回声', '破晓', '长风', '终章',
];

String _cn(int n) {
  const List<String> digits = <String>[
    '零', '一', '二', '三', '四', '五', '六', '七', '八', '九'
  ];
  if (n < 10) return digits[n];
  if (n < 20) return '十${n % 10 == 0 ? '' : digits[n % 10]}';
  if (n < 100) {
    final int tens = n ~/ 10;
    final int ones = n % 10;
    return '${digits[tens]}十${ones == 0 ? '' : digits[ones]}';
  }
  return '$n';
}

const List<String> _seedA = <String>[
  '海风从远处的礁石间穿过，带着咸涩的气息，落在少年被晒得发烫的肩头。',
  '他抬起头，望向天边那一线将明未明的光，心里忽然生出一种说不清的悸动。',
  '岸边的老渔夫收拾着渔网，嘴里哼着谁也听不懂的调子，仿佛这海他已经守了一生。',
  '船桨划开水面，涟漪一圈圈荡开，把倒映其中的云影揉碎成细碎的银鳞。',
  '远山如黛，隐在薄雾之后，看不清轮廓，却总让人忍不住想要走近一探究竟。',
  '他把行囊背得更紧了些，脚下的青石板被夜露打湿，走起来发出轻微的声响。',
  '灯笼在风里摇晃，昏黄的光晕忽明忽暗，把两个人的影子拉得很长很长。',
  '她没有回头，只是把手中的伞往他那边偏了偏，任凭自己半边肩膀淋在雨里。',
];

const List<String> _seedB = <String>[
  '警报声在城市上空盘旋，人群像退潮般涌向地下的通道，脚步声连成一片。',
  '他握紧了口袋里那封没能寄出的信，纸角已经被汗水浸软，字迹却依旧清晰。',
  '窗外的天空被火光染成暗红，远处传来沉闷的回响，像是大地在低声叹息。',
  '收音机里断断续续地播报着消息，每一个字都被电流搅得支离破碎。',
  '她把最后一块面包掰成两半，递过去时，指尖还在不受控制地轻轻发抖。',
  '黑暗中有人低声唱起了熟悉的歌，起初只有一个声音，随后越来越多。',
  '黎明还很远，可只要还有人愿意点亮一盏灯，长夜便不算太难熬过去。',
  '他们约定，等这一切结束，就回到城南那条种满梧桐的小街上去。',
];

const List<String> _seedKokoro = <String>[
  '我总习惯称他为先生，因此这里也只写作先生，不愿提起他真正的名字。',
  '那一年的镰仓海边，人群散去之后，我常常独自望着退潮的沙滩发呆。',
  '先生说话时总带着一种淡淡的疏离，仿佛把自己与世界隔开了一层薄薄的玻璃。',
  '他待人温和，却极少让谁真正走近，那份客气反倒像是一种礼貌的拒绝。',
  '我年轻，急于弄清一切，而他只是笑，说有些事说出来便失了它本来的分量。',
  '师母在一旁替他斟茶，眉眼间的温柔里，似乎也藏着一点不为人知的忧愁。',
  '每逢谈及往事，先生的神色就会暗下来，像午后忽然被云影遮住的庭院。',
  '他曾对我说，你现在还不懂，等你也背上了什么，自然就明白了。',
];

const List<String> _seedNingen = <String>[
  '回顾我的一生，那是一段充满了羞耻的岁月，连自己也不愿再多看一眼。',
  '我始终无法理解人们所说的幸福，于是只好用滑稽去讨好，用玩笑掩饰恐惧。',
  '从很小的时候起，我就学会了扮演，把真正的自己藏在层层的笑脸之后。',
  '别人越是喜欢那个假装出来的我，我心底的荒凉便越是无处安放。',
  '酒与麻醉能让我暂时忘却，可醒来时，那份对人世的畏惧仍旧原封不动。',
  '我害怕被人看穿，也害怕被人当真，于是不断地逃，逃到更深的孤独里去。',
  '有人说我是个好孩子，可我知道，那不过是因为我从不敢流露真实的心意。',
  '如今连悲伤也变得模糊，我只是安静地活着，像一件被世界遗忘的旧物。',
];

const List<String> _seedYukiguni = <String>[
  '穿过县界那条长长的隧道，眼前豁然一白，火车便驶入了雪的国度。',
  '夜的底色白了起来，远处的山峦沉默地覆着积雪，连声音都被埋得很轻。',
  '车窗上凝着水汽，映出对面女子的侧脸，与窗外流过的灯火重叠在一处。',
  '温泉小镇的夜晚静得出奇，只有屋檐上的雪偶尔滑落，发出细碎的声响。',
  '她的声音清澈得近乎透明，像是从很远的雪原上传来，落进人的心里。',
  '岛村望着她认真的模样，忽然觉得这一切的情意，或许终究是徒劳的。',
  '炉火映红了半间屋子，窗外却依旧是无边的、安静得让人心颤的白。',
  '银河仿佛就悬在头顶，繁密而清冷，把整座雪国都笼在一片辽远的光里。',
];
