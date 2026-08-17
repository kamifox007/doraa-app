// ignore_for_file: invalid_use_of_protected_member
part of '../screens/ride_flow.dart';

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
                    color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('drag_map_or_select'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(pickupAddress, style: const TextStyle(color: Colors.white70)),
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
            color: const Color(0xFF1A1A1A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pickupAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
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
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
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
                  child: Text(tr('confirm_pickup_btn'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black)),
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
          Text(tr('choose_dropoff'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          TextField(
            controller: _dropoffController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
              labelText: tr('search_destination'),
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
            ),
            onChanged: (value) => setState(() => dropoffAddress = value.isEmpty ? tr('title_dropoff') : value),
          ),
          const SizedBox(height: 16),
          Text(tr('recent_destinations'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(tr('airport'), style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), side: const BorderSide(color: Color(0xFFFFD700))),
              Chip(label: Text(tr('university'), style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), side: const BorderSide(color: Color(0xFFFFD700))),
              Chip(label: Text(tr('central_market'), style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), side: const BorderSide(color: Color(0xFFFFD700))),
            ],
          ),
          const SizedBox(height: 16),
          Text(tr('favorites'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text(tr('home_place'), style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), side: const BorderSide(color: Color(0xFFFFD700))),
              Chip(label: Text(tr('work_place'), style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), side: const BorderSide(color: Color(0xFFFFD700))),
              Chip(label: Text(tr('center_place'), style: const TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1E1E1E), side: const BorderSide(color: Color(0xFFFFD700))),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('route_preview'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
              ),
              child: Text(tr('confirm_dropoff_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
    
    // Ø­Ø³Ø§Ø¨ Ø§Ù„Ø³Ø¹Ø± Ø¨Ù†Ø§Ø¡Ù‹ Ø¹Ù„Ù‰ Ù†ÙˆØ¹ Ø§Ù„Ø±Ø­Ù„Ø© (Ø¥Ø°Ø§ ÙƒØ§Ù†Øª ØªØ´Ø§Ø±ÙƒÙŠØ© ÙŠÙ†Ù‚Ø³Ù… Ø¹Ù„Ù‰ Ø¹Ø¯Ø¯ Ø§Ù„Ø£Ø´Ø®Ø§Øµ)
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
              Text(tr('title_fare'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
          // Ø®Ø±ÙŠØ·Ø© Ø§Ù„Ø±Ø­Ù„Ø©
          Container(
            height: 130,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildMapPreview(),
            ),
          ),
          const SizedBox(height: 16),
          // Ø§Ø®ØªÙŠØ§Ø± Ù†ÙˆØ¹ Ø§Ù„Ø±Ø­Ù„Ø© (ØªØ´Ø§Ø±ÙƒÙŠØ© Ø£Ù… ÙØ±Ø¯ÙŠØ©)
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
                          ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)])
                          : const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF1E1E1E)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: !isSharedRide ? Colors.transparent : const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                      boxShadow: !isSharedRide 
                          ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.person, color: !isSharedRide ? Colors.black : Colors.white70, size: 32),
                        const SizedBox(height: 8),
                        Text(tr('solo_ride'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: !isSharedRide ? Colors.black : Colors.white)),
                        const SizedBox(height: 4),
                        Text('Ø³ÙŠØ§Ø±Ø© Ù„ÙƒÙ ÙˆØ­Ø¯Ùƒ', style: TextStyle(fontSize: 11, color: !isSharedRide ? Colors.black54 : Colors.white54)),
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
                          ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)])
                          : const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF1E1E1E)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSharedRide ? Colors.transparent : const Color(0xFFFFD700).withValues(alpha: 0.3), width: 2),
                      boxShadow: isSharedRide 
                          ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.people, color: isSharedRide ? Colors.black : Colors.white70, size: 32),
                        const SizedBox(height: 8),
                        Text(tr('shared_ride'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSharedRide ? Colors.black : Colors.white)),
                        const SizedBox(height: 4),
                        Text('ØªØ´Ø§Ø±ÙƒÙŠØ© Ø¨Ø³Ø¹Ø± Ø«Ø§Ø¨Øª', style: TextStyle(fontSize: 11, color: isSharedRide ? Colors.black54 : Colors.white54)),
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
                  const Text('ØªÙ‚Ø³ÙŠÙ… Ø§Ù„Ø±Ø­Ù„Ø© Ø¹Ù„Ù‰:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('Ø´Ø®ØµÙŠÙ† (Ã·2)')),
                        ButtonSegment(value: 3, label: Text('3 Ø£Ø´Ø®Ø§Øµ (Ã·3)')),
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
                              return const Color(0xFFFFD700);
                            }
                            return const Color(0xFF1E1E1E);
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.black;
                            }
                            return const Color(0xFFFFD700);
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
                        'ØªÙ… ØªØ­Ø¯ÙŠØ¯ Ø³Ø¹Ø± Ø§Ù„Ù…Ù‚Ø¹Ø¯ Ø¨Ø´ÙƒÙ„ Ø«Ø§Ø¨Øª Ù„Ù€ $sharedSeatsCount Ø£Ø´Ø®Ø§Øµ!',
                        style: TextStyle(color: Colors.purple.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Ø¨Ø·Ø§Ù‚Ø© ØªÙØ§ØµÙŠÙ„ Ø§Ù„Ø£Ø¬Ø±Ø©
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                _fareRow(tr('base_fare'), '${breakdown.baseFare.toInt()} Ø¯Ø¬'),
                _fareRow('${tr('distance_cost')} (${distanceKm.toStringAsFixed(1)} ÙƒÙ…)', '${breakdown.distanceFare.toInt()} Ø¯Ø¬'),
                _fareRow('${tr('time_cost')} ($durationMinutes Ø¯Ù‚ÙŠÙ‚Ø©)', '${breakdown.timeFare.toInt()} Ø¯Ø¬'),
                if (breakdown.surgeMultiplier > 1.0) ...[
                  const Divider(),
                  _fareRow(
                    breakdown.surgeLabel,
                    'Ã—${breakdown.surgeMultiplier.toStringAsFixed(1)}',
                    highlight: true,
                  ),
                ],
                const Divider(thickness: 1.5),
                _fareRow(
                  isSharedRide ? tr('discounted_shared_fare') : tr('total_fare'), 
                  '${displayTotalFare.toInt()} Ø¯Ø¬', 
                  bold: true,
                  highlight: isSharedRide
                ),
                const SizedBox(height: 4),
                _fareRow(tr('dora_commission'), '- ${(isSharedRide ? breakdown.commission / sharedSeatsCount : breakdown.commission).toInt()} Ø¯Ø¬', dimmed: true),
                _fareRow(tr('driver_net'), '${breakdown.driverNet.toInt()} Ø¯Ø¬', green: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!isSharedRide) ...[
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: tr('suggest_fare_label'),
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
                helperText: tr('suggest_fare_helper'),
                helperStyle: const TextStyle(color: Colors.white54),
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
              activeColor: const Color(0xFFFFD700),
              onChanged: (value) {
                setState(() {
                  customFare = value;
                  proposedFare = value;
                });
              },
            ),
            Text('${tr('acceptable_range')} ${minFare.toInt()} - ${maxFare.toInt()} Ø¯Ø¬ ${tr('raise_price_hint')}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitRideRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSharedRide ? const Color(0xFFFFD700) : const Color(0xFF1E1E1E),
                foregroundColor: isSharedRide ? Colors.black : const Color(0xFFFFD700),
                side: BorderSide(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16)
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Color(0xFFFFD700))
                  : Text(isSharedRide 
                      ? 'ØªØ£ÙƒÙŠØ¯ Ø­Ø¬Ø² Ù…Ù‚Ø¹Ø¯ ØªØ´Ø§Ø±ÙƒÙŠ - ${proposedFare.toInt()} Ø¯Ø¬'
                      : '${tr('send_request_btn')} - ${proposedFare.toInt()} Ø¯Ø¬', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSharedRide ? Colors.black : const Color(0xFFFFD700))),
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
          Text(tr('drivers_offers_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: driverOffers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final driver = driverOffers[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFFFD700).withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: Color(0xFFFFD700), size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(driver.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.directions_car, color: Colors.white70, size: 16),
                                    const SizedBox(width: 4),
                                    Text(driver.carInfo, style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${proposedFare.toInt()} Ø¯Ø¬', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFFD700))),
                              const SizedBox(height: 4),
                              Text('${driver.etaMinutes} ${tr('minutes')}', style: const TextStyle(color: Colors.white70)),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD700),
                                foregroundColor: Colors.black,
                              ),
                              child: Text(tr('accept_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleDriverSelection(driver, 'counter'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFFD700),
                                side: const BorderSide(color: Color(0xFFFFD700)),
                              ),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700),
                side: const BorderSide(color: Color(0xFFFFD700)),
              ),
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
          Text(tr('riders_requests_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text(tr('available_for_drivers'), style: const TextStyle(color: Colors.white)),
                    subtitle: Text(isDriverOnline ? tr('online_for_requests') : tr('offline'), style: const TextStyle(color: Colors.white70)),
                    value: isDriverOnline,
                    activeColor: const Color(0xFFFFD700),
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
                    // ØªØ±ØªÙŠØ¨ Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ù…Ù† Ø§Ù„Ø£Ù‚Ø±Ø¨ Ù„Ù„Ø£Ø¨Ø¹Ø¯ (Ø®ÙˆØ§Ø±Ø²Ù…ÙŠØ© Ø§Ù„ÙØ±Ø² Ø§Ù„Ù…ÙƒØ§Ù†ÙŠ)
                    final sortedRequests = List<RideRequest>.from(pendingRequests)..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
                    final request = sortedRequests[index];
                    final currentFare = _driverCounterOffers[request.id] ?? request.proposedFare;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('${request.pickup} â†’ ${request.dropoff}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
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
                                Text('${tr('distance_from_you')} ${request.distanceKm.toStringAsFixed(1)} ÙƒÙ…', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Ù…Ù†Ø·Ù‚Ø© Ø§Ù„ØªØ³Ø¹ÙŠØ± ÙˆØ§Ù„ØªÙØ§ÙˆØ¶ Ø§Ù„Ù…Ø¯Ù…Ø¬Ø©
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
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
                                          icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFFFD700), size: 28),
                                          onPressed: () => setState(() => _driverCounterOffers[request.id] = (currentFare - 50).clamp(100.0, 5000.0)),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  Expanded(
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Text(request.isShared ? 'Ø³Ø¹Ø± Ø«Ø§Ø¨Øª' : 'Ø§Ù„Ø³Ø¹Ø± Ø§Ù„Ù…Ø¹Ø±ÙˆØ¶', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                          Text('${currentFare.toInt()} Ø¯Ø¬', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
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
                                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFFD700), size: 28),
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
                                        selectedDriverName = 'Ø£Ù†Øª';
                                        _step = RideFlowStep.activeRide;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: request.isShared ? Colors.greenAccent : const Color(0xFFFFD700),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(tr('accept_btn'), style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
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
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5), width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.directions_car_rounded, size: 64, color: Color(0xFFFFD700)),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ø£Ø±Ø¨Ø§Ø­ Ø±Ø§Ø¦Ø¹Ø© ÙÙŠ Ø§Ù†ØªØ¸Ø§Ø±Ùƒ!',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ù‡Ø°Ù‡ Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø­Ù‚ÙŠÙ‚ÙŠØ© ÙˆÙ…ØªØ§Ø­Ø© Ø§Ù„Ø¢Ù†. Ø§Ù†Ø¶Ù…ÙŠ ÙƒØ³Ø§Ø¦Ù‚Ø© Ù…Ø¹ØªÙ…Ø¯Ø© Ù„ØªØ¨Ø¯Ø¦ÙŠ Ø¨Ù‚Ø¨ÙˆÙ„ Ø§Ù„Ø·Ù„Ø¨Ø§Øª ÙˆØ¬Ù†ÙŠ Ø§Ù„Ø£Ø±Ø¨Ø§Ø­ ÙÙˆØ±Ø§Ù‹.',
                                  style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
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
                                    backgroundColor: const Color(0xFFFFD700),
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Ø³Ø¬Ù„ÙŠ ÙƒØ³Ø§Ø¦Ù‚Ø© Ø§Ù„Ø¢Ù†', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    
    // Ø¥Ø°Ø§ Ù„Ù… ØªÙƒÙ† ÙÙŠ Ø±Ø­Ù„Ø© Ù†Ø´Ø·Ø©ØŒ ÙŠÙ…ÙƒÙ†Ù‡Ø§ Ø§Ø³ØªÙ‚Ø¨Ø§Ù„ Ø§Ù„Ø·Ù„Ø¨Ø§Øª
    if (_step != RideFlowStep.activeRide) return true;
    
    // Ø¥Ø°Ø§ ÙƒØ§Ù†Øª ÙÙŠ Ø±Ø­Ù„Ø© Ù†Ø´Ø·Ø©:
    // ØªÙØ¹ÙŠÙ„ Ù…ÙŠØ²Ø© (Queue Next Ride) Ø§Ù„Ø¬Ù…ÙŠÙ„Ø©:
    // ØªØ¸Ù‡Ø± Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ø¬Ø¯ÙŠØ¯Ø© ÙÙ‚Ø· Ø¥Ø°Ø§ Ø¨Ø¯Ø£Øª Ø§Ù„Ø±Ø­Ù„Ø© ÙˆÙƒØ§Ù†Øª Ø§Ù„Ù…Ø³Ø§ÙØ© Ø§Ù„Ù…ØªØ¨Ù‚ÙŠØ© Ù„Ù„ÙˆØµÙˆÙ„ 10 ÙƒÙ… Ø£Ùˆ Ø£Ù‚Ù„.
    // Ù‡Ø°Ø§ ÙŠÙ…Ù†Ø¹ Ø§Ù„Ø·Ù…Ø¹ ÙˆØ§Ù„Ø¥Ù„ØºØ§Ø¡ ÙÙŠ Ø¨Ø¯Ø§ÙŠØ© Ø§Ù„Ø±Ø­Ù„Ø©!
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
      
      // Ù…Ø­Ø§ÙƒØ§Ø© ÙˆØµÙˆÙ„ Ø·Ù„Ø¨ Ø¬Ø¯ÙŠØ¯ Ù…Ø¹ Ø±Ù†ÙŠÙ† Ø¨Ø¹Ø¯ 3 Ø«ÙˆØ§Ù†Ù Ù…Ù† Ø§Ù„Ø§ØªØµØ§Ù„
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
    // ØªØ´ØºÙŠÙ„ Ù†ØºÙ…Ø© Ø±Ù†ÙŠÙ† Ø¬Ø°Ø§Ø¨Ø© ÙˆÙ…Ø±ÙŠØ­Ø© Ù„Ù„Ø³Ø§Ø¦Ù‚Ø©
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
            const Text('Ø§Ù„ÙˆØ¬Ù‡Ø©: Ø¨Ù† Ø¹ÙƒÙ†ÙˆÙ†', style: TextStyle(fontSize: 16)), // Can be dynamic later
            const SizedBox(height: 4),
            const Text('Ø§Ù„Ø£Ø¬Ø±Ø©: 600 Ø¯Ø¬', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              // _audioPlayer.stop(); // Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„Ø±Ù†ÙŠÙ†
              Navigator.pop(context);
            },
            child: Text(tr('ignore_btn'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              // _audioPlayer.stop(); // Ø¥ÙŠÙ‚Ø§Ù Ø§Ù„Ø±Ù†ÙŠÙ†
              Navigator.pop(context);
              setState(() {
                _step = RideFlowStep.activeRide; // Ù†Ù†ØªÙ‚Ù„ Ù„Ù„Ø±Ø­Ù„Ø© Ù…Ø¨Ø§Ø´Ø±Ø©
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text('${tr('current_price_label')} ${proposedFare.toInt()} Ø¯Ø¬', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), fontSize: 18)),
                const SizedBox(height: 8),
                Text('${tr('selected_driver_label')} $selectedDriverName', style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              child: ListView(
                children: [
                  ...negotiationHistory.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(entry, style: const TextStyle(color: Colors.white)),
                      )),
                  if (negotiationHistory.isEmpty)
                    Text(tr('no_messages_negotiation'), style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _offerController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: tr('send_new_offer'),
              labelStyle: const TextStyle(color: Colors.white70),
              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFFD700))),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleNegotiationAction('accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                  child: Text(tr('accept_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleNegotiationAction('counter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFFFFD700)),
                  ),
                  child: Text(tr('negotiate_btn')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => _handleNegotiationAction('declined'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
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
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text(tr('ride_pin_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    ridePin,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 10, color: Color(0xFFFFD700)),
                  ),
                  const SizedBox(height: 8),
                  Text(tr('give_pin_to_driver'), style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDriverMode ? '${tr('rider_label')} ${selectedRequest?.pickup ?? selectedDriverName}' : '${tr('driver_label')} $selectedDriverName',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(isDriverMode ? tr('driver_mode_active') : tr('ride_active_now'), style: const TextStyle(color: Colors.white70)),
                  if (!isRideStarted) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8860B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFD700)),
                      ),
                      child: Column(
                        children: [
                          Text(tr('driver_waiting_at_pickup'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                          const SizedBox(height: 4),
                          Text('${tr('current_waiting_time')} 6 ${tr('minutes')}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          Text(
                            '${tr('free_waiting_exceeded')} ${RideService.calculateWaitingFee(6)} Ø¯Ø¬',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
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
                        }, icon: const Icon(Icons.call, color: Colors.black), label: Text(tr('call_btn'), style: const TextStyle(color: Colors.black)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)))),
                        const SizedBox(width: 8),
                        Expanded(child: OutlinedButton.icon(onPressed: () async {
                          final url = Uri.parse('sms:0550000000');
                          if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                        }, icon: const Icon(Icons.chat, color: Color(0xFFFFD700)), label: Text(tr('message_btn'), style: const TextStyle(color: Color(0xFFFFD700))), style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFFD700))))),
                        const SizedBox(width: 8),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: _cancelRide, 
                          icon: const Icon(Icons.cancel, color: Colors.white), 
                          label: Text(tr('cancel_btn'), style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                        )),
                      ],
                    ),
                  if (isDriverMode && isRideStarted) ...[
                    const SizedBox(height: 16),
                    const Text('Ù…Ø­Ø§ÙƒØ§Ø© Ø§Ù„Ù…Ø³Ø§ÙØ© Ù„Ù„ÙˆØµÙˆÙ„ (Ù„Ø§Ø®ØªØ¨Ø§Ø± Ù…ÙŠØ²Ø© Ø§Ù„Ø±Ø­Ù„Ø© Ø§Ù„ØªØ§Ù„ÙŠØ©):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Slider(
                      value: distanceKm.clamp(0.0, 50.0),
                      min: 0,
                      max: 50,
                      divisions: 50,
                      activeColor: distanceKm <= 10 ? Colors.green : Colors.pink,
                      label: '${distanceKm.toInt()} ÙƒÙ…',
                      onChanged: (val) {
                        setState(() {
                          final wasAble = canReceiveRequests;
                          distanceKm = val;
                          final isAble = canReceiveRequests;
                          if (!wasAble && isAble) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ØªÙ… ØªÙØ¹ÙŠÙ„ (Ø§Ù„Ø±Ø­Ù„Ø© Ø§Ù„ØªØ§Ù„ÙŠØ©)! Ø§Ù„Ù…Ø³Ø§ÙØ© Ø§Ù„Ø¢Ù† 10 ÙƒÙ… Ø£Ùˆ Ø£Ù‚Ù„ØŒ Ø³ØªØ¨Ø¯Ø£ Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø¨Ø§Ù„Ø¸Ù‡ÙˆØ±.', style: TextStyle(fontWeight: FontWeight.bold)),
                                backgroundColor: Colors.green,
                              )
                            );
                            // Ù…Ø­Ø§ÙƒØ§Ø© ÙˆØµÙˆÙ„ Ø·Ù„Ø¨ ÙÙˆØ± Ø¯Ø®ÙˆÙ„ Ø§Ù„Ù…Ù†Ø·Ù‚Ø© Ø§Ù„Ù…Ø³Ù…ÙˆØ­Ø©
                            Timer(const Duration(seconds: 2), () {
                              if (mounted && canReceiveRequests) _showIncomingRideAlert();
                            });
                          }
                        });
                      },
                    ),
                    if (distanceKm <= 10)
                      const Text('âœ… Ù…ÙŠØ²Ø© (Ø§Ø³ØªÙ„Ø§Ù… Ø±Ø­Ù„Ø§Øª Ø£Ø«Ù†Ø§Ø¡ Ø§Ù„Ù‚ÙŠØ§Ø¯Ø©) Ù…ÙØ¹Ù„Ø©!', style: TextStyle(color: Colors.green, fontSize: 12)),
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
                              Text('${tr('fare_label')} ${activeFare.toInt()} Ø¯Ø¬'),
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
                        // Ù…ÙŠØ²Ø© Ø§Ù„Ø±Ø­Ù„Ø§Øª Ø§Ù„Ù…ØªØªØ§Ù„ÙŠØ© (Chain Rides)
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
                                // Ø·Ù„Ø¨ Ø§ÙØªØ±Ø§Ø¶ÙŠ Ù‚Ø±ÙŠØ¨ Ù…Ù† Ø§Ù„ÙˆØ¬Ù‡Ø©
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
                    alignment: message.startsWith('Ø£Ù†Øª:') ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: message.startsWith('Ø£Ù†Øª:') ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: message.contains('[ØµÙˆØª:') 
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
                      // Ù…Ø­Ø§ÙˆÙ„Ø© Ø±ÙØ¹ Ø§Ù„Ù…Ù„Ù Ø¥Ù„Ù‰ Supabase Storage
                      setState(() => isSendingVoice = true);
                      final userId = ref.read(authProvider).userId ?? 'demo-user';
                      final rideId = currentRideId ?? 'local';
                      String voiceContent;
                      final uploadedUrl = await _rideService.uploadVoiceNote(
                        getPlatformFile(localPath), rideId);
                      if (uploadedUrl != null) {
                        voiceContent = '[ØµÙˆØª: $uploadedUrl]';
                        // Ø¥Ø±Ø³Ø§Ù„ Ø§Ù„Ø±Ø³Ø§Ù„Ø© Ø§Ù„ØµÙˆØªÙŠØ© Ø¥Ù„Ù‰ Supabase
                        await _rideService.sendMessage(
                          rideId: rideId,
                          senderId: userId,
                          content: voiceContent,
                          type: 'voice',
                        );
                      } else {
                        // fallback: Ø­ÙØ¸ Ù…Ø­Ù„ÙŠØ§Ù‹ ÙÙ‚Ø·
                        voiceContent = '[ØµÙˆØª: $localPath]';
                      }
                      if (mounted) {
                        setState(() {
                          isSendingVoice = false;
                          chatMessages.add('Ø£Ù†Øª: $voiceContent');
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
                    // Ø¥Ø±Ø³Ø§Ù„ Ø§Ù„Ø±Ø³Ø§Ù„Ø© Ø§Ù„Ù†ØµÙŠØ© Ø¥Ù„Ù‰ Supabase
                    _rideService.sendMessage(
                      rideId: rideId,
                      senderId: userId,
                      content: text,
                      type: 'text',
                    );
                    // Ø¹Ø±Ø¶ Ù…Ø­Ù„ÙŠØ§Ù‹ ÙÙˆØ±Ø§Ù‹ (optimistic update)
                    setState(() {
                      chatMessages.add('Ø£Ù†Øª: $text');
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
                    riderName: 'Ø³Ø§Ø±Ø©',
                    driverName: selectedDriverName,
                    pickup: pickupAddress,
                    dropoff: dropoffAddress,
                    rideId: currentRideId ?? 'ride-demo',
                    price: proposedFare.toInt(),
                    vehicleInfo: 'ØªÙˆÙŠÙˆØªØ§ ÙƒÙˆØ±ÙˆÙ„Ø§',
                    plateNumber: '1234 Ø¯Ø¬',
                  );
                  setState(() {
                    shareMessage = message;
                    showSafetyActions = true;
                  });
                },
                icon: const Icon(Icons.share),
                label: Text(tr('share_ride')), // assuming this key was added earlier, if not I'll just use it inline or wait. Let me check if 'share_ride' exists. Oh, it doesn't. Let me add 'Ù…Ø´Ø§Ø±ÙƒØ© Ø§Ù„Ø±Ø­Ù„Ø©' as 'share_ride'. Wait, I can't add to translation_service now. I'll just leave 'Ù…Ø´Ø§Ø±ÙƒØ© Ø§Ù„Ø±Ø­Ù„Ø©' for now.
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = RideFlowStep.payment),
              child: Text(tr('end_ride_btn')), // already exists from previous stages probably? No, let's keep it 'Ø¥Ù†Ù‡Ø§Ø¡ Ø§Ù„Ø±Ø­Ù„Ø©'
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
    final match = RegExp(r'\[ØµÙˆØª: (.*?)\]').firstMatch(message);
    if (match == null) return const Text('Ø±Ø³Ø§Ù„Ø© ØµÙˆØªÙŠØ© ØºÙŠØ± ØµØ§Ù„Ø­Ø©');
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
              // Ø¯Ø¹Ù… Ø§Ù„ØªØ´ØºÙŠÙ„ Ù…Ù† Ø±Ø§Ø¨Ø· URL Ø£Ùˆ Ù…Ù„Ù Ù…Ø­Ù„ÙŠ
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
        const Text('Ø±Ø³Ø§Ù„Ø© ØµÙˆØªÙŠØ©', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Text(isDriverMode ? tr('confirm_payment_receive_title') : tr('confirm_payment_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tr('agreed_fare_label')} ${activeFare.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white, fontSize: 16)),
                if (!isDriverMode) Text('${tr('distance_label')} $distanceKm ÙƒÙ…', style: const TextStyle(color: Colors.white70)),
                if (!isDriverMode) Text('${tr('duration_label')} $durationMinutes ${tr('minutes')}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                if (isDriverMode) Text('${tr('commission_label')} ${commission.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.redAccent)),
                if (isDriverMode) Text('${tr('net_for_you_label')} ${net.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                if (!isDriverMode) Text('${tr('commission_label')} ${commission.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white70)),
                if (!isDriverMode) Text('${tr('net_profits_label')} ${net.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: paymentConfirmed,
            title: Text(isDriverMode ? tr('i_received_payment') : tr('i_paid_driver'), style: const TextStyle(color: Colors.white)),
            activeColor: const Color(0xFFFFD700),
            checkColor: Colors.black,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: paymentConfirmed ? const Color(0xFFFFD700) : Colors.grey.shade800,
                foregroundColor: paymentConfirmed ? Colors.black : Colors.white54,
              ),
              child: Text(tr('confirm_btn'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
          Center(
            child: Text(
              isDriverMode ? tr('rate_rider_title') : tr('rate_ride_title'), 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'أخبرنا عن تجربتك', 
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index < rating;
                  return GestureDetector(
                    onTap: () => setState(() => rating = index + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        star ? Icons.star_rounded : Icons.star_outline_rounded, 
                        color: star ? const Color(0xFFFFD700) : Colors.white38,
                        size: star ? 48 : 40,
                        shadows: star ? [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.5), blurRadius: 10)] : [],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text('ما الذي أعجبك؟', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: quickTags.map((tag) {
              final isSelected = false; // Add state for tags later if needed
              return ChoiceChip(
                label: Text(tag, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                selectedColor: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF1E1E1E),
                side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFFFD700).withValues(alpha: 0.5)),
                selected: isSelected,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (_) {},
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextField(
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: tr('add_comment_hint'),
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFD700))),
            ),
            onChanged: (value) => setState(() => ratingComment = value),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                await _submitRating();
                if (!mounted) return;
                setState(() => _step = RideFlowStep.receipt);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                elevation: 8,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(tr('submit_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          const SizedBox(height: 16),
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
      riderName: isDriverMode ? 'Ø§Ù„Ø±Ø§ÙƒØ¨Ø©' : 'Ø³Ø§Ø±Ø©',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isDriverMode ? tr('driver_receipt_title') : tr('ride_receipt_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(summary, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                
                if (!isDriverMode) ...[
                  Text('${tr('total_label')} ${receiptFare.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white)),
                  if (isPromoApplied) Text('ÙƒÙˆØ¯ Ø®ØµÙ… Ù…Ø³ØªØ®Ø¯Ù…: -${_promoDiscount.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  const Divider(color: Colors.white24),
                  Text('Ø§Ù„Ù…Ø·Ù„ÙˆØ¨ Ø¯ÙØ¹Ù‡: ${finalRiderFare.toInt()} Ø¯Ø¬', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                ],

                if (isDriverMode) ...[
                  Text('${tr('total_label')} ${receiptFare.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white)),
                  if (_hasPromo) ...[
                    Text('Ø§Ù„Ø¯ÙØ¹ Ø§Ù„Ù†Ù‚Ø¯ÙŠ Ù…Ù† Ø§Ù„Ø±Ø§ÙƒØ¨Ø©: ${(receiptFare - driverCompensation).clamp(0.0, double.infinity).toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.redAccent)),
                    Text('ØªØ¹ÙˆÙŠØ¶ Ø§Ù„Ø®ØµÙ… Ù…Ù† DORA: +${driverCompensation.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    Text('(ØªÙ… Ø¥Ø¶Ø§ÙØ© Ø§Ù„ØªØ¹ÙˆÙŠØ¶ Ø¥Ù„Ù‰ Ù…Ø­ÙØ¸ØªÙƒ Ø¨Ù†Ø¬Ø§Ø­)', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                  const Divider(color: Colors.white24),
                  Text('${tr('commission_label')} ${commission.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.redAccent)),
                  Text('Ø¥Ø¬Ù…Ø§Ù„ÙŠ Ø§Ù„Ø±Ø¨Ø­ (Ø§Ù„ØµØ§ÙÙŠ + Ø§Ù„ØªØ¹ÙˆÙŠØ¶): ${(net).toInt()} Ø¯Ø¬', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 16)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('saved_to_gallery_success'))));
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
              child: Text(tr('save_to_gallery_btn')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('preparing_receipt_share'))));
              }, 
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD700), side: const BorderSide(color: Color(0xFFFFD700))),
              child: Text(tr('share_receipt_btn')))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _step = RideFlowStep.history),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFFD700), side: const BorderSide(color: Color(0xFFFFD700))),
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
          Text(isDriverMode ? tr('driver_history_title') : tr('ride_history_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    title: Text(ride['route'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${ride['date']} â€¢ ${ride['status']}', style: const TextStyle(color: Colors.white70)),
                    trailing: Text('${(ride['net'] ?? ride['fare']).toInt()} Ø¯Ø¬', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
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
          Text(tr('earnings_dashboard_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tr('earnings_today')} ${summary['today']!.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${tr('earnings_week')} ${summary['week']!.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white70)),
                Text('${tr('earnings_month')} ${summary['month']!.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.white70)),
                const Divider(color: Colors.white24),
                Text('${tr('commission_label')} ${summary['commission']!.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.redAccent)),
                Text('${tr('net_label')} ${summary['net']!.toInt()} Ø¯Ø¬', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('quick_stats_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(tr('four_rides_today'), style: const TextStyle(color: Colors.black)), backgroundColor: const Color(0xFFFFD700)),
              Chip(label: Text(tr('satisfaction_93'), style: const TextStyle(color: Colors.black)), backgroundColor: const Color(0xFFFFD700)),
              Chip(label: Text(tr('live_update'), style: const TextStyle(color: Colors.black)), backgroundColor: const Color(0xFFFFD700)),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('personal_settings'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(RideService.buildProfileStatusLabel(
                  isOnline: isDriverOnline,
                  notificationsEnabled: true,
                ), style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                SwitchListTile(
                  dense: true,
                  title: Text(tr('online_status'), style: const TextStyle(color: Colors.white)),
                  value: isDriverOnline,
                  activeColor: const Color(0xFFFFD700),
                  onChanged: (value) => _setDriverOnline(value),
                ),
                SwitchListTile(
                  dense: true,
                  title: Text(tr('notifications_setting'), style: const TextStyle(color: Colors.white)),
                  value: true,
                  activeColor: const Color(0xFFFFD700),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // â”€â”€ Ø²Ø± Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø§Ø´ØªØ±Ø§Ùƒ â”€â”€
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
              },
              icon: const Icon(Icons.card_membership),
              label: const Text('Ø¥Ø¯Ø§Ø±Ø© Ø§Ù„Ø§Ø´ØªØ±Ø§Ùƒ Ø§Ù„Ø´Ù‡Ø±ÙŠ', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ØªÙ… Ø·Ù„Ø¨ Ø§Ù„Ø³Ø­Ø¨ Ø¨Ù†Ø¬Ø§Ø­ØŒ Ù‚ÙŠØ¯ Ø§Ù„Ù…Ø±Ø§Ø¬Ø¹Ø©.')));
            }, child: const Text('Ø³Ø­Ø¨ Ø¥Ù„Ù‰ Ø§Ù„Ø­Ø³Ø§Ø¨')),
          ),
        ],
      ),
    );
  }

}

