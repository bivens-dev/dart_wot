// Copyright 2021 Contributors to the Eclipse Foundation. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

import "package:curie/curie.dart";
import "package:meta/meta.dart";

import "additional_expected_response.dart";
import "expected_response.dart";
import "extensions/json_parser.dart";
import "operation_type.dart";

/// Contains the information needed for performing interactions with a Thing.
@immutable
class Form {
  /// Creates a new [Form] object.
  ///
  /// An [href] has to be provided. A [contentType] is optional.
  Form(
    this.href, {
    this.contentType = "application/json",
    this.contentCoding,
    this.subprotocol,
    this.security,
    this.op,
    this.scopes,
    this.response,
    this.additionalResponses,
    Map<String, dynamic>? additionalFields,
  }) {
    if (additionalFields != null) {
      this.additionalFields.addAll(additionalFields);
    }
  }

  /// Creates a new [Form] from a [json] object.
  factory Form.fromJson(
    Map<String, dynamic> json,
    PrefixMapping prefixMapping,
  ) {
    final Set<String> parsedFields = {};
    final href = json.parseRequiredUriField("href", parsedFields);

    final subprotocol = json.parseField<String>("subprotocol", parsedFields);

    final op = json.parseOperationTypes(parsedFields);

    final contentType = json.parseField<String>("contentType", parsedFields) ??
        "application/json";

    final contentCoding =
        json.parseField<String>("contentCoding", parsedFields);

    final security = json.parseArrayField<String>(
      "security",
      parsedFields: parsedFields,
      minimalSize: 1,
    );
    final scopes =
        json.parseArrayField<String>("scopes", parsedFields: parsedFields);
    final response = json.parseExpectedResponse(prefixMapping, parsedFields);

    final additionalResponses = json.parseAdditionalExpectedResponse(
      prefixMapping,
      contentType,
      parsedFields,
    );

    final additionalFields =
        json.parseAdditionalFields(prefixMapping, parsedFields);

    return Form(
      href,
      contentType: contentType,
      contentCoding: contentCoding,
      subprotocol: subprotocol,
      op: op,
      scopes: scopes,
      security: security,
      response: response,
      additionalResponses: additionalResponses,
      additionalFields: additionalFields,
    );
  }

  /// The [href] pointing to the resource.
  ///
  /// Can be a relative or absolute URI.
  final Uri href;

  /// The subprotocol that is used with this [Form].
  final String? subprotocol;

  /// The operation types supported by this [Form].
  final List<OperationType>? op;

  /// The [contentType] supported by this [Form].
  final String contentType;

  /// The content coding supported by this [Form].
  ///
  /// Content coding values indicate an encoding transformation that has been or
  /// can be applied to a representation.
  /// Content codings are primarily used to allow a representation to be
  /// compressed or otherwise usefully transformed without losing the identity
  /// of its underlying media type and without loss of information.
  /// Examples of content coding include "gzip", "deflate", etc.
  final String? contentCoding;

  /// The list of [security] definitions applied to this [Form].
  final List<String>? security;

  /// A list of OAuth2 scopes that are supposed to be used with this [Form].
  final List<String>? scopes;

  /// The [response] a consumer can expect from interacting with this [Form].
  final ExpectedResponse? response;

  /// This optional term can be used if additional expected responses are
  /// possible, e.g. for error reporting.
  ///
  /// Each additional response needs to be distinguished from others in some way
  /// (for example, by specifying a protocol-specific error code), and may also
  ///  have its own data schema.
  final List<AdditionalExpectedResponse>? additionalResponses;

  /// Additional fields collected during the parsing of a JSON object.
  final Map<String, dynamic> additionalFields = {};
}
