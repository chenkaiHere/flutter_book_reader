// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get bookshelfTitle => '책장';

  @override
  String shelfSummary(int total, int reading) {
    return '$total권 · $reading권 읽는 중';
  }

  @override
  String get searchHint => '제목 / 작가 검색';

  @override
  String get allBooks => '모든 책';

  @override
  String get localTag => '로컬';

  @override
  String get continueReading => '계속 읽기';

  @override
  String readToChapter(int n) {
    return '$n장까지 읽음';
  }

  @override
  String get notStarted => '시작 안 함';

  @override
  String readPercent(int pct) {
    return '$pct% 읽음';
  }

  @override
  String get unread => '안 읽음';

  @override
  String get importTooltip => 'TXT 가져오기';

  @override
  String get importTitle => '로컬 소설 가져오기';

  @override
  String get importDesc => '휴대폰의 TXT 소설을 책장에 추가해 언제든 오프라인으로 읽으세요.';

  @override
  String get importPoint1Title => '한 번 탭';

  @override
  String get importPoint1Body => '로컬 TXT 파일만 선택하면 됩니다. 인터넷 불필요';

  @override
  String get importPoint2Title => '스마트 편집';

  @override
  String get importPoint2Body => '제목, 작가, 챕터를 자동 인식';

  @override
  String get importPoint3Title => '인코딩 걱정 없음';

  @override
  String get importPoint3Body => 'UTF-8 / GBK / Big5 자동 감지';

  @override
  String get importPoint4Title => '저장 및 삭제';

  @override
  String get importPoint4Body => '기기에 저장. 왼쪽으로 밀어 삭제';

  @override
  String get importLater => '나중에';

  @override
  String get importPick => 'TXT 파일 선택';

  @override
  String importedToast(String title, int count) {
    return '「$title」 가져옴 · $count장';
  }

  @override
  String importFailed(String error) {
    return '가져오기 실패: $error';
  }

  @override
  String get deleteTitle => '책 삭제';

  @override
  String deleteMessage(String title) {
    return '「$title」을(를) 삭제할까요? 가져온 책 데이터가 삭제됩니다.';
  }

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get cannotDeleteBuiltin => '기본 제공 책은 삭제할 수 없습니다';

  @override
  String deletedToast(String title) {
    return '「$title」 삭제됨';
  }

  @override
  String get tabDetail => '상세';

  @override
  String get tabToc => '목차';

  @override
  String get tabBookmarks => '북마크';

  @override
  String get statChapters => '챕터';

  @override
  String get statSource => '출처';

  @override
  String get statProgress => '진행';

  @override
  String get sourceLocal => '로컬';

  @override
  String get sourceBuiltin => '기본 제공';

  @override
  String get statusLocalImported => '로컬 가져오기';

  @override
  String get statusBuiltin => '기본 제공 책';

  @override
  String get introHeading => '줄거리';

  @override
  String get noIntro => '줄거리 없음.';

  @override
  String chapterCountLabel(int n) {
    return '전체 $n장';
  }

  @override
  String get orderAsc => '오름차순';

  @override
  String get orderDesc => '내림차순';

  @override
  String get startReading => '읽기 시작';

  @override
  String get noBookmarks => '아직 북마크가 없습니다';

  @override
  String get noBookmarksHint =>
      '읽는 중 오른쪽 상단을 탭하면 북마크를 추가할 수 있어\n언제든 돌아올 수 있습니다.';

  @override
  String bookmarkEntry(int n, String title) {
    return '$n장 · $title';
  }

  @override
  String get emptyShelf => '책이 없습니다 — 오른쪽 상단을 탭해 TXT 가져오기';

  @override
  String get noMatches => '일치하는 책 없음';

  @override
  String loadFailed(String error) {
    return '책을 불러오지 못했습니다: $error';
  }

  @override
  String get languageSheetTitle => '언어';
}
