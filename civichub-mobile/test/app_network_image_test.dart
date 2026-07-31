import 'package:civichub_mobile/core/widgets/app_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppNetworkImage applies cache dimensions from logical size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 3),
          child: AppNetworkImage(
            url: 'https://example.com/image.png',
            logicalWidth: 60,
            logicalHeight: 40,
            fallback: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));

    expect(
      image.image,
      isA<ResizeImage>()
          .having((provider) => provider.width, 'width', 180)
          .having((provider) => provider.height, 'height', 120),
    );
    expect(image.gaplessPlayback, isTrue);
    expect(image.filterQuality, FilterQuality.low);
  });
}
