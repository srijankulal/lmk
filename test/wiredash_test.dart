import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lmk/services/wiredash_service.dart';
import 'package:wiredash/wiredash.dart';

void main() {
  test('WiredashService initializes and has valid credentials', () async {
    expect(WiredashService.projectId, 'lmk-70yfc18');
    expect(WiredashService.secret, 'H2ALJlc_24QHDB0SOOGHlJkfjuUhLzdy');
    expect(WiredashService.instance.isConfigured, true);
  });

  testWidgets('Wiredash metadata callback compiles', (tester) async {
    final widget = Wiredash(
      projectId: 'lmk-70yfc18',
      secret: 'H2ALJlc_24QHDB0SOOGHlJkfjuUhLzdy',
      collectMetaData: (metaData) {
        metaData.custom['error'] = 'test';
        return metaData;
      },
      child: const SizedBox(),
    );
    expect(widget.projectId, 'lmk-70yfc18');
  });
}
