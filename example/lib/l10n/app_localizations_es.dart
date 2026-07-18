// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get bookshelfTitle => 'Estantería';

  @override
  String shelfSummary(int total, int reading) {
    return '$total libros · $reading leyendo';
  }

  @override
  String get searchHint => 'Buscar título / autor';

  @override
  String get allBooks => 'Todos los libros';

  @override
  String get localTag => 'Local';

  @override
  String get continueReading => 'Seguir leyendo';

  @override
  String readToChapter(int n) {
    return 'Leído hasta el capítulo $n';
  }

  @override
  String get notStarted => 'Sin empezar';

  @override
  String readPercent(int pct) {
    return '$pct% leído';
  }

  @override
  String get unread => 'Sin leer';

  @override
  String get importTooltip => 'Importar TXT';

  @override
  String get importTitle => 'Importar novela local';

  @override
  String get importDesc =>
      'Añade novelas TXT de tu teléfono a la estantería y léelas sin conexión cuando quieras.';

  @override
  String get importPoint1Title => 'Un toque';

  @override
  String get importPoint1Body =>
      'Solo elige un archivo TXT local, sin conexión';

  @override
  String get importPoint2Title => 'Formato inteligente';

  @override
  String get importPoint2Body =>
      'Detecta título, autor y capítulos automáticamente';

  @override
  String get importPoint3Title => 'Sin problemas de codificación';

  @override
  String get importPoint3Body => 'Detecta UTF-8 / GBK / Big5 automáticamente';

  @override
  String get importPoint4Title => 'Guardar y borrar';

  @override
  String get importPoint4Body =>
      'Se guarda en el dispositivo; desliza para borrar';

  @override
  String get importLater => 'Ahora no';

  @override
  String get importPick => 'Elegir archivo TXT';

  @override
  String importedToast(String title, int count) {
    return 'Importado «$title» · $count capítulos';
  }

  @override
  String importFailed(String error) {
    return 'Error al importar: $error';
  }

  @override
  String get deleteTitle => 'Eliminar libro';

  @override
  String deleteMessage(String title) {
    return '¿Eliminar «$title»? Se borrarán los datos del libro importado.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get cannotDeleteBuiltin =>
      'Los libros integrados no se pueden eliminar';

  @override
  String deletedToast(String title) {
    return '«$title» eliminado';
  }

  @override
  String get tabDetail => 'Detalle';

  @override
  String get tabToc => 'Índice';

  @override
  String get tabBookmarks => 'Marcadores';

  @override
  String get statChapters => 'Capítulos';

  @override
  String get statSource => 'Origen';

  @override
  String get statProgress => 'Progreso';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceBuiltin => 'Integrado';

  @override
  String get statusLocalImported => 'Importación local';

  @override
  String get statusBuiltin => 'Libro integrado';

  @override
  String get introHeading => 'Sinopsis';

  @override
  String get noIntro => 'Sin sinopsis.';

  @override
  String chapterCountLabel(int n) {
    return '$n capítulos';
  }

  @override
  String get orderAsc => 'Ascendente';

  @override
  String get orderDesc => 'Descendente';

  @override
  String get startReading => 'Empezar a leer';

  @override
  String get noBookmarks => 'Aún no hay marcadores';

  @override
  String get noBookmarksHint =>
      'Toca la esquina superior derecha al leer para añadir un marcador\ny volver cuando quieras.';

  @override
  String bookmarkEntry(int n, String title) {
    return 'Capítulo $n · $title';
  }

  @override
  String get emptyShelf =>
      'No hay libros: toca arriba a la derecha para importar un TXT';

  @override
  String get noMatches => 'No hay libros coincidentes';

  @override
  String loadFailed(String error) {
    return 'Error al cargar los libros: $error';
  }

  @override
  String get languageSheetTitle => 'Idioma';
}
