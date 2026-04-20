import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lrmnbvcpqqqhjochzmzz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxybW5idmNwcXFxaGpvY2h6bXp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMDM2NzMsImV4cCI6MjA5MTY3OTY3M30.eJ5XI0CsindI7zJRhZb0JHaWjyDWS-5vB8vjHps1a1w',
  );

  runApp(const ProviderScope(child: App()));
}