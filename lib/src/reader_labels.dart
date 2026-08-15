import 'package:flutter/widgets.dart';

/// 阅读器所有对外文案的集合，支持本地化 / 白标定制。
///
/// 插件不依赖任何多语言框架：内置 12 种语言的文案预设（见 [forLanguageCode]），
/// 业务方只需把当前语言码传入（如 `ReaderLabels.forLanguageCode('zh')`）。
/// 未命中这 12 种时回退英文 [english]。也可直接构造自定义实例做白标。
///
/// 默认值即英文，因此 `const ReaderLabels()` == [english]。
@immutable
class ReaderLabels {
  const ReaderLabels({
    this.loading = 'Loading…',
    this.loadFailed = 'Failed to load',
    this.retry = 'Retry',
    this.prevChapter = 'Previous',
    this.nextChapter = 'Next',
    this.catalog = 'Contents',
    this.detail = 'Detail',
    this.bookmarkTab = 'Bookmarks',
    this.addBookmark = 'Add bookmark',
    this.removeBookmark = 'Remove bookmark',
    this.noBookmarks = 'No bookmarks yet',
    this.noBookmarksHint =
        'Tap the top-right while reading to add a bookmark,\nso you can jump back anytime.',
    this.noIntro = 'No synopsis',
    this.statChapters = 'Chapters',
    this.statCurrentChapter = 'Current',
    this.statProgress = 'Progress',
    this.introHeading = 'Synopsis',
    this.orderAsc = 'Ascending',
    this.orderDesc = 'Descending',
    this.themeMenu = 'Theme',
    this.dayMode = 'Day',
    this.nightMode = 'Night',
    this.settingsMenu = 'Settings',
    this.fontSize = 'Font size',
    this.lineSpacing = 'Line spacing',
    this.flipMode = 'Page turn',
    this.flipSimulation = 'Curl',
    this.flipCover = 'Cover',
    this.flipSlide = 'Slide',
    this.flipVertical = 'Scroll',
    this.flipNone = 'None',
    this.background = 'Background',
    this.bookEnd = '—— The End ——',
    this.loadingNext = 'Loading next chapter…',
    this.more = 'More',
    this.back = 'Back',
    this.selectCopy = 'Copy',
    this.selectHighlight = 'Highlight',
    this.selectRemoveHighlight = 'Remove',
    this.selectQuery = 'Look up',
    this.selectShare = 'Share',
    this.selectComment = 'Comment',
    this.commentTitle = 'Write a comment',
    this.commentHint = 'Write your thoughts…',
    this.commentSend = 'Send',
    this.noteFilterComment = 'Comments',
    this.segmentCommentsTitleTemplate = '{n} comments',
    this.segmentTagLabel = 'Note',
    this.commentAuthorSelf = 'Me',
    this.commentQuoteTemplate = 'Original: {q}',
    this.commentLike = 'Like',
    this.chapterProgressTemplate = 'Ch. {i}/{n}',
    this.chapterTotalTemplate = '{n} chapters',
    this.notesTab = 'Notes',
    this.noteFilterAll = 'All',
    this.noteDelete = 'Delete',
    this.noteJump = 'Go to',
    this.noNotes = 'No notes yet',
    this.noNotesHint =
        'Highlights, comments and bookmarks you add while reading show up here.',
    this.timeJustNow = 'just now',
    this.timeMinutesAgoTemplate = '{n} min ago',
    this.timeHoursAgoTemplate = '{n} h ago',
    this.timeDaysAgoTemplate = '{n} d ago',
    this.showSegmentComments = 'Show paragraph comments',
    this.hideSegmentComments = 'Hide paragraph comments',
    this.autoTurn = 'Auto page-turn',
    this.autoTurnStop = 'Stop auto-read',
    this.autoTurnExit = 'Exit auto-read',
    this.speedSlow = 'Slow',
    this.speedFast = 'Fast',
  });

  final String loading;
  final String loadFailed;
  final String retry;
  final String prevChapter;
  final String nextChapter;
  final String catalog;
  final String detail;
  final String bookmarkTab;
  final String addBookmark;
  final String removeBookmark;
  final String noBookmarks;
  final String noBookmarksHint;
  final String noIntro;

  /// 详情页统计卡：章节数 / 当前章 / 进度，以及「内容简介」标题。
  final String statChapters;
  final String statCurrentChapter;
  final String statProgress;
  final String introHeading;

  final String orderAsc;
  final String orderDesc;
  final String themeMenu;
  final String dayMode;
  final String nightMode;
  final String settingsMenu;
  final String fontSize;
  final String lineSpacing;
  final String flipMode;

  /// 翻页方式 5 个选项：仿真 / 覆盖 / 平移 / 上下 / 无动画。
  final String flipSimulation;
  final String flipCover;
  final String flipSlide;
  final String flipVertical;
  final String flipNone;

  final String background;
  final String bookEnd;
  final String loadingNext;
  final String more;
  final String back;

  /// 选中文字后的操作菜单：复制 / 划线 / 删除划线 / 查询 / 分享。
  final String selectCopy;
  final String selectHighlight;

  /// 选区与已有划线相交时，工具条上「划线」替换为「删除划线」。
  final String selectRemoveHighlight;
  final String selectQuery;
  final String selectShare;

  /// 选中文字后「评论」：气泡按钮文案 / 底部输入弹层标题 / 输入占位 / 发送按钮。
  final String selectComment;
  final String commentTitle;
  final String commentHint;
  final String commentSend;

  /// 笔记面板筛选「评论」。
  final String noteFilterComment;

