// lib/core/l10n/app_strings.dart
// All UI strings in English and Nepali. Add new keys here.

class AppStrings {
  final String languageCode;
  AppStrings._(this.languageCode);

  static AppStrings of(String code) =>
      code == 'ne' ? AppStrings._('ne') : AppStrings._('en');

  bool get isNepali => languageCode == 'ne';
  String _t(String en, String ne) => isNepali ? ne : en;

  // ── Common ───────────────────────────────────────────────────────────────
  String get appName        => _t('Smart Home Energy', 'स्मार्ट होम एनर्जी');
  String get ok             => _t('OK', 'ठीक छ');
  String get cancel         => _t('Cancel', 'रद्द गर्नुस्');
  String get save           => _t('Save', 'बचत गर्नुस्');
  String get retry          => _t('Retry', 'पुनः प्रयास');
  String get done           => _t('Done', 'सकियो');
  String get loading        => _t('Loading...', 'लोड हुँदैछ...');
  String get connecting     => _t('Connecting...', 'जोडिँदैछ...');
  String get error          => _t('Something went wrong', 'केही गलत भयो');
  String get noInternet     => _t('No internet connection', 'इन्टरनेट छैन');
  String get tryAgain       => _t('Please try again', 'कृपया फेरि प्रयास गर्नुस्');

  // ── Splash Screen ────────────────────────────────────────────────────────
  String get splashTagline    => _t('Smart energy, smarter living', 'स्मार्ट ऊर्जा, बुद्धिमान जीवन');
  String get splashVerifying  => _t('Verifying your session...', 'सत्र प्रमाणित गर्दैछ...');
  String get splashOffline    => _t('Offline — loading saved data', 'अफलाइन — सुरक्षित डाटा लोड हुँदैछ');

  // ── Offline / Connectivity ───────────────────────────────────────────────
  String get offlineMode        => _t('Offline Mode', 'अफलाइन मोड');
  String get offlineBanner      => _t('No internet — showing cached data', 'इन्टरनेट छैन — पुरानो डाटा देखाइएको छ');
  String get serverUnreachable  => _t('Server unreachable — relay control disabled', 'सर्भर पाइएन — रिले नियन्त्रण बन्द छ');
  String get reconnected        => _t('Connected ✓', 'जोडियो ✓');
  String get lastUpdated        => _t('Last updated', 'अन्तिम अपडेट');
  String get sessionExpired     => _t('Session expired. Please sign in again.', 'सत्र समाप्त भयो। कृपया फेरि साइन इन गर्नुस्।');
  String get serverError        => _t('Server error. Please try again.', 'सर्भर त्रुटि। कृपया फेरि प्रयास गर्नुस्।');
  String get checkInternet      => _t('Check your internet connection and try again.', 'इन्टरनेट जाँच गरी फेरि प्रयास गर्नुस्।');
  String get relayOfflineError  => _t('Relay control requires internet connection.', 'रिले नियन्त्रणका लागि इन्टरनेट चाहिन्छ।');

  // ── Auth ─────────────────────────────────────────────────────────────────
  String get signIn         => _t('Sign In', 'साइन इन');
  String get signUp         => _t('Create Account', 'खाता बनाउनुस्');
  String get signOut        => _t('Sign Out', 'साइन आउट');
  String get email          => _t('Email', 'इमेल');
  String get password       => _t('Password', 'पासवर्ड');
  String get fullName       => _t('Full Name', 'पूरा नाम');
  String get loginTitle     => _t('Welcome back', 'स्वागत छ');
  String get loginSubtitle  => _t('Sign in to your smart home', 'आफ्नो स्मार्ट होममा साइन इन गर्नुस्');
  String get registerTitle  => _t('Get Started', 'सुरु गरौं');
  String get registerSubtitle => _t('Create your smart home account', 'आफ्नो स्मार्ट होम खाता बनाउनुस्');
  String get noAccount      => _t("Don't have an account?", 'खाता छैन?');
  String get signUpLink     => _t('Sign up', 'साइन अप');
  String get hasAccount     => _t('Already have an account?', 'पहिले नै खाता छ?');
  String get signInLink     => _t('Sign in', 'साइन इन');
  String get signOutConfirm => _t('Are you sure you want to sign out?', 'के तपाईं साइन आउट गर्न निश्चित हुनुहुन्छ?');
  String get emailEmpty     => _t('Please enter your email', 'कृपया इमेल प्रविष्ट गर्नुस्');
  String get emailInvalid   => _t('Please enter a valid email', 'कृपया सही इमेल प्रविष्ट गर्नुस्');
  String get passwordShort  => _t('Password must be at least 6 characters', 'पासवर्ड कम्तिमा ६ अक्षरको हुनुपर्छ');
  String get nameEmpty      => _t('Please enter your name', 'कृपया नाम प्रविष्ट गर्नुस्');
  String get loginFailed    => _t('Login failed. Please check your credentials.', 'लगइन असफल। कृपया आफ्नो विवरण जाँच गर्नुस्।');
  String get registerFailed => _t('Registration failed. Please try again.', 'दर्ता असफल। कृपया फेरि प्रयास गर्नुस्।');

