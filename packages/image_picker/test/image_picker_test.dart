// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('$ImagePicker', () {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/image_picker');

    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return '';
      });

      log.clear();
    });

    group('#pickImage', () {
      test('passes the image source argument correctly', () async {
        await ImagePicker.pickImage(source: ImageSource.camera);
        await ImagePicker.pickImage(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'saveToAlbum': false,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 1,
              'maxWidth': null,
              'maxHeight': null,
              'saveToAlbum': false,
            }),
          ],
        );
      });

      test('passes the width and height arguments correctly', () async {
        await ImagePicker.pickImage(source: ImageSource.camera);
        await ImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 10.0,
        );
        await ImagePicker.pickImage(
          source: ImageSource.camera,
          maxHeight: 10.0,
        );
        await ImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 10.0,
          maxHeight: 20.0,
        );

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'saveToAlbum': false,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'saveToAlbum': false,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'saveToAlbum': false,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'saveToAlbum': false,
            }),
          ],
        );
      });

      test('does not accept a negative width or height argument', () {
        expect(
          ImagePicker.pickImage(source: ImageSource.camera, maxWidth: -1.0),
          throwsArgumentError,
        );

        expect(
          ImagePicker.pickImage(source: ImageSource.camera, maxHeight: -1.0),
          throwsArgumentError,
        );
      });


      test('passes the saveToAlbum argument correct', () async {
        await ImagePicker.pickImage(source: ImageSource.camera, saveToAlbum: true);
        await ImagePicker.pickImage(source: ImageSource.camera, saveToAlbum: false);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'saveToAlbum': true,
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'saveToAlbum': false,
            }),
          ],
        );
      });

      test('handles a null image path response gracefully', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) => null);

        expect(
            await ImagePicker.pickImage(source: ImageSource.gallery), isNull);
        expect(await ImagePicker.pickImage(source: ImageSource.camera), isNull);
      });
    });

    group('#retrieveLostData', () {
      test('retrieveLostData get success response', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, String>{
            'type': 'image',
            'path': '/example/path',
          };
        });
        final LostDataResponse response = await ImagePicker.retrieveLostData();
        expect(response.type, RetrieveType.image);
        expect(response.file.path, '/example/path');
      });

      test('retrieveLostData get error response', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
          };
        });
        final LostDataResponse response = await ImagePicker.retrieveLostData();
        expect(response.type, RetrieveType.video);
        expect(response.exception.code, 'test_error_code');
        expect(response.exception.message, 'test_error_message');
      });

      test('retrieveLostData get null response', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return null;
        });
        expect((await ImagePicker.retrieveLostData()).isEmpty, true);
      });

      test('retrieveLostData get both path and error should throw', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
            'path': '/example/path',
          };
        });
        expect(ImagePicker.retrieveLostData(), throwsAssertionError);
      });
    });
  });
}
