import sys

file_path = r"c:\Users\Atharva Nair\kavaach\mobile\lib\screens\location\location_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

# Import
import_insert_index = 6
lines.insert(import_insert_index, "import 'package:cloud_firestore/cloud_firestore.dart';\n")

# Find the start and end of _allMarkers
start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if "final Set<Marker> _allMarkers = {" in line:
        start_idx = i
    if start_idx != -1 and "late Set<Marker> _markers;" in line:
        # Check backward to find the close brace
        for j in range(i-1, start_idx, -1):
            if "};" in lines[j]:
                end_idx = j
                break
        break

if start_idx != -1 and end_idx != -1:
    del lines[start_idx:end_idx+1]
    lines.insert(start_idx, "  Set<Marker> _allMarkers = {};\n")

# Find initState
init_idx = -1
for i, line in enumerate(lines):
    if "void initState() {" in line:
        init_idx = i
        break

if init_idx != -1:
    for i in range(init_idx, init_idx+10):
        if "_determinePosition();" in lines[i]:
            lines.insert(i + 1, "    _loadHavensFromFirestore();\n")
            break

load_func = """
  Future<void> _loadHavensFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('safe_havens').get();
      final Set<Marker> fetchedMarkers = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String name = data['name'] ?? 'Unknown';
        final String type = data['type']?.toString().toUpperCase() ?? 'UNKNOWN';
        final double lat = (data['latitude'] ?? 0.0).toDouble();
        final double lng = (data['longitude'] ?? 0.0).toDouble();
        final String contact = data['contact'] ?? '';
        
        double hue = BitmapDescriptor.hueRed;
        if (type == 'POLICE') hue = BitmapDescriptor.hueBlue;
        else if (type == 'HOSPITAL') hue = BitmapDescriptor.hueOrange;
        else if (type == 'SHELTER') hue = BitmapDescriptor.hueGreen;

        fetchedMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: name,
              snippet: 'Type: $type | Contact: $contact',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          )
        );
      }
      
      if (mounted) {
        setState(() {
          _allMarkers.clear();
          _allMarkers.addAll(fetchedMarkers);
          _markers = _buildNavigableMapMarkers(_allMarkers);
        });
      }
    } catch (e) {
      debugPrint('Error loading havens from Firestore: $e');
    }
  }
"""

# Wait, the method to build navigable markers is `_buildNavigableMarkers` not `_buildNavigableMapMarkers`
load_func = load_func.replace("_buildNavigableMapMarkers", "_buildNavigableMarkers")

# Now re-find init_idx because we deleted and added lines above
init_idx = -1
for i, line in enumerate(lines):
    if "void initState() {" in line:
        init_idx = i
        break

lines.insert(init_idx-1, load_func)

with open(file_path, "w", encoding="utf-8") as f:
    f.writelines(lines)

print("Modification complete.")