  /// 段评列表：标题模板（{n}=评论数）/ 条目「段评」标签 / 作者「我」/ 引用原文模板
  /// （{q}=原文）/ 点赞文案。业务方弹出段评列表时可直接取用，避免重复维护多语言。
  final String segmentCommentsTitleTemplate;
  final String segmentTagLabel;
  final String commentAuthorSelf;
  final String commentQuoteTemplate;
  final String commentLike;

  /// 段评列表标题：如「12 条段评」。
  String segmentCommentsTitle(int count) =>
      segmentCommentsTitleTemplate.replaceFirst('{n}', '$count');

  /// 引用原文：如「原文：……」。
  String commentQuote(String quote) =>
      commentQuoteTemplate.replaceFirst('{q}', quote);

  /// “第 x/N 章” 模板：{i}=当前章号（从 1 起），{n}=总章数。
  final String chapterProgressTemplate;

  /// “共 N 章” 模板：{n}=总章数。
  final String chapterTotalTemplate;

  /// “第 x/N 章”
  String chapterProgress(int index, int count) => chapterProgressTemplate
      .replaceFirst('{i}', '${index + 1}')
      .replaceFirst('{n}', '$count');

  /// “共 N 章”
  String chapterTotal(int count) =>
      chapterTotalTemplate.replaceFirst('{n}', '$count');

  /// 笔记面板：Tab 标题 / 筛选「全部」/ 条目菜单「删除」「跳转」/ 空态文案。
  final String notesTab;
  final String noteFilterAll;
  final String noteDelete;
  final String noteJump;
  final String noNotes;
  final String noNotesHint;

  /// 相对时间文案：刚刚 / N 分钟前 / N 小时前 / N 天前（更久用绝对日期）。
  final String timeJustNow;
  final String timeMinutesAgoTemplate;
  final String timeHoursAgoTemplate;
  final String timeDaysAgoTemplate;

  /// 段评角标的显 / 隐（顶栏按钮的无障碍标签与提示）。
  final String showSegmentComments;
  final String hideSegmentComments;

  /// 自动翻页：设置面板里的开启入口 / 自动阅读中显示的停止 / 退出自动阅读 / 速度「慢」「快」。
  final String autoTurn;
  final String autoTurnStop;
  final String autoTurnExit;
  final String speedSlow;
  final String speedFast;

  /// 把时间戳（毫秒）格式化为相对时间；超过 7 天用 “yyyy-MM-dd”。
  String relativeTime(int ms, {DateTime? now}) {
    if (ms <= 0) return '';
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(ms);
    final Duration d = (now ?? DateTime.now()).difference(t);
    if (d.inMinutes < 1) return timeJustNow;
    if (d.inMinutes < 60) {
      return timeMinutesAgoTemplate.replaceFirst('{n}', '${d.inMinutes}');
    }
    if (d.inHours < 24) {
      return timeHoursAgoTemplate.replaceFirst('{n}', '${d.inHours}');
    }
    if (d.inDays <= 7) {
      return timeDaysAgoTemplate.replaceFirst('{n}', '${d.inDays}');
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}';
  }

  // ————————————————————— 内置 12 种语言预设 —————————————————————

  static const ReaderLabels english = ReaderLabels();

  static const ReaderLabels chinese = ReaderLabels(
    loading: '加载中…',
    loadFailed: '加载失败',
    retry: '重试',
    prevChapter: '上一章',
    nextChapter: '下一章',
    catalog: '目录',
    detail: '详情',
    bookmarkTab: '书签',
    addBookmark: '加入书签',
    removeBookmark: '移除书签',
    noBookmarks: '还没有书签',
    noBookmarksHint: '阅读时点击右上角即可添加书签，\n方便随时回到精彩之处。',
    noIntro: '暂无简介',
    statChapters: '章节',
    statCurrentChapter: '当前章',
    statProgress: '进度',
    introHeading: '内容简介',
    orderAsc: '正序',
    orderDesc: '倒序',
    themeMenu: '主题',
    dayMode: '日间',
    nightMode: '夜间',
    settingsMenu: '设置',
    fontSize: '字号',
    lineSpacing: '行距',
    flipMode: '翻页',
    flipSimulation: '仿真',
    flipCover: '覆盖',
    flipSlide: '平移',
    flipVertical: '上下',
    flipNone: '无动画',
    background: '背景 / 主题',
    bookEnd: '—— 全书完 ——',
    loadingNext: '正在载入下一章…',
    more: '更多',
    back: '返回',
    selectCopy: '复制',
    selectHighlight: '划线',
    selectRemoveHighlight: '删除划线',
    selectQuery: '查询',
    selectShare: '分享',
    selectComment: '评论',
    commentTitle: '写评论',
    commentHint: '写下你的想法…',
    commentSend: '发送',
    noteFilterComment: '评论',
    segmentCommentsTitleTemplate: '{n} 条段评',
    segmentTagLabel: '段评',
    commentAuthorSelf: '我',
    commentQuoteTemplate: '原文：{q}',
    commentLike: '赞',
    chapterProgressTemplate: '第 {i}/{n} 章',
    chapterTotalTemplate: '共 {n} 章',
    notesTab: '笔记',
    noteFilterAll: '全部',
    noteDelete: '删除',
    noteJump: '跳转',
    noNotes: '还没有笔记',
    noNotesHint: '阅读时划线、写评论、点右上角加书签，都会出现在这里。',
    timeJustNow: '刚刚',
    timeMinutesAgoTemplate: '{n} 分钟前',
    timeHoursAgoTemplate: '{n} 小时前',
    timeDaysAgoTemplate: '{n} 天前',
    autoTurn: '自动翻页',
    autoTurnStop: '停止自动阅读',
    autoTurnExit: '退出自动阅读',
    speedSlow: '慢',
    speedFast: '快',
    showSegmentComments: '显示段评',
    hideSegmentComments: '隐藏段评',
  );

