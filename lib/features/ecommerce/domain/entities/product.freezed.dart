// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Product {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get imagePath => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get sizes => throw _privateConstructorUsedError;
  List<String> get colors => throw _privateConstructorUsedError;
  bool get isRecommended => throw _privateConstructorUsedError;
  bool get isSummer => throw _privateConstructorUsedError;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductCopyWith<Product> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductCopyWith<$Res> {
  factory $ProductCopyWith(Product value, $Res Function(Product) then) =
      _$ProductCopyWithImpl<$Res, Product>;
  @useResult
  $Res call({
    String id,
    String name,
    String category,
    double price,
    String imagePath,
    String description,
    List<String> sizes,
    List<String> colors,
    bool isRecommended,
    bool isSummer,
  });
}

/// @nodoc
class _$ProductCopyWithImpl<$Res, $Val extends Product>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? price = null,
    Object? imagePath = null,
    Object? description = null,
    Object? sizes = null,
    Object? colors = null,
    Object? isRecommended = null,
    Object? isSummer = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            imagePath: null == imagePath
                ? _value.imagePath
                : imagePath // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
            sizes: null == sizes
                ? _value.sizes
                : sizes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            colors: null == colors
                ? _value.colors
                : colors // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            isRecommended: null == isRecommended
                ? _value.isRecommended
                : isRecommended // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSummer: null == isSummer
                ? _value.isSummer
                : isSummer // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ProductImplCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$$ProductImplCopyWith(
    _$ProductImpl value,
    $Res Function(_$ProductImpl) then,
  ) = __$$ProductImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String category,
    double price,
    String imagePath,
    String description,
    List<String> sizes,
    List<String> colors,
    bool isRecommended,
    bool isSummer,
  });
}

/// @nodoc
class __$$ProductImplCopyWithImpl<$Res>
    extends _$ProductCopyWithImpl<$Res, _$ProductImpl>
    implements _$$ProductImplCopyWith<$Res> {
  __$$ProductImplCopyWithImpl(
    _$ProductImpl _value,
    $Res Function(_$ProductImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? category = null,
    Object? price = null,
    Object? imagePath = null,
    Object? description = null,
    Object? sizes = null,
    Object? colors = null,
    Object? isRecommended = null,
    Object? isSummer = null,
  }) {
    return _then(
      _$ProductImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        imagePath: null == imagePath
            ? _value.imagePath
            : imagePath // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
        sizes: null == sizes
            ? _value._sizes
            : sizes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        colors: null == colors
            ? _value._colors
            : colors // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        isRecommended: null == isRecommended
            ? _value.isRecommended
            : isRecommended // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSummer: null == isSummer
            ? _value.isSummer
            : isSummer // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ProductImpl implements _Product {
  const _$ProductImpl({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imagePath,
    required this.description,
    required final List<String> sizes,
    required final List<String> colors,
    this.isRecommended = false,
    this.isSummer = false,
  }) : _sizes = sizes,
       _colors = colors;

  @override
  final String id;
  @override
  final String name;
  @override
  final String category;
  @override
  final double price;
  @override
  final String imagePath;
  @override
  final String description;
  final List<String> _sizes;
  @override
  List<String> get sizes {
    if (_sizes is EqualUnmodifiableListView) return _sizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sizes);
  }

  final List<String> _colors;
  @override
  List<String> get colors {
    if (_colors is EqualUnmodifiableListView) return _colors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_colors);
  }

  @override
  @JsonKey()
  final bool isRecommended;
  @override
  @JsonKey()
  final bool isSummer;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, category: $category, price: $price, imagePath: $imagePath, description: $description, sizes: $sizes, colors: $colors, isRecommended: $isRecommended, isSummer: $isSummer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._sizes, _sizes) &&
            const DeepCollectionEquality().equals(other._colors, _colors) &&
            (identical(other.isRecommended, isRecommended) ||
                other.isRecommended == isRecommended) &&
            (identical(other.isSummer, isSummer) ||
                other.isSummer == isSummer));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    category,
    price,
    imagePath,
    description,
    const DeepCollectionEquality().hash(_sizes),
    const DeepCollectionEquality().hash(_colors),
    isRecommended,
    isSummer,
  );

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      __$$ProductImplCopyWithImpl<_$ProductImpl>(this, _$identity);
}

abstract class _Product implements Product {
  const factory _Product({
    required final String id,
    required final String name,
    required final String category,
    required final double price,
    required final String imagePath,
    required final String description,
    required final List<String> sizes,
    required final List<String> colors,
    final bool isRecommended,
    final bool isSummer,
  }) = _$ProductImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get category;
  @override
  double get price;
  @override
  String get imagePath;
  @override
  String get description;
  @override
  List<String> get sizes;
  @override
  List<String> get colors;
  @override
  bool get isRecommended;
  @override
  bool get isSummer;

  /// Create a copy of Product
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductImplCopyWith<_$ProductImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
