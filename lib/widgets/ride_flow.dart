// import 'package:flutter/foundation.dart'; // removed for linter
import '../core/utils/file_utils.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/translation_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ride_models.dart';
import '../services/ride_service.dart';
import '../services/routing_service.dart';
import '../services/location_service.dart';
import '../services/ai_service.dart';
import '../providers/auth_providers.dart';
import '../widgets/glass_container.dart';
import '../widgets/profile_screen.dart';
import '../widgets/subscription_screen.dart';
import '../widgets/support_screen.dart';
import '../widgets/notifications_screen.dart';
import '../features/legal/widgets/evidence_banner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/driver_registration_screen.dart';

// Extracted Widgets
import '../features/ride/presentation/widgets/animated_waiting_rider.dart';
import '../features/ride/presentation/widgets/free_map_preview.dart';

part 'ride_flow_steps.dart';

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
  String pickupAddress = 'اختر نقطة الانطلاق';
  String dropoffAddress = 'الوجهة';
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
  String selectedDriverName = 'سارة';
  List<RideOffer> driverOffers = [];
  RideOffer? selectedDriver;
  List<RideRequest> pendingRequests = [];
  RideRequest? selectedRequest;
  String? currentRideId;
  String currentRideDate = '';
  String historyFilter = 'all';
  Map<String, dynamic>? selectedHistoryRide;
  final List<Map<String, dynamic>> driverRideHistory = [
    {'date': '22 يوليو', 'route': 'المطار → المدينة', 'fare': 550, 'commission': 83, 'net': 467, 'status': 'مكتمل'},
    {'date': '20 يوليو', 'route': 'الجامعة → المنزل', 'fare': 320, 'commission': 48, 'net': 272, 'status': 'مكتمل'},
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
  final List<String> quickTags = ['لطيفة', 'سيارة نظيفة', 'وصلت في الوقت', 'غير محترمة'];
  final List<Map<String, dynamic>> rideHistory = [
    {'date': '22 يوليو', 'route': 'المطار → المدينة', 'fare': 550, 'status': 'مكتمل'},
    {'date': '20 يوليو', 'route': 'الجامعة → المنزل', 'fare': 320, 'status': 'مكتمل'},
  ];
  final List<String> quickMessages = ['وصلت', 'أنا هنا', 'شكراً'];
  // chatMessages is now backed by real-time stream from Supabase.
  // We keep a local list for offline/fallback display.
  final List<String> chatMessages = ['تمت الموافقة على الرحلة', 'السائق على الطريق'];
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
  
  Timer? _simulationTimer;
  int _simulationIndex = 0;

  void _startTripSimulation() {
    if (_routePolyline == null || _routePolyline!.isEmpty) return;
    _simulationIndex = 0;
    _simulationTimer?.cancel();
    // تحريك سيارة الرحلة بدقة على مسار الطريق المرسوم
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || _step != RideFlowStep.activeRide) {
        timer.cancel();
        return;
      }
      if (_simulationIndex < _routePolyline!.length) {
        setState(() => driverLocation = _routePolyline![_simulationIndex]);
        _simulationIndex += 3; // تخطي بعض النقاط لتسريع حركة المحاكاة بشكل مناسب
      } else {
        timer.cancel();
      }
    });
  }

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
      
      // الكثافة تزيد في أوقات الذروة
      bool isRushHour = (hour >= 7 && hour <= 10) || (hour >= 16 && hour <= 19);
      int targetVehicles = isRushHour ? 6 : 3;
      int targetRiders = isRushHour ? 4 : 2;
      
      final rand = math.Random();
      
      // تحديث السيارات
      _mockVehicles.removeWhere((v) => v.remainingTicks <= 0);
      for (var v in _mockVehicles) {
        v.remainingTicks--;
        double distance = v.speed;
        v.position = LatLng(
          v.position.latitude + distance * math.cos(v.heading),
          v.position.longitude + distance * math.sin(v.heading)
        );
      }
      
      // إضافة سيارات جديدة بعيداً عن المستخدم لمحاكاة نشاط حقيقي
      while (_mockVehicles.length < targetVehicles) {
        double angle = rand.nextDouble() * 2 * math.pi;
        double dist = 0.005 + rand.nextDouble() * 0.015; // المسافة الأدنى 0.005 لمنع التكدس
        LatLng startPos = LatLng(center.latitude + dist * math.cos(angle), center.longitude + dist * math.sin(angle));
        
        // اتجاه يحاكي شبكة الطرق (زوايا قائمة متعامدة)
        double heading = (rand.nextInt(4) * 90) * (math.pi / 180);
        double speed = 0.0001 + rand.nextDouble() * 0.00015; // حركة بطيئة جدا تحاكي السير الواقعي
        int lifespan = 30 + rand.nextInt(60); // تختفي بعد 30 لـ 90 ثانية
        
        _mockVehicles.add(MockVehicle(startPos, heading, speed, lifespan));
      }
      
      // تحديث الراكبات
      _mockRiders.removeWhere((r) => r.remainingTicks <= 0);
      for (var r in _mockRiders) {
        r.remainingTicks--;
      }
      
      while (_mockRiders.length < targetRiders) {
        double angle = rand.nextDouble() * 2 * math.pi;
        // إبعاد الراكبات الوهميات لمسافة معقولة (حوالي 1.5 لـ 4 كم) كي لا تذهب السائقة للبحث عنهن وتكتشف أنهن وهميات
        double dist = 0.015 + rand.nextDouble() * 0.025;
        LatLng pos = LatLng(center.latitude + dist * math.cos(angle), center.longitude + dist * math.sin(angle));
        int lifespan = 20 + rand.nextInt(40);
        _mockRiders.add(MockRider(pos, lifespan));
      }
      
      setState(() {});
    });
    driverOffers = const [
      RideOffer(id: 'd1', name: 'سارة', rating: 4.9, carInfo: 'تويوتا كورولا', distanceKm: 2.1, etaMinutes: 4),
      RideOffer(id: 'd2', name: 'ريم', rating: 4.8, carInfo: 'هيونداي إلنترا', distanceKm: 3.4, etaMinutes: 7),
      RideOffer(id: 'd3', name: 'نوف', rating: 4.7, carInfo: 'كيا سيراتو', distanceKm: 4.9, etaMinutes: 9),
    ];
    pendingRequests = const [
      RideRequest(id: 'r1', pickup: 'سوق المدينة', dropoff: 'منطقة الأعمال', proposedFare: 420, status: 'searching', distanceKm: 4.5),
      RideRequest(id: 'r2', pickup: 'المطار', dropoff: 'الجامعة', proposedFare: 580, status: 'searching', isShared: true, distanceKm: 2.1),
      RideRequest(id: '3', pickup: 'المرادية', dropoff: 'بن عكنون', proposedFare: 600, status: 'searching', distanceKm: 0.8),
      RideRequest(id: '4', pickup: 'القبة', dropoff: 'حيدرة', proposedFare: 300, status: 'searching', isShared: true, rideType: 'shared_city', distanceKm: 1.5),
      RideRequest(id: '5', pickup: 'الجزائر العاصمة', dropoff: 'وهران', proposedFare: 4500, status: 'searching', isShared: true, rideType: 'shared_intercity', distanceKm: 5.0),
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
      final notifRole = isDriverMode ? 'driver' : 'rider';
      _rideService.startNotificationListener(userId ?? 'demo-user', notifRole);
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
            final prefix = m.senderId == currentUserId ? 'أنت: ' : '';
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
    _simulationTimer?.cancel();
    _debounceTimer?.cancel();
    _searchingAnimController?.dispose();
    _autoOfflineTimer?.cancel();
    _messagesSubscription?.cancel();
    _locationSubscription?.cancel();
    _trackingService.stopTracking();
    AIService.stopAnomalyDetection(); // إيقاف AI عند إغلاق الشاشة
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => isLoadingLocation = true);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
          pickupAddress = 'الرجاء تفعيل الموقع (GPS)';
          // تعيين موقع افتراضي (الجزائر العاصمة مثلاً) ليتمكن المستخدم من السحب
          pickupLocation = const LatLng(36.7538, 3.0588); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('الرجاء تفعيل خدمة الموقع (GPS) لسهولة تحديد مكانك، أو قم بسحب الخريطة يدوياً.'),
            action: SnackBarAction(
              label: 'الإعدادات',
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
          pickupAddress = 'بدون صلاحية (اسحب الخريطة)';
          pickupLocation = const LatLng(36.7538, 3.0588); 
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم رفض صلاحية الموقع. يمكنك سحب الخريطة يدوياً لتحديد مكانك.'),
            action: SnackBarAction(
              label: 'الإعدادات',
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
          setState(() => pickupAddress = address.isEmpty ? 'موقعك الحالي' : address);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => pickupAddress = 'موقعك الحالي');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: IconButton(
            icon: Icon(
              _step == RideFlowStep.home ? Icons.person : Icons.arrow_back,
              color: const Color(0xFFE91E63),
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
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_none, color: Color(0xFFE91E63)),
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
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
                                    const Text('خصم حصري لكِ! 🎉', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('استمتعي بخصم ${_promoDiscount.toInt()} دج على رحلتك القادمة. (صالح لمدة 24 ساعة)', style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                dropoffAddress = name.isNotEmpty ? name : 'موقع غير معروف';
              } else {
                pickupLocation = center;
                pickupAddress = name.isNotEmpty ? name : 'موقع غير معروف';
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
            backgroundColor: Colors.white,
            foregroundColor: Theme.of(context).colorScheme.primary,
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
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 20,
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value == 'الوجهة' || value == 'اختر نقطة الانطلاق' ? hint : value,
                style: TextStyle(
                  color: (value == 'الوجهة' || value == 'اختر نقطة الانطلاق') ? Colors.grey : Colors.black87,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            Text('حدد نقطة الانطلاق والوجهة على الخريطة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          ],
        ),
      );
    }

    final breakdown = RideService.calculateSuggestedFareDetailed(distanceKm: distanceKm, durationMinutes: durationMinutes);
    final sharedFare = RideService.minFareForEstimate(breakdown.totalFare / sharedSeatsCount);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [BoxShadow(color: const Color(0xFFE91E63).withValues(alpha: 0.1), blurRadius: 32, spreadRadius: 5, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 48, height: 5, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF00897B)]), borderRadius: BorderRadius.circular(10)),
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
            textDirection: TextDirection.rtl, // لضمان أن اليمين هو البداية
            children: [
              // الزر الأيمن (فردية أو تفاوض)
              Expanded(
                flex: _selectedRideType != null ? 3 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5F9E)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFFE91E63).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
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
                                  Text('تسعيرة الرحلة الفردية', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => setState(() => proposedFare = (proposedFare - 50).clamp(100.0, 5000.0)),
                                        icon: const Icon(Icons.remove_circle, color: Colors.white, size: 36),
                                      ),
                                      Text('${proposedFare.toInt()} دج', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () => setState(() => proposedFare = (proposedFare + 50).clamp(100.0, 5000.0)),
                                        icon: const Icon(Icons.add_circle, color: Colors.white, size: 36),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : _selectedRideType == 'shared'
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('تسعيرة الرحلة التشاركية', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Text('${sharedFare.toInt()} دج', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person, color: Colors.white, size: 32),
                                      const SizedBox(height: 8),
                                      const Text('رحلة فردية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text('${distanceKm.toStringAsFixed(1)} كم', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // الزر الأيسر (تشاركية أو تأكيد)
              Expanded(
                flex: _selectedRideType != null ? 2 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF26A69A)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF00897B).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
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
                                  Icon(Icons.check_circle, color: Colors.white, size: 36),
                                  SizedBox(height: 8),
                                  Text('تأكيد الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, color: Colors.white, size: 32),
                                  SizedBox(height: 8),
                                  Text('تشاركية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('اقتصادية', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

  /// سطر مفرد في جدول تفاصيل الأجرة
  Widget _fareRow(String label, String value, {bool bold = false, bool dimmed = false, bool green = false, bool highlight = false}) {
    final textStyle = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: dimmed
          ? Colors.grey
          : green
              ? Colors.green.shade700
              : highlight
                  ? Colors.orange.shade800
                  : null,
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
    
    // محاكاة نقطة توقف إضافية (راكبة أخرى) للرحلات التشاركية
    LatLng? sharedStop;
    List<LatLng>? displayPolyline = _routePolyline;
    
    // إخفاء الخط (المتقطع أو المسار) أثناء الرحلة النشطة ليتم التركيز فقط على تتبع سيارة السائقة
    if (_step == RideFlowStep.activeRide) {
      displayPolyline = null;
    } else if (isSharedRide && pickupLocation != null && dropoffLocation != null) {
      sharedStop = LatLng(
        (pickupLocation!.latitude + dropoffLocation!.latitude) / 2 + 0.005,
        (pickupLocation!.longitude + dropoffLocation!.longitude) / 2 - 0.005,
      );
      // إنشاء مسار منكسر (مثلث) يمر بالراكبة الثانية
      displayPolyline = [pickupLocation!, sharedStop, dropoffLocation!];
    }

    // سيارات وهمية جذابة حول المركز في الشاشة الرئيسية
    List<LatLng> mockDrivers = [];
    List<LatLng> mockRiders = [];
    if (_step == RideFlowStep.home) {
      // نظام الابتعاد الذكي: إبعاد السيارات الوهمية والراكبات بمسافة معقولة حتى لا تغطي موقع السائقة
      final bool isWorkingDriver = _userRole == 'driver' && isDriverOnline;
      
      // لا نظهر الوهميات للسائقة إلا إذا كانت في وضع العمل أو كانت مستخدمة عادية
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
      dropoffAddress = _dropoffController.text.isEmpty ? 'المطار' : _dropoffController.text;
      proposedFare = RideService.calculateSuggestedFare(distanceKm: distanceKm, durationMinutes: durationMinutes);
      customFare = proposedFare;
      _step = RideFlowStep.fare;
    });
  }

  Future<void> _submitRideRequest() async {
    setState(() => isSubmitting = true);
    final riderId = ref.read(authProvider).userId ?? 'demo-user';
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
            const Text('العروض المتاحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...driverOffers.map((driver) => Card(
                  child: ListTile(
                    title: Text(driver.name),
                    subtitle: Text('${driver.carInfo} • ${driver.distanceKm} كم • ${driver.etaMinutes} دقيقة'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (isSharedRide) {
                          // رحلة تشاركية = السعر ثابت وبدون تفاوض، ننتقل مباشرة للرحلة النشطة
                          _handleDriverSelection(driver, 'accepted');
                        } else {
                          // رحلة فردية = يمكن التفاوض
                          _handleDriverSelection(driver, 'counter');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSharedRide ? Colors.green : Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(isSharedRide ? 'قبول' : 'مفاوضة', style: const TextStyle(color: Colors.white)),
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
        negotiationHistory.add('تم قبول العرض من ${driver.name}');
        _step = RideFlowStep.activeRide; // ننتقل للرحلة مباشرة
      } else if (action == 'counter') {
        status = 'negotiating';
        negotiationHistory.add('تم فتح مفاوضة مع ${driver.name}');
        _step = RideFlowStep.negotiation;
      } else {
        status = 'declined';
        negotiationHistory.add('تم رفض العرض من ${driver.name}');
        _step = RideFlowStep.home;
      }
    });
  }

  void _handleNegotiationAction(String action) {
    final message = _offerController.text.trim();
    if (message.isNotEmpty) {
      negotiationHistory.add('أنت: $message');
      _offerController.clear();
    }

    setState(() {
      if (action == 'accepted') {
        status = 'accepted';
        negotiationHistory.add('تم قبول العرض');
        _step = RideFlowStep.activeRide;
        _startTripSimulation(); // تفعيل محاكاة سير السيارة على طريق الخريطة
        if (currentRideId != null) {
          if (isDriverMode) {
            _trackingService.startTracking(
              rideId: currentRideId!,
              onLocationUpdate: (pos) {
                if (mounted) setState(() => driverLocation = LatLng(pos.latitude, pos.longitude));
              },
            );
            // ── بدء مراقبة الذكاء الاصطناعي للرحلة ──
            final driverId = ref.read(authProvider).userId ?? 'demo-driver';
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
          negotiationHistory.add('السائق: أقبل $message دج');
        }
        status = 'negotiating';
      } else {
        status = 'declined';
        negotiationHistory.add('تم رفض العرض');
        _step = RideFlowStep.home;
      }
    });
  }

  Future<void> _completePayment() async {
    if (currentRideId == null) {
      return;
    }

    final riderId = ref.read(authProvider).userId ?? 'demo-user';
    final driverId = isDriverMode ? riderId : 'demo-driver';
    final fare = isDriverMode && selectedRequest != null ? selectedRequest!.proposedFare : proposedFare;

    AIService.stopAnomalyDetection(); // إيقاف مراقبة AI عند انتهاء الرحلة
    await _rideService.updateRideStatus(rideId: currentRideId!, status: 'completed');
    await _rideService.createCommissionRecord(
      rideId: currentRideId!,
      fare: fare,
      driverId: driverId,
    );

    paymentConfirmed = false;

    if (!isDriverMode) {
      setState(() {
        rideHistory.insert(0, {
          'date': currentRideDate,
          'route': '$pickupAddress → $dropoffAddress',
          'fare': fare,
          'status': 'مكتمل',
        });
      });
    } else {
      setState(() {
        driverRideHistory.insert(0, {
          'date': currentRideDate,
          'route': selectedRequest != null ? '${selectedRequest!.pickup} → ${selectedRequest!.dropoff}' : '$pickupAddress → $dropoffAddress',
          'fare': fare,
          'commission': RideService.calculateCommission(fare),
          'net': RideService.calculateNetEarnings(fare),
          'status': 'مكتمل',
        });
      });
    }
  }

  Future<void> _submitRating() async {
    if (currentRideId == null) {
      return;
    }

    final currentUserId = ref.read(authProvider).userId ?? 'demo-user';
    final reviewerId = currentUserId;
    final revieweeId = isDriverMode ? 'demo-rider' : 'demo-driver';

    await _rideService.createRatingRecord(
      rideId: currentRideId!,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      rating: rating,
      comment: ratingComment.isEmpty ? null : ratingComment,
      isDriverRating: isDriverMode,
    );

    await _rideService.updateProfileTotals(
      userId: revieweeId,
      role: isDriverMode ? 'rider' : 'driver',
      completedRides: 1,
      averageRating: rating.toDouble(),
    );

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
          title: const Text('إدخال رمز الرحلة'),
          content: TextField(
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(labelText: 'الرمز السري (PIN) من الزبونة'),
            onChanged: (value) => enteredPin = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (enteredPin == ridePin) {
                  setState(() => isRideStarted = true);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز صحيح! تم بدء الرحلة')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز خاطئ!')));
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  // ── getter for selected driver id ──
  String? get selectedDriverId => selectedDriver?.id;

  // ── تفعيل / تعطيل وضع السائقة ──
  // ── تأكيد موقع الانطلاق ──
  // ── إلغاء الرحلة مع الرسوم ──
  Future<void> _cancelRide() async {
    final mockDistanceKm = 0.5; // مسافة السائقة عن موقعك (للتجربة)
    final mockMinutes = 5; // الدقائق التي مرت

    final fee = RideService.calculateCancellationFee(mockDistanceKm, mockMinutes);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الرحلة', style: TextStyle(color: Colors.red)),
        content: Text(
          fee > 0 
          ? 'هل أنت متأكد من إلغاء الرحلة؟\n\nسيتم احتساب غرامة إلغاء قدرها ${fee.toInt()} دج تضاف إلى مديونيتك لأن السائقة أصبحت قريبة جداً (أقل من 1 كم).'
          : 'هل أنت متأكد من إلغاء الرحلة؟'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (currentRideId != null) {
      await _rideService.updateRideStatus(rideId: currentRideId!, status: 'cancelled');
      if (fee > 0) {
        await RideService.applyCancellationPenalty(
          userId: ref.read(authProvider).userId ?? 'demo-user',
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

  // ── بدء التسجيل الصوتي ──
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

  // ── إيقاف التسجيل الصوتي ──
  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() => isRecording = false);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  // ── إرسال الرسالة الصوتية ──
  Future<void> _sendVoiceNote() async {
    if (_recordingPath == null || currentRideId == null) return;
    setState(() => isSendingVoice = true);
    try {
      final file = getPlatformFile(_recordingPath!);
      final url = await _rideService.uploadVoiceNote(file, currentRideId!);
      if (url != null) {
        final senderId = ref.read(authProvider).userId ?? 'demo-user';
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
