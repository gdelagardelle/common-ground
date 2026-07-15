#!/usr/bin/env python3
"""Generate L10nCatalog.json + L10n.swift with all app translations."""

import json
from pathlib import Path

# key -> (en, de, fr, pt, lb)
STRINGS: dict[str, tuple[str, str, str, str, str]] = {
    # Tabs & shell
    "tab.home": ("Home", "Start", "Accueil", "Início", "Doheem"),
    "tab.calendar": ("Calendar", "Kalender", "Calendrier", "Calendário", "Kalenner"),
    "tab.children": ("Children", "Kinder", "Enfants", "Crianças", "Kanner"),
    "tab.messages": ("Messages", "Nachrichten", "Messages", "Mensagens", "Noriichten"),
    "tab.more": ("More", "Mehr", "Plus", "Mais", "Méi"),
    "app.name": ("Common Ground", "Common Ground", "Common Ground", "Common Ground", "Common Ground"),
    "app.tagline": ("Your family's private space", "Der private Raum Ihrer Familie", "L'espace privé de votre famille", "O espaço privado da sua família", "De private Raum vun ärer Famill"),
    "common.done": ("Done", "Fertig", "Terminé", "Concluído", "Fäerdeg"),
    "common.cancel": ("Cancel", "Abbrechen", "Annuler", "Cancelar", "Ofbriechen"),
    "common.save": ("Save", "Sichern", "Enregistrer", "Guardar", "Späicheren"),
    "common.back": ("Back", "Zurück", "Retour", "Voltar", "Zréck"),
    "common.continue": ("Continue", "Weiter", "Continuer", "Continuar", "Weider"),
    "common.getStarted": ("Get Started", "Loslegen", "Commencer", "Começar", "Ufänken"),
    "common.add": ("Add", "Hinzufügen", "Ajouter", "Adicionar", "Derbäisetzen"),
    "common.edit": ("Edit", "Bearbeiten", "Modifier", "Editar", "Beaarbechten"),
    "common.delete": ("Delete", "Löschen", "Supprimer", "Eliminar", "Läschen"),
    "common.post": ("Post", "Veröffentlichen", "Publier", "Publicar", "Verëffentlechen"),
    "common.share": ("Share", "Teilen", "Partager", "Partilhar", "Deelen"),
    "common.seeAll": ("See All", "Alle anzeigen", "Tout voir", "Ver tudo", "Alles weisen"),
    "common.search": ("Search", "Suchen", "Rechercher", "Pesquisar", "Sichen"),
    "common.clearSearch": ("Clear search", "Suche löschen", "Effacer la recherche", "Limpar pesquisa", "Sich läschen"),
    "common.yes": ("Yes", "Ja", "Oui", "Sim", "Jo"),
    "common.no": ("No", "Nein", "Non", "Não", "Nee"),
    "common.ok": ("OK", "OK", "OK", "OK", "OK"),
    "common.error": ("Error", "Fehler", "Erreur", "Erro", "Feeler"),
    "common.loading": ("Loading…", "Laden…", "Chargement…", "A carregar…", "Lueden…"),
    "common.none": ("None", "Keine", "Aucun", "Nenhum", "Keen"),
    "common.version": ("Version", "Version", "Version", "Versão", "Versioun"),
    "common.age": ("Age %d", "Alter %d", "Âge %d", "Idade %d", "Alter %d"),
    "common.withToday": ("With %@ today", "Heute bei %@", "Avec %@ aujourd'hui", "Com %@ hoje", "Haut mat %@"),
    "common.child": ("Child", "Kind", "Enfant", "Criança", "Kand"),
    "common.you": ("You", "Sie", "Vous", "Você", "Dir"),

    # Language settings
    "language.title": ("Language", "Sprache", "Langue", "Idioma", "Sprooch"),
    "language.system": ("System Language", "Systemsprache", "Langue du système", "Idioma do sistema", "Systemsprooch"),
    "language.footer": ("Choose the language for all buttons, labels, and messages in Common Ground.", "Wählen Sie die Sprache für alle Schaltflächen, Beschriftungen und Nachrichten in Common Ground.", "Choisissez la langue de tous les boutons, libellés et messages dans Common Ground.", "Escolha o idioma de todos os botões, etiquetas e mensagens no Common Ground.", "Wielt d'Sprooch fir all Knäppercher, Beschriftungen a Messagen am Common Ground."),

    # Lock screen
    "lock.unlock": ("Unlock", "Entsperren", "Déverrouiller", "Desbloquear", "Entspären"),
    "lock.unlockFaceID": ("Unlock with Face ID", "Mit Face ID entsperren", "Déverrouiller avec Face ID", "Desbloquear com Face ID", "Mat Face ID entspären"),
    "lock.unlockTouchID": ("Unlock with Touch ID", "Mit Touch ID entsperren", "Déverrouiller avec Touch ID", "Desbloquear com Touch ID", "Mat Touch ID entspären"),
    "lock.now": ("Lock Now", "Jetzt sperren", "Verrouiller maintenant", "Bloquear agora", "Elo spären"),
    "lock.require": ("Require %@", "%@ erforderlich", "Exiger %@", "Exigir %@", "%@ erfuerderen"),
    "lock.method.faceID": ("Face ID", "Face ID", "Face ID", "Face ID", "Face ID"),
    "lock.method.touchID": ("Touch ID", "Touch ID", "Touch ID", "Touch ID", "Touch ID"),
    "lock.method.passcode": ("Passcode", "Code", "Code", "Código", "Code"),

    # Home
    "home.title": ("Home", "Start", "Accueil", "Início", "Doheem"),
    "home.greeting.morning": ("Good morning", "Guten Morgen", "Bonjour", "Bom dia", "Gudde Moien"),
    "home.greeting.afternoon": ("Good afternoon", "Guten Tag", "Bon après-midi", "Boa tarde", "Gudde Mëtteg"),
    "home.greeting.evening": ("Good evening", "Guten Abend", "Bonsoir", "Boa noite", "Gudden Owend"),
    "home.subtitle": ("Here's what's happening with your family today, %@.", "Das passiert heute in Ihrer Familie, %@.", "Voici ce qui se passe dans votre famille aujourd'hui, %@.", "Isto é o que acontece com a sua família hoje, %@.", "Sou ass et haut an ärer Famill ausgesäit, %@."),
    "home.quickActions": ("Quick actions", "Schnellaktionen", "Actions rapides", "Ações rápidas", "Séier Aktiounen"),
    "home.action.event": ("Event", "Termin", "Événement", "Evento", "Evenement"),
    "home.action.update": ("Update", "Update", "Mise à jour", "Atualização", "Mise à jour"),
    "home.action.expense": ("Expense", "Ausgabe", "Dépense", "Despesa", "Ausgab"),
    "home.action.message": ("Message", "Nachricht", "Message", "Mensagem", "Noriicht"),
    "home.action.askAI": ("Ask AI", "KI fragen", "Demander à l'IA", "Perguntar à IA", "KI froen"),
    "home.todaysUpdates": ("Today's Updates", "Heutige Updates", "Mises à jour du jour", "Atualizações de hoje", "Updates vun haut"),
    "home.noUpdates": ("No updates yet today", "Noch keine Updates heute", "Pas encore de mises à jour aujourd'hui", "Ainda sem atualizações hoje", "Nach keng Updates haut"),
    "home.shareWhatHappened": ("Share what happened", "Teilen, was passiert ist", "Partager ce qui s'est passé", "Partilhar o que aconteceu", "Deelen wat geschitt ass"),
    "home.updatePrompt.title": ("A calm check-in for your co-parent", "Ein ruhiger Check-in für Ihren Co-Elternteil", "Un point calme pour votre co-parent", "Um check-in tranquilo para o seu co-pai/mãe", "E rouegen Check-in fir ären Co-Elterendeel"),
    "home.updatePrompt.body": ("Share a short note about school, activities, or how the day went — no long chat required.", "Teilen Sie eine kurze Notiz über Schule, Aktivitäten oder den Tagesverlauf — kein langer Chat nötig.", "Partagez une courte note sur l'école, les activités ou la journée — pas besoin d'une longue conversation.", "Partilhe uma nota curta sobre a escola, atividades ou o dia — sem conversa longa.", "Deelt eng kuerz Notiz iwwer Schoul, Aktivitéiten oder de Dag — kee laangen Chat néideg."),
    "home.comingUp": ("Coming Up", "Demnächst", "À venir", "A seguir", "Geschitt"),
    "home.noUpcomingEvents": ("No upcoming events", "Keine anstehenden Termine", "Aucun événement à venir", "Sem eventos futuros", "Keng evenementer geschitt"),
    "home.needsAttention": ("Needs Attention", "Erfordert Aufmerksamkeit", "Nécessite une attention", "Precisa de atenção", "Brauch Opmierksamkeet"),
    "home.outstandingExpenses": ("Outstanding Expenses", "Offene Ausgaben", "Dépenses en attente", "Despesas pendentes", "Open Ausgaben"),
    "home.expensePending": ("$%@ pending reimbursement", "$%@ Erstattung ausstehend", "$%@ remboursement en attente", "$%@ reembolso pendente", "$%@ Remboursement ausstoend"),
    "home.activeMedications": ("Active Medications", "Aktive Medikamente", "Médicaments actifs", "Medicamentos ativos", "Aktiv Medikamenter"),
    "home.medicationCount": ("%d medication with reminders", "%d Medikament mit Erinnerungen", "%d médicament avec rappels", "%d medicamento com lembretes", "%d Medikament mat Erënnerungen"),
    "home.medicationsCount": ("%d medications with reminders", "%d Medikamente mit Erinnerungen", "%d médicaments avec rappels", "%d medicamentos com lembretes", "%d Medikamenter mat Erënnerungen"),
    "home.passportExpiring": ("Passport Expiring", "Reisepass läuft ab", "Passeport expirant", "Passaporte a expirar", "Pass laf of"),
    "home.passportRenew": ("Renew before %@", "Erneuern vor %@", "Renouveler avant %@", "Renovar antes de %@", "Erneieren virun %@"),
    "home.aiAssistant": ("AI Assistant", "KI-Assistent", "Assistant IA", "Assistente de IA", "KI-Assistent"),

    # Onboarding
    "onboarding.welcome": ("Welcome to\nCommon Ground", "Willkommen bei\nCommon Ground", "Bienvenue sur\nCommon Ground", "Bem-vindo ao\nCommon Ground", "Wëllkomm bei\nCommon Ground"),
    "onboarding.subtitle": ("The calm, shared home for raising your children across households.", "Das ruhige, gemeinsame Zuhause für die Erziehung Ihrer Kinder über Haushalte hinweg.", "Le foyer calme et partagé pour élever vos enfants entre foyers.", "O lar calmo e partilhado para criar os seus filhos entre lares.", "Den rouegen, gedeelten Doheem fir Är Kanner iwwer Haushalter ze erzéien."),
    "onboarding.trust.private.title": ("Private by design", "Privat by Design", "Privé par conception", "Privado por conceção", "Privat no Design"),
    "onboarding.trust.private.detail": ("Your family data stays on your devices.", "Ihre Familiendaten bleiben auf Ihren Geräten.", "Les données de votre famille restent sur vos appareils.", "Os dados da sua família ficam nos seus dispositivos.", "Är Familljendaten bleiwen op ären Apparater."),
    "onboarding.trust.coparent.title": ("Built for co-parents", "Für Co-Eltern gemacht", "Conçu pour les co-parents", "Feito para co-pais", "Fir Co-Elteren gebaut"),
    "onboarding.trust.coparent.detail": ("Daily updates, custody, and expenses in one place.", "Tägliche Updates, Sorgerecht und Ausgaben an einem Ort.", "Mises à jour quotidiennes, garde et dépenses en un seul endroit.", "Atualizações diárias, custódia e despesas num só lugar.", "Deeglech Updates, Sorgerecht an Ausgaben op enger Plaz."),
    "onboarding.createFamily": ("Create a Family", "Familie erstellen", "Créer une famille", "Criar uma família", "Eng Famill erstellen"),
    "onboarding.joinFamily": ("Join with Family Code", "Mit Familiencode beitreten", "Rejoindre avec le code famille", "Entrar com código da família", "Mat Familljencode bäitrieden"),
    "onboarding.aboutYou": ("About You", "Über Sie", "À propos de vous", "Sobre si", "Iwwer Iech"),
    "onboarding.aboutYou.footer": ("This is how you'll appear to your co-parent and family.", "So erscheinen Sie bei Ihrem Co-Elternteil und Ihrer Familie.", "C'est ainsi que vous apparaîtrez auprès de votre co-parent et de votre famille.", "É assim que aparecerá ao seu co-pai/mãe e à família.", "Sou erschéngt Dir bei ärem Co-Elterendeel an der Famill."),
    "onboarding.yourName": ("Your name", "Ihr Name", "Votre nom", "O seu nome", "Ären Numm"),
    "onboarding.family": ("Family", "Familie", "Famille", "Família", "Famill"),
    "onboarding.familyName": ("Family name (optional)", "Familienname (optional)", "Nom de famille (facultatif)", "Nome da família (opcional)", "Familljennumm (optional)"),
    "onboarding.coParentName": ("Co-parent name (optional)", "Name des Co-Elternteils (optional)", "Nom du co-parent (facultatif)", "Nome do co-pai/mãe (opcional)", "Numm vum Co-Elterendeel (optional)"),
    "onboarding.child": ("Child", "Kind", "Enfant", "Criança", "Kand"),
    "onboarding.firstName": ("First name", "Vorname", "Prénom", "Nome próprio", "Virnumm"),
    "onboarding.lastName": ("Last name", "Nachname", "Nom", "Apelido", "Familljennumm"),
    "onboarding.dateOfBirth": ("Date of birth", "Geburtsdatum", "Date de naissance", "Data de nascimento", "Gebuertsdatum"),
    "onboarding.exploreDemo": ("Explore with demo data", "Mit Demodaten erkunden", "Explorer avec des données de démo", "Explorar com dados de demonstração", "Mat Demodaten entdecken"),
    "onboarding.saveError": ("Couldn't save your family. Please try again.", "Familie konnte nicht gespeichert werden. Bitte erneut versuchen.", "Impossible d'enregistrer votre famille. Veuillez réessayer.", "Não foi possível guardar a sua família. Tente novamente.", "Famill konnt net gespäichert ginn. Probéiert w.e.g. nach eng Kéier."),

    # Children
    "children.title": ("Children", "Kinder", "Enfants", "Crianças", "Kanner"),
    "children.addFirst.title": ("Add Your First Child", "Erstes Kind hinzufügen", "Ajoutez votre premier enfant", "Adicione o seu primeiro filho", "Füügt äert éischt Kand derbäi"),
    "children.addFirst.message": ("Create a profile to track health, school, expenses, and milestones.", "Erstellen Sie ein Profil für Gesundheit, Schule, Ausgaben und Meilensteine.", "Créez un profil pour suivre la santé, l'école, les dépenses et les étapes.", "Crie um perfil para acompanhar saúde, escola, despesas e marcos.", "Erstellt e Profil fir Gesondheet, Schoul, Ausgaben a Meilesteng."),
    "children.addChild": ("Add Child", "Kind hinzufügen", "Ajouter un enfant", "Adicionar criança", "Kand derbäisetzen"),
    "children.born": ("Born %@", "Geboren %@", "Né(e) le %@", "Nascido(a) em %@", "Gebuer den %@"),
    "children.tapGenmoji": ("Tap to set Genmoji or photo", "Tippen für Genmoji oder Foto", "Appuyez pour définir un Genmoji ou une photo", "Toque para definir Genmoji ou foto", "Tippt fir Genmoji oder Foto"),
    "children.vitals": ("Vitals", "Vitaldaten", "Signes vitaux", "Dados vitais", "Vitaldaten"),
    "children.bloodType": ("Blood Type", "Blutgruppe", "Groupe sanguin", "Tipo sanguíneo", "Bluttgrupp"),
    "children.allergies": ("Allergies", "Allergien", "Allergies", "Alergias", "Allergien"),
    "children.clothing": ("Clothing", "Kleidung", "Vêtements", "Roupa", "Kleedung"),
    "children.shoes": ("Shoes", "Schuhe", "Chaussures", "Sapatos", "Schong"),
    "children.module.medical": ("Medical", "Medizinisch", "Médical", "Médico", "Medizinesch"),
    "children.module.school": ("School", "Schule", "École", "Escola", "Schoul"),
    "children.module.expenses": ("Expenses", "Ausgaben", "Dépenses", "Despesas", "Ausgaben"),
    "children.module.documents": ("Documents", "Dokumente", "Documents", "Documentos", "Dokumenter"),
    "children.module.timeline": ("Timeline", "Zeitleiste", "Chronologie", "Cronologia", "Zäitlinn"),
    "children.module.emergency": ("Emergency", "Notfall", "Urgence", "Emergência", "Noutfall"),

    # Avatar editor
    "avatar.title": ("Face", "Gesicht", "Visage", "Rosto", "Gesiicht"),
    "avatar.genmoji": ("Create or paste a Genmoji", "Genmoji erstellen oder einfügen", "Créer ou coller un Genmoji", "Criar ou colar um Genmoji", "Genmoji erstellen oder afügen"),
    "avatar.choosePhoto": ("Choose a photo", "Foto auswählen", "Choisir une photo", "Escolher uma foto", "Foto wielen"),
    "avatar.remove": ("Remove custom face", "Eigenes Gesicht entfernen", "Supprimer le visage personnalisé", "Remover rosto personalizado", "Eege Gesiicht ewechhuelen"),
    "avatar.pickEmoji": ("Or pick an emoji", "Oder Emoji wählen", "Ou choisir un emoji", "Ou escolher um emoji", "Oder en Emoji wielen"),
    "avatar.member.genmoji": ("Set Genmoji", "Genmoji festlegen", "Définir un Genmoji", "Definir Genmoji", "Genmoji setzen"),
    "avatar.member.hint": ("Use the emoji keyboard to create a Genmoji that looks like you.", "Verwenden Sie die Emoji-Tastatur, um ein Genmoji zu erstellen, das wie Sie aussieht.", "Utilisez le clavier emoji pour créer un Genmoji qui vous ressemble.", "Use o teclado de emojis para criar um Genmoji parecido consigo.", "Benotzt d'Emoji-Tastatur fir e Genmoji ze erstellen deen wie Dir ausgesäit."),
    "avatar.member.remove": ("Remove Genmoji", "Genmoji entfernen", "Supprimer le Genmoji", "Remover Genmoji", "Genmoji ewechhuelen"),
    "avatar.genmoji.sheet.title": ("Create a Genmoji", "Genmoji erstellen", "Créer un Genmoji", "Criar um Genmoji", "E Genmoji erstellen"),
    "avatar.genmoji.sheet.hint": ("Tap the field below, then use the emoji keyboard to create or paste your Genmoji face.", "Tippen Sie unten und verwenden Sie die Emoji-Tastatur, um Ihr Genmoji-Gesicht zu erstellen oder einzufügen.", "Appuyez ci-dessous, puis utilisez le clavier emoji pour créer ou coller votre visage Genmoji.", "Toque abaixo e use o teclado de emojis para criar ou colar o seu rosto Genmoji.", "Tippt hei drënner a benotzt d'Emoji-Tastatur fir äert Genmoji-Gesiicht ze erstellen oder anzeefügen."),
    "avatar.genmoji.clear": ("Clear", "Löschen", "Effacer", "Limpar", "Läschen"),

    # Daily updates
    "daily.title": ("Daily Update", "Tägliches Update", "Mise à jour quotidienne", "Atualização diária", "Deeglechen Update"),
    "daily.intro": ("Share what happened today so your co-parent stays informed — without a long chat.", "Teilen Sie, was heute passiert ist, damit Ihr Co-Elternteil informiert bleibt — ohne langen Chat.", "Partagez ce qui s'est passé aujourd'hui pour informer votre co-parent — sans longue conversation.", "Partilhe o que aconteceu hoje para manter o co-pai/mãe informado — sem conversa longa.", "Deelt wat haut geschitt ass fir ären Co-Elterendeel informéiert ze halen — ouni laangen Chat."),
    "daily.templates": ("Quick templates", "Schnellvorlagen", "Modèles rapides", "Modelos rápidos", "Séier Schablounen"),
    "daily.template": ("Template", "Vorlage", "Modèle", "Modelo", "Schabloun"),
    "daily.update": ("Update", "Update", "Mise à jour", "Atualização", "Mise à jour"),
    "daily.headline": ("Headline", "Überschrift", "Titre", "Título", "Iwwerschrëft"),
    "daily.details": ("Details (optional)", "Details (optional)", "Détails (facultatif)", "Detalhes (opcional)", "Detailer (optional)"),
    "daily.saveError": ("Couldn't save update. Please try again.", "Update konnte nicht gespeichert werden. Bitte erneut versuchen.", "Impossible d'enregistrer la mise à jour. Veuillez réessayer.", "Não foi possível guardar a atualização. Tente novamente.", "Update konnt net gespäichert ginn. Probéiert w.e.g. nach eng Kéier."),
    "daily.preset.general": ("General update", "Allgemeines Update", "Mise à jour générale", "Atualização geral", "Allgemengen Update"),
    "daily.preset.school": ("School day", "Schultag", "Journée d'école", "Dia de escola", "Schouldag"),
    "daily.preset.activity": ("Activity / sport", "Aktivität / Sport", "Activité / sport", "Atividade / desporto", "Aktivitéit / Sport"),
    "daily.preset.absence": ("Couldn't attend", "Konnte nicht teilnehmen", "N'a pas pu assister", "Não pôde comparecer", "Konnt net deelhuelen"),
    "daily.preset.handoff": ("Handoff note", "Übergabenotiz", "Note de transfert", "Nota de entrega", "Iwwergabnotiz"),

    # Calendar
    "calendar.title": ("Calendar", "Kalender", "Calendrier", "Calendário", "Kalenner"),
    "calendar.month": ("Month", "Monat", "Mois", "Mês", "Mount"),
    "calendar.day": ("Day", "Tag", "Jour", "Dia", "Dag"),
    "calendar.custody": ("Custody", "Sorgerecht", "Garde", "Custódia", "Sorgerecht"),
    "calendar.empty.title": ("No events yet", "Noch keine Termine", "Pas encore d'événements", "Ainda sem eventos", "Nach keng Evenementer"),
    "calendar.empty.message": ("Tap + to add a school event, appointment, or custody exchange.", "Tippen Sie +, um einen Schultermin, eine Verabredung oder einen Sorgerechtswechsel hinzuzufügen.", "Appuyez sur + pour ajouter un événement scolaire, un rendez-vous ou un échange de garde.", "Toque em + para adicionar um evento escolar, consulta ou troca de custódia.", "Tippt + fir e Schoulevenement, e Rendez-vous oder eng Sorgerechtsiwwergab derbäizesetzen."),
    "calendar.addEvent": ("Add Event", "Termin hinzufügen", "Ajouter un événement", "Adicionar evento", "Evenement derbäisetzen"),
    "calendar.eventTitle": ("Title", "Titel", "Titre", "Título", "Titel"),
    "calendar.start": ("Start", "Beginn", "Début", "Início", "Ufank"),
    "calendar.end": ("End", "Ende", "Fin", "Fim", "Enn"),
    "calendar.allDay": ("All day", "Ganztägig", "Toute la journée", "Dia inteiro", "Ganzen Dag"),
    "calendar.category": ("Category", "Kategorie", "Catégorie", "Categoria", "Kategorie"),
    "calendar.location": ("Location", "Ort", "Lieu", "Local", "Plaz"),
    "calendar.details": ("Details", "Details", "Détails", "Detalhes", "Detailer"),
    "calendar.reminder": ("Reminder", "Erinnerung", "Rappel", "Lembrete", "Erënnerung"),
    "calendar.noCustodySchedule": ("No custody schedule yet", "Noch kein Sorgerechtsplan", "Pas encore de planning de garde", "Ainda sem calendário de custódia", "Nach kee Sorgerechtsplang"),
    "calendar.setupSchedule": ("Set Up Schedule", "Plan einrichten", "Configurer le planning", "Configurar calendário", "Plang ariichten"),
    "calendar.updateSchedule": ("Update Schedule", "Plan aktualisieren", "Mettre à jour le planning", "Atualizar calendário", "Plang aktualiséieren"),
    "calendar.nextExchange": ("Next exchange: %@", "Nächster Wechsel: %@", "Prochain échange : %@", "Próxima troca: %@", "Nächst Iwwergab: %@"),
    "calendar.scheduleChanges": ("Schedule changes", "Planänderungen", "Modifications du planning", "Alterações de calendário", "Plangännerungen"),
    "calendar.scheduleChanges.note": ("Creating a new schedule replaces generated custody blocks for the next 12 weeks. Manual events are kept.", "Ein neuer Plan ersetzt generierte Sorgerechtsblöcke für die nächsten 12 Wochen. Manuelle Termine bleiben erhalten.", "Un nouveau planning remplace les blocs de garde générés pour les 12 prochaines semaines. Les événements manuels sont conservés.", "Um novo calendário substitui os blocos de custódia gerados nas próximas 12 semanas. Eventos manuais são mantidos.", "En neien Plang ersetzt generéiert Sorgerechtsbléck fir déi nächst 12 Wochen. Manuell Evenementer bleiwen."),

    # Calendar sync & export
    "calendarSync.title": ("Apple Calendar", "Apple Kalender", "Calendrier Apple", "Calendário Apple", "Apple Kalenner"),
    "calendarSync.intro": ("Keep custody schedules in sync with Apple Calendar. Common Ground can export your events and import new ones from your other calendars.", "Halten Sie Sorgerechtspläne mit dem Apple Kalender synchron. Common Ground kann Ihre Termine exportieren und neue aus anderen Kalendern importieren.", "Gardez les plannings de garde synchronisés avec le Calendrier Apple. Common Ground peut exporter vos événements et en importer de nouveaux depuis vos autres calendriers.", "Mantenha os calendários de custódia sincronizados com o Calendário Apple. O Common Ground pode exportar os seus eventos e importar novos dos seus outros calendários.", "Hält Sorgerechtspläng mat dem Apple Kalenner synchron. Common Ground kann Är Evenementer exportéieren an nei aus anere Kalenneren importéieren."),
    "calendarSync.settings": ("Sync Settings", "Sync-Einstellungen", "Paramètres de synchronisation", "Definições de sincronização", "Sync-Astellungen"),
    "calendarSync.autoSync": ("Auto-sync on launch", "Beim Start automatisch synchronisieren", "Synchronisation automatique au lancement", "Sincronizar automaticamente ao abrir", "Beim Start automatesch synchroniséieren"),
    "calendarSync.exportAll": ("Export all events", "Alle Termine exportieren", "Exporter tous les événements", "Exportar todos os eventos", "All Evenementer exportéieren"),
    "calendarSync.exportAll.hint": ("When off, only custody and exchange events are exported.", "Wenn aus, werden nur Sorgerechts- und Übergabetermine exportiert.", "Si désactivé, seuls les événements de garde et d'échange sont exportés.", "Se desativado, apenas eventos de custódia e troca são exportados.", "Wann aus, ginn nëmmen Sorgerechts- an Iwwergab-Evenementer exportéiert."),
    "calendarSync.importAssign": ("Import assign to", "Import zuweisen an", "Attribuer l'import à", "Atribuir importação a", "Import zouweisen un"),
    "calendarSync.noChild": ("No specific child", "Kein bestimmtes Kind", "Aucun enfant spécifique", "Nenhuma criança específica", "Keent bestëmmt Kand"),
    "calendarSync.syncWindow": ("Sync window: %d days", "Sync-Fenster: %d Tage", "Fenêtre de sync : %d jours", "Janela de sincronização: %d dias", "Sync-Fënster: %d Deeg"),
    "calendarSync.syncNow": ("Sync Now", "Jetzt synchronisieren", "Synchroniser maintenant", "Sincronizar agora", "Elo synchroniséieren"),
    "calendarSync.lastSync": ("Last Sync", "Letzte Synchronisation", "Dernière synchronisation", "Última sincronização", "Lescht Synchronisatioun"),
    "calendarSync.exported": ("Exported", "Exportiert", "Exportés", "Exportados", "Exportéiert"),
    "calendarSync.updated": ("Updated", "Aktualisiert", "Mis à jour", "Atualizados", "Aktualiséiert"),
    "calendarSync.imported": ("Imported", "Importiert", "Importés", "Importados", "Importéiert"),
    "calendarSync.time": ("Time", "Zeit", "Heure", "Hora", "Zäit"),
    "calendarSync.accessDenied": ("Calendar access was denied. Enable it in Settings → Common Ground → Calendars.", "Kalenderzugriff wurde verweigert. Aktivieren Sie ihn unter Einstellungen → Common Ground → Kalender.", "L'accès au calendrier a été refusé. Activez-le dans Réglages → Common Ground → Calendriers.", "O acesso ao calendário foi negado. Ative-o em Definições → Common Ground → Calendários.", "Kalennerzougang gouf refuséiert. Aktivéiert en an den Astellungen → Common Ground → Kalenneren."),
    "calendarSync.export.title": ("Export to Calendar", "In Kalender exportieren", "Exporter vers le calendrier", "Exportar para calendário", "An de Kalenner exportéieren"),
    "calendarSync.export.destination": ("Export destination", "Exportziel", "Destination d'export", "Destino da exportação", "Exportzil"),
    "calendarSync.export.dedicated": ("Common Ground calendar", "Common Ground Kalender", "Calendrier Common Ground", "Calendário Common Ground", "Common Ground Kalenner"),
    "calendarSync.export.existing": ("Existing calendar", "Bestehender Kalender", "Calendrier existant", "Calendário existente", "Bestehende Kalenner"),
    "calendarSync.export.choose": ("Choose calendar", "Kalender wählen", "Choisir un calendrier", "Escolher calendário", "Kalenner wielen"),
    "calendarSync.export.now": ("Export Now", "Jetzt exportieren", "Exporter maintenant", "Exportar agora", "Elo exportéieren"),
    "calendarSync.export.hint": ("Export custody and family events into an existing Apple calendar you already use.", "Exportieren Sie Sorgerechts- und Familientermine in einen bestehenden Apple Kalender.", "Exportez les événements de garde et familiaux vers un calendrier Apple existant.", "Exporte eventos de custódia e família para um calendário Apple existente.", "Exportéiert Sorgerechts- a Familljeevenementer an en existente Apple Kalenner."),
    "calendarSync.import.title": ("Import from Calendar", "Aus Kalender importieren", "Importer depuis le calendrier", "Importar do calendário", "Aus dem Kalenner importéieren"),
    "calendarSync.import.now": ("Import Now", "Jetzt importieren", "Importer maintenant", "Importar agora", "Elo importéieren"),
    "calendarSync.noCalendars": ("No writable calendars found. Add a calendar account in Settings.", "Keine beschreibbaren Kalender gefunden. Fügen Sie ein Kalenderkonto in den Einstellungen hinzu.", "Aucun calendrier accessible en écriture. Ajoutez un compte calendrier dans les Réglages.", "Nenhum calendário gravável encontrado. Adicione uma conta de calendário nas Definições.", "Keng beschreifbar Kalenneren fonnt. Füügt e Kalennerkont an den Astellungen derbäi."),

    # More
    "more.title": ("More", "Mehr", "Plus", "Mais", "Méi"),
    "more.familyTools": ("Family Tools", "Familienwerkzeuge", "Outils familiaux", "Ferramentas familiares", "Familljetools"),
    "more.addExpense": ("Add Expense", "Ausgabe hinzufügen", "Ajouter une dépense", "Adicionar despesa", "Ausgab derbäisetzen"),
    "more.addCoParent": ("Add Co-Parent", "Co-Elternteil hinzufügen", "Ajouter un co-parent", "Adicionar co-pai/mãe", "Co-Elterendeel derbäisetzen"),
    "more.checklists": ("Checklists", "Checklisten", "Listes de contrôle", "Listas de verificação", "Checklisten"),
    "more.auditLog": ("Audit Log", "Audit-Protokoll", "Journal d'audit", "Registo de auditoria", "Audit-Log"),
    "more.courtExport": ("Court Export", "Gerichtsexport", "Export judiciaire", "Exportação judicial", "Gerichtsexport"),
    "more.custodyAgreements": ("Custody Agreements", "Sorgerechtsvereinbarungen", "Accords de garde", "Acordos de custódia", "Sorgerechtsaccorden"),
    "more.professionalAccess": ("Professional Access", "Professioneller Zugang", "Accès professionnel", "Acesso profissional", "Professionellen Zougang"),
    "more.professionalPortal": ("Professional Portal", "Professionelles Portal", "Portail professionnel", "Portal profissional", "Professionellt Portal"),
    "more.professional.hint": ("Add an attorney or GAL as a family member with the Professional role for read-only access.", "Fügen Sie einen Anwalt oder GAL als Familienmitglied mit der Rolle Professional für Nur-Lese-Zugriff hinzu.", "Ajoutez un avocat ou un GAL comme membre de la famille avec le rôle Professionnel en lecture seule.", "Adicione um advogado ou GAL como membro da família com a função Profissional para acesso só de leitura.", "Füügt en Affekot oder GAL als Familljemember mat der Roll Professionell fir Lies-Zougang derbäi."),
    "more.integrations": ("Integrations", "Integrationen", "Intégrations", "Integrações", "Integratiounen"),
    "more.appleCalendar": ("Apple Calendar Sync", "Apple Kalender Sync", "Sync Calendrier Apple", "Sincronização Calendário Apple", "Apple Kalenner Sync"),
    "more.inviteCoParent": ("Invite Co-Parent", "Co-Elternteil einladen", "Inviter le co-parent", "Convidar co-pai/mãe", "Co-Elterendeel invitéieren"),
    "more.joinFamily": ("Join Family", "Familie beitreten", "Rejoindre la famille", "Entrar na família", "Famill bäitrieden"),
    "more.iCloudSync": ("iCloud Sync", "iCloud Sync", "Sync iCloud", "Sincronização iCloud", "iCloud Sync"),
    "more.appleHealth": ("Apple Health", "Apple Health", "Apple Santé", "Apple Saúde", "Apple Health"),
    "more.schoolPortal": ("School Portal", "Schulportal", "Portail scolaire", "Portal escolar", "Schoulportal"),
    "more.privacySecurity": ("Privacy & Security", "Datenschutz & Sicherheit", "Confidentialité et sécurité", "Privacidade e segurança", "Dateschutz & Sécherheet"),
    "more.reminders": ("Reminders", "Erinnerungen", "Rappels", "Lembretes", "Erënnerungen"),
    "more.permissions": ("Permissions", "Berechtigungen", "Autorisations", "Permissões", "Berechtegungen"),
    "more.lockOn.footer": ("You'll be asked to unlock when opening the app and after tapping Lock Now.", "Sie werden beim Öffnen der App und nach Tippen auf Jetzt sperren aufgefordert, zu entsperren.", "Vous devrez déverrouiller à l'ouverture de l'app et après avoir appuyé sur Verrouiller maintenant.", "Será solicitado a desbloquear ao abrir a app e após tocar em Bloquear agora.", "Dir gitt beim Oppen vun der App an nom Tippe op Elo spären opgefuerdert ze entspären."),
    "more.lockOff.footer": ("Lock is off. Turn this on to require %@ before viewing family data.", "Sperre ist aus. Aktivieren Sie sie, um %@ vor dem Anzeigen von Familiendaten zu verlangen.", "Le verrouillage est désactivé. Activez-le pour exiger %@ avant d'afficher les données familiales.", "O bloqueio está desativado. Ative-o para exigir %@ antes de ver dados familiares.", "Spär ass aus. Aktivéiert en fir %@ ze verlaangen ier Dir Familljedaten gesitt."),
    "more.remindersOn.footer": ("Reminders are scheduled for custody exchanges and medications.", "Erinnerungen sind für Sorgerechtswechsel und Medikamente geplant.", "Des rappels sont programmés pour les échanges de garde et les médicaments.", "Lembretes estão agendados para trocas de custódia e medicamentos.", "Erënnerungen sinn fir Sorgerechtsiwwergaben a Medikamenter geplangt."),
    "more.remindersOff.footer": ("Enable reminders for custody exchanges and medications.", "Aktivieren Sie Erinnerungen für Sorgerechtswechsel und Medikamente.", "Activez les rappels pour les échanges de garde et les médicaments.", "Ative lembretes para trocas de custódia e medicamentos.", "Aktivéiert Erënnerungen fir Sorgerechtsiwwergaben a Medikamenter."),
    "more.about": ("About", "Über", "À propos", "Sobre", "Iwwer"),
    "more.sync": ("Sync", "Synchronisierung", "Synchronisation", "Sincronização", "Synchronisatioun"),
    "more.sync.local": ("Local", "Lokal", "Local", "Local", "Lokal"),
    "more.sync.iCloud": ("iCloud", "iCloud", "iCloud", "iCloud", "iCloud"),
    "more.checklists.complete": ("%d of %d complete", "%d von %d erledigt", "%d sur %d terminés", "%d de %d concluídos", "%d vu(n) %d fäerdeg"),

    # Permissions
    "permissions.title": ("Permissions", "Berechtigungen", "Autorisations", "Permissões", "Berechtegungen"),
    "permissions.members": ("Family members", "Familienmitglieder", "Membres de la famille", "Membros da família", "Familljemembere"),
    "permissions.members.empty": ("Add family members from Family Tools.", "Fügen Sie Familienmitglieder über Familienwerkzeuge hinzu.", "Ajoutez des membres depuis Outils familiaux.", "Adicione membros em Ferramentas familiares.", "Füügt Familljemembere iwwer Familljetools derbäi."),
    "permissions.defaultRoles": ("Default roles", "Standardrollen", "Rôles par défaut", "Funções predefinidas", "Standardrollen"),
    "permissions.role.parent": ("Parent", "Elternteil", "Parent", "Pai/Mãe", "Elterendeel"),
    "permissions.role.parent.access": ("Full view & edit", "Voller Zugriff & Bearbeitung", "Vue et modification complètes", "Visualização e edição completas", "Voll Zougang & Beaarbechtung"),
    "permissions.role.grandparent": ("Grandparent", "Großelternteil", "Grand-parent", "Avô/Avó", "Grousselterendeel"),
    "permissions.role.grandparent.access": ("Calendar, timeline, school — view only", "Kalender, Zeitleiste, Schule — nur ansehen", "Calendrier, chronologie, école — lecture seule", "Calendário, cronologia, escola — só visualização", "Kalenner, Zäitlinn, Schoul — nëmmen kucken"),
    "permissions.role.professional": ("Professional", "Professionell", "Professionnel", "Profissional", "Professionell"),
    "permissions.role.professional.access": ("Read-only court export", "Gerichtsexport nur lesen", "Export judiciaire en lecture seule", "Exportação judicial só de leitura", "Gerichtsexport nëmmen liesen"),
    "permissions.genmoji": ("Genmoji", "Genmoji", "Genmoji", "Genmoji", "Genmoji"),
    "permissions.whatTheySee": ("What they can see", "Was sie sehen können", "Ce qu'ils peuvent voir", "O que podem ver", "Wat si gesinn kënnen"),
    "permissions.whatTheyChange": ("What they can change", "Was sie ändern können", "Ce qu'ils peuvent modifier", "O que podem alterar", "Wat si änneren kënnen"),
    "permissions.editCalendar": ("Edit calendar", "Kalender bearbeiten", "Modifier le calendrier", "Editar calendário", "Kalenner beaarbechten"),
    "permissions.addExpenses": ("Add expenses", "Ausgaben hinzufügen", "Ajouter des dépenses", "Adicionar despesas", "Ausgaben derbäisetzen"),
    "permissions.editMedical": ("Edit medical", "Medizinisch bearbeiten", "Modifier le médical", "Editar médico", "Medizinesch beaarbechten"),
    "permissions.sendMessages": ("Send messages", "Nachrichten senden", "Envoyer des messages", "Enviar mensagens", "Noriichten schécken"),
    "permissions.courtExport": ("Court export", "Gerichtsexport", "Export judiciaire", "Exportação judicial", "Gerichtsexport"),
    "permissions.resetDefaults": ("Reset to %@ defaults", "Auf %@-Standard zurücksetzen", "Réinitialiser aux valeurs %@ par défaut", "Repor para predefinições de %@", "Op %@-Standard zrécksetzen"),
    "permissions.saved": ("Permissions saved", "Berechtigungen gespeichert", "Autorisations enregistrées", "Permissões guardadas", "Berechtegungen gespäichert"),

    # Member roles
    "role.parent": ("Parent", "Elternteil", "Parent", "Pai/Mãe", "Elterendeel"),
    "role.stepParent": ("Step Parent", "Stiefelternteil", "Beau-parent", "Padrasto/Madrasta", "Stiefelterendeel"),
    "role.grandparent": ("Grandparent", "Großelternteil", "Grand-parent", "Avô/Avó", "Grousselterendeel"),
    "role.guardian": ("Guardian", "Vormund", "Tuteur", "Tutor", "Virmond"),
    "role.fosterParent": ("Foster Parent", "Pflegeelternteil", "Parent d'accueil", "Pai/Mãe de acolhimento", "Pleegelterendeel"),
    "role.caregiver": ("Caregiver", "Betreuer", "Aidant", "Cuidador", "Betreier"),
    "role.professional": ("Professional", "Professionell", "Professionnel", "Profissional", "Professionell"),

    # Event categories
    "event.custody": ("Custody", "Sorgerecht", "Garde", "Custódia", "Sorgerecht"),
    "event.school": ("School", "Schule", "École", "Escola", "Schoul"),
    "event.medical": ("Medical", "Medizinisch", "Médical", "Médico", "Medizinesch"),
    "event.sports": ("Sports", "Sport", "Sports", "Desporto", "Sport"),
    "event.activities": ("Activities", "Aktivitäten", "Activités", "Atividades", "Aktivitéiten"),
    "event.birthday": ("Birthday", "Geburtstag", "Anniversaire", "Aniversário", "Gebuertsdag"),
    "event.holiday": ("Holiday", "Feiertag", "Vacances", "Feriado", "Feierdag"),
    "event.appointment": ("Appointment", "Termin", "Rendez-vous", "Consulta", "Rendez-vous"),
    "event.exchange": ("Exchange", "Übergabe", "Échange", "Troca", "Iwwergab"),
    "event.other": ("Other", "Sonstiges", "Autre", "Outro", "Aneres"),

    # Custody patterns
    "custody.weekOnWeekOff": ("Week On / Week Off", "Woche an / Woche aus", "Semaine chez l'un / semaine chez l'autre", "Semana sim / semana não", "Woch un / Woch aus"),
    "custody.twoTwoThree": ("2-2-3 Schedule", "2-2-3 Plan", "Planning 2-2-3", "Calendário 2-2-3", "2-2-3 Plang"),
    "custody.alternatingWeekends": ("Alternating Weekends", "Wechselnde Wochenenden", "Week-ends alternés", "Fins de semana alternados", "Wiesselnd Weekender"),
    "custody.custom": ("Custom", "Benutzerdefiniert", "Personnalisé", "Personalizado", "Personaliséiert"),
    "custody.withParent": ("With %@", "Bei %@", "Avec %@", "Com %@", "Mat %@"),
    "custody.exchange": ("Custody Exchange", "Sorgerechtsübergabe", "Échange de garde", "Troca de custódia", "Sorgerechtsiwwergab"),
    "custody.weekLabel": ("Custody schedule this week", "Sorgerechtsplan diese Woche", "Planning de garde cette semaine", "Calendário de custódia esta semana", "Sorgerechtsplang dës Woch"),

    # Timeline categories
    "timeline.dailyUpdate": ("Daily Update", "Tägliches Update", "Mise à jour quotidienne", "Atualização diária", "Deeglechen Update"),
    "timeline.milestone": ("Milestone", "Meilenstein", "Étape", "Marco", "Meilesteen"),
    "timeline.medical": ("Medical", "Medizinisch", "Médical", "Médico", "Medizinesch"),
    "timeline.school": ("School", "Schule", "École", "Escola", "Schoul"),
    "timeline.achievement": ("Achievement", "Erfolg", "Réussite", "Conquista", "Erfolleg"),
    "timeline.trip": ("Trip", "Reise", "Voyage", "Viagem", "Rees"),
    "timeline.birthday": ("Birthday", "Geburtstag", "Anniversaire", "Aniversário", "Gebuertsdag"),
    "timeline.first": ("First", "Erstes Mal", "Première fois", "Primeira vez", "Éischte Kéier"),
    "timeline.other": ("Other", "Sonstiges", "Autre", "Outro", "Aneres"),

    # Expense categories
    "expense.medical": ("Medical", "Medizinisch", "Médical", "Médico", "Medizinesch"),
    "expense.education": ("Education", "Bildung", "Éducation", "Educação", "Bildung"),
    "expense.clothing": ("Clothing", "Kleidung", "Vêtements", "Roupa", "Kleedung"),
    "expense.activities": ("Activities", "Aktivitäten", "Activités", "Atividades", "Aktivitéiten"),
    "expense.childcare": ("Childcare", "Kinderbetreuung", "Garde d'enfants", "Cuidados infantis", "Kannerbetreiung"),
    "expense.transport": ("Transport", "Transport", "Transport", "Transporte", "Transport"),
    "expense.food": ("Food", "Essen", "Alimentation", "Alimentação", "Iessen"),
    "expense.other": ("Other", "Sonstiges", "Autre", "Outro", "Aneres"),

    # Messages
    "messages.title": ("Messages", "Nachrichten", "Messages", "Mensagens", "Noriichten"),
    "messages.empty": ("No messages yet", "Noch keine Nachrichten", "Pas encore de messages", "Ainda sem mensagens", "Nach keng Noriichten"),
    "messages.placeholder": ("Message", "Nachricht", "Message", "Mensagem", "Noriicht"),
    "messages.send": ("Send", "Senden", "Envoyer", "Enviar", "Schécken"),

    # Errors
    "error.calendar.noSource": ("No calendar account is available. Add an iCloud or local calendar in Settings.", "Kein Kalenderkonto verfügbar. Fügen Sie einen iCloud- oder lokalen Kalender in den Einstellungen hinzu.", "Aucun compte calendrier disponible. Ajoutez un calendrier iCloud ou local dans les Réglages.", "Nenhuma conta de calendário disponível. Adicione um calendário iCloud ou local nas Definições.", "Keen Kalennerkont disponibel. Füügt en iCloud- oder lokalen Kalenner an den Astellungen derbäi."),
    "error.calendar.notFound": ("The selected calendar could not be found.", "Der ausgewählte Kalender wurde nicht gefunden.", "Le calendrier sélectionné est introuvable.", "O calendário selecionado não foi encontrado.", "Den gewielte Kalenner gouf net fonnt."),

    # Notifications
    "notification.exchange.title": ("Custody Exchange Today", "Sorgerechtsübergabe heute", "Échange de garde aujourd'hui", "Troca de custódia hoje", "Sorgerechtsiwwergab haut"),
    "notification.medication.title": ("Medication Reminder", "Medikamentenerinnerung", "Rappel de médicament", "Lembrete de medicamento", "Medikamentenerënnerung"),

    # Progress / accessibility
    "a11y.progress": ("Progress", "Fortschritt", "Progression", "Progresso", "Fortschrëtt"),
    "a11y.custodyWeek": ("Custody schedule this week", "Sorgerechtsplan diese Woche", "Planning de garde cette semaine", "Calendário de custódia esta semana", "Sorgerechtsplang dës Woch"),
}

