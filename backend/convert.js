const fs = require('fs');
const sourcePath = 'c:/Users/Atharva Nair/kavaach/backend/seed_locations.js';

let content = fs.readFileSync(sourcePath, 'utf8');
let match = content.match(/const defaultLocations = (\[[\s\S]*?\]);/);
if (match) {
  let locations;
  // Use eval to parse the JS array correctly since it's not strict JSON
  eval(`locations = ${match[1]};`);
  
  let dartCode = '  Set<Marker> _markers = {\n';
  
  locations.forEach(loc => {
    let hue = 'BitmapDescriptor.hueRed';
    if (loc.type === 'police') hue = 'BitmapDescriptor.hueBlue';
    else if (loc.type === 'shelter') hue = 'BitmapDescriptor.hueGreen';
    else if (loc.type === 'hospital') hue = 'BitmapDescriptor.hueOrange';
    
    // safe markerId
    let mId = loc.name.replace(/[^a-zA-Z0-9]/g, '_').toLowerCase();
    
    dartCode += `    Marker(
      markerId: const MarkerId('${mId}'),
      position: const LatLng(${loc.latitude}, ${loc.longitude}),
      infoWindow: const InfoWindow(
        title: '${loc.name.replace(/'/g, "\\'")}',
        snippet: 'Type: ${loc.type.toUpperCase()} | Contact: ${loc.contact}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(${hue}),
    ),\n`;
  });
  
  dartCode += '  };\n';
  
  fs.writeFileSync('C:/Users/Atharva Nair/kavaach/backend/dart_markers.txt', dartCode);
  console.log("Done");
} else {
  console.log("no match");
}