  // ── Language ─────────────────────────────────────────────────────────────
  String get langToggleEn   => 'EN';
  String get langToggleNe   => 'NE';

  // ── Navigation ───────────────────────────────────────────────────────────
  String get navDashboard   => _t('Dashboard', 'ड्यासबोर्ड');
  String get navDevices     => _t('Monitors', 'मनिटर');
  String get navAnalytics   => _t('Cost', 'लागत');
  String get navAlerts      => _t('Alerts', 'सूचनाहरू');
  String get navSettings    => _t('Settings', 'सेटिङ');

  // ── Dashboard ────────────────────────────────────────────────────────────
  String get greetingMorning   => _t('Good morning', 'शुभ बिहानी');
  String get greetingAfternoon => _t('Good afternoon', 'शुभ दिउँसो');
  String get greetingEvening   => _t('Good evening', 'शुभ साँझ');
  String get liveReadings   => _t('Live Readings', 'लाइभ डाटा');
  String get waitingData    => _t('Waiting for data...', 'डाटाको प्रतीक्षा...');
  String get activePower    => _t('Active Power', 'सक्रिय पावर');
  String get voltage        => _t('Voltage', 'भोल्टेज');
  String get current        => _t('Current', 'करेन्ट');
  String get frequency      => _t('Frequency', 'फ्रिक्वेन्सी');
  String get powerFactor    => _t('Power Factor', 'पावर फ्याक्टर');
  String get applianceCtrl  => _t('Appliance Control', 'उपकरण नियन्त्रण');
  String get energyToday    => _t('Energy Today', 'आजको ऊर्जा');
  String get noDevice         => _t('No monitor paired', 'कुनै मनिटर जोडिएको छैन');
  String get noDeviceHint     => _t("Let's get started! Pair your Smart Monitor.", 'सुरु गरौं! आफ्नो स्मार्ट मनिटर जोड्नुस्।');
  String get pairMonitor      => _t('Pair Monitor', 'मनिटर जोड्नुस्');
  String get deviceOffline    => _t('Monitor is offline. Showing last known data.', 'मनिटर अफलाइन छ। अन्तिम डाटा देखाइएको छ।');
  String get dataStale        => _t('Data may be outdated', 'डाटा पुरानो हुनसक्छ');
  String get waitingFirst     => _t('Waiting for first reading...', 'पहिलो रिडिङको प्रतीक्षा...');
  String get addDevice        => _t('Add Monitor', 'मनिटर थप्नुस्');
  String get connectingMonitor=> _t('Connecting to your monitor…', 'तपाईंको मनिटरमा जोडिँदैछ…');
  String get connectingHint   => _t('Please wait while we set up your smart monitor.', 'कृपया प्रतीक्षा गर्नुस्, स्मार्ट मनिटर तयार हुँदैछ।');

  // ── Onboarding Steps ─────────────────────────────────────────────────────
  String get onboardStep1   => _t('Get your Smart Monitor pairing code', 'स्मार्ट मनिटरको पेयरिङ कोड लिनुस्');
  String get onboardStep1Sub=> _t('Found on the label on your device', 'उपकरणको लेबलमा लेखिएको छ');
  String get onboardStep2   => _t('Tap "Add Monitor" below', 'तलको "मनिटर थप्नुस्" थिच्नुस्');
  String get onboardStep3   => _t('Start tracking your energy usage!', 'आफ्नो ऊर्जा प्रयोग ट्र्याक गर्न सुरु गर्नुस्!');

  // ── Relay Labels ─────────────────────────────────────────────────────────
  String get relayOn        => _t('ON', 'चालू');
  String get relayOff       => _t('OFF', 'बन्द');
  String get renameAppliance   => _t('Rename Appliance', 'उपकरणको नाम बदल्नुस्');
  String get applianceName     => _t('Appliance name', 'उपकरणको नाम');
  String get defaultRelay1     => _t('Light', 'बत्ती');
  String get defaultRelay2     => _t('Fan', 'पंखा');
  String get defaultRelay3     => _t('Socket', 'सकेट');
  String get defaultRelay4     => _t('Switch', 'स्विच');
  String get relayToggleFail   => _t('Failed to control appliance. Please try again.', 'उपकरण नियन्त्रण गर्न सकिएन। फेरि प्रयास गर्नुस्।');

