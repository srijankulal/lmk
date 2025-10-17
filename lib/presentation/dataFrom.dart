import 'package:flutter/material.dart';
import 'package:lmk/data/models/post/post.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DocForm extends StatefulWidget {
  const DocForm({super.key});

  @override
  State<DocForm> createState() => _DocFormState();
}

class _DocFormState extends State<DocForm> {
  final _titleController = TextEditingController();
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as DocData;
    final formKey = GlobalKey<ShadFormState>();
    _titleController.text = args.documentType ?? '';
    return Scaffold(
      body: Center(
        child: ShadForm(
          key: formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShadInputFormField(
                    id: 'Document Title',
                    label: const Text('Document Title'),
                    placeholder: const Text('Enter Document Title'),
                    controller: _titleController,
                    maxLines: 1,
                    leading: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: const Icon(LucideIcons.file),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Document Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ShadDatePickerFormField(
                    id: 'Issue Date',
                    label: const Text('Issue Date'),
                    enabled: false,
                    placeholder: const Text('Issueid Date not found'),
                    initialValue: args.issueDate != null
                        ? DateTime.parse('${args.issueDate}Z')
                        : null,
                  ),
                  const SizedBox(height: 16),
                  ShadDatePickerFormField(
                    id: 'Expiry Date',
                    label: const Text('Expiry Date'),
                    placeholder: const Text('Expiry Date not found'),
                    initialValue: args.expiryDate != null
                        ? DateTime.parse('${args.expiryDate}Z')
                        : null,
                    validator: (value) {
                      if (value == null) {
                        return 'Expiry Date is required, select a valid date';
                      }
                      return null;
                    },
                  ),
                  ShadButton(
                    child: const Text('Submit'),
                    onPressed: () {
                      if (formKey.currentState!.saveAndValidate()) {
                        print(
                          'validation succeeded with ${formKey.currentState!.value}',
                        );
                      } else {
                        print('validation failed');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