from l10n_extensions import NEW_STRINGS
STRINGS.update(NEW_STRINGS)

def swift_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")

def key_to_property(key: str) -> str:
    parts = key.split(".")
    head = parts[0]
    tail = "".join(
        "".join(word[:1].upper() + word[1:] for word in part.split("_"))
        for part in parts[1:]
    )
    return head + tail

def main():
    root = Path(__file__).resolve().parents[1]
    catalog_json = {
        key: {"en": en, "de": de, "fr": fr, "pt": pt, "lb": lb}
        for key, (en, de, fr, pt, lb) in sorted(STRINGS.items())
    }

    json_out = root / "Packages/CommonGroundCore/Sources/Localization/L10nCatalog.json"
    json_out.write_text(
        json.dumps(catalog_json, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(STRINGS)} keys to {json_out}")

    catalog_swift = """// Generated by scripts/generate-l10n-catalog.py — do not edit by hand.
import Foundation

enum L10nCatalog {
    private static let table: [String: [String: String]] = loadTable()

    private static func loadTable() -> [String: [String: String]] {
        guard let url = Bundle.module.url(forResource: "L10nCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: data)
        else {
            assertionFailure("Missing L10nCatalog.json in CommonGroundCore bundle")
            return [:]
        }
        return decoded
    }

    static func translation(for key: String, language: AppLanguage) -> String? {
        guard language != .system, let row = table[key] else { return nil }
        return row[language.rawValue] ?? row["en"]
    }
}
"""
    catalog_out = root / "Packages/CommonGroundCore/Sources/Localization/L10nCatalog.swift"
    catalog_out.write_text(catalog_swift, encoding="utf-8")
    print(f"Wrote loader to {catalog_out}")

    l10n_lines = [
        "// Generated by scripts/generate-l10n-catalog.py",
        "import Foundation",
        "",
        "public enum L10n {",
        "    private static var activeLanguage: AppLanguage { AppLanguagePreferences.storedLanguage }",
        "",
        "    private static var activeLocale: Locale {",
        "        activeLanguage.locale ?? Locale.current",
        "    }",
        "",
        "    private static func tr(_ key: String) -> String {",
        "        if let value = L10nCatalog.translation(for: key, language: activeLanguage) {",
        "            return value",
        "        }",
        "        if let english = L10nCatalog.translation(for: key, language: .english) {",
        "            return english",
        "        }",
        "        return key",
        "    }",
        "",
        "    public static func format(_ key: String, _ args: CVarArg...) -> String {",
        "        let template = tr(key)",
        "        return String(format: template, locale: activeLocale, arguments: args)",
        "    }",
    ]
    for key in sorted(STRINGS):
        prop = key_to_property(key)
        l10n_lines.append(f"    public static var {prop}: String {{ tr(\"{swift_escape(key)}\") }}")
    l10n_lines.append("}")
    l10n_lines.append("")

    l10n_out = root / "Packages/CommonGroundCore/Sources/Localization/L10n.swift"
    l10n_out.write_text("\n".join(l10n_lines), encoding="utf-8")
    print(f"Wrote {len(STRINGS)} properties to {l10n_out}")

if __name__ == "__main__":
    main()
