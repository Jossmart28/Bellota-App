import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_mi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('mi'),
  ];

  /// No description provided for @appTitleTitle.
  ///
  /// In es, this message translates to:
  /// **'Bellota · Calendario Menstrual'**
  String get appTitleTitle;

  /// No description provided for @navigationHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navigationHome;

  /// No description provided for @navigationCalendar.
  ///
  /// In es, this message translates to:
  /// **'Calendario'**
  String get navigationCalendar;

  /// No description provided for @navigationLog.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get navigationLog;

  /// No description provided for @navigationMap.
  ///
  /// In es, this message translates to:
  /// **'Mapa'**
  String get navigationMap;

  /// No description provided for @navigationProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navigationProfile;

  /// No description provided for @dashboardPredictions.
  ///
  /// In es, this message translates to:
  /// **'Predicciones'**
  String get dashboardPredictions;

  /// No description provided for @dashboardTodaysSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen de hoy'**
  String get dashboardTodaysSummary;

  /// No description provided for @dashboardInformationForYou.
  ///
  /// In es, this message translates to:
  /// **'Información para ti'**
  String get dashboardInformationForYou;

  /// No description provided for @dashboardComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get dashboardComingSoon;

  /// No description provided for @cyclePhasesPhase.
  ///
  /// In es, this message translates to:
  /// **'Fase'**
  String get cyclePhasesPhase;

  /// No description provided for @cyclePhasesMenstrualPhase.
  ///
  /// In es, this message translates to:
  /// **'Fase Menstrual'**
  String get cyclePhasesMenstrualPhase;

  /// No description provided for @cyclePhasesFollicularPhase.
  ///
  /// In es, this message translates to:
  /// **'Fase Folicular'**
  String get cyclePhasesFollicularPhase;

  /// No description provided for @cyclePhasesOvulatoryPhase.
  ///
  /// In es, this message translates to:
  /// **'Fase Ovulatoria'**
  String get cyclePhasesOvulatoryPhase;

  /// No description provided for @cyclePhasesLutealPhase.
  ///
  /// In es, this message translates to:
  /// **'Fase Lútea'**
  String get cyclePhasesLutealPhase;

  /// No description provided for @cyclePhasesMenstrual.
  ///
  /// In es, this message translates to:
  /// **'Menstrual'**
  String get cyclePhasesMenstrual;

  /// No description provided for @cyclePhasesFollicular.
  ///
  /// In es, this message translates to:
  /// **'Folicular'**
  String get cyclePhasesFollicular;

  /// No description provided for @cyclePhasesOvulatory.
  ///
  /// In es, this message translates to:
  /// **'Ovulatoria'**
  String get cyclePhasesOvulatory;

  /// No description provided for @cyclePhasesLuteal.
  ///
  /// In es, this message translates to:
  /// **'Lútea'**
  String get cyclePhasesLuteal;

  /// No description provided for @calendarJan.
  ///
  /// In es, this message translates to:
  /// **'ene'**
  String get calendarJan;

  /// No description provided for @calendarFeb.
  ///
  /// In es, this message translates to:
  /// **'feb'**
  String get calendarFeb;

  /// No description provided for @calendarMar.
  ///
  /// In es, this message translates to:
  /// **'mar'**
  String get calendarMar;

  /// No description provided for @calendarApr.
  ///
  /// In es, this message translates to:
  /// **'abr'**
  String get calendarApr;

  /// No description provided for @calendarMay.
  ///
  /// In es, this message translates to:
  /// **'may'**
  String get calendarMay;

  /// No description provided for @calendarJun.
  ///
  /// In es, this message translates to:
  /// **'jun'**
  String get calendarJun;

  /// No description provided for @calendarJul.
  ///
  /// In es, this message translates to:
  /// **'jul'**
  String get calendarJul;

  /// No description provided for @calendarAug.
  ///
  /// In es, this message translates to:
  /// **'ago'**
  String get calendarAug;

  /// No description provided for @calendarSep.
  ///
  /// In es, this message translates to:
  /// **'sep'**
  String get calendarSep;

  /// No description provided for @calendarOct.
  ///
  /// In es, this message translates to:
  /// **'oct'**
  String get calendarOct;

  /// No description provided for @calendarNov.
  ///
  /// In es, this message translates to:
  /// **'nov'**
  String get calendarNov;

  /// No description provided for @calendarDec.
  ///
  /// In es, this message translates to:
  /// **'dic'**
  String get calendarDec;

  /// No description provided for @calendarSun.
  ///
  /// In es, this message translates to:
  /// **'dom'**
  String get calendarSun;

  /// No description provided for @calendarMon.
  ///
  /// In es, this message translates to:
  /// **'lun'**
  String get calendarMon;

  /// No description provided for @calendarTue.
  ///
  /// In es, this message translates to:
  /// **'mar'**
  String get calendarTue;

  /// No description provided for @calendarWed.
  ///
  /// In es, this message translates to:
  /// **'mié'**
  String get calendarWed;

  /// No description provided for @calendarThu.
  ///
  /// In es, this message translates to:
  /// **'jue'**
  String get calendarThu;

  /// No description provided for @calendarFri.
  ///
  /// In es, this message translates to:
  /// **'vie'**
  String get calendarFri;

  /// No description provided for @calendarSat.
  ///
  /// In es, this message translates to:
  /// **'sáb'**
  String get calendarSat;

  /// No description provided for @calendarViewsYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get calendarViewsYear;

  /// No description provided for @calendarViewsMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get calendarViewsMonth;

  /// No description provided for @calendarViewsWeekShort.
  ///
  /// In es, this message translates to:
  /// **'Sem.'**
  String get calendarViewsWeekShort;

  /// No description provided for @calendarViewsView.
  ///
  /// In es, this message translates to:
  /// **'Vista'**
  String get calendarViewsView;

  /// No description provided for @calendarViewsWeeklyView.
  ///
  /// In es, this message translates to:
  /// **'Vista Semanal'**
  String get calendarViewsWeeklyView;

  /// No description provided for @calendarViewsMonthlyView.
  ///
  /// In es, this message translates to:
  /// **'Vista Mensual'**
  String get calendarViewsMonthlyView;

  /// No description provided for @calendarViewsYearlyView.
  ///
  /// In es, this message translates to:
  /// **'Vista Anual'**
  String get calendarViewsYearlyView;

  /// No description provided for @calendarViewsBackToYear.
  ///
  /// In es, this message translates to:
  /// **'Volver al Año'**
  String get calendarViewsBackToYear;

  /// No description provided for @symptomsAndActionsLogSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Registrar síntomas'**
  String get symptomsAndActionsLogSymptoms;

  /// No description provided for @symptomsAndActionsLoggedSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas Registrados'**
  String get symptomsAndActionsLoggedSymptoms;

  /// No description provided for @symptomsAndActionsNoEntriesDay.
  ///
  /// In es, this message translates to:
  /// **'No hay registros para este día. Presiona el botón para agregar.'**
  String get symptomsAndActionsNoEntriesDay;

  /// No description provided for @symptomsAndActionsNoSymptomsLogged.
  ///
  /// In es, this message translates to:
  /// **'Ningún síntoma registrado.'**
  String get symptomsAndActionsNoSymptomsLogged;

  /// No description provided for @symptomsAndActionsPeriodStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio del periodo'**
  String get symptomsAndActionsPeriodStart;

  /// No description provided for @symptomsAndActionsLastPeriodStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio del último período'**
  String get symptomsAndActionsLastPeriodStart;

  /// No description provided for @symptomsAndActionsExpectedSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas esperados'**
  String get symptomsAndActionsExpectedSymptoms;

  /// No description provided for @symptomsAndActionsNextPeriodWillBe.
  ///
  /// In es, this message translates to:
  /// **'Tu próximo periodo será...'**
  String get symptomsAndActionsNextPeriodWillBe;

  /// No description provided for @symptomsAndActionsBasedOnLastCycles.
  ///
  /// In es, this message translates to:
  /// **'Basado en tus últimos ciclos.'**
  String get symptomsAndActionsBasedOnLastCycles;

  /// No description provided for @symptomsAndActionsRecentPeriodError.
  ///
  /// In es, this message translates to:
  /// **'Ya existe un inicio de periodo reciente. Elimina el registro anterior para agregar este.'**
  String get symptomsAndActionsRecentPeriodError;

  /// No description provided for @symptomsCramps.
  ///
  /// In es, this message translates to:
  /// **'Cólicos'**
  String get symptomsCramps;

  /// No description provided for @symptomsFatigue.
  ///
  /// In es, this message translates to:
  /// **'Cansancio'**
  String get symptomsFatigue;

  /// No description provided for @symptomsHighEnergy.
  ///
  /// In es, this message translates to:
  /// **'Energía alta'**
  String get symptomsHighEnergy;

  /// No description provided for @symptomsSeverePain.
  ///
  /// In es, this message translates to:
  /// **'Fuerte dolor'**
  String get symptomsSeverePain;

  /// No description provided for @symptomsMoodSwings.
  ///
  /// In es, this message translates to:
  /// **'Cambios de humor'**
  String get symptomsMoodSwings;

  /// No description provided for @symptomsSensitivity.
  ///
  /// In es, this message translates to:
  /// **'Sensibilidad'**
  String get symptomsSensitivity;

  /// No description provided for @onboardingWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenida a Bellota!'**
  String get onboardingWelcome;

  /// No description provided for @onboardingInstructions.
  ///
  /// In es, this message translates to:
  /// **'Para comenzar, necesitamos saber cuándo fue el primer día de tu último período.  Toca un día en el calendario para marcarlo.'**
  String get onboardingInstructions;

  /// No description provided for @onboardingLetsStart.
  ///
  /// In es, this message translates to:
  /// **'Empecemos'**
  String get onboardingLetsStart;

  /// No description provided for @onboardingTapStartDay.
  ///
  /// In es, this message translates to:
  /// **'Toca el día de inicio'**
  String get onboardingTapStartDay;

  /// No description provided for @onboardingTapLastPeriodStart.
  ///
  /// In es, this message translates to:
  /// **'Toca el día en que comenzó tu último período'**
  String get onboardingTapLastPeriodStart;

  /// No description provided for @onboardingConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get onboardingConfirm;

  /// No description provided for @onboardingCalendarIsBelow.
  ///
  /// In es, this message translates to:
  /// **'El calendario está debajo'**
  String get onboardingCalendarIsBelow;

  /// No description provided for @onboardingGotItLetsGo.
  ///
  /// In es, this message translates to:
  /// **'Entendido, ¡vamos!'**
  String get onboardingGotItLetsGo;

  /// No description provided for @informationStressQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo afecta el estrés tu ciclo?'**
  String get informationStressQuestion;

  /// No description provided for @informationStressAnswer.
  ///
  /// In es, this message translates to:
  /// **'El estrés crónico puede alterar tus niveles hormonales, provocando retrasos en tu periodo o cambios en la ovulación.'**
  String get informationStressAnswer;

  /// No description provided for @registrationFormCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get registrationFormCancel;

  /// No description provided for @registrationFormSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas'**
  String get registrationFormSymptoms;

  /// No description provided for @registrationFormWholeBody.
  ///
  /// In es, this message translates to:
  /// **'Todo el cuerpo'**
  String get registrationFormWholeBody;

  /// No description provided for @registrationFormFever.
  ///
  /// In es, this message translates to:
  /// **'Fiebre'**
  String get registrationFormFever;

  /// No description provided for @registrationFormBodyAche.
  ///
  /// In es, this message translates to:
  /// **'Dolor de cuerpo'**
  String get registrationFormBodyAche;

  /// No description provided for @registrationFormGeneralDistension.
  ///
  /// In es, this message translates to:
  /// **'Distensión general'**
  String get registrationFormGeneralDistension;

  /// No description provided for @registrationFormHead.
  ///
  /// In es, this message translates to:
  /// **'Cabeza'**
  String get registrationFormHead;

  /// No description provided for @registrationFormHeadache.
  ///
  /// In es, this message translates to:
  /// **'Dolor de cabeza'**
  String get registrationFormHeadache;

  /// No description provided for @registrationFormVertigo.
  ///
  /// In es, this message translates to:
  /// **'Vértigo'**
  String get registrationFormVertigo;

  /// No description provided for @registrationFormInsomnia.
  ///
  /// In es, this message translates to:
  /// **'Insomnio'**
  String get registrationFormInsomnia;

  /// No description provided for @registrationFormVomiting.
  ///
  /// In es, this message translates to:
  /// **'Vómitos'**
  String get registrationFormVomiting;

  /// No description provided for @registrationFormAcne.
  ///
  /// In es, this message translates to:
  /// **'Acné'**
  String get registrationFormAcne;

  /// No description provided for @registrationFormAbdomen.
  ///
  /// In es, this message translates to:
  /// **'Abdomen'**
  String get registrationFormAbdomen;

  /// No description provided for @registrationFormAbdominalPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor abdominal'**
  String get registrationFormAbdominalPain;

  /// No description provided for @registrationFormAbdominalDistension.
  ///
  /// In es, this message translates to:
  /// **'Distensión abdominal y vientre hinchado'**
  String get registrationFormAbdominalDistension;

  /// No description provided for @registrationFormDiarrhea.
  ///
  /// In es, this message translates to:
  /// **'Diarrea'**
  String get registrationFormDiarrhea;

  /// No description provided for @registrationFormConstipation.
  ///
  /// In es, this message translates to:
  /// **'Estreñimiento'**
  String get registrationFormConstipation;

  /// No description provided for @registrationFormOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get registrationFormOther;

  /// No description provided for @registrationFormBreastTenderness.
  ///
  /// In es, this message translates to:
  /// **'Sensibilidad en los senos'**
  String get registrationFormBreastTenderness;

  /// No description provided for @registrationFormAbnormalDischarge.
  ///
  /// In es, this message translates to:
  /// **'Secreción vaginal anormal'**
  String get registrationFormAbnormalDischarge;

  /// No description provided for @registrationFormSpotting.
  ///
  /// In es, this message translates to:
  /// **'Manchado menstrual'**
  String get registrationFormSpotting;

  /// No description provided for @registrationFormPersonalization.
  ///
  /// In es, this message translates to:
  /// **'Personalización'**
  String get registrationFormPersonalization;

  /// No description provided for @registrationFormCustomSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas personalizados'**
  String get registrationFormCustomSymptoms;

  /// No description provided for @registrationFormPressEnter.
  ///
  /// In es, this message translates to:
  /// **'Pulse la tecla Enter para finalizar la edición'**
  String get registrationFormPressEnter;

  /// No description provided for @registrationFormVaginalFlow.
  ///
  /// In es, this message translates to:
  /// **'Flujo vaginal'**
  String get registrationFormVaginalFlow;

  /// No description provided for @registrationFormDry.
  ///
  /// In es, this message translates to:
  /// **'Seco'**
  String get registrationFormDry;

  /// No description provided for @registrationFormThick.
  ///
  /// In es, this message translates to:
  /// **'Espeso'**
  String get registrationFormThick;

  /// No description provided for @registrationFormLiquidElastic.
  ///
  /// In es, this message translates to:
  /// **'Líquido y elástico'**
  String get registrationFormLiquidElastic;

  /// No description provided for @registrationFormWatery.
  ///
  /// In es, this message translates to:
  /// **'Acuoso'**
  String get registrationFormWatery;

  /// No description provided for @registrationFormEggWhite.
  ///
  /// In es, this message translates to:
  /// **'Clara de huevo'**
  String get registrationFormEggWhite;

  /// No description provided for @registrationFormSex.
  ///
  /// In es, this message translates to:
  /// **'Sexo'**
  String get registrationFormSex;

  /// No description provided for @registrationFormNoContraception.
  ///
  /// In es, this message translates to:
  /// **'Sin anticoncepción'**
  String get registrationFormNoContraception;

  /// No description provided for @registrationFormCondom.
  ///
  /// In es, this message translates to:
  /// **'Condón'**
  String get registrationFormCondom;

  /// No description provided for @registrationFormNoEjaculation.
  ///
  /// In es, this message translates to:
  /// **'Sin eyacular'**
  String get registrationFormNoEjaculation;

  /// No description provided for @registrationFormShortPill.
  ///
  /// In es, this message translates to:
  /// **'Píldora de corta duración'**
  String get registrationFormShortPill;

  /// No description provided for @registrationFormBleedingPattern.
  ///
  /// In es, this message translates to:
  /// **'Patrón de Sangrado'**
  String get registrationFormBleedingPattern;

  /// No description provided for @registrationFormFlowIntensity.
  ///
  /// In es, this message translates to:
  /// **'Intensidad del flujo'**
  String get registrationFormFlowIntensity;

  /// No description provided for @registrationFormLightFlow.
  ///
  /// In es, this message translates to:
  /// **'Leve <3'**
  String get registrationFormLightFlow;

  /// No description provided for @registrationFormModerateFlow.
  ///
  /// In es, this message translates to:
  /// **'Moderado 3-5'**
  String get registrationFormModerateFlow;

  /// No description provided for @registrationFormHeavyFlow.
  ///
  /// In es, this message translates to:
  /// **'Abundante >5'**
  String get registrationFormHeavyFlow;

  /// No description provided for @registrationFormClots.
  ///
  /// In es, this message translates to:
  /// **'Coágulos'**
  String get registrationFormClots;

  /// No description provided for @registrationFormNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get registrationFormNever;

  /// No description provided for @registrationFormOccasional.
  ///
  /// In es, this message translates to:
  /// **'Ocasional'**
  String get registrationFormOccasional;

  /// No description provided for @registrationFormFrequent.
  ///
  /// In es, this message translates to:
  /// **'Frecuente'**
  String get registrationFormFrequent;

  /// No description provided for @registrationFormIntermenstrualSpotting.
  ///
  /// In es, this message translates to:
  /// **'Manchado intermenstrual'**
  String get registrationFormIntermenstrualSpotting;

  /// No description provided for @registrationFormNo.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get registrationFormNo;

  /// No description provided for @registrationFormYes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get registrationFormYes;

  /// No description provided for @registrationFormCycleDays.
  ///
  /// In es, this message translates to:
  /// **'Días del ciclo (Ej. 14, 15)'**
  String get registrationFormCycleDays;

  /// No description provided for @registrationFormSexSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas en relaciones sexuales'**
  String get registrationFormSexSymptoms;

  /// No description provided for @registrationFormPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor'**
  String get registrationFormPain;

  /// No description provided for @registrationFormBleeding.
  ///
  /// In es, this message translates to:
  /// **'Sangrado'**
  String get registrationFormBleeding;

  /// No description provided for @registrationFormUnusualFlow.
  ///
  /// In es, this message translates to:
  /// **'Flujo inusual'**
  String get registrationFormUnusualFlow;

  /// No description provided for @registrationFormNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get registrationFormNone;

  /// No description provided for @registrationFormPainAndSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Dolor y Sintomatología'**
  String get registrationFormPainAndSymptoms;

  /// No description provided for @registrationFormPainLevel.
  ///
  /// In es, this message translates to:
  /// **'Nivel de dolor'**
  String get registrationFormPainLevel;

  /// No description provided for @registrationFormCharacter.
  ///
  /// In es, this message translates to:
  /// **'Carácter'**
  String get registrationFormCharacter;

  /// No description provided for @registrationFormIncapacitating.
  ///
  /// In es, this message translates to:
  /// **'Incapacitante'**
  String get registrationFormIncapacitating;

  /// No description provided for @registrationFormNotIncapacitating.
  ///
  /// In es, this message translates to:
  /// **'No incapacitante'**
  String get registrationFormNotIncapacitating;

  /// No description provided for @registrationFormCriticalPainDays.
  ///
  /// In es, this message translates to:
  /// **'Días con dolor crítico'**
  String get registrationFormCriticalPainDays;

  /// No description provided for @registrationFormPhaseDays.
  ///
  /// In es, this message translates to:
  /// **'Días de la fase (Ej. 1, 2)'**
  String get registrationFormPhaseDays;

  /// No description provided for @registrationFormTreatment.
  ///
  /// In es, this message translates to:
  /// **'Tratamiento'**
  String get registrationFormTreatment;

  /// No description provided for @registrationFormMedication.
  ///
  /// In es, this message translates to:
  /// **'Medicamento'**
  String get registrationFormMedication;

  /// No description provided for @registrationFormThermalRemedies.
  ///
  /// In es, this message translates to:
  /// **'Remedios térmicos'**
  String get registrationFormThermalRemedies;

  /// No description provided for @registrationFormPhysicalSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas físicos'**
  String get registrationFormPhysicalSymptoms;

  /// No description provided for @registrationFormSevereCramps.
  ///
  /// In es, this message translates to:
  /// **'Cólicos severos'**
  String get registrationFormSevereCramps;

  /// No description provided for @registrationFormMenstrualMigraine.
  ///
  /// In es, this message translates to:
  /// **'Migraña menstrual'**
  String get registrationFormMenstrualMigraine;

  /// No description provided for @registrationFormMastalgia.
  ///
  /// In es, this message translates to:
  /// **'Mastalgia'**
  String get registrationFormMastalgia;

  /// No description provided for @registrationFormEmotionalSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas emocionales'**
  String get registrationFormEmotionalSymptoms;

  /// No description provided for @registrationFormAnxiety.
  ///
  /// In es, this message translates to:
  /// **'Ansiedad'**
  String get registrationFormAnxiety;

  /// No description provided for @registrationFormExtremeFatigue.
  ///
  /// In es, this message translates to:
  /// **'Fatiga extrema'**
  String get registrationFormExtremeFatigue;

  /// No description provided for @registrationFormPmddSuspicion.
  ///
  /// In es, this message translates to:
  /// **'Sospecha de TDPM'**
  String get registrationFormPmddSuspicion;

  /// No description provided for @registrationFormBreastExam.
  ///
  /// In es, this message translates to:
  /// **'Autoexamen de mama'**
  String get registrationFormBreastExam;

  /// No description provided for @registrationFormDone.
  ///
  /// In es, this message translates to:
  /// **'Realizado (7 días post)'**
  String get registrationFormDone;

  /// No description provided for @registrationFormPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get registrationFormPending;

  /// No description provided for @registrationFormPeriodStarts.
  ///
  /// In es, this message translates to:
  /// **'Inicia el período'**
  String get registrationFormPeriodStarts;

  /// No description provided for @registrationFormSaved.
  ///
  /// In es, this message translates to:
  /// **'Registrado ✓'**
  String get registrationFormSaved;

  /// No description provided for @registrationFormSaveLog.
  ///
  /// In es, this message translates to:
  /// **'Guardar registro'**
  String get registrationFormSaveLog;

  /// No description provided for @registrationFormLowerBackPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor lumbar'**
  String get registrationFormLowerBackPain;

  /// No description provided for @registrationFormLegCramps.
  ///
  /// In es, this message translates to:
  /// **'Calambres en piernas'**
  String get registrationFormLegCramps;

  /// No description provided for @registrationFormAppetiteChanges.
  ///
  /// In es, this message translates to:
  /// **'Cambios de apetito'**
  String get registrationFormAppetiteChanges;

  /// No description provided for @registrationFormCravings.
  ///
  /// In es, this message translates to:
  /// **'Antojos'**
  String get registrationFormCravings;

  /// No description provided for @registrationFormWaterRetention.
  ///
  /// In es, this message translates to:
  /// **'Retención de líquidos'**
  String get registrationFormWaterRetention;

  /// No description provided for @registrationFormNightSweats.
  ///
  /// In es, this message translates to:
  /// **'Sudoración nocturna'**
  String get registrationFormNightSweats;

  /// No description provided for @registrationFormPalpitations.
  ///
  /// In es, this message translates to:
  /// **'Palpitaciones'**
  String get registrationFormPalpitations;

  /// No description provided for @registrationFormDizziness.
  ///
  /// In es, this message translates to:
  /// **'Mareos'**
  String get registrationFormDizziness;

  /// No description provided for @registrationFormHotFlashes.
  ///
  /// In es, this message translates to:
  /// **'Sofocos'**
  String get registrationFormHotFlashes;

  /// No description provided for @registrationFormJointPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor articular'**
  String get registrationFormJointPain;

  /// No description provided for @registrationFormBloating.
  ///
  /// In es, this message translates to:
  /// **'Hinchazón'**
  String get registrationFormBloating;

  /// No description provided for @registrationFormNausea.
  ///
  /// In es, this message translates to:
  /// **'Náuseas'**
  String get registrationFormNausea;

  /// No description provided for @registrationFormPelvicPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor pélvico'**
  String get registrationFormPelvicPain;

  /// No description provided for @registrationFormIrritability.
  ///
  /// In es, this message translates to:
  /// **'Irritabilidad'**
  String get registrationFormIrritability;

  /// No description provided for @registrationFormSadness.
  ///
  /// In es, this message translates to:
  /// **'Tristeza'**
  String get registrationFormSadness;

  /// No description provided for @registrationFormCryingEasily.
  ///
  /// In es, this message translates to:
  /// **'Llanto fácil'**
  String get registrationFormCryingEasily;

  /// No description provided for @registrationFormConcentrationDifficulty.
  ///
  /// In es, this message translates to:
  /// **'Dificultad para concentrarse'**
  String get registrationFormConcentrationDifficulty;

  /// No description provided for @registrationFormLowSelfEsteem.
  ///
  /// In es, this message translates to:
  /// **'Baja autoestima'**
  String get registrationFormLowSelfEsteem;

  /// No description provided for @registrationFormMoodSwings.
  ///
  /// In es, this message translates to:
  /// **'Cambios de humor'**
  String get registrationFormMoodSwings;

  /// No description provided for @registrationFormBloodColor.
  ///
  /// In es, this message translates to:
  /// **'Color del sangrado'**
  String get registrationFormBloodColor;

  /// No description provided for @registrationFormBrightRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo brillante'**
  String get registrationFormBrightRed;

  /// No description provided for @registrationFormDarkRed.
  ///
  /// In es, this message translates to:
  /// **'Rojo oscuro'**
  String get registrationFormDarkRed;

  /// No description provided for @registrationFormBrown.
  ///
  /// In es, this message translates to:
  /// **'Marrón'**
  String get registrationFormBrown;

  /// No description provided for @registrationFormPink.
  ///
  /// In es, this message translates to:
  /// **'Rosado'**
  String get registrationFormPink;

  /// No description provided for @registrationFormBreastExamInfo.
  ///
  /// In es, this message translates to:
  /// **'Realizar mensualmente, 7-10 días después del inicio del período'**
  String get registrationFormBreastExamInfo;

  /// No description provided for @registrationFormBreastNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get registrationFormBreastNormal;

  /// No description provided for @registrationFormBreastLump.
  ///
  /// In es, this message translates to:
  /// **'Bulto detectado'**
  String get registrationFormBreastLump;

  /// No description provided for @registrationFormBreastLocalizedPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor localizado'**
  String get registrationFormBreastLocalizedPain;

  /// No description provided for @registrationFormBreastSkinChange.
  ///
  /// In es, this message translates to:
  /// **'Cambio en piel'**
  String get registrationFormBreastSkinChange;

  /// No description provided for @registrationFormBreastDischarge.
  ///
  /// In es, this message translates to:
  /// **'Secreción'**
  String get registrationFormBreastDischarge;

  /// No description provided for @registrationFormBreastPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get registrationFormBreastPending;

  /// No description provided for @registrationFormPainNone.
  ///
  /// In es, this message translates to:
  /// **'Sin dolor'**
  String get registrationFormPainNone;

  /// No description provided for @registrationFormPainMild.
  ///
  /// In es, this message translates to:
  /// **'Leve'**
  String get registrationFormPainMild;

  /// No description provided for @registrationFormPainModerate.
  ///
  /// In es, this message translates to:
  /// **'Moderado'**
  String get registrationFormPainModerate;

  /// No description provided for @registrationFormPainSevere.
  ///
  /// In es, this message translates to:
  /// **'Severo'**
  String get registrationFormPainSevere;

  /// No description provided for @registrationFormPainIncapacitating.
  ///
  /// In es, this message translates to:
  /// **'Incapacitante'**
  String get registrationFormPainIncapacitating;

  /// No description provided for @registrationFormPainAlertMsg.
  ///
  /// In es, this message translates to:
  /// **'Un dolor de esta intensidad amerita consulta médica. Considera agendar una cita.'**
  String get registrationFormPainAlertMsg;

  /// No description provided for @registrationFormDryInfo.
  ///
  /// In es, this message translates to:
  /// **'Fase post-ovulatoria, baja fertilidad'**
  String get registrationFormDryInfo;

  /// No description provided for @registrationFormThickInfo.
  ///
  /// In es, this message translates to:
  /// **'Normal, fase lútea'**
  String get registrationFormThickInfo;

  /// No description provided for @registrationFormLiquidElasticInfo.
  ///
  /// In es, this message translates to:
  /// **'Fertilidad en aumento'**
  String get registrationFormLiquidElasticInfo;

  /// No description provided for @registrationFormWateryInfo.
  ///
  /// In es, this message translates to:
  /// **'Fertilidad alta, cerca de ovulación'**
  String get registrationFormWateryInfo;

  /// No description provided for @registrationFormEggWhiteInfo.
  ///
  /// In es, this message translates to:
  /// **'Fase más fértil, ovulación inminente'**
  String get registrationFormEggWhiteInfo;

  /// No description provided for @registrationFormFertilityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta fertilidad'**
  String get registrationFormFertilityHigh;

  /// No description provided for @registrationFormFertilityMedium.
  ///
  /// In es, this message translates to:
  /// **'Fertilidad media'**
  String get registrationFormFertilityMedium;

  /// No description provided for @registrationFormFertilityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja fertilidad'**
  String get registrationFormFertilityLow;

  /// No description provided for @registrationFormNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas personales'**
  String get registrationFormNotes;

  /// No description provided for @registrationFormNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe observaciones del día...'**
  String get registrationFormNotesHint;

  /// No description provided for @registrationFormComplete.
  ///
  /// In es, this message translates to:
  /// **'Completo'**
  String get registrationFormComplete;

  /// No description provided for @registrationFormPartial.
  ///
  /// In es, this message translates to:
  /// **'Parcial'**
  String get registrationFormPartial;

  /// No description provided for @registrationFormLogProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso del registro'**
  String get registrationFormLogProgress;

  /// No description provided for @registrationFormSelectedCount.
  ///
  /// In es, this message translates to:
  /// **'seleccionados'**
  String get registrationFormSelectedCount;

  /// No description provided for @registrationFormAddSymptom.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get registrationFormAddSymptom;

  /// No description provided for @registrationFormTotalCycles.
  ///
  /// In es, this message translates to:
  /// **'Total de ciclos registrados'**
  String get registrationFormTotalCycles;

  /// No description provided for @registrationFormLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get registrationFormLocation;

  /// No description provided for @registrationFormTopSymptoms.
  ///
  /// In es, this message translates to:
  /// **'Síntomas más frecuentes'**
  String get registrationFormTopSymptoms;

  /// No description provided for @registrationFormFlowIntensityLabel.
  ///
  /// In es, this message translates to:
  /// **'Intensidad del flujo'**
  String get registrationFormFlowIntensityLabel;

  /// No description provided for @registrationFormClotsLabel.
  ///
  /// In es, this message translates to:
  /// **'Coágulos'**
  String get registrationFormClotsLabel;

  /// No description provided for @registrationFormSpottingLabel.
  ///
  /// In es, this message translates to:
  /// **'Manchado intermenstrual'**
  String get registrationFormSpottingLabel;

  /// No description provided for @registrationFormSpottingDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días de manchado'**
  String get registrationFormSpottingDaysLabel;

  /// No description provided for @registrationFormSexSymptomsLabel.
  ///
  /// In es, this message translates to:
  /// **'Síntomas en relaciones sexuales'**
  String get registrationFormSexSymptomsLabel;

  /// No description provided for @registrationFormPainEvaLabel.
  ///
  /// In es, this message translates to:
  /// **'Nivel de dolor (EVA)'**
  String get registrationFormPainEvaLabel;

  /// No description provided for @registrationFormPainCharacterLabel.
  ///
  /// In es, this message translates to:
  /// **'Carácter del dolor'**
  String get registrationFormPainCharacterLabel;

  /// No description provided for @registrationFormPainDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días con dolor crítico'**
  String get registrationFormPainDaysLabel;

  /// No description provided for @registrationFormTreatmentLabel.
  ///
  /// In es, this message translates to:
  /// **'Tratamiento'**
  String get registrationFormTreatmentLabel;

  /// No description provided for @registrationFormPhysicalSymptomsLabel.
  ///
  /// In es, this message translates to:
  /// **'Síntomas físicos'**
  String get registrationFormPhysicalSymptomsLabel;

  /// No description provided for @registrationFormEmotionalSymptomsLabel.
  ///
  /// In es, this message translates to:
  /// **'Síntomas emocionales'**
  String get registrationFormEmotionalSymptomsLabel;

  /// No description provided for @registrationFormBreastExamLabel.
  ///
  /// In es, this message translates to:
  /// **'Autoexamen de mama'**
  String get registrationFormBreastExamLabel;

  /// No description provided for @registrationFormBloodColorLabel.
  ///
  /// In es, this message translates to:
  /// **'Color del sangrado'**
  String get registrationFormBloodColorLabel;

  /// No description provided for @registrationFormPrintPdf.
  ///
  /// In es, this message translates to:
  /// **'Imprimir'**
  String get registrationFormPrintPdf;

  /// No description provided for @registrationFormSharePdf.
  ///
  /// In es, this message translates to:
  /// **'Compartir PDF'**
  String get registrationFormSharePdf;

  /// No description provided for @registrationFormPageOf.
  ///
  /// In es, this message translates to:
  /// **'Página'**
  String get registrationFormPageOf;

  /// No description provided for @registrationFormGeneratedBy.
  ///
  /// In es, this message translates to:
  /// **'Generado por'**
  String get registrationFormGeneratedBy;

  /// No description provided for @registrationFormReportDisclaimer.
  ///
  /// In es, this message translates to:
  /// **'Este reporte no sustituye una valoración médica profesional.'**
  String get registrationFormReportDisclaimer;

  /// No description provided for @registrationFormAlertIrregularDetail.
  ///
  /// In es, this message translates to:
  /// **'Alerta: {value} días (normal 21-35 días)'**
  String registrationFormAlertIrregularDetail(Object value);

  /// No description provided for @registrationFormNormalDurationDetail.
  ///
  /// In es, this message translates to:
  /// **'Duración normal: {value} días'**
  String registrationFormNormalDurationDetail(Object value);

  /// No description provided for @registrationFormAlertBleedingDetail.
  ///
  /// In es, this message translates to:
  /// **'Alerta: {value} días consecutivos (máx. 7 días)'**
  String registrationFormAlertBleedingDetail(Object value);

  /// No description provided for @registrationFormAlertAmenorrheaDetail.
  ///
  /// In es, this message translates to:
  /// **'Sin registro. Posible retraso sin confirmación de embarazo.'**
  String get registrationFormAlertAmenorrheaDetail;

  /// No description provided for @registrationFormNoAlertAmenorrhea.
  ///
  /// In es, this message translates to:
  /// **'Sin alerta. Última menstruación registrada: {value}'**
  String registrationFormNoAlertAmenorrhea(Object value);

  /// No description provided for @registrationFormAlertSeverePainDetail.
  ///
  /// In es, this message translates to:
  /// **'Alerta: dolor severo {value}/10 que no cede'**
  String registrationFormAlertSeverePainDetail(Object value);

  /// No description provided for @registrationFormPainNormalRange.
  ///
  /// In es, this message translates to:
  /// **'Dolor dentro del rango: {value}/10'**
  String registrationFormPainNormalRange(Object value);

  /// No description provided for @registrationFormNoPainLogged.
  ///
  /// In es, this message translates to:
  /// **'Sin registro de dolor'**
  String get registrationFormNoPainLogged;

  /// No description provided for @registrationFormEmotional.
  ///
  /// In es, this message translates to:
  /// **'Emocional'**
  String get registrationFormEmotional;

  /// No description provided for @registrationFormDigestive.
  ///
  /// In es, this message translates to:
  /// **'Digestivo'**
  String get registrationFormDigestive;

  /// No description provided for @registrationFormConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get registrationFormConfirm;

  /// No description provided for @profileAndReportHealthProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil de salud'**
  String get profileAndReportHealthProfile;

  /// No description provided for @profileAndReportCycleDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración del ciclo'**
  String get profileAndReportCycleDuration;

  /// No description provided for @profileAndReportPeriodDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración de la menstruación'**
  String get profileAndReportPeriodDuration;

  /// No description provided for @profileAndReportDays.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get profileAndReportDays;

  /// No description provided for @profileAndReportDay.
  ///
  /// In es, this message translates to:
  /// **'día'**
  String get profileAndReportDay;

  /// No description provided for @profileAndReportMedicalReport.
  ///
  /// In es, this message translates to:
  /// **'Informe médico'**
  String get profileAndReportMedicalReport;

  /// No description provided for @profileAndReportGenerate.
  ///
  /// In es, this message translates to:
  /// **'Generar'**
  String get profileAndReportGenerate;

  /// No description provided for @profileAndReportAppPreferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencia de la aplicación'**
  String get profileAndReportAppPreferences;

  /// No description provided for @profileAndReportRemindersNotifications.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios y notificaciones'**
  String get profileAndReportRemindersNotifications;

  /// No description provided for @profileAndReportPrivacyPolicy.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get profileAndReportPrivacyPolicy;

  /// No description provided for @profileAndReportLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get profileAndReportLanguage;

  /// No description provided for @profileAndReportAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get profileAndReportAppearance;

  /// No description provided for @profileAndReportLightMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Claro'**
  String get profileAndReportLightMode;

  /// No description provided for @profileAndReportDarkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Oscuro'**
  String get profileAndReportDarkMode;

  /// No description provided for @profileAndReportLogout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get profileAndReportLogout;

  /// No description provided for @profileAndReportGeneratingReport.
  ///
  /// In es, this message translates to:
  /// **'Generando informe...'**
  String get profileAndReportGeneratingReport;

  /// No description provided for @profileAndReportNotSpecified.
  ///
  /// In es, this message translates to:
  /// **'No especificado'**
  String get profileAndReportNotSpecified;

  /// No description provided for @profileAndReportNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get profileAndReportNormal;

  /// No description provided for @profileAndReportIrregular.
  ///
  /// In es, this message translates to:
  /// **'Irregular'**
  String get profileAndReportIrregular;

  /// No description provided for @profileAndReportProlonged.
  ///
  /// In es, this message translates to:
  /// **'Prolongado'**
  String get profileAndReportProlonged;

  /// No description provided for @profileAndReportShort.
  ///
  /// In es, this message translates to:
  /// **'Corto'**
  String get profileAndReportShort;

  /// No description provided for @profileAndReportHealthReportTitle.
  ///
  /// In es, this message translates to:
  /// **'REPORTE DE SALUD'**
  String get profileAndReportHealthReportTitle;

  /// No description provided for @profileAndReportHealthReportSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Reporte menstrual y clínico ginecológico'**
  String get profileAndReportHealthReportSubtitle;

  /// No description provided for @profileAndReportPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista Previa'**
  String get profileAndReportPreview;

  /// No description provided for @profileAndReportSavePdf.
  ///
  /// In es, this message translates to:
  /// **'Guardar PDF'**
  String get profileAndReportSavePdf;

  /// No description provided for @profileAndReportSecGeneral.
  ///
  /// In es, this message translates to:
  /// **'1. INFORMACIÓN GENERAL'**
  String get profileAndReportSecGeneral;

  /// No description provided for @profileAndReportSecSummary.
  ///
  /// In es, this message translates to:
  /// **'2. RESUMEN ESTADÍSTICO'**
  String get profileAndReportSecSummary;

  /// No description provided for @profileAndReportSecPattern.
  ///
  /// In es, this message translates to:
  /// **'3. PATRÓN DE SANGRADO Y FLUJO'**
  String get profileAndReportSecPattern;

  /// No description provided for @profileAndReportSecPain.
  ///
  /// In es, this message translates to:
  /// **'4. DOLOR Y SINTOMATOLOGÍA ACOMPAÑANTE'**
  String get profileAndReportSecPain;

  /// No description provided for @profileAndReportSecAlerts.
  ///
  /// In es, this message translates to:
  /// **'5. ALERTAS AUTOMÁTICAS PARA CONSULTA MÉDICA'**
  String get profileAndReportSecAlerts;

  /// No description provided for @profileAndReportIrregularCycles.
  ///
  /// In es, this message translates to:
  /// **'Ciclos irregulares'**
  String get profileAndReportIrregularCycles;

  /// No description provided for @profileAndReportProlongedBleeding.
  ///
  /// In es, this message translates to:
  /// **'Sangrado prolongado'**
  String get profileAndReportProlongedBleeding;

  /// No description provided for @profileAndReportAmenorrhea.
  ///
  /// In es, this message translates to:
  /// **'Amenorrea'**
  String get profileAndReportAmenorrhea;

  /// No description provided for @profileAndReportAlertPain.
  ///
  /// In es, this message translates to:
  /// **'Dolor de alerta'**
  String get profileAndReportAlertPain;

  /// No description provided for @profileAndReportPatient.
  ///
  /// In es, this message translates to:
  /// **'Paciente'**
  String get profileAndReportPatient;

  /// No description provided for @profileAndReportAge.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get profileAndReportAge;

  /// No description provided for @profileAndReportAnalyzedRange.
  ///
  /// In es, this message translates to:
  /// **'Rango analizado'**
  String get profileAndReportAnalyzedRange;

  /// No description provided for @profileAndReportContraceptives.
  ///
  /// In es, this message translates to:
  /// **'Anticonceptivos'**
  String get profileAndReportContraceptives;

  /// No description provided for @profileAndReportLmp.
  ///
  /// In es, this message translates to:
  /// **'FUM'**
  String get profileAndReportLmp;

  /// No description provided for @profileAndReportCycleAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio del ciclo'**
  String get profileAndReportCycleAverage;

  /// No description provided for @profileAndReportBleedingAverage.
  ///
  /// In es, this message translates to:
  /// **'Promedio de sangrado'**
  String get profileAndReportBleedingAverage;

  /// No description provided for @profileAndReportMostFrequentFlow.
  ///
  /// In es, this message translates to:
  /// **'Flujo más frecuente'**
  String get profileAndReportMostFrequentFlow;

  /// No description provided for @profileAndReportLogoutConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás segura de que deseas cerrar sesión?\nTus datos quedarán guardados para cuando vuelvas.'**
  String get profileAndReportLogoutConfirm;

  /// No description provided for @profileAndReportCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get profileAndReportCancel;

  /// No description provided for @profileAndReportSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get profileAndReportSave;

  /// No description provided for @profileAndReportAdjustCycle.
  ///
  /// In es, this message translates to:
  /// **'Ajusta la duración promedio de tu ciclo menstrual'**
  String get profileAndReportAdjustCycle;

  /// No description provided for @profileAndReportAdjustPeriod.
  ///
  /// In es, this message translates to:
  /// **'Ajusta cuántos días dura tu menstruación'**
  String get profileAndReportAdjustPeriod;

  /// No description provided for @profileAndReportChangePhoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de perfil'**
  String get profileAndReportChangePhoto;

  /// No description provided for @profileAndReportGallery.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get profileAndReportGallery;

  /// No description provided for @profileAndReportCamera.
  ///
  /// In es, this message translates to:
  /// **'Cámara'**
  String get profileAndReportCamera;

  /// No description provided for @profileAndReportDeletePhoto.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get profileAndReportDeletePhoto;

  /// No description provided for @onboardingAndAuthSlogan.
  ///
  /// In es, this message translates to:
  /// **'Tu acompañante de salud menstrual'**
  String get onboardingAndAuthSlogan;

  /// No description provided for @onboardingAndAuthSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get onboardingAndAuthSkip;

  /// No description provided for @onboardingAndAuthContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingAndAuthContinue;

  /// No description provided for @onboardingAndAuthStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingAndAuthStart;

  /// No description provided for @onboardingAndAuthSlide1Title.
  ///
  /// In es, this message translates to:
  /// **'Conoce tu ciclo'**
  String get onboardingAndAuthSlide1Title;

  /// No description provided for @onboardingAndAuthSlide1Sub.
  ///
  /// In es, this message translates to:
  /// **'Registra cada día y descubre\nlos patrones que tu cuerpo te comunica.'**
  String get onboardingAndAuthSlide1Sub;

  /// No description provided for @onboardingAndAuthSlide2Title.
  ///
  /// In es, this message translates to:
  /// **'Registra cómo te sientes'**
  String get onboardingAndAuthSlide2Title;

  /// No description provided for @onboardingAndAuthSlide2Sub.
  ///
  /// In es, this message translates to:
  /// **'Síntomas, flujo, humor y más —\ntodo en un solo lugar, cada día.'**
  String get onboardingAndAuthSlide2Sub;

  /// No description provided for @onboardingAndAuthSlide3Title.
  ///
  /// In es, this message translates to:
  /// **'Predicciones inteligentes'**
  String get onboardingAndAuthSlide3Title;

  /// No description provided for @onboardingAndAuthSlide3Sub.
  ///
  /// In es, this message translates to:
  /// **'Bellota aprende de tu historial\ny te avisa cuándo esperar tu próximo período.'**
  String get onboardingAndAuthSlide3Sub;

  /// No description provided for @onboardingAndAuthLoginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get onboardingAndAuthLoginTitle;

  /// No description provided for @onboardingAndAuthWelcomeBack.
  ///
  /// In es, this message translates to:
  /// **'Bienvenida de vuelta 🌸'**
  String get onboardingAndAuthWelcomeBack;

  /// No description provided for @onboardingAndAuthEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get onboardingAndAuthEmailLabel;

  /// No description provided for @onboardingAndAuthEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@correo.com'**
  String get onboardingAndAuthEmailHint;

  /// No description provided for @onboardingAndAuthPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get onboardingAndAuthPasswordLabel;

  /// No description provided for @onboardingAndAuthForgotPass.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get onboardingAndAuthForgotPass;

  /// No description provided for @onboardingAndAuthEnter.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get onboardingAndAuthEnter;

  /// No description provided for @onboardingAndAuthOrContinueWith.
  ///
  /// In es, this message translates to:
  /// **'o continúa con'**
  String get onboardingAndAuthOrContinueWith;

  /// No description provided for @onboardingAndAuthContinueGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get onboardingAndAuthContinueGoogle;

  /// No description provided for @onboardingAndAuthNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta? '**
  String get onboardingAndAuthNoAccount;

  /// No description provided for @onboardingAndAuthRegisterNow.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get onboardingAndAuthRegisterNow;

  /// No description provided for @onboardingAndAuthCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get onboardingAndAuthCreateAccount;

  /// No description provided for @onboardingAndAuthJoinBellota.
  ///
  /// In es, this message translates to:
  /// **'Únete a Bellota 🌸'**
  String get onboardingAndAuthJoinBellota;

  /// No description provided for @onboardingAndAuthNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get onboardingAndAuthNameLabel;

  /// No description provided for @onboardingAndAuthNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre o apodo'**
  String get onboardingAndAuthNameHint;

  /// No description provided for @onboardingAndAuthConfirmPass.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Contraseña'**
  String get onboardingAndAuthConfirmPass;

  /// No description provided for @onboardingAndAuthRegisterBtn.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get onboardingAndAuthRegisterBtn;

  /// No description provided for @onboardingAndAuthInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo no válido'**
  String get onboardingAndAuthInvalidEmail;

  /// No description provided for @onboardingAndAuthEnterEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo'**
  String get onboardingAndAuthEnterEmail;

  /// No description provided for @onboardingAndAuthEnterPass.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu contraseña'**
  String get onboardingAndAuthEnterPass;

  /// No description provided for @onboardingAndAuthMin6Chars.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get onboardingAndAuthMin6Chars;

  /// No description provided for @onboardingAndAuthEnterName.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu nombre'**
  String get onboardingAndAuthEnterName;

  /// No description provided for @onboardingAndAuthConfirmPassReq.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get onboardingAndAuthConfirmPassReq;

  /// No description provided for @onboardingAndAuthPassNoMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get onboardingAndAuthPassNoMatch;

  /// No description provided for @onboardingAndAuthPersonalData.
  ///
  /// In es, this message translates to:
  /// **'Datos Personales'**
  String get onboardingAndAuthPersonalData;

  /// No description provided for @onboardingAndAuthTellUs.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos sobre ti'**
  String get onboardingAndAuthTellUs;

  /// No description provided for @onboardingAndAuthOnlyOnce.
  ///
  /// In es, this message translates to:
  /// **'Solo lo hacemos una vez 🌸'**
  String get onboardingAndAuthOnlyOnce;

  /// No description provided for @onboardingAndAuthYourCycle.
  ///
  /// In es, this message translates to:
  /// **'Tu Ciclo Menstrual'**
  String get onboardingAndAuthYourCycle;

  /// No description provided for @onboardingAndAuthDepartment.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get onboardingAndAuthDepartment;

  /// No description provided for @onboardingAndAuthMunicipality.
  ///
  /// In es, this message translates to:
  /// **'Municipio'**
  String get onboardingAndAuthMunicipality;

  /// No description provided for @onboardingAndAuthCycleDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración del ciclo'**
  String get onboardingAndAuthCycleDuration;

  /// No description provided for @onboardingAndAuthPeriodDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración de la menstruación'**
  String get onboardingAndAuthPeriodDuration;

  /// No description provided for @onboardingAndAuthAge.
  ///
  /// In es, this message translates to:
  /// **'Edad'**
  String get onboardingAndAuthAge;

  /// No description provided for @onboardingAndAuthAgeHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. 25 años'**
  String get onboardingAndAuthAgeHint;

  /// No description provided for @onboardingAndAuthInvalidNumber.
  ///
  /// In es, this message translates to:
  /// **'Introduce un número válido'**
  String get onboardingAndAuthInvalidNumber;

  /// No description provided for @onboardingAndAuthLocationSelected.
  ///
  /// In es, this message translates to:
  /// **'Ubicación seleccionada'**
  String get onboardingAndAuthLocationSelected;

  /// No description provided for @onboardingAndAuthSelectOnMap.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar en el mapa'**
  String get onboardingAndAuthSelectOnMap;

  /// No description provided for @onboardingAndAuthTapToOpenMap.
  ///
  /// In es, this message translates to:
  /// **'Toca para abrir el mapa'**
  String get onboardingAndAuthTapToOpenMap;

  /// No description provided for @onboardingAndAuthLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get onboardingAndAuthLocation;

  /// No description provided for @onboardingAndAuthHealthCenterFilter.
  ///
  /// In es, this message translates to:
  /// **'Filtro para Centros de Salud'**
  String get onboardingAndAuthHealthCenterFilter;

  /// No description provided for @onboardingAndAuthMedications.
  ///
  /// In es, this message translates to:
  /// **'Anticonceptivos / Medicamentos'**
  String get onboardingAndAuthMedications;

  /// No description provided for @onboardingAndAuthMedNone.
  ///
  /// In es, this message translates to:
  /// **'Ninguno'**
  String get onboardingAndAuthMedNone;

  /// No description provided for @onboardingAndAuthMedIud.
  ///
  /// In es, this message translates to:
  /// **'DIU'**
  String get onboardingAndAuthMedIud;

  /// No description provided for @onboardingAndAuthMedPills.
  ///
  /// In es, this message translates to:
  /// **'Pastillas'**
  String get onboardingAndAuthMedPills;

  /// No description provided for @onboardingAndAuthMedAnticonvulsants.
  ///
  /// In es, this message translates to:
  /// **'Anticonvulsivos'**
  String get onboardingAndAuthMedAnticonvulsants;

  /// No description provided for @onboardingAndAuthMedAnticoagulants.
  ///
  /// In es, this message translates to:
  /// **'Anticoagulantes'**
  String get onboardingAndAuthMedAnticoagulants;

  /// No description provided for @onboardingAndAuthCycle.
  ///
  /// In es, this message translates to:
  /// **'Ciclo'**
  String get onboardingAndAuthCycle;

  /// No description provided for @onboardingAndAuthMenstruation.
  ///
  /// In es, this message translates to:
  /// **'Menstruación'**
  String get onboardingAndAuthMenstruation;

  /// No description provided for @onboardingAndAuthFinishRegistration.
  ///
  /// In es, this message translates to:
  /// **'Finalizar Registro'**
  String get onboardingAndAuthFinishRegistration;

  /// No description provided for @registrationFormStabbing.
  ///
  /// In es, this message translates to:
  /// **'Punzante'**
  String get registrationFormStabbing;

  /// No description provided for @registrationFormPulsating.
  ///
  /// In es, this message translates to:
  /// **'Pulsátil'**
  String get registrationFormPulsating;

  /// No description provided for @registrationFormContinuous.
  ///
  /// In es, this message translates to:
  /// **'Continuo'**
  String get registrationFormContinuous;

  /// No description provided for @registrationFormRest.
  ///
  /// In es, this message translates to:
  /// **'Descanso'**
  String get registrationFormRest;

  /// No description provided for @registrationFormHeat.
  ///
  /// In es, this message translates to:
  /// **'Calor'**
  String get registrationFormHeat;

  /// No description provided for @registrationFormSelfExamNormal.
  ///
  /// In es, this message translates to:
  /// **'Normal'**
  String get registrationFormSelfExamNormal;

  /// No description provided for @registrationFormSelfExamAbnormal.
  ///
  /// In es, this message translates to:
  /// **'Anormal'**
  String get registrationFormSelfExamAbnormal;

  /// No description provided for @registrationFormSticky.
  ///
  /// In es, this message translates to:
  /// **'Pegajoso'**
  String get registrationFormSticky;

  /// No description provided for @registrationFormCreamy.
  ///
  /// In es, this message translates to:
  /// **'Cremoso'**
  String get registrationFormCreamy;

  /// No description provided for @registrationFormYellowish.
  ///
  /// In es, this message translates to:
  /// **'Amarillento'**
  String get registrationFormYellowish;

  /// No description provided for @registrationFormGreenish.
  ///
  /// In es, this message translates to:
  /// **'Verdoso'**
  String get registrationFormGreenish;

  /// No description provided for @registrationFormGrayish.
  ///
  /// In es, this message translates to:
  /// **'Grisáceo'**
  String get registrationFormGrayish;

  /// No description provided for @registrationFormFoulOdor.
  ///
  /// In es, this message translates to:
  /// **'Mal olor'**
  String get registrationFormFoulOdor;

  /// No description provided for @registrationFormItching.
  ///
  /// In es, this message translates to:
  /// **'Picazón'**
  String get registrationFormItching;

  /// No description provided for @registrationFormBurning.
  ///
  /// In es, this message translates to:
  /// **'Ardor'**
  String get registrationFormBurning;

  /// No description provided for @registrationFormKeyInfo.
  ///
  /// In es, this message translates to:
  /// **'Info'**
  String get registrationFormKeyInfo;

  /// No description provided for @symptomsAndActionsRecentPeriodTitle.
  ///
  /// In es, this message translates to:
  /// **'Periodo reciente'**
  String get symptomsAndActionsRecentPeriodTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'mi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'mi':
      return AppLocalizationsMi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
