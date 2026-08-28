import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/product.dart';
import '../providers/ecommerce_provider.dart';
import '../providers/product_management_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  /// Si [product] es null se crea uno nuevo; si tiene valor se edita.
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  bool _isLoading = false;

  XFile? _pickedXFile;
  Uint8List? _pickedBytes;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descriptionCtrl;

  static const _availableSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  static const _availableColors = [
    'black', 'white', 'grey', 'navy', 'blue',
    'red', 'green', 'yellow', 'orange', 'pink', 'purple', 'brown',
  ];

  late Set<String> _selectedSizes;
  late Set<String> _selectedColors;

  late bool _isRecommended;
  late bool _isSummer;

  // URL actual almacenada en Firestore (puede ser vacía en productos nuevos)
  late String _currentImageUrl;

  bool get _isEditing => widget.product != null;
  bool get _hasImage => _pickedBytes != null || _currentImageUrl.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _priceCtrl =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _isRecommended = p?.isRecommended ?? false;
    _isSummer = p?.isSummer ?? false;
    _currentImageUrl = p?.imagePath ?? '';
    _selectedSizes = Set<String>.from(p?.sizes ?? ['XS', 'S', 'M', 'L', 'XL']);
    _selectedColors = Set<String>.from(p?.colors ?? ['black', 'blue', 'grey', 'white']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      setState(() {
        _pickedXFile = xfile;
        _pickedBytes = bytes;
      });
    }
  }


  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen para el producto.')),
      );
      return;
    }
    if (_selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una talla.')),
      );
      return;
    }
    if (_selectedColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un color.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imagePath = _currentImageUrl;

      // Sube la nueva imagen si el usuario seleccionó una
      if (_pickedBytes != null && _pickedXFile != null) {
        final productId = widget.product?.id.isNotEmpty == true
            ? widget.product!.id
            : DateTime.now().millisecondsSinceEpoch.toString();

        imagePath = await ref
            .read(imageStorageDatasourceProvider)
            .uploadProductImage(
              xfile: _pickedXFile!,
              productId: productId,
            );
      }

      final product = Product(
        id: widget.product?.id ?? '',
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        imagePath: imagePath,
        description: _descriptionCtrl.text.trim(),
        sizes: _selectedSizes.toList(),
        colors: _selectedColors.toList(),
        isRecommended: _isRecommended,
        isSummer: _isSummer,
      );

      final notifier = ref.read(allProductsProvider.notifier);
      if (_isEditing) {
        await notifier.updateProduct(product);
      } else {
        await notifier.addProduct(product);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Producto actualizado correctamente.'
                : 'Producto agregado correctamente.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Producto' : 'Nuevo Producto'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ImagePicker(
                pickedBytes: _pickedBytes,
                currentImageUrl: _currentImageUrl,
                onTap: _pickImage,
              ),
              const SizedBox(height: 20),
              _field(
                controller: _nameCtrl,
                label: 'Nombre',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _categoryCtrl,
                label: 'Categoría (ej: Black / M)',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _priceCtrl,
                label: 'Precio (USD)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                controller: _descriptionCtrl,
                label: 'Descripción',
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              _ChipSelector(
                label: 'Tallas',
                options: _availableSizes,
                selected: _selectedSizes,
                onToggle: (val) => setState(() {
                  if (_selectedSizes.contains(val)) {
                    _selectedSizes.remove(val);
                  } else {
                    _selectedSizes.add(val);
                  }
                }),
              ),
              const SizedBox(height: 16),
              _ChipSelector(
                label: 'Colores',
                options: _availableColors,
                selected: _selectedColors,
                onToggle: (val) => setState(() {
                  if (_selectedColors.contains(val)) {
                    _selectedColors.remove(val);
                  } else {
                    _selectedColors.add(val);
                  }
                }),
              ),
              const SizedBox(height: 20),
              const Text(
                'Categorías de visualización',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                title: const Text('Recomendado ("Perfect for you")'),
                value: _isRecommended,
                onChanged: (v) => setState(() => _isRecommended = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Verano ("For this summer")'),
                value: _isSummer,
                onChanged: (v) => setState(() => _isSummer = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEditing ? 'Guardar cambios' : 'Agregar producto',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final Uint8List? pickedBytes;
  final String currentImageUrl;
  final VoidCallback onTap;

  const _ImagePicker({
    required this.pickedBytes,
    required this.currentImageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (pickedBytes != null) {
      imageContent = Image.memory(pickedBytes!, fit: BoxFit.cover);
    } else if (currentImageUrl.isNotEmpty) {
      imageContent = currentImageUrl.startsWith('http')
          ? Image(
              image: NetworkImage(
                currentImageUrl,
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
              ),
              fit: BoxFit.cover,
            )
          : Image.asset(currentImageUrl, fit: BoxFit.cover);
    } else {
      imageContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Toca para seleccionar imagen',
              style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCDD6F4)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageContent,
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Cambiar', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSelector extends StatelessWidget {
  final String label;
  final List<String> options;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _ChipSelector({
    required this.label,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
              selectedColor: const Color(0xFF0A7CFF),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: const Color(0xFFF2F2F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0A7CFF)
                      : Colors.transparent,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }
}