  // ── Devices Screen ───────────────────────────────────────────────────────
  String get myMonitors     => _t('My Monitors', 'मेरा मनिटरहरू');
  String get noMonitors     => _t('No monitors added yet', 'कुनै मनिटर थपिएको छैन');
  String get noMonitorsHint => _t('Tap + to pair your Smart Monitor', 'स्मार्ट मनिटर जोड्न + थिच्नुस्');
  String get online         => _t('Online', 'अनलाइन');
  String get offline        => _t('Offline', 'अफलाइन');
  String get lastSeen       => _t('Last seen', 'अन्तिम पटक');
  String get active         => _t('Active', 'सक्रिय');
  String get minutesAgo     => _t('min ago', 'मिनेट अघि');
  String get hoursAgo       => _t('hrs ago', 'घण्टा अघि');
  String get justNow        => _t('Just now', 'भर्खरै');

  // ── Add / Pair Device ────────────────────────────────────────────────────
  String get pairTitle      => _t('Pair Smart Monitor', 'स्मार्ट मनिटर जोड्नुस्');
  String get pairSubtitle   => _t('Enter the pairing code found on your device label.', 'आफ्नो उपकरणको लेबलमा भएको पेयरिङ कोड प्रविष्ट गर्नुस्।');
  String get pairingCode    => _t('Pairing Code', 'पेयरिङ कोड');
  String get pairingCodeHint=> _t('e.g. ESP32-001', 'जस्तै: ESP32-001');
  String get pairingCodeEmpty => _t('Please enter the pairing code', 'कृपया पेयरिङ कोड प्रविष्ट गर्नुस्');
  String get monitorName    => _t('Monitor Name', 'मनिटरको नाम');
  String get monitorNameHint=> _t('e.g. Living Room', 'जस्तै: बैठक कोठा');
  String get monitorNameEmpty => _t('Please enter a name', 'कृपया नाम प्रविष्ट गर्नुस्');
  String get room           => _t('Room / Location', 'कोठा / स्थान');
  String get roomHint       => _t('Select a room', 'कोठा छान्नुस्');
  String get pairBtn        => _t('Pair Monitor', 'मनिटर जोड्नुस्');
  String get pairSuccess    => _t('Monitor Connected!', 'मनिटर जोडियो!');
  String get pairSuccessMsg => _t('Your Smart Monitor is now ready to use.', 'तपाईंको स्मार्ट मनिटर अब प्रयोगको लागि तयार छ।');
  String get goToDashboard  => _t('Go to Dashboard', 'ड्यासबोर्डमा जानुस्');
  String get pairFailed     => _t('Pairing failed. Check your code and try again.', 'जोड्न सकिएन। कोड जाँच गरी फेरि प्रयास गर्नुस्।');
  String get pairNetworkErr => _t("Can't reach server. Check your internet connection.", 'सर्भरमा पुग्न सकिएन। इन्टरनेट जाँच गर्नुस्।');
  String get pairCodeNotFound => _t('Pairing code not recognized. Check the label on your device.', 'पेयरिङ कोड पहिचान भएन। उपकरणको लेबल जाँच गर्नुस्।');
  String get pairAlreadyPaired => _t('This monitor is already paired to an account.', 'यो मनिटर पहिले नै खातामा जोडिएको छ।');
  String get pairHelpTitle  => _t('Where is my pairing code?', 'मेरो पेयरिङ कोड कहाँ छ?');
  String get pairHelpBody   => _t(
    'Your pairing code is the Device ID printed on the label attached to your Smart Monitor hardware. It looks like "ESP32-001" or "ESP32-ABC".\n\nIf you cannot find it, check the underside or back of the device.',
    'तपाईंको पेयरिङ कोड स्मार्ट मनिटर हार्डवेयरमा टाँसिएको लेबलमा छापिएको Device ID हो। यो "ESP32-001" वा "ESP32-ABC" जस्तो देखिन्छ।\n\nयदि भेट्टाउन सक्नुभएन भने, उपकरणको तल वा पछाडि जाँच गर्नुस्।',
  );

  // ── Room names ───────────────────────────────────────────────────────────
  List<String> get rooms => isNepali
      ? ['बैठक कोठा', 'सुत्ने कोठा', 'भान्साकोठा', 'बाथरूम', 'अध्ययन कोठा', 'गैरेज', 'अन्य']
      : ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Study Room', 'Garage', 'Other'];

