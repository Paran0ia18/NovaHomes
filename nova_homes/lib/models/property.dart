import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyLocation {
  const PropertyLocation({
    required this.address,
    required this.city,
    required this.country,
    required this.lat,
    required this.lng,
  });

  final String address;
  final String city;
  final String country;
  final double lat;
  final double lng;

  factory PropertyLocation.fromMap(Map<String, dynamic> map) {
    return PropertyLocation(
      address: (map['address'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      country: (map['country'] ?? '') as String,
      lat: (map['lat'] as num?)?.toDouble() ?? 0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address': address,
      'city': city,
      'country': country,
      'lat': lat,
      'lng': lng,
    };
  }

  String get fullLabel => '$city, $country';
}

class Property {
  const Property({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.guests,
    required this.bedrooms,
    required this.amenities,
    required this.nightlyPrice,
    required this.geoLocation,
  });

  final String id;
  final String title;
  final String location;
  final String description;
  final String imageUrl;
  final String price;
  final double rating;
  final int reviews;
  final int guests;
  final int bedrooms;
  final List<String> amenities;
  final int nightlyPrice;
  final PropertyLocation geoLocation;

  factory Property.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    final int nightly = (data['nightlyPrice'] as num?)?.toInt() ?? 0;
    final PropertyLocation location = PropertyLocation.fromMap(
      (data['location'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
    final List<String> amenities =
        ((data['amenities'] as List<dynamic>?) ?? <dynamic>[])
            .map((dynamic item) => item.toString())
            .toList(growable: false);

    return Property(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      location: location.fullLabel,
      description: (data['description'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      price: '\$$nightly / night',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      guests: (data['guests'] as num?)?.toInt() ?? 0,
      bedrooms: (data['bedrooms'] as num?)?.toInt() ?? 0,
      amenities: amenities,
      nightlyPrice: nightly,
      geoLocation: location,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'nightlyPrice': nightlyPrice,
      'rating': rating,
      'reviews': reviews,
      'guests': guests,
      'bedrooms': bedrooms,
      'amenities': amenities.map((String item) => item.toLowerCase()).toList(),
      'location': geoLocation.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

const List<Property> mockProperties = <Property>[
  Property(
    id: 'mock_1',
    title: 'Azure Cliffside Villa',
    location: 'Amalfi Coast, Italy',
    description:
        'A dramatic seafront villa with floor-to-ceiling views, infinity pool, and curated Italian interiors.',
    imageUrl:
        'https://images.unsplash.com/photo-1613977257363-707ba9348227?auto=format&fit=crop&w=900&q=70',
    price: '\$450 / night',
    rating: 4.9,
    reviews: 126,
    guests: 6,
    bedrooms: 3,
    amenities: <String>['wifi', 'pool', 'kitchen', 'ac', 'ocean view'],
    nightlyPrice: 450,
    geoLocation: PropertyLocation(
      address: 'Via Marina Grande 1',
      city: 'Amalfi',
      country: 'Italy',
      lat: 40.634,
      lng: 14.602,
    ),
  ),
  Property(
    id: 'mock_2',
    title: 'Modern Villa in Mallorca',
    location: 'Palma, Spain',
    description:
        'Minimalist architecture, sun deck, and private courtyard designed for serene Mediterranean stays.',
    imageUrl:
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=900&q=70',
    price: '\$620 / night',
    rating: 4.8,
    reviews: 94,
    guests: 8,
    bedrooms: 4,
    amenities: <String>['wifi', 'pool', 'gym', 'parking', 'outdoor dining'],
    nightlyPrice: 620,
    geoLocation: PropertyLocation(
      address: 'Passeig Maritim 22',
      city: 'Mallorca',
      country: 'Spain',
      lat: 39.569,
      lng: 2.65,
    ),
  ),
  Property(
    id: 'mock_3',
    title: 'Glass House Retreat',
    location: 'Kyoto Forest, Japan',
    description:
        'A tranquil glass residence immersed in cedar woods with premium spa facilities and silent luxury.',
    imageUrl:
        'https://images.unsplash.com/photo-1510798831971-661eb04b3739?auto=format&fit=crop&w=900&q=70',
    price: '\$320 / night',
    rating: 5.0,
    reviews: 78,
    guests: 2,
    bedrooms: 1,
    amenities: <String>['wifi', 'sauna', 'hot tub', 'fireplace', 'workspace'],
    nightlyPrice: 320,
    geoLocation: PropertyLocation(
      address: 'Arashiyama Road 5',
      city: 'Kyoto',
      country: 'Japan',
      lat: 35.011,
      lng: 135.768,
    ),
  ),
  Property(
    id: 'mock_4',
    title: 'Cliffside Mansion',
    location: 'Beverly Hills, USA',
    description:
        'Palatial estate with manicured gardens, cinema room, and panoramic city lights from every suite.',
    imageUrl:
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?auto=format&fit=crop&w=900&q=70',
    price: '\$1,200 / night',
    rating: 4.8,
    reviews: 210,
    guests: 12,
    bedrooms: 6,
    amenities: <String>['pool', 'cinema', 'gym', 'security', 'valet parking'],
    nightlyPrice: 1200,
    geoLocation: PropertyLocation(
      address: 'Sunset Boulevard 101',
      city: 'Los Angeles',
      country: 'USA',
      lat: 34.073,
      lng: -118.4,
    ),
  ),
  Property(
    id: 'mock_5',
    title: 'Penthouse Lumiere',
    location: 'Dubai Marina, UAE',
    description:
        'Ultra-luxury penthouse featuring skyline terrace, private elevator, and bespoke concierge service.',
    imageUrl:
        'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=900&q=70',
    price: '\$890 / night',
    rating: 4.95,
    reviews: 163,
    guests: 5,
    bedrooms: 3,
    amenities: <String>[
      'skyline view',
      'concierge',
      'smart home',
      'infinity jacuzzi',
      'private lift',
    ],
    nightlyPrice: 890,
    geoLocation: PropertyLocation(
      address: 'Marina Walk 87',
      city: 'Dubai',
      country: 'UAE',
      lat: 25.079,
      lng: 55.141,
    ),
  ),
];
