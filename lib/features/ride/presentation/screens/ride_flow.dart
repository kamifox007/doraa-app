// import 'package:flutter/foundation.dart'; // removed for linter
import 'package:doraa/core/utils/file_utils.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:doraa/services/translation_service.dart';
import 'package:doraa/services/wallet_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:doraa/models/ride_models.dart';
import 'package:doraa/services/ride_service.dart';
import 'package:doraa/services/routing_service.dart';
import 'package:doraa/services/location_service.dart';
import 'package:doraa/services/ai_service.dart';
import 'package:doraa/services/rating_service.dart' as rating_svc;
import 'package:doraa/models/rating_model.dart' as rating_mod;
import 'package:doraa/providers/auth_providers.dart';
import 'package:doraa/features/profile/presentation/screens/profile_screen.dart';
import 'package:doraa/features/subscription/presentation/screens/subscription_screen.dart';
import 'package:doraa/features/support/presentation/screens/support_screen.dart';
import 'package:doraa/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:doraa/features/legal/widgets/evidence_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:doraa/features/auth/presentation/screens/driver_registration_screen.dart';

// Extracted Widgets
import 'package:doraa/features/ride/presentation/widgets/animated_waiting_rider.dart';
import 'package:doraa/features/ride/presentation/widgets/free_map_preview.dart';

part '../widgets/ride_flow_steps.dart';

class MockVehicle {
  LatLng position;
  double heading;
  double speed;
  int remainingTicks;
  MockVehicle(this.position, this.heading, this.speed, this.remainingTicks);
}

class MockRider {
  LatLng position;
  int remainingTicks;
  MockRider(this.position, this.remainingTicks);
}

// AnimatedWaitingRider and FreeMapPreview have been extracted.

enum RideFlowStep {
  home,
  pickup,
  dropoff,
  fare,
  drivers,
  negotiation,
  activeRide,
  payment,
  rating,
  receipt,
  history,
  driverRequests,
  earnings
}

class RideFlowScreen extends ConsumerStatefulWidget {
  const RideFlowScreen({super.key});

  @override
  ConsumerState<RideFlowScreen> createState() => _RideFlowScreenState();
}

class _RideFlowScreenState extends ConsumerState<RideFlowScreen> with TickerProviderStateMixin {
  final RideService _rideService = RideService();
  final LocationTrackingService _trackingService = LocationTrackingService();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();

  RideFlowStep _step = RideFlowStep.home;
  String pickupAddress = 'Ø§Ø®ØªØ± Ù†Ù‚Ø·Ø© Ø§Ù„Ø§Ù†Ø·Ù„Ø§Ù‚';
  String dropoffAddress = 'Ø§Ù„ÙˆØ¬Ù‡Ø©';
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  List<LatLng>? _routePolyline;
  
  // Unified flow state
  bool isSelectingDropoff = false;
  String? _selectedRideType;
  final Map<String, double> _driverCounterOffers = {}; // To store local counter offers for each request
  Timer? _debounceTimer;
  bool _isSearchingForDriver = false;
  AnimationController? _searchingAnimController;
  Animation<double>? _pulseAnimation;
  double distanceKm = 8;
  int durationMinutes = 15;
  double proposedFare = 450;
  double customFare = 450;
  String status = 'searching';
  String selectedDriverName = 'Ø³Ø§Ø±Ø©';
  List<RideOffer> driverOffers = [];
  RideOffer? selectedDriver;
  List<RideRequest> pendingRequests = [];
  RideRequest? selectedRequest;
  String? currentRideId;
  String currentRideDate = '';
  String historyFilter = 'all';
  Map<String, dynamic>? selectedHistoryRide;
  final List<Map<String, dynamic>> driverRideHistory = [
    {'date': '22 ÙŠÙˆÙ„ÙŠÙˆ', 'route': 'Ø§Ù„Ù…Ø·Ø§Ø± â†’ Ø§Ù„Ù…Ø¯ÙŠÙ†Ø©', 'fare': 550, 'commission': 83, 'net': 467, 'status': 'Ù…ÙƒØªÙ…Ù„'},
    {'date': '20 ÙŠÙˆÙ„ÙŠÙˆ', 'route': 'Ø§Ù„Ø¬Ø§Ù…Ø¹Ø© â†’ Ø§Ù„Ù…Ù†Ø²Ù„', 'fare': 320, 'commission': 48, 'net': 272, 'status': 'Ù…ÙƒØªÙ…Ù„'},
  ];
  final List<String> negotiationHistory = [];
  bool isLoadingLocation = false;
  bool isSubmitting = false;
  bool sosExpanded = false;
  bool isDriverMode = false;
  bool isDriverOnline = false;
  Timer? _autoOfflineTimer;
  bool paymentConfirmed = false;
  int rating = 5;
  String ratingComment = '';
  String shareMessage = '';
  bool showSafetyActions = false;
  final List<String> quickTags = ['Ù„Ø·ÙŠÙØ©', 'Ø³ÙŠØ§Ø±Ø© Ù†Ø¸ÙŠÙØ©', 'ÙˆØµÙ„Øª ÙÙŠ Ø§Ù„ÙˆÙ‚Øª', 'ØºÙŠØ± Ù…Ø­ØªØ±Ù…Ø©'];
  final List<Map<String, dynamic>> rideHistory = [
    {'date': '22 ÙŠÙˆÙ„ÙŠÙˆ', 'route': 'Ø§Ù„Ù…Ø·Ø§Ø± â†’ Ø§Ù„Ù…Ø¯ÙŠÙ†Ø©', 'fare': 550, 'status': 'Ù…ÙƒØªÙ…Ù„'},
    {'date': '20 ÙŠÙˆÙ„ÙŠÙˆ', 'route': 'Ø§Ù„Ø¬Ø§Ù…Ø¹Ø© â†’ Ø§Ù„Ù…Ù†Ø²Ù„', 'fare': 320, 'status': 'Ù…ÙƒØªÙ…Ù„'},
  ];
  final List<String> quickMessages = ['ÙˆØµÙ„Øª', 'Ø£Ù†Ø§ Ù‡Ù†Ø§', 'Ø´ÙƒØ±Ø§Ù‹'];
  // chatMessages is now backed by real-time stream from Supabase.
  // We keep a local list for offline/fallback display.
  final List<String> chatMessages = ['ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø±Ø­Ù„Ø©', 'Ø§Ù„Ø³Ø§Ø¦Ù‚ Ø¹Ù„Ù‰ Ø§Ù„Ø·Ø±ÙŠÙ‚'];
  final TextEditingController _chatController = TextEditingController();
  String ridePin = '';
  bool isRideStarted = false;
  bool isRecording = false;
  bool isSendingVoice = false;
  bool isSharedRide = false;
  int sharedSeatsCount = 2;
  bool isIntercity = false;
  String? _userRole;
  Timer? _mockCarsTimer;
  final List<MockVehicle> _mockVehicles = [];
  final List<MockRider> _mockRiders = [];
  