  static const ReaderLabels spanish = ReaderLabels(
    loading: 'Cargando…',
    loadFailed: 'Error al cargar',
    retry: 'Reintentar',
    prevChapter: 'Anterior',
    nextChapter: 'Siguiente',
    catalog: 'Índice',
    detail: 'Detalle',
    bookmarkTab: 'Marcadores',
    addBookmark: 'Añadir marcador',
    removeBookmark: 'Quitar marcador',
    noBookmarks: 'Aún no hay marcadores',
    noBookmarksHint:
        'Toca la esquina superior derecha al leer para añadir un marcador\ny volver cuando quieras.',
    noIntro: 'Sin sinopsis',
    statChapters: 'Capítulos',
    statCurrentChapter: 'Actual',
    statProgress: 'Progreso',
    introHeading: 'Sinopsis',
    orderAsc: 'Ascendente',
    orderDesc: 'Descendente',
    themeMenu: 'Tema',
    dayMode: 'Día',
    nightMode: 'Noche',
    settingsMenu: 'Ajustes',
    fontSize: 'Tamaño',
    lineSpacing: 'Interlineado',
    flipMode: 'Paso de página',
    flipSimulation: 'Realista',
    flipCover: 'Cubrir',
    flipSlide: 'Deslizar',
    flipVertical: 'Vertical',
    flipNone: 'Ninguna',
    background: 'Fondo',
    bookEnd: '—— Fin ——',
    loadingNext: 'Cargando el siguiente capítulo…',
    more: 'Más',
    back: 'Atrás',
    selectCopy: 'Copiar',
    selectHighlight: 'Subrayar',
    selectRemoveHighlight: 'Quitar',
    selectQuery: 'Buscar',
    selectShare: 'Compartir',
    chapterProgressTemplate: 'Cap. {i}/{n}',
    chapterTotalTemplate: '{n} capítulos',
    selectComment: 'Comentar',
    commentTitle: 'Escribir un comentario',
    commentHint: 'Escribe lo que piensas…',
    commentSend: 'Enviar',
    noteFilterComment: 'Comentarios',
    segmentCommentsTitleTemplate: '{n} comentarios',
    segmentTagLabel: 'Nota',
    commentAuthorSelf: 'Yo',
    commentQuoteTemplate: 'Original: {q}',
    commentLike: 'Me gusta',
    notesTab: 'Notas',
    noteFilterAll: 'Todo',
    noteDelete: 'Eliminar',
    noteJump: 'Ir a',
    noNotes: 'Aún no hay notas',
    noNotesHint:
        'Los subrayados, comentarios y marcadores que añadas al leer aparecerán aquí.',
    timeJustNow: 'ahora mismo',
    timeMinutesAgoTemplate: 'hace {n} min',
    timeHoursAgoTemplate: 'hace {n} h',
    timeDaysAgoTemplate: 'hace {n} d',
    autoTurn: 'Cambio automático',
    autoTurnStop: 'Detener lectura automática',
    autoTurnExit: 'Salir de lectura automática',
    speedSlow: 'Lento',
    speedFast: 'Rápido',
    showSegmentComments: 'Mostrar comentarios de párrafo',
    hideSegmentComments: 'Ocultar comentarios de párrafo',
  );

  static const ReaderLabels french = ReaderLabels(
    loading: 'Chargement…',
    loadFailed: 'Échec du chargement',
    retry: 'Réessayer',
    prevChapter: 'Précédent',
    nextChapter: 'Suivant',
    catalog: 'Sommaire',
    detail: 'Détail',
    bookmarkTab: 'Signets',
    addBookmark: 'Ajouter un signet',
    removeBookmark: 'Retirer le signet',
    noBookmarks: 'Aucun signet',
    noBookmarksHint:
        'Touchez en haut à droite pendant la lecture pour ajouter un signet\net y revenir à tout moment.',
    noIntro: 'Pas de résumé',
    statChapters: 'Chapitres',
    statCurrentChapter: 'Actuel',
    statProgress: 'Progression',
    introHeading: 'Résumé',
    orderAsc: 'Croissant',
    orderDesc: 'Décroissant',
    themeMenu: 'Thème',
    dayMode: 'Jour',
    nightMode: 'Nuit',
    settingsMenu: 'Réglages',
    fontSize: 'Taille',
    lineSpacing: 'Interligne',
    flipMode: 'Tourner la page',
    flipSimulation: 'Réaliste',
    flipCover: 'Couvrir',
    flipSlide: 'Glisser',
    flipVertical: 'Vertical',
    flipNone: 'Aucune',
    background: 'Arrière-plan',
    bookEnd: '—— Fin ——',
    loadingNext: 'Chargement du chapitre suivant…',
    more: 'Plus',
    back: 'Retour',
    selectCopy: 'Copier',
    selectHighlight: 'Surligner',
    selectRemoveHighlight: 'Retirer',
    selectQuery: 'Rechercher',
    selectShare: 'Partager',
    chapterProgressTemplate: 'Ch. {i}/{n}',
    chapterTotalTemplate: '{n} chapitres',
    selectComment: 'Commenter',
    commentTitle: 'Écrire un commentaire',
    commentHint: 'Écrivez vos impressions…',
    commentSend: 'Envoyer',
    noteFilterComment: 'Commentaires',
    segmentCommentsTitleTemplate: '{n} commentaires',
    segmentTagLabel: 'Note',
    commentAuthorSelf: 'Moi',
    commentQuoteTemplate: 'Original : {q}',
    commentLike: "J'aime",
    notesTab: 'Notes',
    noteFilterAll: 'Tout',
    noteDelete: 'Supprimer',
    noteJump: 'Aller à',
    noNotes: 'Aucune note pour le moment',
    noNotesHint:
        'Les surlignages, commentaires et marque-pages ajoutés en lisant apparaîtront ici.',
    timeJustNow: "à l'instant",
    timeMinutesAgoTemplate: 'il y a {n} min',
    timeHoursAgoTemplate: 'il y a {n} h',
    timeDaysAgoTemplate: 'il y a {n} j',
    autoTurn: 'Tourne-page auto',
    autoTurnStop: 'Arrêter la lecture auto',
    autoTurnExit: 'Quitter la lecture auto',
    speedSlow: 'Lent',
    speedFast: 'Rapide',
    showSegmentComments: 'Afficher les commentaires',
    hideSegmentComments: 'Masquer les commentaires',
  );

