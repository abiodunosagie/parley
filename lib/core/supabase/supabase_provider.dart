// FILE: core/supabase/supabase_provider.dart
// The one Supabase client, initialised in main.dart. Data-layer code reads it from here so tests
// can override it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
