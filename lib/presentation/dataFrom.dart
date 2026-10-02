import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:lmk/components/colours/colours.dart';

class DocForm extends StatefulWidget {
  const DocForm({super.key});

  @override
  State<DocForm> createState() => _DocFormState();
}

class _DocFormState extends State<DocForm> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<ShadFormState>();

  DocData? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_args == null) {
      _args = ModalRoute.of(context)!.settings.arguments as DocData;
      final docTitle = _args?.documentType ?? '';
      if (docTitle.isNotEmpty) {
        _titleController.text = docTitle;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Document details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          const _LiquidBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ShadForm(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.layers,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Basic info',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ShadInputFormField(
                            id: 'Document Title',
                            label: const Text('Document title'),
                            placeholder: const Text('Enter document title'),
                            controller: _titleController,
                            textCapitalization: TextCapitalization.words,
                            maxLines: 1,
                            maxLength: 64,
                            leading: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(
                                LucideIcons.file,
                                color: AppColors.primary,
                              ),
                            ),
                            validator: (value) {
                              if (value.trim().isEmpty) {
                                return 'Document title is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This name helps you recognize the document later.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dates',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ShadDatePickerFormField(
                            id: 'Issue Date',
                            label: const Text('Issue date'),
                            // enabled: false,
                            placeholder: const Text('Issue date not found'),
                            initialValue: _args?.issueDate != null
                                ? DateTime.parse('${_args!.issueDate}Z')
                                : null,
                          ),
                          const SizedBox(height: 16),
                          ShadDatePickerFormField(
                            closeOnSelection: true,
                            id: 'Expiry Date',
                            label: const Text('Expiry date'),
                            placeholder: const Text('Select expiry date'),
                            initialValue: _args?.expiryDate != null
                                ? DateTime.parse('${_args!.expiryDate}Z')
                                : null,
                            validator: (value) {
                              if (value == null) {
                                return 'Expiry date is required. Select a valid date.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                ),
                                onPressed: () => Navigator.maybePop(context),
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              ShadButton(
                                child: const Text('Next'),
                                backgroundColor: AppColors.primary,
                                onPressed: () {
                                  if (_formKey.currentState!
                                      .saveAndValidate()) {
                                    Navigator.pushNamed(
                                      context,
                                      '/setReminder',
                                      arguments: DocData(
                                        documentType: _titleController.text
                                            .trim(),
                                        issueDate: _formKey
                                            .currentState!
                                            .value['Issue Date'],
                                        expiryDate: _formKey
                                            .currentState!
                                            .value['Expiry Date'],
                                      ),
                                    );
                                    // ignore: avoid_print
                                    print(
                                      'validation succeeded with ${_formKey.currentState!.value}',
                                    );
                                  } else {
                                    // ignore: avoid_print
                                    print('validation failed');
                                    ShadToaster.of(context).show(
                                      ShadToast.destructive(
                                        title: const Text('Validation failed'),
                                        description: const Text(
                                          'Please correct the errors.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
    );
      },
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.surfaceGlass,
            border: Border.all(color: AppColors.borderSubtle, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Background: minimalist obsidian dark background with ambient glows
class _LiquidBackground extends StatelessWidget {
  const _LiquidBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Stack(
        children: const [
          _Glow(size: 320, color: AppColors.primary, top: -60, right: -80),
          _Glow(size: 280, color: AppColors.accent, bottom: 80, left: -60),
          _Glow(size: 200, color: Color(0xFFFF5B2E), bottom: -40, right: -40),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  final double? top, left, right, bottom;

  const _Glow({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withAlpha(45),
              color.withAlpha(12),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}


