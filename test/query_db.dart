import 'package:supabase/supabase.dart';

Future<void> main() async {
  print('Initializing Supabase client (Pure Dart)...');
  final supabase = SupabaseClient(
    'https://srtmangifebgvysddenp.supabase.co',
    'sb_publishable_OinhRPcHtVPk-qUbt6P5ZQ_hRvttwsL',
  );

  try {
    print('Querying categories count...');
    final categoriesRes = await supabase.from('categories').select('id');
    print('Found ${categoriesRes.length} categories in DB.');

    print('Querying products count...');
    final productsRes = await supabase.from('products').select('id');
    print('Found ${productsRes.length} products in DB.');
  } catch (e) {
    print('Error querying Supabase: $e');
  }
}