  static const ReaderLabels arabic = ReaderLabels(
    loading: 'جارٍ التحميل…',
    loadFailed: 'فشل التحميل',
    retry: 'إعادة',
    prevChapter: 'السابق',
    nextChapter: 'التالي',
    catalog: 'الفهرس',
    detail: 'التفاصيل',
    bookmarkTab: 'الإشارات',
    addBookmark: 'إضافة إشارة',
    removeBookmark: 'إزالة الإشارة',
    noBookmarks: 'لا توجد إشارات بعد',
    noBookmarksHint:
        'أثناء القراءة اضغط أعلى اليمين لإضافة إشارة،\nلتعود إليها في أي وقت.',
    noIntro: 'لا يوجد ملخص',
    statChapters: 'الفصول',
    statCurrentChapter: 'الحالي',
    statProgress: 'التقدم',
    introHeading: 'الملخص',
    orderAsc: 'تصاعدي',
    orderDesc: 'تنازلي',
    themeMenu: 'السمة',
    dayMode: 'نهاري',
    nightMode: 'ليلي',
    settingsMenu: 'الإعدادات',
    fontSize: 'حجم الخط',
    lineSpacing: 'تباعد الأسطر',
    flipMode: 'تقليب الصفحة',
    flipSimulation: 'محاكاة',
    flipCover: 'تغطية',
    flipSlide: 'انزلاق',
    flipVertical: 'عمودي',
    flipNone: 'بدون',
    background: 'الخلفية',
    bookEnd: '—— النهاية ——',
    loadingNext: 'جارٍ تحميل الفصل التالي…',
    more: 'المزيد',
    back: 'رجوع',
    selectCopy: 'نسخ',
    selectHighlight: 'تحديد',
    selectRemoveHighlight: 'إزالة',
    selectQuery: 'بحث',
    selectShare: 'مشاركة',
    chapterProgressTemplate: 'الفصل {i}/{n}',
    chapterTotalTemplate: '{n} فصلًا',
    selectComment: 'تعليق',
    commentTitle: 'اكتب تعليقًا',
    commentHint: 'اكتب ما يخطر لك…',
    commentSend: 'إرسال',
    noteFilterComment: 'التعليقات',
    segmentCommentsTitleTemplate: '{n} تعليقًا',
    segmentTagLabel: 'ملاحظة',
    commentAuthorSelf: 'أنا',
    commentQuoteTemplate: 'النص الأصلي: {q}',
    commentLike: 'إعجاب',
    notesTab: 'الملاحظات',
    noteFilterAll: 'الكل',
    noteDelete: 'حذف',
    noteJump: 'الانتقال',
    noNotes: 'لا توجد ملاحظات بعد',
    noNotesHint:
        'ستظهر هنا التظليلات والتعليقات والعلامات التي تضيفها أثناء القراءة.',
    timeJustNow: 'الآن',
    timeMinutesAgoTemplate: 'قبل {n} دقيقة',
    timeHoursAgoTemplate: 'قبل {n} ساعة',
    timeDaysAgoTemplate: 'قبل {n} يوم',
    autoTurn: 'تقليب تلقائي',
    autoTurnStop: 'إيقاف القراءة التلقائية',
    autoTurnExit: 'الخروج من القراءة التلقائية',
    speedSlow: 'بطيء',
    speedFast: 'سريع',
    showSegmentComments: 'إظهار تعليقات الفقرة',
    hideSegmentComments: 'إخفاء تعليقات الفقرة',
  );

