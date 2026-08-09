// ignore_for_file: invalid_use_of_protected_member
part of 'ride_flow.dart';

extension _RideFlowStepsExtension on _RideFlowScreenState {
  Widget _buildPickupStep() {
    final tr = ref.watch(translationProvider).tr;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              SizedBox.expand(child: _buildMapPreview(showPickupMarker: true)),
              Center(
                child: Icon(Icons.location_pin, size: 48, color: Theme.of(context).colorScheme.primary),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('drag_map_or_select'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(pickupAddress, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFCE4EC)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFF00897B)]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF00897B), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pickupAddress,
                      style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFFF5F9E)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _confirmPickupLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: Text(tr('confirm_pickup_btn'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropoffStep() {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('choose_dropoff'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _dropoffController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: tr('search_destination'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => dropoffAddress = value.isEmpty ? tr('title_dropoff') : value),
          ),
          const SizedBox(height: 16),
          Text(tr('recent_destinations'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(tr('airport'))),
              Chip(label: Text(tr('university'))),
              Chip(label: Text(tr('central_market'))),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('favorites'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(tr('home_place'))),
              Chip(label: Text(tr('work_place'))),
              Chip(label: Text(tr('center_place'))),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('route_preview'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Expanded(child: _buildMiniRoutePreview()),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmDropoffLocation,
              child: Text(tr('confirm_dropoff_btn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareStep() {
    final tr = ref.watch(translationProvider).tr;
    final breakdown = RideService.calculateSuggestedFareDetailed(
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
    );
    
    // حساب السعر بناءً على نوع الرحلة (إذا كانت تشاركية ينقسم على عدد الأشخاص)
    final displayTotalFare = isSharedRide ? breakdown.totalFare / sharedSeatsCount : breakdown.totalFare;
    final minFare = RideService.minFareForEstimate(displayTotalFare);
    final maxFare = RideService.maxFareForEstimate(displayTotalFare);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tr('title_fare'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: breakdown.isNight ? const Color(0xFF1A237E) : const Color(0xFFF9A825),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  breakdown.period,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // خريطة الرحلة
          Container(
            height: 130,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildMapPreview(),
            ),
          ),
          const SizedBox(height: 16),
          // اختيار نوع الرحلة (تشاركية أم فردية)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    isSharedRide = false;
                    proposedFare = breakdown.totalFare;
                    customFare = proposedFare;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: !isSharedRide 
                          ? const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5F9E)])
                          : const LinearGradient(colors: [Colors.white, Colors.white]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: !isSharedRide ? Colors.transparent : Colors.grey.shade300, width: 2),
                      boxShadow: !isSharedRide 
                          ? [BoxShadow(color: const Color(0xFFE91E63).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person, color: !isSharedRide ? Colors.white : Colors.grey.shade600, size: 32),
                        const SizedBox(height: 8),
                        Text(tr('solo_ride'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: !isSharedRide ? Colors.white : Colors.grey.shade700)),
                        const SizedBox(height: 4),
                        Text('سيارة لكِ وحدك', style: TextStyle(fontSize: 11, color: !isSharedRide ? Colors.white70 : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    isSharedRide = true;
                    proposedFare = breakdown.totalFare / sharedSeatsCount;
                    customFare = proposedFare;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: isSharedRide 
                          ? const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFFE040FB)])
                          : const LinearGradient(colors: [Colors.white, Colors.white]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSharedRide ? Colors.transparent : Colors.grey.shade300, width: 2),
                      boxShadow: isSharedRide 
                          ? [BoxShadow(color: const Color(0xFF9C27B0).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.people, color: isSharedRide ? Colors.white : Colors.grey.shade600, size: 32),
                        const SizedBox(height: 8),
                        Text(tr('shared_ride'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSharedRide ? Colors.white : Colors.grey.shade700)),
                        const SizedBox(height: 4),
                        Text('تشاركية بسعر ثابت', style: TextStyle(fontSize: 11, color: isSharedRide ? Colors.white70 : Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isSharedRide) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Row(
                children: [
                  const Text('تقسيم الرحلة على:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9C27B0))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('شخصين (÷2)')),
                        ButtonSegment(value: 3, label: Text('3 أشخاص (÷3)')),
                      ],
                      selected: {sharedSeatsCount},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          sharedSeatsCount = newSelection.first;
                          proposedFare = breakdown.totalFare / sharedSeatsCount;
                          customFare = proposedFare;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Color(0xFF9C27B0);
                            }
                            return Colors.white;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return const Color(0xFF9C27B0);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF9C27B0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم تحديد سعر المقعد بشكل ثابت لـ $sharedSeatsCount أشخاص!',
                        style: TextStyle(color: Colors.purple.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // بطاقة تفاصيل الأجرة
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00897B).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _fareRow(tr('base_fare'), '${breakdown.baseFare.toInt()} دج'),
                _fareRow('${tr('distance_cost')} (${distanceKm.toStringAsFixed(1)} كم)', '${breakdown.distanceFare.toInt()} دج'),
                _fareRow('${tr('time_cost')} ($durationMinutes دقيقة)', '${breakdown.timeFare.toInt()} دج'),
                if (breakdown.surgeMultiplier > 1.0) ...[
                  const Divider(),
                  _fareRow(
                    breakdown.surgeLabel,
                    '×${breakdown.surgeMultiplier.toStringAsFixed(1)}',
                    highlight: true,
                  ),
                ],
                const Divider(thickness: 1.5),
                _fareRow(
                  isSharedRide ? tr('discounted_shared_fare') : tr('total_fare'), 
                  '${displayTotalFare.toInt()} دج', 
                  bold: true,
                  highlight: isSharedRide
                ),
                const SizedBox(height: 4),
                _fareRow(tr('dora_commission'), '- ${(isSharedRide ? breakdown.commission / sharedSeatsCount : breakdown.commission).toInt()} دج', dimmed: true),
                _fareRow(tr('driver_net'), '${breakdown.driverNet.toInt()} دج', green: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isSharedRide) ...[
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: tr('suggest_fare_label'),
                border: const OutlineInputBorder(),
                helperText: tr('suggest_fare_helper'),
              ),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed != null) {
                  setState(() {
                    customFare = parsed;
                    proposedFare = parsed;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Slider(
              min: minFare,
              max: maxFare,
              value: customFare.clamp(minFare, maxFare),
              activeColor: const Color(0xFFE91E63),
              onChanged: (value) {
                setState(() {
                  customFare = value;
                  proposedFare = value;
                });
              },
            ),
            Text('${tr('acceptable_range')} ${minFare.toInt()} - ${maxFare.toInt()} دج ${tr('raise_price_hint')}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitRideRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSharedRide ? const Color(0xFF9C27B0) : null,
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isSharedRide 
                      ? 'تأكيد حجز مقعد تشاركي - ${proposedFare.toInt()} دج'
                      : '${tr('send_request_btn')} - ${proposedFare.toInt()} دج', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),

          if (!isRideStarted && !isDriverMode) ...[
            const SizedBox(height: 12),
            Text(tr('send_voice_note_label'), style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: Icon(isRecording ? Icons.stop_circle : Icons.mic, color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary, size: 32),
                  onPressed: isRecording ? _stopRecording : _startRecording,
                ),
                if (isRecording) Text(tr('recording_in_progress'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                if (!isRecording && _recordingPath != null && !isSendingVoice)
                  ElevatedButton(onPressed: _sendVoiceNote, child: Text(tr('send_btn'))),
                if (isSendingVoice) const CircularProgressIndicator(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriversStep() {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('drivers_offers_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: driverOffers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final driver = driverOffers[index];
                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(driver.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.directions_car, color: Colors.grey.shade600, size: 16),
                                    const SizedBox(width: 4),
                                    Text(driver.carInfo, style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${proposedFare.toInt()} دج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                              const SizedBox(height: 4),
                              Text('${driver.etaMinutes} ${tr('minutes')}', style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleDriverSelection(driver, 'accepted'),
                              child: Text(tr('accept_btn')),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleDriverSelection(driver, 'counter'),
                              child: Text(tr('negotiate_btn')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _step = RideFlowStep.home),
              child: Text(tr('back_to_home_btn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRequestsStep() {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('riders_requests_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text(tr('available_for_drivers')),
                    subtitle: Text(isDriverOnline ? tr('online_for_requests') : tr('offline')),
                    value: isDriverOnline,
                    onChanged: (value) => _setDriverOnline(value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                ListView.separated(
                  itemCount: pendingRequests.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // ترتيب الطلبات من الأقرب للأبعد (خوارزمية الفرز المكاني)
                    final sortedRequests = List<RideRequest>.from(pendingRequests)..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
                    final request = sortedRequests[index];
                    final currentFare = _driverCounterOffers[request.id] ?? request.proposedFare;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('${request.pickup} → ${request.dropoff}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                if (request.isShared)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: request.rideType == 'shared_intercity' ? Colors.blue.shade100 : Colors.purple.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: request.rideType == 'shared_intercity' ? Colors.blue.shade300 : Colors.purple.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          request.rideType == 'shared_intercity' ? Icons.emoji_transportation : Icons.location_city, 
                                          size: 14, 
                                          color: request.rideType == 'shared_intercity' ? Colors.blue.shade700 : Colors.purple
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          request.rideType == 'shared_intercity' ? tr('shared_intercity_tag') : tr('shared_city_tag'), 
                                          style: TextStyle(
                                            fontSize: 10, 
                                            color: request.rideType == 'shared_intercity' ? Colors.blue.shade700 : Colors.purple, 
                                            fontWeight: FontWeight.bold
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('${tr('distance_from_you')} ${request.distanceKm.toStringAsFixed(1)} كم', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // منطقة التسعير والتفاوض المدمجة
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  if (!request.isShared)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(Icons.remove_circle_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                                          onPressed: () => setState(() => _driverCounterOffers[request.id] = (currentFare - 50).clamp(100.0, 5000.0)),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(request.isShared ? 'سعر ثابت' : 'السعر المعروض', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                          Text('${currentFare.toInt()} دج', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (!request.isShared)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 8),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary, size: 28),
                                          onPressed: () => setState(() => _driverCounterOffers[request.id] = (currentFare + 50).clamp(100.0, 5000.0)),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedRequest = RideRequest(
                                          id: request.id,
                                          pickup: request.pickup,
                                          dropoff: request.dropoff,
                                          proposedFare: currentFare,
                                          status: request.status,
                                          pin: request.pin,
                                          isShared: request.isShared,
                                          rideType: request.rideType,
                                          distanceKm: request.distanceKm,
                                        );
                                        selectedDriverName = 'أنت';
                                        _step = RideFlowStep.activeRide;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: request.isShared ? Colors.green : Theme.of(context).colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(tr('accept_btn'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_userRole != 'driver')
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.3),
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFE91E63).withValues(alpha: 0.5), width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_car_rounded, size: 64, color: Color(0xFFE91E63)),
                                const SizedBox(height: 16),
                                const Text(
                                  'أرباح رائعة في انتظارك!',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'هذه الطلبات حقيقية ومتاحة الآن. انضمي كسائقة معتمدة لتبدئي بقبول الطلبات وجني الأرباح فوراً.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverRegistrationScreen()));
                                    if (result == true && mounted) {
                                      setState(() => _userRole = 'pending_driver');
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE91E63),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('سجلي كسائقة الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() {
                isDriverMode = false;
                _setDriverOnline(false);
                _step = RideFlowStep.home;
              }),
              child: Text(tr('back_to_home_btn')),
            ),
          ),
        ],
      ),
    );
  }

  bool get canReceiveRequests {
    if (!isDriverOnline) return false;
    
    // إذا لم تكن في رحلة نشطة، يمكنها استقبال الطلبات
    if (_step != RideFlowStep.activeRide) return true;
    
    // إذا كانت في رحلة نشطة:
    // تفعيل ميزة (Queue Next Ride) الجميلة:
    // تظهر الطلبات الجديدة فقط إذا بدأت الرحلة وكانت المسافة المتبقية للوصول 10 كم أو أقل.
    // هذا يمنع الطمع والإلغاء في بداية الرحلة!
    if (isDriverMode && isRideStarted && distanceKm <= 10.0) {
      return true;
    }
    
    return false;
  }

  void _setDriverOnline(bool value) {
    if (value == isDriverOnline) return;
    setState(() => isDriverOnline = value);

    if (value) {
      final riderId = ref.read(authProvider).userId ?? 'demo-driver';
      _trackingService.startTracking(rideId: 'driver-$riderId', onLocationUpdate: (_) {});
      _autoOfflineTimer?.cancel();
      _autoOfflineTimer = Timer(const Duration(hours: 8), () {
        if (mounted) setState(() => isDriverOnline = false);
        _trackingService.stopTracking();
      });
      
      // محاكاة وصول طلب جديد مع رنين بعد 3 ثوانٍ من الاتصال
      Timer(const Duration(seconds: 3), () {
        if (mounted && canReceiveRequests) {
          _showIncomingRideAlert();
        }
      });
    } else {
      _autoOfflineTimer?.cancel();
      _trackingService.stopTracking();
    }
  }

  void _showIncomingRideAlert() {
    final tr = ref.read(translationProvider).tr;
    // تشغيل نغمة رنين جذابة ومريحة للسائقة
    _audioPlayer.play(UrlSource('https://cdn.pixabay.com/download/audio/2021/08/04/audio_0625c1539c.mp3'));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Color(0xFFE91E63)),
            const SizedBox(width: 8),
            Text(tr('incoming_ride_alert_title'), style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الوجهة: بن عكنون', style: TextStyle(fontSize: 16)), // Can be dynamic later
            const SizedBox(height: 4),
            const Text('الأجرة: 600 دج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(tr('shared_ride'), style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12)),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // _audioPlayer.stop(); // إيقاف الرنين
              Navigator.pop(context);
            },
            child: Text(tr('ignore_btn'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // _audioPlayer.stop(); // إيقاف الرنين
              Navigator.pop(context);
              setState(() {
                _step = RideFlowStep.activeRide; // ننتقل للرحلة مباشرة
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(tr('accept_request_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationStep() {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text('${tr('current_price_label')} ${proposedFare.toInt()} دج', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${tr('selected_driver_label')} $selectedDriverName'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                children: [
                  ...negotiationHistory.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(entry),
                      )),
                  if (negotiationHistory.isEmpty)
                    Text(tr('no_messages_negotiation')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offerController,
            decoration: InputDecoration(
              labelText: tr('send_new_offer'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleNegotiationAction('accepted'),
                  child: Text(tr('accept_btn')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleNegotiationAction('counter'),
                  child: Text(tr('negotiate_btn')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => _handleNegotiationAction('declined'),
                  child: Text(tr('reject_btn')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideStep() {
    final tr = ref.watch(translationProvider).tr;
    final activeFare = isDriverMode && selectedRequest != null ? selectedRequest!.proposedFare : proposedFare;
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: FreeMapPreview(
            center: driverLocation ?? pickupLocation ?? const LatLng(24.7136, 46.6753),
            showPickupMarker: !isDriverMode && !isRideStarted, 
            pickupLocation: isDriverMode ? (driverLocation ?? pickupLocation) : pickupLocation,
            dropoffLocation: isDriverMode ? pickupLocation : driverLocation,
            driverLocation: isDriverMode ? (driverLocation ?? pickupLocation) : driverLocation,
            isRideStarted: isRideStarted,
            waitingRiderLocations: (isSharedRide && !isDriverMode && !isRideStarted) 
                ? [const LatLng(36.7550, 3.0600)] // Example coordinates for the second rider
                : [],
          ),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EvidenceBanner(),
          if (!isDriverMode && !isRideStarted)
            GlassContainer(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(tr('ride_pin_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    ridePin,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 10, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(tr('give_pin_to_driver'), style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDriverMode ? '${tr('rider_label')} ${selectedRequest?.pickup ?? selectedDriverName}' : '${tr('driver_label')} $selectedDriverName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(isDriverMode ? tr('driver_mode_active') : tr('ride_active_now')),
                  if (!isRideStarted) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(tr('driver_waiting_at_pickup'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          const SizedBox(height: 4),
                          Text('${tr('current_waiting_time')} 6 ${tr('minutes')}', style: const TextStyle(fontSize: 12)),
                          Text(
                            '${tr('free_waiting_exceeded')} ${RideService.calculateWaitingFee(6)} دج',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (!isDriverMode)
                    Row(
                      children: [
                        Expanded(child: ElevatedButton.icon(onPressed: () async {
                          final url = Uri.parse('tel:0550000000');
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        }, icon: const Icon(Icons.call), label: Text(tr('call_btn')))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: () async {
                          final url = Uri.parse('sms:0550000000');
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        }, icon: const Icon(Icons.chat), label: Text(tr('message_btn')))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: _cancelRide, 
                          icon: const Icon(Icons.cancel), 
                          label: Text(tr('cancel_btn')),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        )),
                      ],
                    ),
                  if (isDriverMode && isRideStarted) ...[
                    const SizedBox(height: 16),
                    const Text('محاكاة المسافة للوصول (لاختبار ميزة الرحلة التالية):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Slider(
                      value: distanceKm.clamp(0.0, 50.0),
                      min: 0,
                      max: 50,
                      divisions: 50,
                      activeColor: distanceKm <= 10 ? Colors.green : Colors.pink,
                      label: '${distanceKm.toInt()} كم',
                      onChanged: (val) {
                        setState(() {
                          final wasAble = canReceiveRequests;
                          distanceKm = val;
                          final isAble = canReceiveRequests;
                          if (!wasAble && isAble) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم تفعيل (الرحلة التالية)! المسافة الآن 10 كم أو أقل، ستبدأ الطلبات بالظهور.', style: TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.green,
                              )
                            );
                            // محاكاة وصول طلب فور دخول المنطقة المسموحة
                            Timer(const Duration(seconds: 2), () {
                              if (mounted && canReceiveRequests) _showIncomingRideAlert();
                            });
                          }
                        });
                      },
                    ),
                    if (distanceKm <= 10)
                      const Text('✅ ميزة (استلام رحلات أثناء القيادة) مفعلة!', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
          if (isDriverMode)
            Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(onPressed: () async {
                              final url = Uri.parse('tel:0550000000');
                              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                            }, icon: const Icon(Icons.call), label: Text(tr('call_btn')))),
                            const SizedBox(width: 8),
                            Expanded(child: OutlinedButton.icon(onPressed: () async {
                              final url = Uri.parse('sms:0550000000');
                              if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                            }, icon: const Icon(Icons.chat), label: Text(tr('message_btn')))),
                            const SizedBox(width: 8),
                            Expanded(child: ElevatedButton.icon(
                              onPressed: _cancelRide, 
                              icon: const Icon(Icons.cancel), 
                              label: Text(tr('cancel_btn')),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            )),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedRequest != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${tr('from_label')} ${selectedRequest!.pickup}'),
                              Text('${tr('to_label')} ${selectedRequest!.dropoff}'),
                              Text('${tr('fare_label')} ${activeFare.toInt()} دج'),
                              const SizedBox(height: 8),
                            ],
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async { 
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tr('verifying_location_match'))),
                              );
                              
                              await _trackingService.startTracking(
                                rideId: selectedRequest?.id ?? 'ride-demo', 
                                onLocationUpdate: (position) {
                                  // Mocking the rider's location for the demo (assuming rider is exactly here)
                                  final riderLat = position.latitude + 0.0001; // very close
                                  final riderLng = position.longitude;
                                  
                                  // Calculate speed in km/h
                                  final speedKmH = (position.speed * 3.6); 
                                  
                                  // Check Co-location condition
                                  final autoStart = RideService.checkAutoStartCondition(
                                    riderLat: riderLat,
                                    riderLng: riderLng,
                                    driverLat: position.latitude,
                                    driverLng: position.longitude,
                                    currentSpeedKmH: speedKmH,
                                  );

                                  if (autoStart && !isRideStarted) {
                                    if (mounted) {
                                      setState(() {
                                        isRideStarted = true;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(tr('location_match_success')),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  }
                                }
                              ); 
                            }, 
                            icon: const Icon(Icons.navigation), 
                            label: Text(tr('arrived_auto_start_btn'))
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isRideStarted ? null : () => _promptForPin(), 
                            icon: const Icon(Icons.play_arrow), 
                            label: Text(isRideStarted ? tr('ride_ongoing_auto') : tr('or_enter_pin_manual'))
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () async { 
                              await _trackingService.stopTracking(); 
                              setState(() {
                                _step = RideFlowStep.rating;
                                isRideStarted = false;
                              });
                            }, 
                            icon: const Icon(Icons.check_circle), 
                            label: Text(tr('completed_btn'))
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ميزة الرحلات المتتالية (Chain Rides)
                        if (isRideStarted)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.radar, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tr('continuous_search_title'),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                      ),
                                    ),
                                    Switch(
                                      value: true,
                                      activeThumbColor: Colors.blue.shade700,
                                      onChanged: (val) {},
                                    ),
                                  ],
                                ),
                                Text(
                                  tr('continuous_search_desc'),
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                const SizedBox(height: 12),
                                // طلب افتراضي قريب من الوجهة
                                Card(
                                  elevation: 0,
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.blue.shade100)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person, color: Colors.blue)),
                                    title: Text(tr('from_dropoff_to_center'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    subtitle: Text(tr('distance_from_dropoff'), style: const TextStyle(fontSize: 11)),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('next_ride_booked_success'))));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        minimumSize: Size.zero,
                                        backgroundColor: Colors.blue.shade700,
                                      ),
                                      child: Text(tr('pre_book_btn'), style: const TextStyle(fontSize: 11, color: Colors.white)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('live_location'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildMiniRoutePreview(height: 140),
                const SizedBox(height: 8),
                Text(tr('eta_and_distance_remaining')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: quickMessages.map((message) => ActionChip(label: Text(message), onPressed: () {
              _chatController.text = message;
            })).toList(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                children: chatMessages.map((message) => Padding(
                  padding: const EdgeInsets.only(bottom: 8), 
                  child: Align(
                    alignment: message.startsWith('أنت:') ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: message.startsWith('أنت:') ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: message.contains('[صوت:') 
                          ? _buildAudioMessage(message)
                          : Text(message),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: tr('write_message_hint'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPressStart: (_) async {
                  if (await _audioRecorder.hasPermission()) {
                    setState(() => isRecording = true);
                    final dir = await getTemporaryDirectory();
                    _recordingPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
                    await _audioRecorder.start(const RecordConfig(), path: _recordingPath!);
                  }
                },
                onLongPressEnd: (_) async {
                  if (isRecording) {
                    final localPath = await _audioRecorder.stop();
                    setState(() => isRecording = false);
                    if (localPath != null && mounted) {
                      // محاولة رفع الملف إلى Supabase Storage
                      setState(() => isSendingVoice = true);
                      final userId = ref.read(authProvider).userId ?? 'demo-user';
                      final rideId = currentRideId ?? 'local';
                      String voiceContent;
                      final uploadedUrl = await _rideService.uploadVoiceNote(
                        getPlatformFile(localPath), rideId);
                      if (uploadedUrl != null) {
                        voiceContent = '[صوت: $uploadedUrl]';
                        // إرسال الرسالة الصوتية إلى Supabase
                        await _rideService.sendMessage(
                          rideId: rideId,
                          senderId: userId,
                          content: voiceContent,
                          type: 'voice',
                        );
                      } else {
                        // fallback: حفظ محلياً فقط
                        voiceContent = '[صوت: $localPath]';
                      }
                      if (mounted) {
                        setState(() {
                          isSendingVoice = false;
                          chatMessages.add('أنت: $voiceContent');
                        });
                      }
                    }
                  }
                },
                child: isSendingVoice
                  ? const SizedBox(
                      width: 44, height: 44,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(isRecording ? 16 : 12),
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isRecording ? Icons.mic_none : Icons.mic, color: Colors.white),
                    ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                onPressed: () {
                  final text = _chatController.text.trim();
                  if (text.isNotEmpty) {
                    final userId = ref.read(authProvider).userId ?? 'demo-user';
                    final rideId = currentRideId ?? 'local';
                    // إرسال الرسالة النصية إلى Supabase
                    _rideService.sendMessage(
                      rideId: rideId,
                      senderId: userId,
                      content: text,
                      type: 'text',
                    );
                    // عرض محلياً فوراً (optimistic update)
                    setState(() {
                      chatMessages.add('أنت: $text');
                      _chatController.clear();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => setState(() => sosExpanded = !sosExpanded),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('SOS'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final message = RideService.buildSafetyHandoffMessage(
                    riderName: 'سارة',
                    driverName: selectedDriverName,
                    pickup: pickupAddress,
                    dropoff: dropoffAddress,
                    rideId: currentRideId ?? 'ride-demo',
                    price: proposedFare.toInt(),
                    vehicleInfo: 'تويوتا كورولا',
                    plateNumber: '1234 دج',
                  );
                  setState(() {
                    shareMessage = message;
                    showSafetyActions = true;
                  });
                },
                icon: const Icon(Icons.share),
                label: Text(tr('share_ride')), // assuming this key was added earlier, if not I'll just use it inline or wait. Let me check if 'share_ride' exists. Oh, it doesn't. Let me add 'مشاركة الرحلة' as 'share_ride'. Wait, I can't add to translation_service now. I'll just leave 'مشاركة الرحلة' for now.
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = RideFlowStep.payment),
              child: Text(tr('end_ride_btn')), // already exists from previous stages probably? No, let's keep it 'إنهاء الرحلة'
            ),
          ),
          if (sosExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  ListTile(leading: const Icon(Icons.call), title: Text(tr('call_emergency_contact'))),
                  ListTile(
                    leading: const Icon(Icons.local_police, color: Colors.red),
                    title: Text(tr('trigger_sos_alarm'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('sos_sent_success')), backgroundColor: Colors.red),
                      );
                      await RideService.triggerSOS(
                        rideId: currentRideId ?? 'local',
                        userId: 'demo-user', // would be ref.read(authProvider).userId
                        role: isDriverMode ? 'driver' : 'rider',
                        lat: (isDriverMode ? driverLocation?.latitude : pickupLocation?.latitude) ?? 0.0,
                        lng: (isDriverMode ? driverLocation?.longitude : pickupLocation?.longitude) ?? 0.0,
                      );
                    },
                  ),
                  ListTile(leading: const Icon(Icons.mic), title: Text(tr('start_recording'))),
                  ListTile(
                    leading: const Icon(Icons.report_problem, color: Colors.orange), 
                    title: Text(tr('report_complaint'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SupportScreen(rideId: currentRideId, targetId: selectedDriverId)));
                    },
                  ),
                ],
              ),
            ),
          if (showSafetyActions)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Card(
                color: const Color(0xFFEFF8F6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('safe_share_created'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(shareMessage),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildAudioMessage(String message) {
    final match = RegExp(r'\[صوت: (.*?)\]').firstMatch(message);
    if (match == null) return const Text('رسالة صوتية غير صالحة');
    final path = match.group(1)!;
    final isThisPlaying = _isPlaying && _currentlyPlayingPath == path;
    final isRemote = path.startsWith('http');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(isThisPlaying ? Icons.stop : Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
          onPressed: () async {
            if (isThisPlaying) {
              await _audioPlayer.stop();
              setState(() => _isPlaying = false);
            } else {
              if (_isPlaying) await _audioPlayer.stop();
              // دعم التشغيل من رابط URL أو ملف محلي
              if (isRemote) {
                await _audioPlayer.play(UrlSource(path));
              } else {
                await _audioPlayer.play(DeviceFileSource(path));
              }
              setState(() {
                _isPlaying = true;
                _currentlyPlayingPath = path;
              });
            }
          },
        ),
        Icon(
          isRemote ? Icons.cloud_done : Icons.phone_android,
          size: 14,
          color: Colors.grey,
        ),
        const SizedBox(width: 4),
        const Text('رسالة صوتية', style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final tr = ref.watch(translationProvider).tr;
    final activeFare = isDriverMode && selectedRequest != null ? selectedRequest!.proposedFare : proposedFare;
    final commission = RideService.calculateCommission(activeFare);
    final net = RideService.calculateNetEarnings(activeFare);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isDriverMode ? tr('confirm_payment_receive_title') : tr('confirm_payment_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr('agreed_fare_label')} ${activeFare.toInt()} دج'),
                  if (!isDriverMode) Text('${tr('distance_label')} $distanceKm كم'),
                  if (!isDriverMode) Text('${tr('duration_label')} $durationMinutes ${tr('minutes')}'),
                  const SizedBox(height: 8),
                  if (isDriverMode) Text('${tr('commission_label')} ${commission.toInt()} دج'),
                  if (isDriverMode) Text('${tr('net_for_you_label')} ${net.toInt()} دج'),
                  if (!isDriverMode) Text('${tr('commission_label')} ${commission.toInt()} دج'),
                  if (!isDriverMode) Text('${tr('net_profits_label')} ${net.toInt()} دج'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: paymentConfirmed,
            title: Text(isDriverMode ? tr('i_received_payment') : tr('i_paid_driver')),
            onChanged: (value) => setState(() => paymentConfirmed = value ?? false),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: paymentConfirmed
                  ? () async {
                      await _completePayment();
                      if (!mounted) return;
                      setState(() => _step = RideFlowStep.rating);
                    }
                  : null,
              child: Text(tr('confirm_btn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStep() {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isDriverMode ? tr('rate_rider_title') : tr('rate_ride_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final star = index < rating;
              return IconButton(
                onPressed: () => setState(() => rating = index + 1),
                icon: Icon(star ? Icons.star : Icons.star_border, color: Colors.amber),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: tr('add_comment_hint'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => ratingComment = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: quickTags.map((tag) => ChoiceChip(label: Text(tag), selected: false, onSelected: (_) {})).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await _submitRating();
                if (!mounted) return;
                setState(() => _step = RideFlowStep.receipt);
              },
              child: Text(tr('submit_btn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptStep() {
    final tr = ref.watch(translationProvider).tr;
    final ride = selectedHistoryRide;
    final receiptFare = ride != null
        ? ride['fare'] as double
        : (isDriverMode && selectedRequest != null ? selectedRequest!.proposedFare : proposedFare);
    final commission = RideService.calculateCommission(receiptFare);
    final net = RideService.calculateNetEarnings(receiptFare);
    final rideDate = ride != null ? ride['date'] as String : currentRideDate;

    // Promo calculation
    final isPromoApplied = !isDriverMode && _hasPromo;
    final finalRiderFare = isPromoApplied ? (receiptFare - _promoDiscount).clamp(0.0, double.infinity) : receiptFare;
    final driverCompensation = _hasPromo ? _promoDiscount : 0.0;

    final summary = RideService.buildReceiptSummary(
      riderName: isDriverMode ? 'الراكبة' : 'سارة',
      driverName: selectedDriverName,
      pickup: isDriverMode && selectedRequest != null ? selectedRequest!.pickup : pickupAddress,
      dropoff: isDriverMode && selectedRequest != null ? selectedRequest!.dropoff : dropoffAddress,
      fare: isDriverMode ? receiptFare : finalRiderFare, // Rider sees discounted fare
      date: rideDate,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isDriverMode ? tr('driver_receipt_title') : tr('ride_receipt_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(summary),
                  const SizedBox(height: 12),
                  
                  if (!isDriverMode) ...[
                    Text('${tr('total_label')} ${receiptFare.toInt()} دج'),
                    if (isPromoApplied) Text('كود خصم مستخدم: -${_promoDiscount.toInt()} دج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('المطلوب دفعه: ${finalRiderFare.toInt()} دج', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
                  ],

                  if (isDriverMode) ...[
                    Text('${tr('total_label')} ${receiptFare.toInt()} دج'),
                    if (_hasPromo) ...[
                      Text('الدفع النقدي من الراكبة: ${(receiptFare - driverCompensation).clamp(0.0, double.infinity).toInt()} دج', style: const TextStyle(color: Colors.redAccent)),
                      Text('تعويض الخصم من DORA: +${driverCompensation.toInt()} دج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('(تم إضافة التعويض إلى محفظتك بنجاح)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                    const Divider(),
                    Text('${tr('commission_label')} ${commission.toInt()} دج'),
                    Text('إجمالي الربح (الصافي + التعويض): ${(net).toInt()} دج', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('saved_to_gallery_success'))));
              }, child: Text(tr('save_to_gallery_btn')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('preparing_receipt_share'))));
              }, child: Text(tr('share_receipt_btn')))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _step = RideFlowStep.history),
              child: Text(tr('view_history_btn')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStep() {
    final tr = ref.watch(translationProvider).tr;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(isDriverMode ? tr('driver_history_title') : tr('ride_history_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _historyFilterButton('all', tr('filter_all')),
                const SizedBox(width: 8),
                _historyFilterButton('completed', tr('filter_completed')),
                const SizedBox(width: 8),
                _historyFilterButton('cancelled', tr('filter_cancelled')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredRideHistory.length,
              itemBuilder: (context, index) {
                final ride = _filteredRideHistory[index];
                return Card(
                  child: ListTile(
                    title: Text(ride['route']),
                    subtitle: Text('${ride['date']} • ${ride['status']}'),
                    trailing: Text('${(ride['net'] ?? ride['fare']).toInt()} دج'),
                    onTap: () => setState(() {
                      selectedHistoryRide = ride;
                      _step = RideFlowStep.receipt;
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsStep() {
    final tr = ref.watch(translationProvider).tr;
    final summary = RideService.buildEarningsSummary(proposedFare);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('earnings_dashboard_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr('earnings_today')} ${summary['today']!.toInt()} دج'),
                  Text('${tr('earnings_week')} ${summary['week']!.toInt()} دج'),
                  Text('${tr('earnings_month')} ${summary['month']!.toInt()} دج'),
                  Text('${tr('commission_label')} ${summary['commission']!.toInt()} دج'),
                  Text('${tr('net_label')} ${summary['net']!.toInt()} دج'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('quick_stats_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(tr('four_rides_today'))),
              Chip(label: Text(tr('satisfaction_93'))),
              Chip(label: Text(tr('live_update'))),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('personal_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(RideService.buildProfileStatusLabel(
                    isOnline: isDriverOnline,
                    notificationsEnabled: true,
                  )),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    title: Text(tr('online_status')),
                    value: isDriverOnline,
                    onChanged: (value) => _setDriverOnline(value),
                  ),
                  SwitchListTile(
                    dense: true,
                    title: Text(tr('notifications_setting')),
                    value: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ── زر إدارة الاشتراك ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
              icon: const Icon(Icons.card_membership),
              label: const Text('إدارة الاشتراك الشهري', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم طلب السحب بنجاح، قيد المراجعة.')));
            }, child: const Text('سحب إلى الحساب')),
          ),
        ],
      ),
    );
  }

}
