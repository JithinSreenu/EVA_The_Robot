// ============================================================================
// QUIZ QUESTION MODEL
// ============================================================================
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

// ============================================================================
// QUIZ QUESTIONS DATABASE (200+ questions supported!)
// ============================================================================
final List<QuizQuestion> quizQuestions = [
  
  // ========== KERALA QUESTIONS ==========
  QuizQuestion(
    question: "കേരളത്തിലെ ഏറ്റവും നീളം കൂടിയ നദി ഏതാണ്?",
    options: ["പെരിയാർ", "ഭാരതപ്പുഴ", "പമ്പ", "ചാലിയാർ"],
    correctIndex: 0,
  ),
  
  QuizQuestion(
    question: "കേരളത്തിന്റെ തലസ്ഥാനം ഏതാണ്?",
    options: ["കൊച്ചി", "തിരുവനന്തപുരം", "കോഴിക്കോട്", "തൃശ്ശൂർ"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "കേരളത്തിലെ ദേശീയോദ്യാനങ്ങളുടെ എണ്ണം എത്ര?",
    options: ["4", "5", "6", "7"],
    correctIndex: 2,
  ),

  // ========== INDIA QUESTIONS ==========
  QuizQuestion(
    question: "ഇന്ത്യയുടെ ആദ്യത്തെ പ്രധാനമന്ത്രി ആരാണ്?",
    options: ["ഗാന്ധിജി", "നെഹ്‌റു", "പട്ടേൽ", "അംബേദ്കർ"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "ഇന്ത്യയുടെ ദേശീയ പക്ഷി ഏതാണ്?",
    options: ["മയിൽ", "കഴുകൻ", "തത്ത", "കൊക്ക്"],
    correctIndex: 0,
  ),
  
  QuizQuestion(
    question: "ഇന്ത്യയുടെ സ്വാതന്ത്ര്യദിനം ഏത് തീയതിയാണ്?",
    options: ["26 ജനുവരി", "15 ഓഗസ്റ്റ്", "2 ഒക്ടോബർ", "14 നവംബർ"],
    correctIndex: 1,
  ),

  // ========== WORLD QUESTIONS ==========
  QuizQuestion(
    question: "ലോകത്തിലെ ഏറ്റവും വലിയ സമുദ്രം ഏതാണ്?",
    options: ["അറ്റ്ലാന്റിക്", "പസഫിക്", "ഇന്ത്യൻ", "ആർട്ടിക്"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "സൗരയൂഥത്തിലെ ഏറ്റവും വലിയ ഗ്രഹം ഏതാണ്?",
    options: ["ചൊവ്വ", "വ്യാഴം", "ശനി", "യുറാനസ്"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "ലോകത്തിലെ ഏറ്റവും ഉയരം കൂടിയ പർവ്വതം ഏതാണ്?",
    options: ["കാഞ്ചൻജംഗ", "എവറസ്റ്റ്", "കെ2", "മകാലു"],
    correctIndex: 1,
  ),

  // ========== CINEMA QUESTIONS ==========
  QuizQuestion(
    question: "മലയാള സിനിമയിലെ ആദ്യത്തെ ശബ്ദചിത്രം ഏത്?",
    options: ["വിഗതകുമാരൻ", "ബാലൻ", "നീലക്കുയിൽ", "മാർത്താണ്ഡവർമ്മ"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "ആദ്യത്തെ മലയാള ചലച്ചിത്രം ഏതാണ്?",
    options: ["വിഗതകുമാരൻ", "നീലക്കുയിൽ", "ബാലൻ", "പ്രഹ്ലാദൻ"],
    correctIndex: 0,
  ),

  // ========== SCIENCE QUESTIONS ==========
  QuizQuestion(
    question: "ജലത്തിന്റെ രാസനാമം എന്താണ്?",
    options: ["H2O", "CO2", "O2", "N2"],
    correctIndex: 0,
  ),
  
  QuizQuestion(
    question: "പ്രകാശത്തിന്റെ വേഗത സെക്കൻഡിൽ എത്രയാണ്?",
    options: ["3 ലക്ഷം കി.മീ", "2 ലക്ഷം കി.മീ", "4 ലക്ഷം കി.മീ", "5 ലക്ഷം കി.മീ"],
    correctIndex: 0,
  ),
  
  QuizQuestion(
    question: "ഭൂമിയുടെ ഉപഗ്രഹം ഏതാണ്?",
    options: ["ചൊവ്വ", "ചന്ദ്രൻ", "ശുക്രൻ", "വ്യാഴം"],
    correctIndex: 1,
  ),

  // ========== SPORTS QUESTIONS ==========
  QuizQuestion(
    question: "ക്രിക്കറ്റ് ലോകകപ്പ് ഏറ്റവും കൂടുതൽ തവണ നേടിയ രാജ്യം?",
    options: ["ഇന്ത്യ", "ഓസ്‌ട്രേലിയ", "വെസ്റ്റ് ഇൻഡീസ്", "പാക്കിസ്താൻ"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "ഒളിമ്പിക്‌സിൽ ഇന്ത്യയ്ക്ക് ആദ്യമായി സ്വർണം നേടിയത് ഏത് കായികമേഖലയിലാണ്?",
    options: ["ഹോക്കി", "ബാഡ്മിന്റൺ", "ഷൂട്ടിംഗ്", "അത്‌ലറ്റിക്‌സ്"],
    correctIndex: 0,
  ),

  // ========== HISTORY QUESTIONS ==========
  QuizQuestion(
    question: "ഇന്ത്യൻ സ്വാതന്ത്ര്യ സമരത്തിന്റെ പിതാവ് എന്നറിയപ്പെടുന്നത് ആരെയാണ്?",
    options: ["ജവഹർലാൽ നെഹ്‌റു", "മഹാത്മാ ഗാന്ധി", "സുഭാഷ് ചന്ദ്രബോസ്", "ഭഗത് സിംഗ്"],
    correctIndex: 1,
  ),
  
  QuizQuestion(
    question: "ചരിത്രത്തിലെ ആദ്യത്തെ ലോകമഹായുദ്ധം ആരംഭിച്ചത് ഏത് വർഷമാണ്?",
    options: ["1914", "1918", "1939", "1945"],
    correctIndex: 0,
  ),

  // ========== MATHEMATICS QUESTIONS ==========
  QuizQuestion(
    question: "2 + 2 × 2 എത്ര?",
    options: ["6", "8", "4", "10"],
    correctIndex: 0,
  ),
  
  QuizQuestion(
    question: "ഒരു സമചതുരത്തിന് എത്ര വശങ്ങളുണ്ട്?",
    options: ["3", "4", "5", "6"],
    correctIndex: 1,
  ),

  // ========== GENERAL KNOWLEDGE ==========
  QuizQuestion(
    question: "ഒരു വർഷത്തിൽ എത്ര ദിവസങ്ങൾ ഉണ്ട്?",
    options: ["365", "366", "360", "364"],
    correctIndex: 0,
  ),
  
  QuizQuestion(
    question: "മഴവില്ലിൽ എത്ര നിറങ്ങൾ ഉണ്ട്?",
    options: ["5", "6", "7", "8"],
    correctIndex: 2,
  ),

  // ✅ YOU CAN ADD 180+ MORE QUESTIONS HERE
  // Just copy the QuizQuestion format and paste below
  
  // Example format for adding more:
  /*
  QuizQuestion(
    question: "നിങ്ങളുടെ ചോദ്യം ഇവിടെ ടൈപ്പ് ചെയ്യുക?",
    options: ["ഓപ്ഷൻ 1", "ഓപ്ഷൻ 2", "ഓപ്ഷൻ 3", "ഓപ്ഷൻ 4"],
    correctIndex: 0, // 0, 1, 2, or 3 (0 = first option)
  ),
  */
];
