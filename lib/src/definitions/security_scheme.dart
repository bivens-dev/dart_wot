// Copyright 2021 The NAMIB Project Developers
//
// Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
// https://www.apache.org/licenses/LICENSE-2.0> or the MIT license
// <LICENSE-MIT or https://opensource.org/licenses/MIT>, at your
// option. This file may not be copied, modified, or distributed
// except according to those terms.
//
// SPDX-License-Identifier: MIT OR Apache-2.0

/// Class that contains metadata describing the configuration of a security
/// mechanism.
///
///
class SecurityScheme {
  /// The actual security [scheme] identifier.
  ///
  /// Can be one of `nosec`, `combo`, `basic`, `digest`, `bearer`, `psk`,
  /// `oauth2`, or `apikey`.
  // TODO(JKRhb): Should this field be optional? See https://w3c.github.io/wot-thing-description/#td-vocab-scheme--SecurityScheme
  late String scheme;

  /// The default [description] of this [SecurityScheme].
  String? description;

  /// A [Map] of multi-language [descriptions].
  final Map<String, String> descriptions = {};

  ///
  String? proxy;

  /// A [List] of JSON-LD `@type` annotations.
  List<String>? jsonLdType = [];

  /// Creates a new [SecurityScheme] from the optional parameters [scheme],
  /// [description], and [proxy].
  SecurityScheme(this.scheme, this.description, this.proxy);

  /// Creates a [SecurityScheme] from a [json] object.
  SecurityScheme.fromJson(Map<String, dynamic> json) {
    final dynamic scheme = json["scheme"];
    if (scheme is! String) {
      throw ArgumentError(
          'Illegal type ${scheme.runtimeType} found for SecurityScheme');
    }
    this.scheme = scheme;

    if (json["proxy"] is String) {
      proxy = json["proxy"] as String;
    }

    if (json["description"] is String) {
      description = json["description"] as String;
    }

    if (json["descriptions"] is Map<String, dynamic>) {
      final descriptions = json["descriptions"] as Map<String, dynamic>;
      for (final entry in descriptions.entries) {
        final dynamic value = entry.value;
        if (value is String) {
          this.descriptions[entry.key] = value;
        }
      }
    }

    final dynamic jsonLdType = json["@type"];

    if (jsonLdType is String) {
      this.jsonLdType = [jsonLdType];
    } else if (jsonLdType is List<String>) {
      this.jsonLdType = jsonLdType;
    }

    // TODO(JKRhb): Parse additional fields
  }
}
