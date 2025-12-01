import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/app_localizations.dart';

class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage> {
  static const LatLng _tarUmtCenter = LatLng(3.2142, 101.7266);

  LatLng? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  CampusLocation? _selectedLocation;

  final List<CampusLocation> _campusLocations = const [
    // West Campus (with coordinates from campus_location.txt)
    CampusLocation(
      id: 'west_bangunan_tun_tan_siew_sin',
      name: 'Bangunan Tun Tan Siew Sin',
      campusZone: 'West',
      latitude: 3.214704,
      longitude: 101.726124,
    ),
    CampusLocation(
      id: 'west_bangunan_tun_dr_lim_liong_sik',
      name: 'Bangunan Tun Dr Lim Liong Sik',
      campusZone: 'West',
      latitude: 3.213893,
      longitude: 101.726572,
    ),
    CampusLocation(
      id: 'west_basketball_court_1',
      name: 'Basketball Court 1',
      campusZone: 'West',
      latitude: 3.215103,
      longitude: 101.728053,
    ),
    CampusLocation(
      id: 'west_basketball_court_2',
      name: 'Basketball Court 2',
      campusZone: 'West',
      latitude: 3.214803,
      longitude: 101.727506,
    ),
    CampusLocation(
      id: 'west_block_a',
      name: 'Block A',
      campusZone: 'West',
      latitude: 3.215197,
      longitude: 101.726481,
    ),
    CampusLocation(
      id: 'west_block_b',
      name: 'Block B',
      campusZone: 'West',
      latitude: 3.215441,
      longitude: 101.726545,
    ),
    CampusLocation(
      id: 'west_block_c',
      name: 'Block C',
      campusZone: 'West',
      latitude: 3.215952,
      longitude: 101.727093,
    ),
    CampusLocation(
      id: 'west_block_d',
      name: 'Block D',
      campusZone: 'West',
      latitude: 3.216713,
      longitude: 101.726669,
    ),
    CampusLocation(
      id: 'west_block_h',
      name: 'Block H (CPUS)',
      campusZone: 'West',
      latitude: 3.215417,
      longitude: 101.726025,
    ),
    CampusLocation(
      id: 'west_block_k',
      name: 'Block K',
      campusZone: 'West',
      latitude: 3.216812,
      longitude: 101.725169,
    ),
    CampusLocation(
      id: 'west_block_m',
      name: 'Block M (FEBE)',
      campusZone: 'West',
      latitude: 3.216761,
      longitude: 101.727806,
    ),
    CampusLocation(
      id: 'west_block_n',
      name: 'Block N',
      campusZone: 'West',
      latitude: 3.217294,
      longitude: 101.72716,
    ),
    CampusLocation(
      id: 'west_block_p',
      name: 'Block P',
      campusZone: 'West',
      latitude: 3.2178,
      longitude: 101.726427,
    ),
    CampusLocation(
      id: 'west_block_pa',
      name: 'Block PA',
      campusZone: 'West',
      latitude: 3.217556,
      longitude: 101.726114,
    ),
    CampusLocation(
      id: 'west_block_q',
      name: 'Block Q (CNBL)',
      campusZone: 'West',
      latitude: 3.218001,
      longitude: 101.7272,
    ),
    CampusLocation(
      id: 'west_block_r',
      name: 'Block R (FSAH)',
      campusZone: 'West',
      latitude: 3.21798,
      longitude: 101.72786,
    ),
    CampusLocation(
      id: 'west_block_v',
      name: 'Block V',
      campusZone: 'West',
      latitude: 3.216611,
      longitude: 101.730225,
    ),
    CampusLocation(
      id: 'west_block_w',
      name: 'Block W',
      campusZone: 'West',
      latitude: 3.216935,
      longitude: 101.730174,
    ),
    CampusLocation(
      id: 'west_block_x',
      name: 'Block X',
      campusZone: 'West',
      latitude: 3.217238,
      longitude: 101.730488,
    ),
    CampusLocation(
      id: 'west_block_y',
      name: 'Block Y',
      campusZone: 'West',
      latitude: 3.217524,
      longitude: 101.730488,
    ),
    CampusLocation(
      id: 'west_club_house',
      name: 'Club House',
      campusZone: 'West',
      latitude: 3.217358,
      longitude: 101.73015,
    ),
    CampusLocation(
      id: 'west_dewan_utama',
      name: 'Dewan Utama TARUMT',
      campusZone: 'West',
      latitude: 3.216413,
      longitude: 101.729539,
    ),
    CampusLocation(
      id: 'west_dk_a',
      name: 'DK A',
      campusZone: 'West',
      latitude: 3.216753,
      longitude: 101.727291,
    ),
    CampusLocation(
      id: 'west_dk_b',
      name: 'DK B',
      campusZone: 'West',
      latitude: 3.216622,
      longitude: 101.725607,
    ),
    CampusLocation(
      id: 'west_dk_c',
      name: 'DK C',
      campusZone: 'West',
      latitude: 3.218108,
      longitude: 101.728262,
    ),
    CampusLocation(
      id: 'west_dk_d',
      name: 'DK D',
      campusZone: 'West',
      latitude: 3.218097,
      longitude: 101.728579,
    ),
    CampusLocation(
      id: 'west_dk1',
      name: 'DK1',
      campusZone: 'West',
      latitude: 3.216276,
      longitude: 101.725907,
    ),
    CampusLocation(
      id: 'west_dk2',
      name: 'DK2',
      campusZone: 'West',
      latitude: 3.21641,
      longitude: 101.725918,
    ),
    CampusLocation(
      id: 'west_dk3',
      name: 'DK3',
      campusZone: 'West',
      latitude: 3.216416,
      longitude: 101.72613,
    ),
    CampusLocation(
      id: 'west_dk4',
      name: 'DK4',
      campusZone: 'West',
      latitude: 3.216258,
      longitude: 101.726122,
    ),
    CampusLocation(
      id: 'west_dk5',
      name: 'DK5',
      campusZone: 'West',
      latitude: 3.216844,
      longitude: 101.725937,
    ),
    CampusLocation(
      id: 'west_dk6',
      name: 'DK6',
      campusZone: 'West',
      latitude: 3.216999,
      longitude: 101.725947,
    ),
    CampusLocation(
      id: 'west_dk7',
      name: 'DK7',
      campusZone: 'West',
      latitude: 3.216997,
      longitude: 101.726143,
    ),
    CampusLocation(
      id: 'west_dk8',
      name: 'DK8',
      campusZone: 'West',
      latitude: 3.216839,
      longitude: 101.72614,
    ),
    CampusLocation(
      id: 'west_dk_s',
      name: 'DK S',
      campusZone: 'West',
      latitude: 3.217283,
      longitude: 101.729391,
    ),
    CampusLocation(
      id: 'west_dk_w',
      name: 'DK W',
      campusZone: 'West',
      latitude: 3.217744,
      longitude: 101.728297,
    ),
    CampusLocation(
      id: 'west_dk_x',
      name: 'DK X',
      campusZone: 'West',
      latitude: 3.217768,
      longitude: 101.728562,
    ),
    CampusLocation(
      id: 'west_dk_y',
      name: 'DK Y',
      campusZone: 'West',
      latitude: 3.217516,
      longitude: 101.728538,
    ),
    CampusLocation(
      id: 'west_dk_z',
      name: 'DK Z',
      campusZone: 'West',
      latitude: 3.217532,
      longitude: 101.728294,
    ),
    CampusLocation(
      id: 'west_fern_house',
      name: 'Fern House',
      campusZone: 'West',
      latitude: 3.217696,
      longitude: 101.730448,
    ),
    CampusLocation(
      id: 'west_garden_cafe',
      name: 'Graden Cafe',
      campusZone: 'West',
      latitude: 3.213997,
      longitude: 101.72683,
    ),
    CampusLocation(
      id: 'west_gym',
      name: 'Gym',
      campusZone: 'West',
      latitude: 3.217265,
      longitude: 101.729971,
    ),
    CampusLocation(
      id: 'west_library',
      name: 'Library',
      campusZone: 'West',
      latitude: 3.217254,
      longitude: 101.728037,
    ),
    CampusLocation(
      id: 'west_red_bricks_cafeteria',
      name: 'Red Bricks Cafeteria',
      campusZone: 'West',
      latitude: 3.216126,
      longitude: 101.725655,
    ),
    CampusLocation(
      id: 'west_sports_complex',
      name: 'Sport Complex',
      campusZone: 'West',
      latitude: 3.218159,
      longitude: 101.729673,
    ),
    CampusLocation(
      id: 'west_arena_student_centre',
      name: 'TARUMT ARENA / Student Centre',
      campusZone: 'West',
      latitude: 3.216619,
      longitude: 101.728281,
    ),
    CampusLocation(
      id: 'west_the_roots_cafe',
      name: 'The Roots Cafe',
      campusZone: 'West',
      latitude: 3.216129,
      longitude: 101.7276,
    ),
    CampusLocation(
      id: 'west_yum_yum_cafeteria',
      name: 'Yum Yum Cafeteria',
      campusZone: 'West',
      latitude: 3.21592,
      longitude: 101.727838,
    ),

    // East Campus (with coordinates from campus_location.txt)
    CampusLocation(
      id: 'east_block_a',
      name: 'Block A',
      campusZone: 'East',
      latitude: 3.217578,
      longitude: 101.732291,
    ),
    CampusLocation(
      id: 'east_block_b',
      name: 'Block B',
      campusZone: 'East',
      latitude: 3.217918,
      longitude: 101.732307,
    ),
    CampusLocation(
      id: 'east_block_c',
      name: 'Block C',
      campusZone: 'East',
      latitude: 3.218269,
      longitude: 101.732293,
    ),
    CampusLocation(
      id: 'east_block_d',
      name: 'Block D',
      campusZone: 'East',
      latitude: 3.217907,
      longitude: 101.732838,
    ),
    CampusLocation(
      id: 'east_block_e',
      name: 'Block E',
      campusZone: 'East',
      latitude: 3.217551,
      longitude: 101.732857,
    ),
    CampusLocation(
      id: 'east_block_f',
      name: 'Block F',
      campusZone: 'East',
      latitude: 3.217554,
      longitude: 101.733409,
    ),
    CampusLocation(
      id: 'east_block_g',
      name: 'Block G',
      campusZone: 'East',
      latitude: 3.217926,
      longitude: 101.733436,
    ),
    CampusLocation(
      id: 'east_block_h',
      name: 'Block H',
      campusZone: 'East',
      latitude: 3.218274,
      longitude: 101.73401,
    ),
    CampusLocation(
      id: 'east_block_i',
      name: 'Block I',
      campusZone: 'East',
      latitude: 3.217913,
      longitude: 101.734013,
    ),
    CampusLocation(
      id: 'east_block_j',
      name: 'Block J',
      campusZone: 'East',
      latitude: 3.217575,
      longitude: 101.733999,
    ),
    CampusLocation(
      id: 'east_hostel_office_canteen',
      name: 'Hostel, Office & Canteen',
      campusZone: 'East',
      latitude: 3.21821,
      longitude: 101.733042,
    ),
    CampusLocation(
      id: 'east_block_sa',
      name: 'Block SA (FAFB, CPE)',
      campusZone: 'East',
      latitude: 3.216073,
      longitude: 101.733994,
    ),
    CampusLocation(
      id: 'east_block_sb',
      name: 'Block SB',
      campusZone: 'East',
      latitude: 3.216306,
      longitude: 101.73346,
    ),
    CampusLocation(
      id: 'east_block_sd',
      name: 'Block SD',
      campusZone: 'East',
      latitude: 3.21693,
      longitude: 101.734364,
    ),
    CampusLocation(
      id: 'east_block_se',
      name: 'Block SE',
      campusZone: 'East',
      latitude: 3.216708,
      longitude: 101.734638,
    ),
    CampusLocation(
      id: 'east_block_sf',
      name: 'Block SF',
      campusZone: 'East',
      latitude: 3.216456,
      longitude: 101.734868,
    ),
    CampusLocation(
      id: 'east_block_sg',
      name: 'Block SG (SG1–SG6)',
      campusZone: 'East',
      latitude: 3.216108,
      longitude: 101.734536,
    ),
    CampusLocation(
      id: 'east_casuarina_cafe',
      name: 'Casuarina Cafe',
      campusZone: 'East',
      latitude: 3.216774,
      longitude: 101.733659,
    ),
    CampusLocation(
      id: 'east_brown_woods',
      name: 'Brown Woods',
      campusZone: 'East',
      latitude: 3.216563,
      longitude: 101.734069,
    ),
    CampusLocation(
      id: 'east_institut_vtar',
      name: 'Institut VTAR',
      campusZone: 'East',
      latitude: 3.21513,
      longitude: 101.731816,
    ),
    CampusLocation(
      id: 'east_tar_ec_college',
      name: 'TAR EC College',
      campusZone: 'East',
      latitude: 3.214549,
      longitude: 101.730826,
    ),
    CampusLocation(
      id: 'east_dk_aba_abb',
      name: 'DK ABA & DK ABB',
      campusZone: 'East',
      latitude: 3.215227,
      longitude: 101.731164,
    ),
    CampusLocation(
      id: 'east_dk_abc_abd',
      name: 'DK ABC & DK ABD',
      campusZone: 'East',
      latitude: 3.215615,
      longitude: 101.731599,
    ),
    CampusLocation(
      id: 'east_dk_abe_abf',
      name: 'DK ABE & DK ABF',
      campusZone: 'East',
      latitude: 3.216054,
      longitude: 101.731912,
    ),
    CampusLocation(
      id: 'east_woodland_park',
      name: 'Woodland Park',
      campusZone: 'East',
      latitude: 3.216375,
      longitude: 101.732336,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = _campusLocations.first;
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = strings.t('campus.locationError');
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = strings.t('campus.error');
        });
        return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // same behaviour as before
        distanceFilter: 0, // report all movements
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      setState(() {
        _locationError = strings.t('campus.locationError');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final LatLng mapCenter = _currentPosition ?? _tarUmtCenter;

    final markers = <Marker>[
      // Campus locations with known coordinates
      for (final location in _campusLocations)
        Marker(
          width: 40,
          height: 40,
          point: LatLng(location.latitude, location.longitude),
          child: Icon(
            Icons.location_on,
            color:
                location.id == _selectedLocation?.id
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
            size: 32,
          ),
        ),
      // Current user location
      if (_currentPosition != null)
        Marker(
          width: 40,
          height: 40,
          point: _currentPosition!,
          child: Icon(
            Icons.my_location,
            color: theme.colorScheme.tertiary,
            size: 28,
          ),
        ),
    ];

    final polylines = <Polyline>[
      if (_currentPosition != null && _selectedLocation != null)
        Polyline(
          points: [
            _currentPosition!,
            LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude),
          ],
          strokeWidth: 4,
          color: theme.colorScheme.primary,
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('campus.title'))),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('campus.intro.title'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seeing where you are and where your class is can take away some of that “I\'m lost and late” stress.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<CampusLocation>(
                    isExpanded: true,
                    value: _selectedLocation,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedLocation = value;
                      });
                    },
                    items:
                        _campusLocations
                            .map(
                              (location) => DropdownMenuItem<CampusLocation>(
                                value: location,
                                child: Text(
                                  '${location.campusZone} • ${location.name}',
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  if (_isLoadingLocation)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            strings.t('campus.loading'),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    )
                  else if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _locationError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: mapCenter,
                      initialZoom: 17,
                      minZoom: 15,
                      maxZoom: 19,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'my.edu.tarumt.calm_campus',
                      ),
                      if (markers.isNotEmpty) MarkerLayer(markers: markers),
                      if (polylines.isNotEmpty)
                        PolylineLayer(polylines: polylines),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _currentPosition != null && _selectedLocation != null
                    ? strings.t('campus.legend')
                    : 'Map data © OpenStreetMap contributors. This map is meant to gently help you find your way, not track you.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.campusZone,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String campusZone;
  final double latitude;
  final double longitude;
}