  static const ReaderLabels bengali = ReaderLabels(
    loading: 'লোড হচ্ছে…',
    loadFailed: 'লোড ব্যর্থ',
    retry: 'আবার',
    prevChapter: 'আগের',
    nextChapter: 'পরের',
    catalog: 'সূচিপত্র',
    detail: 'বিবরণ',
    bookmarkTab: 'বুকমার্ক',
    addBookmark: 'বুকমার্ক যোগ',
    removeBookmark: 'বুকমার্ক সরান',
    noBookmarks: 'এখনও কোনো বুকমার্ক নেই',
    noBookmarksHint:
        'পড়ার সময় বুকমার্ক যোগ করতে উপরের ডানদিকে ট্যাপ করুন,\nযাতে যেকোনো সময় ফিরে আসতে পারেন।',
    noIntro: 'কোনো সারসংক্ষেপ নেই',
    statChapters: 'অধ্যায়',
    statCurrentChapter: 'বর্তমান',
    statProgress: 'অগ্রগতি',
    introHeading: 'সারসংক্ষেপ',
    orderAsc: 'ঊর্ধ্বক্রম',
    orderDesc: 'অধোক্রম',
    themeMenu: 'থিম',
    dayMode: 'দিন',
    nightMode: 'রাত',
    settingsMenu: 'সেটিংস',
    fontSize: 'ফন্ট',
    lineSpacing: 'লাইন ফাঁক',
    flipMode: 'পৃষ্ঠা উল্টানো',
    flipSimulation: 'সিমুলেশন',
    flipCover: 'কভার',
    flipSlide: 'স্লাইড',
    flipVertical: 'উল্লম্ব',
    flipNone: 'কোনোটি নয়',
    background: 'পটভূমি',
    bookEnd: '—— সমাপ্ত ——',
    loadingNext: 'পরের অধ্যায় লোড হচ্ছে…',
    more: 'আরও',
    back: 'ফিরুন',
    selectCopy: 'কপি',
    selectHighlight: 'হাইলাইট',
    selectRemoveHighlight: 'সরান',
    selectQuery: 'অনুসন্ধান',
    selectShare: 'শেয়ার',
    chapterProgressTemplate: 'অধ্যায় {i}/{n}',
    chapterTotalTemplate: '{n}টি অধ্যায়',
    selectComment: 'মন্তব্য',
    commentTitle: 'মন্তব্য লিখুন',
    commentHint: 'আপনার ভাবনা লিখুন…',
    commentSend: 'পাঠান',
    noteFilterComment: 'মন্তব্য',
    segmentCommentsTitleTemplate: '{n}টি মন্তব্য',
    segmentTagLabel: 'নোট',
    commentAuthorSelf: 'আমি',
    commentQuoteTemplate: 'মূল লেখা: {q}',
    commentLike: 'পছন্দ',
    notesTab: 'নোট',
    noteFilterAll: 'সব',
    noteDelete: 'মুছুন',
    noteJump: 'যান',
    noNotes: 'এখনও কোনো নোট নেই',
    noNotesHint:
        'পড়ার সময় যোগ করা হাইলাইট, মন্তব্য ও বুকমার্ক এখানে দেখা যাবে।',
    timeJustNow: 'এইমাত্র',
    timeMinutesAgoTemplate: '{n} মিনিট আগে',
    timeHoursAgoTemplate: '{n} ঘণ্টা আগে',
    timeDaysAgoTemplate: '{n} দিন আগে',
    autoTurn: 'স্বয়ংক্রিয় পৃষ্ঠা',
    autoTurnStop: 'স্বয়ংক্রিয় পড়া বন্ধ',
    autoTurnExit: 'স্বয়ংক্রিয় পড়া থেকে বেরোন',
    speedSlow: 'ধীর',
    speedFast: 'দ্রুত',
    showSegmentComments: 'অনুচ্ছেদ মন্তব্য দেখান',
    hideSegmentComments: 'অনুচ্ছেদ মন্তব্য লুকান',
  );

  static const ReaderLabels portuguese = ReaderLabels(
    loading: 'Carregando…',
    loadFailed: 'Falha ao carregar',
    retry: 'Tentar de novo',
    prevChapter: 'Anterior',
    nextChapter: 'Próximo',
    catalog: 'Índice',
    detail: 'Detalhes',
    bookmarkTab: 'Marcadores',
    addBookmark: 'Adicionar marcador',
    removeBookmark: 'Remover marcador',
    noBookmarks: 'Ainda sem marcadores',
    noBookmarksHint:
        'Toque no canto superior direito ao ler para adicionar um marcador\ne voltar quando quiser.',
    noIntro: 'Sem sinopse',
    statChapters: 'Capítulos',
    statCurrentChapter: 'Atual',
    statProgress: 'Progresso',
    introHeading: 'Sinopse',
    orderAsc: 'Crescente',
    orderDesc: 'Decrescente',
    themeMenu: 'Tema',
    dayMode: 'Dia',
    nightMode: 'Noite',
    settingsMenu: 'Ajustes',
    fontSize: 'Tamanho',
    lineSpacing: 'Espaçamento',
    flipMode: 'Virar página',
    flipSimulation: 'Realista',
    flipCover: 'Cobrir',
    flipSlide: 'Deslizar',
    flipVertical: 'Vertical',
    flipNone: 'Nenhuma',
    background: 'Fundo',
    bookEnd: '—— Fim ——',
    loadingNext: 'Carregando o próximo capítulo…',
    more: 'Mais',
    back: 'Voltar',
    selectCopy: 'Copiar',
    selectHighlight: 'Destacar',
    selectRemoveHighlight: 'Remover',
    selectQuery: 'Consultar',
    selectShare: 'Compartilhar',
    chapterProgressTemplate: 'Cap. {i}/{n}',
    chapterTotalTemplate: '{n} capítulos',
    selectComment: 'Comentar',
    commentTitle: 'Escrever um comentário',
    commentHint: 'Escreva o que achou…',
    commentSend: 'Enviar',
    noteFilterComment: 'Comentários',
    segmentCommentsTitleTemplate: '{n} comentários',
    segmentTagLabel: 'Nota',
    commentAuthorSelf: 'Eu',
    commentQuoteTemplate: 'Original: {q}',
    commentLike: 'Gostei',
    notesTab: 'Notas',
    noteFilterAll: 'Tudo',
    noteDelete: 'Excluir',
    noteJump: 'Ir para',
    noNotes: 'Ainda sem notas',
    noNotesHint:
        'Destaques, comentários e marcadores adicionados durante a leitura aparecem aqui.',
    timeJustNow: 'agora mesmo',
    timeMinutesAgoTemplate: 'há {n} min',
    timeHoursAgoTemplate: 'há {n} h',
    timeDaysAgoTemplate: 'há {n} d',
    autoTurn: 'Virar automático',
    autoTurnStop: 'Parar leitura automática',
    autoTurnExit: 'Sair da leitura automática',
    speedSlow: 'Lento',
    speedFast: 'Rápido',
    showSegmentComments: 'Mostrar comentários do parágrafo',
    hideSegmentComments: 'Ocultar comentários do parágrafo',
  );

