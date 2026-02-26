// ignore_for_file: lines_longer_than_80_chars

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:form_dynamic_builder/src/controller/form_controller.dart';
import 'package:form_dynamic_builder/src/models/components/select_component.dart';
import 'package:form_dynamic_builder/src/models/data_source.dart';
import 'package:form_dynamic_builder/src/models/form_config.dart';
import 'package:form_dynamic_builder/src/models/form_settings.dart';
import 'package:form_dynamic_builder/src/services/data_source_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Potter API response — array of books.
const _potterBooksResponse = '''
[
  {"title": "The Philosopher's Stone", "index": 0},
  {"title": "The Chamber of Secrets", "index": 1},
  {"title": "The Prisoner of Azkaban", "index": 2},
  {"title": "The Goblet of Fire", "index": 3}
]
''';

/// Potter API response — single book (filtered).
const _singleBookResponse = '''
[
  {"title": "The Chamber of Secrets", "index": 1}
]
''';

/// Builds a minimal [FormConfig] with the given [components] JSON list.
FormConfig buildConfig({
  Map<String, dynamic>? dsForm,
  List<Map<String, dynamic>> components = const [],
}) {
  return FormConfig(
    id: 'test_form',
    title: 'Test Form',
    description: '',
    components:
        components.map((e) => SelectComponent.fromJson(e)).toList().cast(),
    settings: FormSettings(),
    dsForm: dsForm,
  );
}

/// Builds a [FormController] wrapping the given config.
FormController buildController({
  Map<String, dynamic>? dsForm,
  List<Map<String, dynamic>> components = const [],
  Map<String, String> authHeaders = const {},
}) {
  return FormController(
    config: buildConfig(dsForm: dsForm, components: components),
    authHeaders: authHeaders,
  );
}

// ---------------------------------------------------------------------------
// Tests: URL Interpolation (no HTTP)
// ---------------------------------------------------------------------------

