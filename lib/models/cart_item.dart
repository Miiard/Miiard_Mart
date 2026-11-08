import 'product_model.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({required this.product, required this.quantity});

  CartItem copyWith({Product? product, int? quantity}) => CartItem(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );

  double get lineTotal => product.discountedPrice * quantity;
  double get lineOriginal => product.price * quantity;
}
