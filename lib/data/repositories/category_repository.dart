import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';
import 'auth_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseProvider));
});

class CategoryRepository {
  final SupabaseClient _supabase;

  CategoryRepository(this._supabase);

  Future<List<CategoryModel>> getCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .order('name', ascending: true);
    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  Future<CategoryModel?> getCategoryBySlug(String slug) async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    if (response == null) return null;
    return CategoryModel.fromJson(response);
  }
}