  StreamSubscription<List<RideMessage>>? _messagesSubscription;
  StreamSubscription<Map<String, dynamic>?>? _locationSubscription;
  LatLng? driverLocation;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  
  // Promo variables
  final bool _hasPromo = true;
  final double _promoDiscount = 200;
  bool _showPromoBanner = true;

  @override
  void initState() {
    super.initState();
    _searchingAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _searchingAnimController!, curve: Curves.easeInOut));
    
    _mockCarsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _step != RideFlowStep.home) return;
      
      final center = pickupLocation ?? const LatLng(36.7538, 3.0588);
      final hour = DateTime.now().hour;
      
      // Ø§Ù„ÙƒØ«Ø§ÙØ© ØªØ²ÙŠØ¯ ÙÙŠ Ø£ÙˆÙ‚Ø§Øª Ø§Ù„Ø°Ø±ÙˆØ©
      bool isRushHour = (hour >= 7 && hour <= 10) || (hour >= 16 && hour <= 19);
      int targetVehicles = isRushHour ? 6 : 3;
      int targetRiders = isRushHour ? 4 : 2;
      
      final rand = math.Random();
      
      // ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø³ÙŠØ§Ø±Ø§Øª
      _mockVehicles.removeWhere((v) => v.remainingTicks <= 0);
      for (var v in _mockVehicles) {
        v.remainingTicks--;
        double distance = v.speed;
        v.position = LatLng(
          v.position.latitude + distance * math.cos(v.heading),
          v.position.longitude + distance * math.sin(v.heading)
        );
      }
      
      // Ø¥Ø¶Ø§ÙØ© Ø³ÙŠØ§Ø±Ø§Øª Ø¬Ø¯ÙŠØ¯Ø© Ø¨Ø¹ÙŠØ¯Ø§Ù‹ Ø¹Ù† Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ù„Ù…Ø­Ø§ÙƒØ§Ø© Ù†Ø´Ø§Ø· Ø­Ù‚ÙŠÙ‚ÙŠ
      while (_mockVehicles.length < targetVehicles) {
        double angle = rand.nextDouble() * 2 * math.pi;
        double dist = 0.005 + rand.nextDouble() * 0.015; // Ø§Ù„Ù…Ø³Ø§ÙØ© Ø§Ù„Ø£Ø¯Ù†Ù‰ 0.005 Ù„Ù…Ù†Ø¹ Ø§Ù„ØªÙƒØ¯Ø³
        LatLng startPos = LatLng(center.latitude + dist * math.cos(angle), center.longitude + dist * math.sin(angle));
        
        // Ø§ØªØ¬Ø§Ù‡ ÙŠØ­Ø§ÙƒÙŠ Ø´Ø¨ÙƒØ© Ø§Ù„Ø·Ø±Ù‚ (Ø²ÙˆØ§ÙŠØ§ Ù‚Ø§Ø¦Ù…Ø© Ù…ØªØ¹Ø§Ù…Ø¯Ø©)
        double heading = (rand.nextInt(4) * 90) * (math.pi / 180);
        double speed = 0.0001 + rand.nextDouble() * 0.00015; // Ø­Ø±ÙƒØ© Ø¨Ø·ÙŠØ¦Ø© Ø¬Ø¯Ø§ ØªØ­Ø§ÙƒÙŠ Ø§Ù„Ø³ÙŠØ± Ø§Ù„ÙˆØ§Ù‚Ø¹ÙŠ
        int lifespan = 30 + rand.nextInt(60); // ØªØ®ØªÙÙŠ Ø¨Ø¹Ø¯ 30 Ù„Ù€ 90 Ø«Ø§Ù†ÙŠØ©
        
        _mockVehicles.add(MockVehicle(startPos, heading, speed, lifespan));
      }
      
      // ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø±Ø§ÙƒØ¨Ø§Øª
      _mockRiders.removeWhere((r) => r.remainingTicks <= 0);
      for (var r in _mockRiders) {
        r.remainingTicks--;
      }
      
      while (_mockRiders.length < targetRiders) {
        double angle = rand.nextDouble() * 2 * math.pi;
        // Ø¥Ø¨Ø¹Ø§Ø¯ Ø§Ù„Ø±Ø§ÙƒØ¨Ø§Øª Ø§Ù„ÙˆÙ‡Ù…ÙŠØ§Øª Ù„Ù…Ø³Ø§ÙØ© Ù…Ø¹Ù‚ÙˆÙ„Ø© (Ø­ÙˆØ§Ù„ÙŠ 1.5 Ù„Ù€ 4 ÙƒÙ…) ÙƒÙŠ Ù„Ø§ ØªØ°Ù‡Ø¨ Ø§Ù„Ø³Ø§Ø¦Ù‚Ø© Ù„Ù„Ø¨Ø­Ø« Ø¹Ù†Ù‡Ù† ÙˆØªÙƒØªØ´Ù Ø£Ù†Ù‡Ù† ÙˆÙ‡Ù…ÙŠØ§Øª
        double dist = 0.015 + rand.nextDouble() * 0.025;
        LatLng pos = LatLng(center.latitude + dist * math.cos(angle), center.longitude + dist * math.sin(angle));
        int lifespan = 20 + rand.nextInt(40);
        _mockRiders.add(MockRider(pos, lifespan));
      }
      
      setState(() {});
    });
    driverOffers = const [
      RideOffer(id: 'd1', name: 'Ø³Ø§Ø±Ø©', rating: 4.9, carInfo: 'ØªÙˆÙŠÙˆØªØ§ ÙƒÙˆØ±ÙˆÙ„Ø§', distanceKm: 2.1, etaMinutes: 4),
      RideOffer(id: 'd2', name: 'Ø±ÙŠÙ…', rating: 4.8, carInfo: 'Ù‡ÙŠÙˆÙ†Ø¯Ø§ÙŠ Ø¥Ù„Ù†ØªØ±Ø§', distanceKm: 3.4, etaMinutes: 7),
      RideOffer(id: 'd3', name: 'Ù†ÙˆÙ', rating: 4.7, carInfo: 'ÙƒÙŠØ§ Ø³ÙŠØ±Ø§ØªÙˆ', distanceKm: 4.9, etaMinutes: 9),
    ];
    pendingRequests = const [
      RideRequest(id: 'r1', pickup: 'Ø³ÙˆÙ‚ Ø§Ù„Ù…Ø¯ÙŠÙ†Ø©', dropoff: 'Ù…Ù†Ø·Ù‚Ø© Ø§Ù„Ø£Ø¹Ù…Ø§Ù„', proposedFare: 420, status: 'searching', distanceKm: 4.5),
      RideRequest(id: 'r2', pickup: 'Ø§Ù„Ù…Ø·Ø§Ø±', dropoff: 'Ø§Ù„Ø¬Ø§Ù…Ø¹Ø©', proposedFare: 580, status: 'searching', isShared: true, distanceKm: 2.1),
      RideRequest(id: '3', pickup: 'Ø§Ù„Ù…Ø±Ø§Ø¯ÙŠØ©', dropoff: 'Ø¨Ù† Ø¹ÙƒÙ†ÙˆÙ†', proposedFare: 600, status: 'searching', distanceKm: 0.8),
      RideRequest(id: '4', pickup: 'Ø§Ù„Ù‚Ø¨Ø©', dropoff: 'Ø­ÙŠØ¯Ø±Ø©', proposedFare: 300, status: 'searching', isShared: true, rideType: 'shared_city', distanceKm: 1.5),
      RideRequest(id: '5', pickup: 'Ø§Ù„Ø¬Ø²Ø§Ø¦Ø± Ø§Ù„Ø¹Ø§ØµÙ…Ø©', dropoff: 'ÙˆÙ‡Ø±Ø§Ù†', proposedFare: 4500, status: 'searching', isShared: true, rideType: 'shared_intercity', distanceKm: 5.0),
    ];
    _initializeLocation();
    
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingPath = null;
        });
      }
    });

    Future.microtask(() async {
      final userId = ref.read(authProvider).userId;
      if (userId != null) {
        try {
          final res = await Supabase.instance.client.from('user_profiles').select('role').eq('user_id', userId).maybeSingle();
          if (res != null && mounted) setState(() => _userRole = res['role']);
        } catch (_) {}
      }
      if (userId != null) {
        _rideService.startNotificationListener(userId, isDriverMode ? 'driver' : 'rider');
      }
    });
  }

  void _subscribeToMessages(String rideId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _rideService.subscribeToMessages(rideId).listen((messages) {
      if (!mounted) return;
      final currentUserId = ref.read(authProvider).userId ?? 'demo-user';
      setState(() {
        chatMessages
          ..clear()
          ..addAll(messages.map((m) {
            final prefix = m.senderId == currentUserId ? 'Ø£Ù†Øª: ' : '';
            return '$prefix${m.content}';
          }));
      });
    });
  }

  @override
  void dispose() {
    _dropoffController.dispose();
    _offerController.dispose();
    _chatController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _mockCarsTimer?.cancel();
    _debounceTimer?.cancel();
    _searchingAnimController?.dispose();
    _autoOfflineTimer?.cancel();
    _messagesSubscription?.cancel();
    _locationSubscription?.cancel();
    _trackingService.stopTracking();
    AIService.stopAnomalyDetection(); // Ø¥ÙŠÙ‚Ø§Ù AI Ø¹Ù†Ø¯ Ø¥ØºÙ„Ø§Ù‚ Ø§Ù„Ø´Ø§Ø´Ø©
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => isLoadingLocation = true);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
          pickupAddress = 'Ø§Ù„Ø±Ø¬Ø§Ø¡ ØªÙØ¹ÙŠÙ„ Ø§Ù„Ù…ÙˆÙ‚Ø¹ (GPS)';
          // ØªØ¹ÙŠÙŠÙ† Ù…ÙˆÙ‚Ø¹ Ø§ÙØªØ±Ø§Ø¶ÙŠ (Ø§Ù„Ø¬Ø²Ø§Ø¦Ø± Ø§Ù„Ø¹Ø§ØµÙ…Ø© Ù…Ø«Ù„Ø§Ù‹) Ù„ÙŠØªÙ…ÙƒÙ† Ø§Ù„Ù…Ø³ØªØ®Ø¯Ù… Ù…Ù† Ø§Ù„Ø³Ø­Ø¨
          pickupLocation = const LatLng(36.7538, 3.0588); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ø§Ù„Ø±Ø¬Ø§Ø¡ ØªÙØ¹ÙŠÙ„ Ø®Ø¯Ù…Ø© Ø§Ù„Ù…ÙˆÙ‚Ø¹ (GPS) Ù„Ø³Ù‡ÙˆÙ„Ø© ØªØ­Ø¯ÙŠØ¯ Ù…ÙƒØ§Ù†ÙƒØŒ Ø£Ùˆ Ù‚Ù… Ø¨Ø³Ø­Ø¨ Ø§Ù„Ø®Ø±ÙŠØ·Ø© ÙŠØ¯ÙˆÙŠØ§Ù‹.'),
            action: SnackBarAction(
              label: 'Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª',
              textColor: Colors.yellow,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
          pickupAddress = 'Ø¨Ø¯ÙˆÙ† ØµÙ„Ø§Ø­ÙŠØ© (Ø§Ø³Ø­Ø¨ Ø§Ù„Ø®Ø±ÙŠØ·Ø©)';
          pickupLocation = const LatLng(36.7538, 3.0588); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ØªÙ… Ø±ÙØ¶ ØµÙ„Ø§Ø­ÙŠØ© Ø§Ù„Ù…ÙˆÙ‚Ø¹. ÙŠÙ…ÙƒÙ†Ùƒ Ø³Ø­Ø¨ Ø§Ù„Ø®Ø±ÙŠØ·Ø© ÙŠØ¯ÙˆÙŠØ§Ù‹ Ù„ØªØ­Ø¯ÙŠØ¯ Ù…ÙƒØ§Ù†Ùƒ.'),
            action: SnackBarAction(
              label: 'Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª',
              textColor: Colors.yellow,
              onPressed: () => Geolocator.openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
    final location = LatLng(position.latitude, position.longitude);

    await _reverseGeocode(location);

    if (!mounted) return;
    setState(() {
      pickupLocation = location;
      isLoadingLocation = false;
    });
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(location.latitude, location.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [place.street, place.locality, place.country]
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .join(' ');
        if (mounted) {
          setState(() => pickupAddress = address.isEmpty ? 'Ù…ÙˆÙ‚Ø¹Ùƒ Ø§Ù„Ø­Ø§Ù„ÙŠ' : address);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => pickupAddress = 'Ù…ÙˆÙ‚Ø¹Ùƒ Ø§Ù„Ø­Ø§Ù„ÙŠ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 8)],
          ),
          child: IconButton(
            icon: Icon(
              _step == RideFlowStep.home ? Icons.person : Icons.arrow_back,
              color: const Color(0xFFFFD700),
            ),
            onPressed: () {
              if (_step == RideFlowStep.home) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else {
                _handleBack();
              }
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 8)],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Color(0xFFFFD700)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
              },
            ),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: PopScope(
          canPop: _step == RideFlowStep.home,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _handleBack();
            }
          },
          child: Stack(
            children: [
              _buildStepBody(),
              if (!isDriverMode && _showPromoBanner && _step == RideFlowStep.home)
                Positioned(
                  top: 90,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                      boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer, color: Colors.yellowAccent, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Ø®ØµÙ… Ø­ØµØ±ÙŠ Ù„ÙƒÙ! ðŸŽ‰', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Ø§Ø³ØªÙ…ØªØ¹ÙŠ Ø¨Ø®ØµÙ… ${_promoDiscount.toInt()} Ø¯Ø¬ Ø¹Ù„Ù‰ Ø±Ø­Ù„ØªÙƒ Ø§Ù„Ù‚Ø§Ø¯Ù…Ø©. (ØµØ§Ù„Ø­ Ù„Ù…Ø¯Ø© 24 Ø³Ø§Ø¹Ø©)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white70),
                                onPressed: () => setState(() => _showPromoBanner = false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    setState(() {
      switch (_step) {
        case RideFlowStep.pickup:
        case RideFlowStep.dropoff:
        case RideFlowStep.driverRequests:
        case RideFlowStep.earnings:
          _step = RideFlowStep.home;
          isDriverMode = false;
          break;
        case RideFlowStep.fare:
          _step = RideFlowStep.dropoff;
          break;
        case RideFlowStep.drivers:
          _step = RideFlowStep.fare;
          break;
        case RideFlowStep.negotiation:
          _step = RideFlowStep.fare; // Or cancel the ride request
          break;
        case RideFlowStep.payment:
          _step = RideFlowStep.activeRide;
          break;
        case RideFlowStep.rating:
          _step = RideFlowStep.payment;
          break;
        case RideFlowStep.receipt:
        case RideFlowStep.history:
          _step = RideFlowStep.home;
          break;
        case RideFlowStep.activeRide:
          // In active ride, don't allow back to avoid breaking flow, or show dialog
          break;
        case RideFlowStep.home:
          break;
      }
    });
  }

  String get _appBarTitle {
    final tr = ref.read(translationProvider).tr;
    switch (_step) {
      case RideFlowStep.pickup:
        return tr('title_pickup');
      case RideFlowStep.dropoff:
        return tr('title_dropoff');
      case RideFlowStep.fare:
        return tr('title_fare');
      case RideFlowStep.drivers:
        return tr('title_drivers');
      case RideFlowStep.negotiation:
        return tr('title_negotiation');
      case RideFlowStep.activeRide:
        return tr('title_active_ride');
      case RideFlowStep.payment:
        return tr('title_payment');
      case RideFlowStep.rating:
        return tr('title_rating');
      case RideFlowStep.receipt:
        return tr('title_receipt');
      case RideFlowStep.history:
        return tr('title_history');
      case RideFlowStep.driverRequests:
        return tr('title_requests');
      case RideFlowStep.earnings:
        return tr('title_earnings');
      case RideFlowStep.home:
        return tr('title_home');
    }
  }

  Future<void> _reverseGeocodeCenter(LatLng center) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(center.latitude, center.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final name = '${place.street ?? ''} ${place.locality ?? ''}'.trim();
          if (mounted) {
            setState(() {
              if (isSelectingDropoff) {
                dropoffLocation = center;
                dropoffAddress = name.isNotEmpty ? name : 'Ù…ÙˆÙ‚Ø¹ ØºÙŠØ± Ù…Ø¹Ø±ÙˆÙ';
              } else {
                pickupLocation = center;
                pickupAddress = name.isNotEmpty ? name : 'Ù…ÙˆÙ‚Ø¹ ØºÙŠØ± Ù…Ø¹Ø±ÙˆÙ';
              }
              // Calculate distance dynamically if both are set
              if (pickupLocation != null && dropoffLocation != null) {
                distanceKm = const Distance().as(LengthUnit.Kilometer, pickupLocation!, dropoffLocation!);
                durationMinutes = (distanceKm * 3).round().clamp(1, 100);
                
                // Re-calculate suggested fare
                final breakdown = RideService.calculateSuggestedFareDetailed(
                  distanceKm: distanceKm,
                  durationMinutes: durationMinutes,
                );
                proposedFare = RideService.minFareForEstimate(breakdown.totalFare);
                
                // Draw dotted line between the two points
                _routePolyline = [pickupLocation!, dropoffLocation!];
              }
            });
          }
        }
      } catch (e) {
        debugPrint("Reverse geocoding error: $e");
      }
    });
  }

  Widget _buildStepBody() {
    switch (_step) {
      case RideFlowStep.pickup:
        return _buildPickupStep();
      case RideFlowStep.dropoff:
        return _buildDropoffStep();
      case RideFlowStep.fare:
        return _buildFareStep();
      case RideFlowStep.drivers:
        return _buildDriversStep();
      case RideFlowStep.negotiation:
        return _buildNegotiationStep();
      case RideFlowStep.activeRide:
        return _buildActiveRideStep();
      case RideFlowStep.payment:
        return _buildPaymentStep();
      case RideFlowStep.rating:
        return _buildRatingStep();
      case RideFlowStep.receipt:
        return _buildReceiptStep();
      case RideFlowStep.history:
        return _buildHistoryStep();
      case RideFlowStep.driverRequests:
        return _buildDriverRequestsStep();
      case RideFlowStep.earnings:
        return _buildEarningsStep();
      case RideFlowStep.home:
        return _buildHomeStep();
    }
  }

  Widget _buildHomeStep() {
    final tr = ref.watch(translationProvider).tr;
    return Stack(
      children: [
        SizedBox.expand(child: _buildMapPreview(showPickupMarker: false)),
        
        // Fixed Center Pin (Girl Avatar) for dragging
        Center(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.only(bottom: 60), // Offset to point to the exact center
              child: const AnimatedWaitingRider(),
            ),
          ),
        ),

        // Searching Animation Overlay
        if (_isSearchingForDriver)
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation!,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation!.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.pink.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 15)
                      ],
                    ),
                    child: const Icon(Icons.phone_android, size: 70, color: Colors.white),
                  ),
                );
              },
            ),
          ),

        // Top Search Bars
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Column(
              children: [
                _buildSearchInput(
                  icon: Icons.my_location,
                  iconColor: const Color(0xFF00897B),
                  hint: tr('where_from'),
                  value: pickupAddress,
                  isActive: !isSelectingDropoff,
                  onTap: () => setState(() => isSelectingDropoff = false),
                ),
                const SizedBox(height: 8),
                _buildSearchInput(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFE91E63),
                  hint: tr('where_to_go'),
                  value: dropoffAddress,
                  isActive: isSelectingDropoff,
                  onTap: () => setState(() => isSelectingDropoff = true),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 300,
          right: 24,
          child: FloatingActionButton(
            heroTag: 'location',
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: const Color(0xFFFFD700),
            elevation: 4,
            onPressed: _initializeLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
        
        // Bottom Action Panel
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildUnifiedBottomPanel(tr),
        ),
      ],
    );
  }

  Widget _buildSearchInput({
    required IconData icon,
    required Color iconColor,
    required String hint,
    required String value,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFFFFD700) : Colors.transparent, width: 1.5),
          boxShadow: isActive ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 8)] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFD700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == 'Ø§Ù„ÙˆØ¬Ù‡Ø©' || value == 'Ø§Ø®ØªØ± Ù†Ù‚Ø·Ø© Ø§Ù„Ø§Ù†Ø·Ù„Ø§Ù‚' ? hint : value,
                style: TextStyle(
                  color: (value == 'Ø§Ù„ÙˆØ¬Ù‡Ø©' || value == 'Ø§Ø®ØªØ± Ù†Ù‚Ø·Ø© Ø§Ù„Ø§Ù†Ø·Ù„Ø§Ù‚') ? Colors.white54 : Colors.white,
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedBottomPanel(String Function(String) tr) {
    // If locations are not fully set, just show a prompt
    if (pickupLocation == null || dropoffLocation == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -5))],
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(10))),
            const Text('Ø­Ø¯Ø¯ Ù†Ù‚Ø·Ø© Ø§Ù„Ø§Ù†Ø·Ù„Ø§Ù‚ ÙˆØ§Ù„ÙˆØ¬Ù‡Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø®Ø±ÙŠØ·Ø©', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
          ],
        ),
      );
    }

    final breakdown = RideService.calculateSuggestedFareDetailed(distanceKm: distanceKm, durationMinutes: durationMinutes);
    final sharedFare = RideService.minFareForEstimate(breakdown.totalFare / sharedSeatsCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.15), blurRadius: 32, spreadRadius: 5, offset: const Offset(0, -5))],
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48, height: 5, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          
          if (_selectedRideType != null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: () => setState(() => _selectedRideType = null),
                color: Colors.grey,
              ),
            ),
            
          Row(
            textDirection: TextDirection.rtl,
            children: [
              // Ø§Ù„Ø²Ø± Ø§Ù„Ø£ÙŠÙ…Ù† (ÙØ±Ø¯ÙŠØ© Ø£Ùˆ ØªÙØ§ÙˆØ¶)
              Expanded(
                flex: _selectedRideType != null ? 3 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: _selectedRideType == 'solo'
                        ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)])
                        : const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF2A2A2A)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedRideType == 'solo' ? Colors.transparent : const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    boxShadow: _selectedRideType == 'solo' ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _selectedRideType == null ? () => setState(() => _selectedRideType = 'solo') : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _selectedRideType == 'solo'
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('ØªØ³Ø¹ÙŠØ±Ø© Ø§Ù„Ø±Ø­Ù„Ø© Ø§Ù„ÙØ±Ø¯ÙŠØ©', style: TextStyle(color: Colors.black87, fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => setState(() => proposedFare = (proposedFare - 50).clamp(100.0, 5000.0)),
                                        icon: const Icon(Icons.remove_circle, color: Colors.black, size: 36),
                                      ),
                                      Text('${proposedFare.toInt()} Ø¯Ø¬', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => setState(() => proposedFare = (proposedFare + 50).clamp(100.0, 5000.0)),
                                        icon: const Icon(Icons.add_circle, color: Colors.black, size: 36),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : _selectedRideType == 'shared'
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('ØªØ³Ø¹ÙŠØ±Ø© Ø§Ù„Ø±Ø­Ù„Ø© Ø§Ù„ØªØ´Ø§Ø±ÙƒÙŠØ©', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Text('${sharedFare.toInt()} Ø¯Ø¬', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.person, color: Color(0xFFFFD700), size: 32),
                                      SizedBox(height: 8),
                                      Text('Ø±Ø­Ù„Ø© ÙØ±Ø¯ÙŠØ©', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text('Ø®Ø§ØµØ©', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Ø§Ù„Ø²Ø± Ø§Ù„Ø£ÙŠØ³Ø± (ØªØ´Ø§Ø±ÙƒÙŠØ© Ø£Ùˆ ØªØ£ÙƒÙŠØ¯)
              Expanded(
                flex: _selectedRideType != null ? 2 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: _selectedRideType != null
                        ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)])
                        : const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF2A2A2A)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedRideType != null ? Colors.transparent : const Color(0xFFFFD700).withValues(alpha: 0.3)),
                    boxShadow: _selectedRideType != null ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _selectedRideType == null
                          ? () => setState(() => _selectedRideType = 'shared')
                          : () => _startSearching(isShared: _selectedRideType == 'shared'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _selectedRideType != null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.black, size: 36),
                                  SizedBox(height: 8),
                                  Text('ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø·Ù„Ø¨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, color: Color(0xFFFFD700), size: 32),
                                  SizedBox(height: 8),
                                  Text('ØªØ´Ø§Ø±ÙƒÙŠØ©', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('Ø§Ù‚ØªØµØ§Ø¯ÙŠØ©', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startSearching({required bool isShared}) {
    setState(() {
      isSharedRide = isShared;
      _isSearchingForDriver = true;
    });
    
    // Simulate searching delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSearchingForDriver = false;
          _step = RideFlowStep.drivers; // Transition to drivers view
        });
      }
    });
  }

  // UI step methods have been moved to ride_flow_steps.dart via extension

  /// Ø³Ø·Ø± Ù…ÙØ±Ø¯ ÙÙŠ Ø¬Ø¯ÙˆÙ„ ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ø£Ø¬Ø±Ø©
  Widget _fareRow(String label, String value, {bool bold = false, bool dimmed = false, bool green = false, bool highlight = false}) {
    final textStyle = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: dimmed
          ? Colors.white54
          : green
              ? Colors.greenAccent
              : highlight
                  ? const Color(0xFFFFD700)
                  : Colors.white,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(value, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildMapPreview({bool showPickupMarker = false, LatLng? driverLocation}) {
    final location = driverLocation ?? pickupLocation ?? const LatLng(36.7538, 3.0588);
    
    // Ù…Ø­Ø§ÙƒØ§Ø© Ù†Ù‚Ø·Ø© ØªÙˆÙ‚Ù Ø¥Ø¶Ø§ÙÙŠØ© (Ø±Ø§ÙƒØ¨Ø© Ø£Ø®Ø±Ù‰) Ù„Ù„Ø±Ø­Ù„Ø§Øª Ø§Ù„ØªØ´Ø§Ø±ÙƒÙŠØ©
    LatLng? sharedStop;
    List<LatLng>? displayPolyline = _routePolyline;
    
    // Ø¥Ø®ÙØ§Ø¡ Ø§Ù„Ø®Ø· (Ø§Ù„Ù…ØªÙ‚Ø·Ø¹ Ø£Ùˆ Ø§Ù„Ù…Ø³Ø§Ø±) Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ø±Ø­Ù„Ø© Ø§Ù„Ù†Ø´Ø·Ø© Ù„ÙŠØªÙ… Ø§Ù„ØªØ±ÙƒÙŠØ² ÙÙ‚Ø· Ø¹Ù„Ù‰ ØªØªØ¨Ø¹ Ø³ÙŠØ§Ø±Ø© Ø§Ù„Ø³Ø§Ø¦Ù‚Ø©
    if (_step == RideFlowStep.activeRide) {
      displayPolyline = null;
    } else if (isSharedRide && pickupLocation != null && dropoffLocation != null) {
      sharedStop = LatLng(
        (pickupLocation!.latitude + dropoffLocation!.latitude) / 2 + 0.005,
        (pickupLocation!.longitude + dropoffLocation!.longitude) / 2 - 0.005,
      );
      // Ø¥Ù†Ø´Ø§Ø¡ Ù…Ø³Ø§Ø± Ù…Ù†ÙƒØ³Ø± (Ù…Ø«Ù„Ø«) ÙŠÙ…Ø± Ø¨Ø§Ù„Ø±Ø§ÙƒØ¨Ø© Ø§Ù„Ø«Ø§Ù†ÙŠØ©
      displayPolyline = [pickupLocation!, sharedStop, dropoffLocation!];
    }

    // Ø³ÙŠØ§Ø±Ø§Øª ÙˆÙ‡Ù…ÙŠØ© Ø¬Ø°Ø§Ø¨Ø© Ø­ÙˆÙ„ Ø§Ù„Ù…Ø±ÙƒØ² ÙÙŠ Ø§Ù„Ø´Ø§Ø´Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©
    List<LatLng> mockDrivers = [];
    List<LatLng> mockRiders = [];
    if (_step == RideFlowStep.home) {
      // Ù†Ø¸Ø§Ù… Ø§Ù„Ø§Ø¨ØªØ¹Ø§Ø¯ Ø§Ù„Ø°ÙƒÙŠ: Ø¥Ø¨Ø¹Ø§Ø¯ Ø§Ù„Ø³ÙŠØ§Ø±Ø§Øª Ø§Ù„ÙˆÙ‡Ù…ÙŠØ© ÙˆØ§Ù„Ø±Ø§ÙƒØ¨Ø§Øª Ø¨Ù…Ø³Ø§ÙØ© Ù…Ø¹Ù‚ÙˆÙ„Ø© Ø­ØªÙ‰ Ù„Ø§ ØªØºØ·ÙŠ Ù…ÙˆÙ‚Ø¹ Ø§Ù„Ø³Ø§Ø¦Ù‚Ø©
      final bool isWorkingDriver = _userRole == 'driver' && isDriverOnline;
      
      // Ù„Ø§ Ù†Ø¸Ù‡Ø± Ø§Ù„ÙˆÙ‡Ù…ÙŠØ§Øª Ù„Ù„Ø³Ø§Ø¦Ù‚Ø© Ø¥Ù„Ø§ Ø¥Ø°Ø§ ÙƒØ§Ù†Øª ÙÙŠ ÙˆØ¶Ø¹ Ø§Ù„Ø¹Ù…Ù„ Ø£Ùˆ ÙƒØ§Ù†Øª Ù…Ø³ØªØ®Ø¯Ù…Ø© Ø¹Ø§Ø¯ÙŠØ©
      if (_userRole != 'driver' || isWorkingDriver) {
        mockDrivers = _mockVehicles.map((v) => v.position).toList();
        mockRiders = _mockRiders.map((r) => r.position).toList();
      }
    }

    return FreeMapPreview(
      center: location,
      showPickupMarker: showPickupMarker,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      routePolyline: displayPolyline,
      waitingRiderLocations: [
        ...sharedStop != null ? [sharedStop] : <LatLng>[],
        ...mockRiders,
      ],
      nearbyDrivers: mockDrivers,
      onCenterChanged: _reverseGeocodeCenter,
    );
  }

  Widget _buildMiniRoutePreview({double height = 140}) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              color: const Color(0xFFEEF8F5),
              child: const Center(child: Icon(Icons.map_outlined, size: 40, color: Color(0xFF00897B))),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route, color: Color(0xFF00897B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPickupLocation() async {
    if (pickupLocation == null) {
      setState(() {
        pickupLocation = const LatLng(24.7136, 46.6753);
      });
    }
    await _reverseGeocode(pickupLocation!);
    setState(() => _step = RideFlowStep.dropoff);
  }

  Future<void> _confirmDropoffLocation() async {
    if (dropoffLocation == null && pickupLocation != null) {
      setState(() {
        dropoffLocation = LatLng(pickupLocation!.latitude + 0.01, pickupLocation!.longitude + 0.01);
      });
    }

    if (pickupLocation != null && dropoffLocation != null) {
      final route = await RoutingService().getRoute(pickupLocation!, dropoffLocation!);
      if (route != null && mounted) {
        setState(() {
          distanceKm = route.distanceKm;
          durationMinutes = route.durationMinutes;
          _routePolyline = route.polyline;
        });
      }
    }

    setState(() {
      dropoffAddress = _dropoffController.text.isEmpty ? 'Ø§Ù„Ù…Ø·Ø§Ø±' : _dropoffController.text;
      proposedFare = RideService.calculateSuggestedFare(distanceKm: distanceKm, durationMinutes: durationMinutes);
      customFare = proposedFare;
      _step = RideFlowStep.fare;
    });
  }

  Future<void> _submitRideRequest() async {
    setState(() => isSubmitting = true);
    final riderId = ref.read(authProvider).userId;
    if (riderId == null) {
      final translation = ref.read(translationProvider).tr;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(translation('error_getting_phone'))));
      return;
    }
    final result = await _rideService.createRide(
      riderId: riderId,
      pickup: pickupAddress,
      dropoff: dropoffAddress,
      proposedFare: proposedFare,
    );
    currentRideId = result['id'];
    ridePin = result['pin'] ?? '';
    currentRideDate = _formatDateTime(DateTime.now());
    // Subscribe to real-time chat for this ride
    if (currentRideId != null) _subscribeToMessages(currentRideId!);
    if (!mounted) return;
    setState(() {
      status = 'searching';
      isSubmitting = false;
      _step = RideFlowStep.drivers;
    });
    await _showDriverSelectionSheet();
  }

  Future<void> _showDriverSelectionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ø§Ù„Ø¹Ø±ÙˆØ¶ Ø§Ù„Ù…ØªØ§Ø­Ø©', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...driverOffers.map((driver) => Card(
                  child: ListTile(
                    title: Text(driver.name),
                    subtitle: Text('${driver.carInfo} â€¢ ${driver.distanceKm} ÙƒÙ… â€¢ ${driver.etaMinutes} Ø¯Ù‚ÙŠÙ‚Ø©'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (isSharedRide) {
                          // Ø±Ø­Ù„Ø© ØªØ´Ø§Ø±ÙƒÙŠØ© = Ø§Ù„Ø³Ø¹Ø± Ø«Ø§Ø¨Øª ÙˆØ¨Ø¯ÙˆÙ† ØªÙØ§ÙˆØ¶ØŒ Ù†Ù†ØªÙ‚Ù„ Ù…Ø¨Ø§Ø´Ø±Ø© Ù„Ù„Ø±Ø­Ù„Ø© Ø§Ù„Ù†Ø´Ø·Ø©
                          _handleDriverSelection(driver, 'accepted');
                        } else {
                          // Ø±Ø­Ù„Ø© Ù Ø±Ø¯ÙŠØ© = ÙŠÙ…ÙƒÙ† Ø§Ù„ØªÙ Ø§ÙˆØ¶
                          _handleDriverSelection(driver, 'counter');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSharedRide ? Colors.green : Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(isSharedRide ? 'Ù‚Ø¨ÙˆÙ„' : 'Ù…Ù Ø§ÙˆØ¶Ø©', style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _handleDriverSelection(RideOffer driver, String action) {
    setState(() {
      selectedDriver = driver;
      selectedDriverName = driver.name;
      if (action == 'accepted') {
        status = 'accepted';
        negotiationHistory.add('ØªÙ… Ù‚Ø¨ÙˆÙ„ Ø§Ù„Ø¹Ø±Ø¶ Ù…Ù† ${driver.name}');
        _step = RideFlowStep.activeRide; // Ù†Ù†ØªÙ‚Ù„ Ù„Ù„Ø±Ø­Ù„Ø© Ù…Ø¨Ø§Ø´Ø±Ø©
      } else if (action == 'counter') {
        status = 'negotiating';
        negotiationHistory.add('ØªÙ… Ù ØªØ­ Ù…Ù Ø§ÙˆØ¶Ø© Ù…Ø¹ ${driver.name}');
        _step = RideFlowStep.negotiation;
      } else {
        status = 'declined';
        negotiationHistory.add('ØªÙ… Ø±Ù Ø¶ Ø§Ù„Ø¹Ø±Ø¶ Ù…Ù† ${driver.name}');
        _step = RideFlowStep.home;
      }
    });
  }

  void _handleNegotiationAction(String action) {
    final message = _offerController.text.trim();
    if (message.isNotEmpty) {
      negotiationHistory.add('Ø£Ù†Øª: $message');
      _offerController.clear();
    }

    setState(() {
      if (action == 'accepted') {
        status = 'accepted';
        negotiationHistory.add('ØªÙ… Ù‚Ø¨ÙˆÙ„ Ø§Ù„Ø¹Ø±Ø¶');
        _step = RideFlowStep.activeRide;
        if (currentRideId != null) {
          if (isDriverMode) {
            _trackingService.startTracking(
              rideId: currentRideId!,
              onLocationUpdate: (pos) {
                if (mounted) setState(() => driverLocation = LatLng(pos.latitude, pos.longitude));
              },
            );
            // â”€â”€ Ø¨Ø¯Ø¡ Ù…Ø±Ø§Ù‚Ø¨Ø© Ø§Ù„Ø°ÙƒØ§Ø¡ Ø§Ù„Ø§ØµØ·Ù†Ø§Ø¹ÙŠ Ù„Ù„Ø±Ø­Ù„Ø© â”€â”€
            final driverId = ref.read(authProvider).userId ?? '';
            AIService.startAnomalyDetection(
              rideId: currentRideId!,
              driverId: driverId,
            );
          } else {
            _locationSubscription?.cancel();
            _locationSubscription = _rideService.subscribeToRideLocation(currentRideId!).listen((loc) {
              if (loc != null && mounted) {
                setState(() => driverLocation = LatLng(loc['latitude'], loc['longitude']));
              }
            });
          }
        }
      } else if (action == 'counter') {
        if (message.isNotEmpty) {
          proposedFare = double.tryParse(message) ?? proposedFare;
          negotiationHistory.add('Ø§Ù„Ø³Ø§Ø¦Ù‚: Ø£Ù‚Ø¨Ù„ $message Ø¯Ø¬');
        }
        status = 'negotiating';
      } else {
        status = 'declined';
        negotiationHistory.add('ØªÙ… Ø±ÙØ¶ Ø§Ù„Ø¹Ø±Ø¶');
        _step = RideFlowStep.home;
      }
    });
  }

  Future<void> _completePayment() async {
    if (currentRideId == null) {
      return;
    }

    final currentUserId = ref.read(authProvider).userId ?? '';
    final driverId = isDriverMode ? currentUserId : (selectedDriverId ?? '');
    // In rider mode, riderId = currentUserId; in driver mode, riderId = selectedRequest?.riderId ?? ''

    final currentFare = selectedRequest?.proposedFare ?? proposedFare;

    AIService.stopAnomalyDetection(); // إيقاف مراقبة AI عند انتهاء الرحلة
    await _rideService.updateRideStatus(rideId: currentRideId!, status: 'completed');
    await _rideService.createCommissionRecord(
      rideId: currentRideId!,
      fare: currentFare,
      driverId: driverId,
    );

    if (isDriverMode) {
      final commission = RideService.calculateCommission(currentFare);
      await ref.read(walletServiceProvider).deductCommission(commission, currentRideId!);
    }

    paymentConfirmed = false;

    if (!mounted) return;

    if (!isDriverMode) {
      setState(() {
        rideHistory.insert(0, {
          'date': currentRideDate,
          'route': '$pickupAddress → $dropoffAddress',
          'fare': currentFare,
          'status': 'مكتمل',
        });
      });
    } else {
      setState(() {
        driverRideHistory.insert(0, {
          'date': currentRideDate,
          'route': selectedRequest != null ? '${selectedRequest!.pickup} → ${selectedRequest!.dropoff}' : '$pickupAddress → $dropoffAddress',
          'fare': currentFare,
          'commission': RideService.calculateCommission(currentFare),
          'net': RideService.calculateNetEarnings(currentFare),
          'status': 'مكتمل',
        });
      });
    }
  }

  Future<void> _submitRating() async {
    if (currentRideId == null) {
      return;
    }

    final currentUserId = ref.read(authProvider).userId ?? '';
    final reviewerId = currentUserId;
    
    final revieweeId = await _rideService.getOpponentId(currentRideId!, isDriverMode);
    if (!mounted) return;
    if (revieweeId == null || revieweeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطأ: لم يتم العثور على الطرف الآخر للتقييم.')));
      return;
    }
    try {
      final ratingService = ref.read(rating_svc.ratingServiceProvider);
      final newRating = rating_mod.RatingModel(
        id: '',
        rideId: currentRideId!,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        score: rating,
        comment: ratingComment.isEmpty ? null : ratingComment,
        createdAt: DateTime.now(),
      );

      await ratingService.submitRating(newRating);

      await _rideService.updateProfileTotals(
        userId: revieweeId,
        role: isDriverMode ? 'rider' : 'driver',
        completedRides: 1,
        averageRating: rating.toDouble(),
      );
    } catch (e) {
      debugPrint('Error submitting rating: $e');
    }

    ratingComment = '';
  }

  String _formatDateTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get _filteredRideHistory {
    final history = isDriverMode ? driverRideHistory : rideHistory;
    if (historyFilter == 'all') {
      return history;
    }
    return history.where((ride) => ride['status'] == historyFilter).toList();
  }

  Widget _historyFilterButton(String value, String label) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: historyFilter == value ? const Color(0xFF00897B) : Colors.grey.shade300,
          foregroundColor: historyFilter == value ? Colors.white : Colors.black,
        ),
        onPressed: () => setState(() => historyFilter = value),
        child: Text(label),
      ),
    );
  }

  void _promptForPin() {
    showDialog(
      context: context,
      builder: (context) {
        String enteredPin = '';
        return AlertDialog(
          title: const Text('Ø¥Ø¯Ø®Ø§Ù„ Ø±Ù…Ø² Ø§Ù„Ø±Ø­Ù„Ø©'),
          content: TextField(
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'Ø§Ù„Ø±Ù…Ø² Ø§Ù„Ø³Ø±ÙŠ (PIN) Ù…Ù† Ø§Ù„Ø²Ø¨ÙˆÙ†Ø©'),
            onChanged: (value) => enteredPin = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ø¥Ù„ØºØ§Ø¡'),
            ),
            ElevatedButton(
              onPressed: () {
                if (enteredPin == ridePin) {
                  setState(() => isRideStarted = true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ø§Ù„Ø±Ù…Ø² ØµØ­ÙŠØ­! ØªÙ… Ø¨Ø¯Ø¡ Ø§Ù„Ø±Ø­Ù„Ø©')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ø§Ù„Ø±Ù…Ø² Ø®Ø§Ø·Ø¦!')));
                }
              },
              child: const Text('ØªØ£ÙƒÙŠØ¯'),
            ),
          ],
        );
      },
    );
  }

  // â”€â”€ getter for selected driver id â”€â”€
  String? get selectedDriverId => selectedDriver?.id;

  // â”€â”€ ØªÙ Ø¹ÙŠÙ„ / ØªØ¹Ø·ÙŠÙ„ ÙˆØ¶Ø¹ Ø§Ù„Ø³Ø§Ø¦Ù‚Ø© â”€â”€
  // â”€â”€ ØªØ£ÙƒÙŠØ¯ Ù…ÙˆÙ‚Ø¹ Ø§Ù„Ø§Ù†Ø·Ù„Ø§Ù‚ â”€â”€
  // â”€â”€ Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ø±Ø­Ù„Ø© Ù…Ø¹ Ø§Ù„Ø±Ø³ÙˆÙ… â”€â”€
  Future<void> _cancelRide() async {
    final mockDistanceKm = 0.5; // Ù…Ø³Ø§Ù Ø© Ø§Ù„Ø³Ø§Ø¦Ù‚Ø© Ø¹Ù† Ù…ÙˆÙ‚Ø¹Ùƒ (Ù„Ù„ØªØ¬Ø±Ø¨Ø©)
    final mockMinutes = 5; // Ø§Ù„Ø¯Ù‚Ø§Ø¦Ù‚ Ø§Ù„ØªÙŠ Ù…Ø±Øª

    final fee = RideService.calculateCancellationFee(mockDistanceKm, mockMinutes);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ø±Ø­Ù„Ø©', style: TextStyle(color: Colors.red)),
        content: Text(
          fee > 0 
          ? 'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ù…Ù† Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ø±Ø­Ù„Ø©ØŸ\n\nØ³ÙŠØªÙ… Ø§Ø­ØªØ³Ø§Ø¨ ØºØ±Ø§Ù…Ø© Ø¥Ù„ØºØ§Ø¡ Ù‚Ø¯Ø±Ù‡Ø§ ${fee.toInt()} Ø¯Ø¬ ØªØ¶Ø§Ù  Ø¥Ù„Ù‰ Ù…Ø¯ÙŠÙˆÙ†ÙŠØªÙƒ Ù„Ø£Ù† Ø§Ù„Ø³Ø§Ø¦Ù‚Ø© Ø£ØµØ¨Ø­Øª Ù‚Ø±ÙŠØ¨Ø© Ø¬Ø¯Ø§Ù‹ (Ø£Ù‚Ù„ Ù…Ù† 1 ÙƒÙ…).'
          : 'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ù…Ù† Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ø±Ø­Ù„Ø©ØŸ'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ØªØ±Ø§Ø¬Ø¹'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø¥Ù„ØºØ§Ø¡'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (currentRideId != null) {
      await _rideService.updateRideStatus(rideId: currentRideId!, status: 'cancelled');
      if (fee > 0) {
        await RideService.applyCancellationPenalty(
          userId: ref.read(authProvider).userId ?? '',
          feeAmount: fee,
          rideId: currentRideId!,
        );
      }
    }
    setState(() {
      currentRideId = null;
      _step = RideFlowStep.home;
      isRideStarted = false;
      selectedDriver = null;
      selectedRequest = null;
    });
  }

  // â”€â”€ Ø¨Ø¯Ø¡ Ø§Ù„ØªØ³Ø¬ÙŠÙ„ Ø§Ù„ØµÙˆØªÙŠ â”€â”€
  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) return;
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordingPath!,
      );
      setState(() => isRecording = true);
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  // â”€â”€ Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„ØªØ³Ø¬ÙŠÙ„ Ø§Ù„ØµÙˆØªÙŠ â”€â”€
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() => isRecording = false);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  // â”€â”€ Ø¥Ø±Ø³Ø§Ù„ Ø§Ù„Ø±Ø³Ø§Ù„Ø© Ø§Ù„ØµÙˆØªÙŠØ© â”€â”€
  Future<void> _sendVoiceNote() async {
    if (_recordingPath == null || currentRideId == null) return;
    setState(() => isSendingVoice = true);
    try {
      final file = getPlatformFile(_recordingPath!);
      final url = await _rideService.uploadVoiceNote(file, currentRideId!);
      if (url != null) {
        final senderId = ref.read(authProvider).userId;
        if (senderId == null) return;
        await _rideService.sendMessage(
          rideId: currentRideId!,
          senderId: senderId,
          content: url,
          type: 'voice',
        );
        setState(() => _recordingPath = null);
      }
    } catch (e) {
      debugPrint('Error sending voice note: $e');
    }
    setState(() => isSendingVoice = false);
  }
}