  static const ReaderLabels russian = ReaderLabels(
    loading: 'Загрузка…',
    loadFailed: 'Ошибка загрузки',
    retry: 'Повторить',
    prevChapter: 'Назад',
    nextChapter: 'Вперёд',
    catalog: 'Оглавление',
    detail: 'Детали',
    bookmarkTab: 'Закладки',
    addBookmark: 'Добавить закладку',
    removeBookmark: 'Убрать закладку',
    noBookmarks: 'Пока нет закладок',
    noBookmarksHint:
        'Во время чтения нажмите вверху справа, чтобы добавить закладку\nи вернуться в любой момент.',
    noIntro: 'Нет аннотации',
    statChapters: 'Главы',
    statCurrentChapter: 'Текущая',
    statProgress: 'Прогресс',
    introHeading: 'Аннотация',
    orderAsc: 'По возрастанию',
    orderDesc: 'По убыванию',
    themeMenu: 'Тема',
    dayMode: 'День',
    nightMode: 'Ночь',
    settingsMenu: 'Настройки',
    fontSize: 'Шрифт',
    lineSpacing: 'Интервал',
    flipMode: 'Перелистывание',
    flipSimulation: 'Имитация',
    flipCover: 'Наложение',
    flipSlide: 'Сдвиг',
    flipVertical: 'Вертик.',
    flipNone: 'Нет',
    background: 'Фон',
    bookEnd: '—— Конец ——',
    loadingNext: 'Загрузка следующей главы…',
    more: 'Ещё',
    back: 'Назад',
    selectCopy: 'Копировать',
    selectHighlight: 'Выделить',
    selectRemoveHighlight: 'Убрать',
    selectQuery: 'Найти',
    selectShare: 'Поделиться',
    chapterProgressTemplate: 'Гл. {i}/{n}',
    chapterTotalTemplate: 'Глав: {n}',
    selectComment: 'Комментарий',
    commentTitle: 'Написать комментарий',
    commentHint: 'Поделитесь мыслями…',
    commentSend: 'Отправить',
    noteFilterComment: 'Комментарии',
    segmentCommentsTitleTemplate: 'Комментариев: {n}',
    segmentTagLabel: 'Заметка',
    commentAuthorSelf: 'Я',
    commentQuoteTemplate: 'Оригинал: {q}',
    commentLike: 'Нравится',
    notesTab: 'Заметки',
    noteFilterAll: 'Все',
    noteDelete: 'Удалить',
    noteJump: 'Перейти',
    noNotes: 'Пока нет заметок',
    noNotesHint:
        'Выделения, комментарии и закладки, добавленные при чтении, появятся здесь.',
    timeJustNow: 'только что',
    timeMinutesAgoTemplate: '{n} мин назад',
    timeHoursAgoTemplate: '{n} ч назад',
    timeDaysAgoTemplate: '{n} дн назад',
    autoTurn: 'Автолистание',
    autoTurnStop: 'Остановить авточтение',
    autoTurnExit: 'Выйти из авточтения',
    speedSlow: 'Медленно',
    speedFast: 'Быстро',
    showSegmentComments: 'Показать комментарии к абзацу',
    hideSegmentComments: 'Скрыть комментарии к абзацу',
  );

  static const ReaderLabels hindi = ReaderLabels(
    loading: 'लोड हो रहा है…',
    loadFailed: 'लोड विफल',
    retry: 'पुनः प्रयास',
    prevChapter: 'पिछला',
    nextChapter: 'अगला',
    catalog: 'अनुक्रम',
    detail: 'विवरण',
    bookmarkTab: 'बुकमार्क',
    addBookmark: 'बुकमार्क जोड़ें',
    removeBookmark: 'बुकमार्क हटाएँ',
    noBookmarks: 'अभी कोई बुकमार्क नहीं',
    noBookmarksHint:
        'पढ़ते समय बुकमार्क जोड़ने के लिए ऊपर दाईं ओर टैप करें,\nताकि कभी भी वापस आ सकें।',
    noIntro: 'कोई सारांश नहीं',
    statChapters: 'अध्याय',
    statCurrentChapter: 'वर्तमान',
    statProgress: 'प्रगति',
    introHeading: 'सारांश',
    orderAsc: 'आरोही',
    orderDesc: 'अवरोही',
    themeMenu: 'थीम',
    dayMode: 'दिन',
    nightMode: 'रात',
    settingsMenu: 'सेटिंग',
    fontSize: 'फ़ॉन्ट',
    lineSpacing: 'पंक्ति अंतर',
    flipMode: 'पेज पलटना',
    flipSimulation: 'सिमुलेशन',
    flipCover: 'कवर',
    flipSlide: 'स्लाइड',
    flipVertical: 'वर्टिकल',
    flipNone: 'कोई नहीं',
    background: 'पृष्ठभूमि',
    bookEnd: '—— समाप्त ——',
    loadingNext: 'अगला अध्याय लोड हो रहा है…',
    more: 'और',
    back: 'वापस',
    selectCopy: 'कॉपी',
    selectHighlight: 'हाइलाइट',
    selectRemoveHighlight: 'हटाएँ',
    selectQuery: 'खोजें',
    selectShare: 'शेयर',
    chapterProgressTemplate: 'अध्याय {i}/{n}',
    chapterTotalTemplate: '{n} अध्याय',
    selectComment: 'टिप्पणी',
    commentTitle: 'टिप्पणी लिखें',
    commentHint: 'अपने विचार लिखें…',
    commentSend: 'भेजें',
    noteFilterComment: 'टिप्पणियाँ',
    segmentCommentsTitleTemplate: '{n} टिप्पणियाँ',
    segmentTagLabel: 'नोट',
    commentAuthorSelf: 'मैं',
    commentQuoteTemplate: 'मूल: {q}',
    commentLike: 'पसंद',
    notesTab: 'नोट्स',
    noteFilterAll: 'सभी',
    noteDelete: 'हटाएँ',
    noteJump: 'जाएँ',
    noNotes: 'अभी कोई नोट नहीं',
    noNotesHint:
        'पढ़ते समय जोड़े गए हाइलाइट, टिप्पणियाँ और बुकमार्क यहाँ दिखेंगे।',
    timeJustNow: 'अभी',
    timeMinutesAgoTemplate: '{n} मिनट पहले',
    timeHoursAgoTemplate: '{n} घंटे पहले',
    timeDaysAgoTemplate: '{n} दिन पहले',
    autoTurn: 'स्वतः पृष्ठ पलटना',
    autoTurnStop: 'स्वतः पठन रोकें',
    autoTurnExit: 'स्वतः पठन से बाहर',
    speedSlow: 'धीमा',
    speedFast: 'तेज़',
    showSegmentComments: 'अनुच्छेद टिप्पणियाँ दिखाएँ',
    hideSegmentComments: 'अनुच्छेद टिप्पणियाँ छिपाएँ',
  );

