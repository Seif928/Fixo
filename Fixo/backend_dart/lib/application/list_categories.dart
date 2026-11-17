import '../domain/catalog.dart';

final class ListCategories {
  const ListCategories(this.repository);
  final CatalogRepository repository;
  Future<CatalogSnapshot> call() => repository.categories();
}
