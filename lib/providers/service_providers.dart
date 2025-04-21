import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/place_service.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';

final placeServiceProvider = Provider((ref) => PlaceService());
final postServiceProvider = Provider((ref) => PostService());
final authServiceProvider = Provider((ref) => AuthService());
