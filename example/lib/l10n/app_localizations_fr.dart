// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get bookshelfTitle => 'Bibliothèque';

  @override
  String shelfSummary(int total, int reading) {
    return '$total livres · $reading en cours';
  }

  @override
  String get searchHint => 'Rechercher titre / auteur';

  @override
  String get allBooks => 'Tous les livres';

  @override
  String get localTag => 'Local';

  @override
  String get continueReading => 'Continuer la lecture';

  @override
  String readToChapter(int n) {
    return 'Lu jusqu\'au chapitre $n';
  }

  @override
  String get notStarted => 'Non commencé';

  @override
  String readPercent(int pct) {
    return '$pct% lu';
  }

  @override
  String get unread => 'Non lu';

  @override
  String get importTooltip => 'Importer TXT';

  @override
  String get importTitle => 'Importer un roman local';

  @override
  String get importDesc =>
      'Ajoutez des romans TXT de votre téléphone à la bibliothèque et lisez hors ligne à tout moment.';

  @override
  String get importPoint1Title => 'En un tap';

  @override
  String get importPoint1Body =>
      'Choisissez un fichier TXT local, sans connexion';

  @override
  String get importPoint2Title => 'Mise en page intelligente';

  @override
  String get importPoint2Body =>
      'Détecte titre, auteur et chapitres automatiquement';

  @override
  String get importPoint3Title => 'Encodage sans souci';

  @override
  String get importPoint3Body => 'Détecte UTF-8 / GBK / Big5 automatiquement';

  @override
  String get importPoint4Title => 'Enregistrer et supprimer';

  @override
  String get importPoint4Body =>
      'Stocké sur l\'appareil ; balayez pour supprimer';

  @override
  String get importLater => 'Plus tard';

  @override
  String get importPick => 'Choisir un fichier TXT';

  @override
  String importedToast(String title, int count) {
    return '« $title » importé · $count chapitres';
  }

  @override
  String importFailed(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String get deleteTitle => 'Supprimer le livre';

  @override
  String deleteMessage(String title) {
    return 'Supprimer « $title » ? Les données du livre importé seront effacées.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get cannotDeleteBuiltin =>
      'Les livres intégrés ne peuvent pas être supprimés';

  @override
  String deletedToast(String title) {
    return '« $title » supprimé';
  }

  @override
  String get tabDetail => 'Détail';

  @override
  String get tabToc => 'Sommaire';

  @override
  String get tabBookmarks => 'Signets';

  @override
  String get statChapters => 'Chapitres';

  @override
  String get statSource => 'Source';

  @override
  String get statProgress => 'Progression';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceBuiltin => 'Intégré';

  @override
  String get statusLocalImported => 'Import local';

  @override
  String get statusBuiltin => 'Livre intégré';

  @override
  String get introHeading => 'Résumé';

  @override
  String get noIntro => 'Pas de résumé.';

  @override
  String chapterCountLabel(int n) {
    return '$n chapitres';
  }

  @override
  String get orderAsc => 'Croissant';

  @override
  String get orderDesc => 'Décroissant';

  @override
  String get startReading => 'Commencer la lecture';

  @override
  String get noBookmarks => 'Aucun signet';

  @override
  String get noBookmarksHint =>
      'Touchez en haut à droite pendant la lecture pour ajouter un signet\net y revenir à tout moment.';

  @override
  String bookmarkEntry(int n, String title) {
    return 'Chapitre $n · $title';
  }

  @override
  String get emptyShelf =>
      'Aucun livre — touchez en haut à droite pour importer un TXT';

  @override
  String get noMatches => 'Aucun livre correspondant';

  @override
  String loadFailed(String error) {
    return 'Échec du chargement des livres : $error';
  }

  @override
  String get languageSheetTitle => 'Langue';
}