  static const ReaderLabels urdu = ReaderLabels(
    loading: 'لوڈ ہو رہا ہے…',
    loadFailed: 'لوڈ ناکام',
    retry: 'دوبارہ',
    prevChapter: 'پچھلا',
    nextChapter: 'اگلا',
    catalog: 'فہرست',
    detail: 'تفصیل',
    bookmarkTab: 'بُک مارکس',
    addBookmark: 'بُک مارک شامل کریں',
    removeBookmark: 'بُک مارک ہٹائیں',
    noBookmarks: 'ابھی کوئی بُک مارک نہیں',
    noBookmarksHint:
        'پڑھتے وقت بُک مارک شامل کرنے کے لیے اوپر دائیں طرف ٹیپ کریں،\nتاکہ کسی بھی وقت واپس آ سکیں۔',
    noIntro: 'کوئی خلاصہ نہیں',
    statChapters: 'ابواب',
    statCurrentChapter: 'حالیہ',
    statProgress: 'پیش رفت',
    introHeading: 'خلاصہ',
    orderAsc: 'صعودی',
    orderDesc: 'نزولی',
    themeMenu: 'تھیم',
    dayMode: 'دن',
    nightMode: 'رات',
    settingsMenu: 'ترتیبات',
    fontSize: 'فونٹ',
    lineSpacing: 'سطری فاصلہ',
    flipMode: 'صفحہ پلٹنا',
    flipSimulation: 'سمولیشن',
    flipCover: 'کور',
    flipSlide: 'سلائیڈ',
    flipVertical: 'عمودی',
    flipNone: 'کوئی نہیں',
    background: 'پس منظر',
    bookEnd: '—— اختتام ——',
    loadingNext: 'اگلا باب لوڈ ہو رہا ہے…',
    more: 'مزید',
    back: 'واپس',
    selectCopy: 'کاپی',
    selectHighlight: 'نمایاں',
    selectRemoveHighlight: 'ہٹائیں',
    selectQuery: 'تلاش',
    selectShare: 'شیئر',
    chapterProgressTemplate: 'باب {i}/{n}',
    chapterTotalTemplate: '{n} ابواب',
    selectComment: 'تبصرہ',
    commentTitle: 'تبصرہ لکھیں',
    commentHint: 'اپنے خیالات لکھیں…',
    commentSend: 'بھیجیں',
    noteFilterComment: 'تبصرے',
    segmentCommentsTitleTemplate: '{n} تبصرے',
    segmentTagLabel: 'نوٹ',
    commentAuthorSelf: 'میں',
    commentQuoteTemplate: 'اصل متن: {q}',
    commentLike: 'پسند',
    notesTab: 'نوٹس',
    noteFilterAll: 'سب',
    noteDelete: 'حذف کریں',
    noteJump: 'جائیں',
    noNotes: 'ابھی کوئی نوٹ نہیں',
    noNotesHint:
        'پڑھتے ہوئے شامل کی گئی ہائی لائٹس، تبصرے اور بک مارکس یہاں دکھائی دیں گے۔',
    timeJustNow: 'ابھی',
    timeMinutesAgoTemplate: '{n} منٹ پہلے',
    timeHoursAgoTemplate: '{n} گھنٹے پہلے',
    timeDaysAgoTemplate: '{n} دن پہلے',
    autoTurn: 'خودکار صفحہ پلٹنا',
    autoTurnStop: 'خودکار مطالعہ روکیں',
    autoTurnExit: 'خودکار مطالعہ سے باہر',
    speedSlow: 'آہستہ',
    speedFast: 'تیز',
    showSegmentComments: 'پیراگراف تبصرے دکھائیں',
    hideSegmentComments: 'پیراگراف تبصرے چھپائیں',
  );

