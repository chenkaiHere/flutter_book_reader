// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get bookshelfTitle => 'Estante';

  @override
  String shelfSummary(int total, int reading) {
    return '$total livros · $reading lendo';
  }

  @override
  String get searchHint => 'Buscar título / autor';

  @override
  String get allBooks => 'Todos os livros';

  @override
  String get localTag => 'Local';

  @override
  String get continueReading => 'Continuar lendo';

  @override
  String readToChapter(int n) {
    return 'Lido até o capítulo $n';
  }

  @override
  String get notStarted => 'Não iniciado';

  @override
  String readPercent(int pct) {
    return '$pct% lido';
  }

  @override
  String get unread => 'Não lido';

  @override
  String get importTooltip => 'Importar TXT';

  @override
  String get importTitle => 'Importar romance local';

  @override
  String get importDesc =>
      'Adicione romances TXT do seu telefone à estante e leia offline quando quiser.';

  @override
  String get importPoint1Title => 'Um toque';

  @override
  String get importPoint1Body =>
      'Basta escolher um arquivo TXT local, sem internet';

  @override
  String get importPoint2Title => 'Layout inteligente';

  @override
  String get importPoint2Body =>
      'Detecta título, autor e capítulos automaticamente';

  @override
  String get importPoint3Title => 'Sem problemas de codificação';

  @override
  String get importPoint3Body => 'Detecta UTF-8 / GBK / Big5 automaticamente';

  @override
  String get importPoint4Title => 'Salvar e excluir';

  @override
  String get importPoint4Body =>
      'Armazenado no dispositivo; deslize para excluir';

  @override
  String get importLater => 'Agora não';

  @override
  String get importPick => 'Escolher arquivo TXT';

  @override
  String importedToast(String title, int count) {
    return '«$title» importado · $count capítulos';
  }

  @override
  String importFailed(String error) {
    return 'Falha ao importar: $error';
  }

  @override
  String get deleteTitle => 'Excluir livro';

  @override
  String deleteMessage(String title) {
    return 'Excluir «$title»? Isso removerá os dados do livro importado.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get cannotDeleteBuiltin => 'Livros integrados não podem ser excluídos';

  @override
  String deletedToast(String title) {
    return '«$title» excluído';
  }

  @override
  String get tabDetail => 'Detalhes';

  @override
  String get tabToc => 'Índice';

  @override
  String get tabBookmarks => 'Marcadores';

  @override
  String get statChapters => 'Capítulos';

  @override
  String get statSource => 'Origem';

  @override
  String get statProgress => 'Progresso';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceBuiltin => 'Integrado';

  @override
  String get statusLocalImported => 'Importação local';

  @override
  String get statusBuiltin => 'Livro integrado';

  @override
  String get introHeading => 'Sinopse';

  @override
  String get noIntro => 'Sem sinopse.';

  @override
  String chapterCountLabel(int n) {
    return '$n capítulos';
  }

  @override
  String get orderAsc => 'Crescente';

  @override
  String get orderDesc => 'Decrescente';

  @override
  String get startReading => 'Começar a ler';

  @override
  String get noBookmarks => 'Ainda sem marcadores';

  @override
  String get noBookmarksHint =>
      'Toque no canto superior direito ao ler para adicionar um marcador\ne voltar quando quiser.';

  @override
  String bookmarkEntry(int n, String title) {
    return 'Capítulo $n · $title';
  }

  @override
  String get emptyShelf =>
      'Nenhum livro — toque no canto superior direito para importar um TXT';

  @override
  String get noMatches => 'Nenhum livro correspondente';

  @override
  String loadFailed(String error) {
    return 'Falha ao carregar os livros: $error';
  }

  @override
  String get languageSheetTitle => 'Idioma';
}