  // ── Cost / Analytics ─────────────────────────────────────────────────────
  String get costTitle      => _t('Cost & Usage', 'लागत र प्रयोग');
  String get today          => _t('Today', 'आज');
  String get thisMonth      => _t('This Month', 'यो महिना');
  String get thisYear       => _t('This Year', 'यो वर्ष');
  String get totalUsage     => _t('Total Usage', 'कुल प्रयोग');
  String get estimatedBill  => _t('Estimated Bill', 'अनुमानित बिल');
  String get dailyAvg       => _t('Daily Average', 'दैनिक औसत');
  String get peakUsage      => _t('Peak Usage', 'उच्च प्रयोग');
  String get savingsTip     => _t('Savings Tip', 'बचत सुझाव');
  String get costPerKWh     => _t('Rate per kWh', 'प्रति kWh दर');
  String get slab           => _t('Tariff Slab', 'ट्यारिफ स्ल्याब');
  String get noCostData     => _t('No usage data yet', 'अहिलेसम्म कुनै डाटा छैन');
  String get projectedBill  => _t('Projected Monthly Bill', 'अनुमानित मासिक बिल');
  String get billBreakdown  => _t('Bill Breakdown', 'बिलको विवरण');

  String tipForUsage(double kwh) {
    if (kwh < 50) {
      return _t(
        'Great job! Your usage is low. Keep appliances on only when needed.',
        'राम्रो! तपाईंको प्रयोग कम छ। उपकरणहरू आवश्यकता अनुसार मात्र चलाउनुस्।',
      );
    } else if (kwh < 150) {
      return _t(
        'Average usage. Try switching off fans and lights when leaving a room.',
        'सामान्य प्रयोग। कोठाबाट बाहिर जाँदा पंखा र बत्ती बन्द गर्ने प्रयास गर्नुस्।',
      );
    } else {
      return _t(
        'High usage this month. Consider checking which appliances use the most power.',
        'यो महिना उच्च प्रयोग भएको छ। कुन उपकरणले बढी बिजुली खर्च गर्छ जाँच गर्नुस्।',
      );
    }
  }

  // ── Alerts ───────────────────────────────────────────────────────────────
  String get alertsTitle    => _t('Alerts', 'सूचनाहरू');
  String get noAlerts       => _t('No alerts', 'कुनै सूचना छैन');
  String get noAlertsHint   => _t('You\'re all good! Alerts will appear here.', 'सबै ठीक छ! सूचनाहरू यहाँ देखिनेछन्।');
  String get markAllRead    => _t('Mark all as read', 'सबै पढिएको चिन्ह लगाउनुस्');

  // ── Settings ─────────────────────────────────────────────────────────────
  String get settingsTitle  => _t('Settings', 'सेटिङ');
  String get account        => _t('Account', 'खाता');
  String get language       => _t('Language', 'भाषा');
  String get langEnglish    => _t('English', 'अंग्रेजी');
  String get langNepali     => _t('Nepali', 'नेपाली');
  String get tariffSettings => _t('Electricity Tariff (NEA)', 'विद्युत महसुल (नेपाल विद्युत प्राधिकरण)');
  String get tariffHint     => _t(
    'These rates are used to estimate your electricity bill. Update them to match your current NEA tariff.',
    'यी दरहरू तपाईंको विद्युत बिल अनुमान गर्न प्रयोग गरिन्छ। हालको NEA महसुलसँग मिलाउन अद्यावधिक गर्नुस्।',
  );
  String get tariffSaved    => _t('Tariff settings saved ✓', 'महसुल सेटिङ बचत भयो ✓');
  String get tariffFailed   => _t('Failed to save tariff', 'महसुल बचत गर्न सकिएन');
  String get tariffLoadFail => _t('Could not load tariff settings', 'महसुल सेटिङ लोड गर्न सकिएन');
  String get aboutSection   => _t('About', 'बारेमा');
  String get appVersion     => _t('App Version', 'एप संस्करण');
  String get contactSupport => _t('Contact Support', 'सहयोग सम्पर्क');
  String get signOutConfirmMsg => _t('Are you sure you want to sign out?', 'के तपाईं साइन आउट गर्न निश्चित हुनुहुन्छ?');

  // ── Energy Summary ───────────────────────────────────────────────────────
  String get totalKWh       => _t('Total kWh', 'कुल kWh');
  String get avgPower       => _t('Avg. Power', 'औसत पावर');
  String get peakPower      => _t('Peak Power', 'उच्च पावर');
  String get estCost        => _t('Est. Cost', 'अनुमानित लागत');
  String get currency       => 'NPR';
}