  static const ReaderLabels japanese = ReaderLabels(
    loading: '読み込み中…',
    loadFailed: '読み込み失敗',
    retry: '再試行',
    prevChapter: '前の章',
    nextChapter: '次の章',
    catalog: '目次',
    detail: '詳細',
    bookmarkTab: 'しおり',
    addBookmark: 'しおりを追加',
    removeBookmark: 'しおりを削除',
    noBookmarks: 'しおりはまだありません',
    noBookmarksHint: '読書中に右上をタップするとしおりを追加でき、\nいつでも戻れます。',
    noIntro: 'あらすじはありません',
    statChapters: '章',
    statCurrentChapter: '現在',
    statProgress: '進捗',
    introHeading: 'あらすじ',
    orderAsc: '昇順',
    orderDesc: '降順',
    themeMenu: 'テーマ',
    dayMode: '昼',
    nightMode: '夜',
    settingsMenu: '設定',
    fontSize: '文字サイズ',
    lineSpacing: '行間',
    flipMode: 'ページめくり',
    flipSimulation: 'めくり',
    flipCover: 'カバー',
    flipSlide: 'スライド',
    flipVertical: 'スクロール',
    flipNone: 'なし',
    background: '背景',
    bookEnd: '—— 完 ——',
    loadingNext: '次の章を読み込み中…',
    more: 'その他',
    back: '戻る',
    selectCopy: 'コピー',
    selectHighlight: 'ハイライト',
    selectRemoveHighlight: '削除',
    selectQuery: '調べる',
    selectShare: '共有',
    chapterProgressTemplate: '第{i}/{n}章',
    chapterTotalTemplate: '全{n}章',
    selectComment: 'コメント',
    commentTitle: 'コメントを書く',
    commentHint: '感想を書いてください…',
    commentSend: '送信',
    noteFilterComment: 'コメント',
    segmentCommentsTitleTemplate: 'コメント{n}件',
    segmentTagLabel: 'ノート',
    commentAuthorSelf: '自分',
    commentQuoteTemplate: '原文：{q}',
    commentLike: 'いいね',
    notesTab: 'ノート',
    noteFilterAll: 'すべて',
    noteDelete: '削除',
    noteJump: '移動',
    noNotes: 'ノートはまだありません',
    noNotesHint: '読書中に追加したマーカー・コメント・しおりがここに表示されます。',
    timeJustNow: 'たった今',
    timeMinutesAgoTemplate: '{n}分前',
    timeHoursAgoTemplate: '{n}時間前',
    timeDaysAgoTemplate: '{n}日前',
    autoTurn: '自動ページめくり',
    autoTurnStop: '自動読書を停止',
    autoTurnExit: '自動読書を終了',
    speedSlow: '遅い',
    speedFast: '速い',
    showSegmentComments: '段落コメントを表示',
    hideSegmentComments: '段落コメントを非表示',
  );

  static const ReaderLabels korean = ReaderLabels(
    loading: '불러오는 중…',
    loadFailed: '불러오기 실패',
    retry: '다시 시도',
    prevChapter: '이전 장',
    nextChapter: '다음 장',
    catalog: '목차',
    detail: '상세',
    bookmarkTab: '북마크',
    addBookmark: '북마크 추가',
    removeBookmark: '북마크 제거',
    noBookmarks: '아직 북마크가 없습니다',
    noBookmarksHint: '읽는 중 오른쪽 상단을 탭하면 북마크를 추가할 수 있어\n언제든 돌아올 수 있습니다.',
    noIntro: '줄거리 없음',
    statChapters: '챕터',
    statCurrentChapter: '현재',
    statProgress: '진행',
    introHeading: '줄거리',
    orderAsc: '오름차순',
    orderDesc: '내림차순',
    themeMenu: '테마',
    dayMode: '주간',
    nightMode: '야간',
    settingsMenu: '설정',
    fontSize: '글자 크기',
    lineSpacing: '줄 간격',
    flipMode: '페이지 넘김',
    flipSimulation: '실감',
    flipCover: '덮기',
    flipSlide: '슬라이드',
    flipVertical: '세로',
    flipNone: '없음',
    background: '배경',
    bookEnd: '—— 끝 ——',
    loadingNext: '다음 장 불러오는 중…',
    more: '더보기',
    back: '뒤로',
    selectCopy: '복사',
    selectHighlight: '하이라이트',
    selectRemoveHighlight: '삭제',
    selectQuery: '찾기',
    selectShare: '공유',
    chapterProgressTemplate: '{i}/{n}장',
    chapterTotalTemplate: '전체 {n}장',
    selectComment: '댓글',
    commentTitle: '댓글 쓰기',
    commentHint: '생각을 적어 주세요…',
    commentSend: '보내기',
    noteFilterComment: '댓글',
    segmentCommentsTitleTemplate: '댓글 {n}개',
    segmentTagLabel: '노트',
    commentAuthorSelf: '나',
    commentQuoteTemplate: '원문: {q}',
    commentLike: '좋아요',
    notesTab: '노트',
    noteFilterAll: '전체',
    noteDelete: '삭제',
    noteJump: '이동',
    noNotes: '아직 노트가 없습니다',
    noNotesHint: '읽는 동안 추가한 하이라이트, 댓글, 북마크가 여기에 표시됩니다.',
    timeJustNow: '방금',
    timeMinutesAgoTemplate: '{n}분 전',
    timeHoursAgoTemplate: '{n}시간 전',
    timeDaysAgoTemplate: '{n}일 전',
    autoTurn: '자동 페이지 넘김',
    autoTurnStop: '자동 읽기 중지',
    autoTurnExit: '자동 읽기 종료',
    speedSlow: '느림',
    speedFast: '빠름',
    showSegmentComments: '문단 댓글 표시',
    hideSegmentComments: '문단 댓글 숨기기',
  );

  /// 语言码 → 预设。
  static const Map<String, ReaderLabels> _byCode = <String, ReaderLabels>{
    'en': english,
    'zh': chinese,
    'es': spanish,
    'fr': french,
    'ar': arabic,
    'bn': bengali,
    'pt': portuguese,
    'ru': russian,
    'hi': hindi,
    'ur': urdu,
    'ja': japanese,
    'ko': korean,
  };

  /// 按语言码取内置文案；不在内置 12 种内则回退英文。
  static ReaderLabels forLanguageCode(String? code) => _byCode[code] ?? english;

  static const ReaderLabels fallback = english;

  static ReaderLabels of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ReaderLabelsScope>()?.labels ??
      fallback;
}

/// 向子树提供 [ReaderLabels]。
class ReaderLabelsScope extends InheritedWidget {
  const ReaderLabelsScope({
    super.key,
    required this.labels,
    required super.child,
  });

  final ReaderLabels labels;

  @override
  bool updateShouldNotify(ReaderLabelsScope oldWidget) =>
      labels != oldWidget.labels;
}