void main() {
  group('DataSourceService.interpolateUrl', () {
    // -----------------------------------------------------------------------
    // Skenario 1: URL tanpa filter (static URL)
    // -----------------------------------------------------------------------
    test('Skenario 1 — URL tanpa filter: tidak ada placeholder, URL tetap sama',
        () {
      const url = 'https://potterapi-fedeperin.vercel.app/en/books';
      final controller = buildController();

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(result, equals(url));
    });

    // -----------------------------------------------------------------------
    // Skenario 2: URL dengan static value dalam URL (bukan placeholder)
    // -----------------------------------------------------------------------
    test(
        'Skenario 2 — URL dengan filter static value dalam URL: tidak ada placeholder',
        () {
      const url = 'https://potterapi-fedeperin.vercel.app/en/books?index=1';
      final controller = buildController();

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(result, equals(url));
    });

    // -----------------------------------------------------------------------
    // Skenario 3: URL dengan filter dari value component lain {{titleBook}}
    // -----------------------------------------------------------------------
    test(
        'Skenario 3 — URL dengan {{component_key}}: mengganti placeholder dengan nilai komponen lain',
        () {
      const url =
          'https://potterapi-fedeperin.vercel.app/en/books?title={{titleBook}}';

      final controller = buildController(
        components: [
          {
            'id': 'c1',
            'type': 'textfield',
            'key': 'titleBook',
            'label': 'Book Title',
          }
        ],
      );

      // Simulasikan user mengisi nilai komponen titleBook.
      controller.updateValue('titleBook', 'The Goblet of Fire');

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(
          result,
          equals(
              'https://potterapi-fedeperin.vercel.app/en/books?title=The Goblet of Fire'));
    });

    test(
        'Skenario 3 — URL dengan {{component_key}} saat value kosong: placeholder diganti empty string',
        () {
      const url =
          'https://potterapi-fedeperin.vercel.app/en/books?title={{titleBook}}';

      final controller = buildController();

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(result,
          equals('https://potterapi-fedeperin.vercel.app/en/books?title='));
    });

    // -----------------------------------------------------------------------
    // Skenario 4: URL dengan filter dari ds_form external variable
    // -----------------------------------------------------------------------
    test(
        'Skenario 4 — URL dengan {{ds_form.task.lcs.bookName}}: mengganti dari dsForm',
        () {
      const url =
          'https://potterapi-fedeperin.vercel.app/en/books?title={{ds_form.task.lcs.bookName}}';

      final controller = buildController(
        dsForm: {
          'task': {
            'lcs': {'bookName': 'The Prisoner of Azkaban'}
          }
        },
      );

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(
          result,
          equals(
              'https://potterapi-fedeperin.vercel.app/en/books?title=The Prisoner of Azkaban'));
    });

    test(
        'Skenario 4 — URL dengan {{ds_form.*}} saat dsForm null: placeholder diganti empty string',
        () {
      const url =
          'https://potterapi-fedeperin.vercel.app/en/books?title={{ds_form.task.lcs.bookName}}';

      final controller = buildController(); // dsForm = null

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(result,
          equals('https://potterapi-fedeperin.vercel.app/en/books?title='));
    });

    // -----------------------------------------------------------------------
    // Skenario 5: URL dengan basic variables (var.static.*)
    // -----------------------------------------------------------------------
    test(
        'Skenario 5 — {{var.static.current_year}}: diganti dengan tahun berjalan',
        () {
      const url =
          'https://potterapi-fedeperin.vercel.app/en/books?publishYear={{var.static.current_year}}';

      final controller = buildController();

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(result, contains(DateTime.now().year.toString()));
    });

    test(
        'Skenario 5 — {{var.static.current_month}}: diganti dengan bulan berjalan (2 digit)',
        () {
      const url = 'https://example.com/api?month={{var.static.current_month}}';
      final controller = buildController();
      final result = DataSourceService.interpolateUrl(url, controller);
      final month = DateTime.now().month.toString().padLeft(2, '0');
      expect(result, contains(month));
    });

    test('Skenario 5 — {{var.static.current_date}}: diganti dengan yyyy-MM-dd',
        () {
      const url = 'https://example.com/api?date={{var.static.current_date}}';
      final controller = buildController();
      final result = DataSourceService.interpolateUrl(url, controller);
      final now = DateTime.now();
      final expected =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(result, contains(expected));
    });

    test(
        'Skenario 5 — multiple placeholders dalam satu URL: semua diganti dengan benar',
        () {
      const url =
          'https://example.com/api?year={{var.static.current_year}}&filter={{ds_form.section.key}}';

      final controller = buildController(
        dsForm: {
          'section': {'key': 'magic'}
        },
      );

      final result = DataSourceService.interpolateUrl(url, controller);

      expect(result, contains(DateTime.now().year.toString()));
      expect(result, contains('magic'));
    });
  });

  // -------------------------------------------------------------------------
  // Tests: extractDependentKeys
  // -------------------------------------------------------------------------
  group('DataSourceService.extractDependentKeys', () {
    test('URL tanpa placeholder: tidak ada dependent keys', () {
      const url = 'https://potterapi-fedeperin.vercel.app/en/books';
      expect(DataSourceService.extractDependentKeys(url), isEmpty);
    });

    test('URL dengan static value hardcoded: tidak ada dependent keys', () {
      const url = 'https://potterapi-fedeperin.vercel.app/en/books?index=1';
      expect(DataSourceService.extractDependentKeys(url), isEmpty);
    });

    test('URL dengan {{var.static.*}}: tidak dianggap dependent key', () {
      const url = 'https://example.com/api?year={{var.static.current_year}}';
      expect(DataSourceService.extractDependentKeys(url), isEmpty);
    });

    test('URL dengan {{ds_form.*}}: tidak dianggap dependent key', () {
      const url = 'https://example.com/api?filter={{ds_form.task.lcs.key}}';
      expect(DataSourceService.extractDependentKeys(url), isEmpty);
    });

    test('URL dengan {{component_key}}: dianggap dependent key', () {
      const url =
          'https://potterapi-fedeperin.vercel.app/en/books?title={{titleBook}}';
      expect(DataSourceService.extractDependentKeys(url), {'titleBook'});
    });

    test('URL dengan multiple component keys: semua terdeteksi', () {
      const url =
          'https://example.com/api?province={{province_id}}&city={{city_id}}&year={{var.static.current_year}}';
      expect(DataSourceService.extractDependentKeys(url),
          {'province_id', 'city_id'});
    });
  });

  // -------------------------------------------------------------------------
  // Tests: fetchOptions (dengan MockClient)
  // -------------------------------------------------------------------------
  group('DataSourceService.fetchOptions', () {
    // -----------------------------------------------------------------------
    // Skenario 1: API GET tanpa filter — ambil semua buku
    // -----------------------------------------------------------------------
    test('Skenario 1 — GET tanpa filter: mengembalikan semua options dari API',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            'https://potterapi-fedeperin.vercel.app/en/books');
        expect(request.method, 'GET');
        return http.Response(_potterBooksResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://potterapi-fedeperin.vercel.app/en/books',
        labelPath: 'title',
        valuePath: 'index',
      );

      final controller = buildController();

      final options = await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(options.length, 4);
      expect(options[0].label, "The Philosopher's Stone");
      expect(options[0].value, '0');
      expect(options[3].label, 'The Goblet of Fire');
      expect(options[3].value, '3');
    });

    // -----------------------------------------------------------------------
    // Skenario 2: filter dari static value dalam URL (bukan placeholder)
    // -----------------------------------------------------------------------
    test(
        'Skenario 2 — GET dengan static filter dalam URL: mengembalikan hasil terfilter',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            'https://potterapi-fedeperin.vercel.app/en/books?index=1');
        return http.Response(_singleBookResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://potterapi-fedeperin.vercel.app/en/books?index=1',
        labelPath: 'title',
        valuePath: 'index',
      );

      final controller = buildController();

      final options = await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(options.length, 1);
      expect(options[0].label, 'The Chamber of Secrets');
      expect(options[0].value, '1');
    });

    // -----------------------------------------------------------------------
    // Skenario 3: filter dari value component lain {{titleBook}}
    // -----------------------------------------------------------------------
    test(
        'Skenario 3 — GET dengan filter dari komponen lain: URL di-interpolasi sebelum request',
        () async {
      String? capturedUrl;

      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_singleBookResponse, 200);
      });

      final api = DataSourceApi(
        url:
            'https://potterapi-fedeperin.vercel.app/en/books?title={{titleBook}}',
        labelPath: 'title',
        valuePath: 'index',
      );

      final controller = buildController(
        components: [
          {
            'id': 'c1',
            'type': 'textfield',
            'key': 'titleBook',
            'label': 'Book Title',
          }
        ],
      );
      controller.updateValue('titleBook', 'The Chamber of Secrets');

      await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      // Uri.parse encodes spaces as %20; decode before comparing.
      expect(Uri.decodeFull(capturedUrl!),
          'https://potterapi-fedeperin.vercel.app/en/books?title=The Chamber of Secrets');
    });

    // -----------------------------------------------------------------------
    // Skenario 4: filter dari ds_form external variable
    // -----------------------------------------------------------------------
    test(
        'Skenario 4 — GET dengan filter dari ds_form: variabel eksternal di-resolve dengan benar',
        () async {
      String? capturedUrl;

      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_singleBookResponse, 200);
      });

      final api = DataSourceApi(
        url:
            'https://potterapi-fedeperin.vercel.app/en/books?title={{ds_form.task.lcs.bookTitle}}',
        labelPath: 'title',
        valuePath: 'index',
      );

      final controller = buildController(
        dsForm: {
          'task': {
            'lcs': {'bookTitle': 'The Prisoner of Azkaban'}
          }
        },
      );

      await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      // Uri.parse encodes spaces as %20; decode before comparing.
      expect(Uri.decodeFull(capturedUrl!),
          'https://potterapi-fedeperin.vercel.app/en/books?title=The Prisoner of Azkaban');
    });

    // -----------------------------------------------------------------------
    // Skenario 5: filter dari basic variable (current_year)
    // -----------------------------------------------------------------------
    test(
        'Skenario 5 — GET dengan {{var.static.current_year}}: URL mengandung tahun berjalan',
        () async {
      String? capturedUrl;

      final mockClient = MockClient((request) async {
        capturedUrl = request.url.toString();
        return http.Response(_potterBooksResponse, 200);
      });

      final api = DataSourceApi(
        url:
            'https://potterapi-fedeperin.vercel.app/en/books?publishYear={{var.static.current_year}}',
        labelPath: 'title',
        valuePath: 'index',
      );

      final controller = buildController();

      await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(capturedUrl, contains(DateTime.now().year.toString()));
      expect(capturedUrl, isNot(contains('{{var.static.current_year}}')));
    });

    // -----------------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------------
    test('API mengembalikan status 500: fetchOptions mengembalikan list kosong',
        () async {
      final mockClient =
          MockClient((_) async => http.Response('Internal Server Error', 500));

      final api = DataSourceApi(
        url: 'https://potterapi-fedeperin.vercel.app/en/books',
        labelPath: 'title',
        valuePath: 'index',
      );

      final options = await DataSourceService.fetchOptions(
        api: api,
        controller: buildController(),
        httpClient: mockClient,
      );

      expect(options, isEmpty);
    });

    test('Network error (exception): fetchOptions mengembalikan list kosong',
        () async {
      // MockClient yang langsung throw exception saat dipakai.
      final mockClient = MockClient((_) async {
        throw const SocketException('Connection refused');
      });

      final api = DataSourceApi(
        url: 'https://potterapi-fedeperin.vercel.app/en/books',
        labelPath: 'title',
        valuePath: 'index',
      );

      final options = await DataSourceService.fetchOptions(
        api: api,
        controller: buildController(),
        httpClient: mockClient,
      );

      expect(options, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Auth headers
    // -----------------------------------------------------------------------
    test('Auth headers dari FormController dikirim dalam request', () async {
      Map<String, String>? capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedHeaders = request.headers;
        return http.Response(_potterBooksResponse, 200);
      });

      final api = DataSourceApi(
        url: 'https://potterapi-fedeperin.vercel.app/en/books',
        labelPath: 'title',
        valuePath: 'index',
      );

      final controller = buildController(
        authHeaders: {'Authorization': 'Bearer test_token_123'},
      );

      await DataSourceService.fetchOptions(
        api: api,
        controller: controller,
        httpClient: mockClient,
      );

      expect(capturedHeaders?['Authorization'], 'Bearer test_token_123');
    });

    // -----------------------------------------------------------------------
    // dataKey (nested response)
    // -----------------------------------------------------------------------
    test('dataKey nested: mengekstrak data dari nested key dengan benar',
        () async {
      const nestedResponse = '''
      {
        "status": "ok",
        "data": {
          "results": [
            {"title": "The Philosopher's Stone", "index": 0}
          ]
        }
      }
      ''';

      final mockClient =
          MockClient((_) async => http.Response(nestedResponse, 200));

      final api = DataSourceApi(
        url: 'https://example.com/api',
        dataKey: 'data.results',
        labelPath: 'title',
        valuePath: 'index',
      );

      final options = await DataSourceService.fetchOptions(
        api: api,
        controller: buildController(),
        httpClient: mockClient,
      );

      expect(options.length, 1);
      expect(options[0].label, "The Philosopher's Stone");
    });
  });
}
