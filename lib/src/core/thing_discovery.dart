// Copyright 2021 The NAMIB Project Developers. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:coap/coap.dart';

import '../../core.dart';
import '../../scripting_api.dart' as scripting_api;
import '../definitions/thing_description.dart';
import 'content.dart';

/// Custom [Exception] that is thrown when the discovery process fails.
class DiscoveryException implements Exception {
  /// Creates a new [DiscoveryException] with the specified error [message].
  DiscoveryException(this.message);

  /// The error message of this exception.
  final String message;

  @override
  String toString() {
    return 'DiscoveryException: $message';
  }
}

/// Implemention of the [scripting_api.ThingDiscovery] interface.
class ThingDiscovery extends Stream<ThingDescription>
    implements scripting_api.ThingDiscovery {
  /// Creates a new [ThingDiscovery] object with a given [thingFilter].
  ThingDiscovery(this.thingFilter, this._servient)
      : _client = _servient.clientFor(thingFilter.url.scheme) {
    _stream = _start();
  }

  final Servient _servient;

  bool _active = true;

  @override
  bool get active => _active;

  @override
  final scripting_api.ThingFilter thingFilter;

  late final Stream<ThingDescription> _stream;

  final ProtocolClient _client;

  Stream<ThingDescription> _start() async* {
    final discoveryMethod = thingFilter.method;

    switch (discoveryMethod) {
      case scripting_api.DiscoveryMethod.direct:
        yield* _discoverDirectly(thingFilter.url);
        break;
      case scripting_api.DiscoveryMethod.coreLinkFormat:
        yield* _discoverWithCoreLinkFormat(thingFilter.url);
        break;
      default:
        throw UnimplementedError();
    }
  }

  @override
  Future<void> stop() async {
    await _client.stop();
    _active = false;
  }

  Future<ThingDescription> _decodeThingDescription(
    Content content,
    Uri uri,
  ) async {
    final value = await _servient.contentSerdes.contentToValue(content, null);
    if (value is! Map<String, dynamic>) {
      throw DiscoveryException(
        'Could not parse Thing Description obtained from $uri',
      );
    }

    return ThingDescription.fromJson(value);
  }

  Stream<ThingDescription> _discoverDirectly(Uri uri) async* {
    yield* _client
        .discoverDirectly(uri, disableMulticast: true)
        .asyncMap((content) => _decodeThingDescription(content, uri));
  }

  Future<List<CoapWebLink>?> _getCoreWebLinks(Content content) async {
    final value = await _servient.contentSerdes.contentToValue(content, null);
    if (value is CoapWebLink) {
      return [value];
    } else if (value is List<CoapWebLink>) {
      return value;
    }

    return null;
  }

  Future<Iterable<Uri>> _filterCoreWebLinks(
    String resourceType,
    Content coreWebLink,
    Uri baseUri,
  ) async {
    final webLinks = await _getCoreWebLinks(coreWebLink);

    if (webLinks == null) {
      throw DiscoveryException(
        'Discovery from $baseUri returned no valid CoRE Link-Format Links.',
      );
    }

    return webLinks
        .where(
          (element) =>
              element.attributes.getResourceTypes()?.contains(resourceType) ??
              false,
        )
        .map((weblink) => Uri.tryParse(weblink.uri))
        .whereType<Uri>()
        .map((uri) => uri.toAbsoluteUri(baseUri));
  }

  Stream<ThingDescription> _discoverWithCoreLinkFormat(Uri uri) async* {
    // TODO: Remove additional quotes once fixed in CoAP library
    yield* _performCoreLinkFormatDiscovery('"wot.thing"', uri)
        .map(_discoverDirectly)
        .flatten();
  }

  Stream<Uri> _performCoreLinkFormatDiscovery(
    String resourceType,
    Uri uri,
  ) async* {
    final Set<Uri> discoveredUris = {};
    final discoveryUri = uri.toLinkFormatDiscoveryUri(resourceType);
    await for (final coreWebLink
        in _client.discoverWithCoreLinkFormat(discoveryUri)) {
      final Iterable<Uri> parsedUris;

      try {
        parsedUris =
            await _filterCoreWebLinks(resourceType, coreWebLink, discoveryUri);
      } on Exception catch (exception) {
        yield* Stream.error(exception);
        continue;
      }

      for (final parsedUri in parsedUris) {
        final uriAdded = discoveredUris.add(parsedUri);

        if (!uriAdded) {
          continue;
        }

        yield parsedUri;
      }
    }
  }

  @override
  StreamSubscription<ThingDescription> listen(
    void Function(ThingDescription event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    Future<void> cleanUpAndDone() async {
      await stop();
      if (onDone != null) {
        onDone();
      }
    }

    return _stream.listen(
      onData,
      onError: onError,
      onDone: cleanUpAndDone,
      cancelOnError: cancelOnError,
    );
  }
}

extension _UriExtension on Uri {
  /// Returns the [path] if it is not empty, otherwise `null`.
  String? get _pathOrNull {
    if (path.isNotEmpty) {
      return path;
    }

    return null;
  }

  /// Converts this [Uri] to one usable for CoRE Resource Discovery.
  ///
  /// If no path should be given (i.e., it is empty) `/.well-known/core` will be
  /// used as a default.
  ///
  /// The specified [resourceType] will be added to the [queryParameters] using
  /// the parameter name `rt`. If this name should already be in use, it will
  /// not be overridden.
  Uri toLinkFormatDiscoveryUri(String resourceType) {
    final Map<String, dynamic> newQueryParameters = {'rt': resourceType};
    if (queryParameters.isNotEmpty) {
      newQueryParameters.addAll(queryParameters);
    }

    return replace(
      path: _pathOrNull ?? '/.well-known/core',
      queryParameters: newQueryParameters,
    );
  }

  /// Converts this [Uri] into an absolute one using a [baseUri].
  ///
  /// If this [Uri] should already be an absolute one, it is returned directly.
  Uri toAbsoluteUri(Uri baseUri) {
    if (isAbsolute) {
      return this;
    }

    return replace(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
    );
  }
}

/// Extension to simplify the handling of nested [Stream]s.
extension _FlatStreamExtension<T> on Stream<Stream<T>> {
  /// Flattens a nested [Stream] of [Stream]s into a single [Stream].
  Stream<T> flatten() async* {
    await for (final stream in this) {
      yield* stream;
    }
  }
}
