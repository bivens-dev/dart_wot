// Copyright 2021 Contributors to the Eclipse Foundation. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// SPDX-License-Identifier: BSD-3-Clause

part of "interaction_affordance.dart";

/// Class representing an [Action] Affordance in a Thing Description.
@immutable
final class Action extends InteractionAffordance {
  /// Creates a new [Action] from a [List] of [forms].
  const Action({
    required super.forms,
    super.title,
    super.titles,
    super.description,
    super.descriptions,
    super.uriVariables,
    super.additionalFields,
    this.safe = false,
    this.idempotent = false,
    this.synchronous,
    this.input,
    this.output,
  });

  /// Creates a new [Action] from a [json] object.
  factory Action.fromJson(
    Map<String, dynamic> json,
    PrefixMapping prefixMapping,
  ) {
    final Set<String> parsedFields = {};

    final title = json.parseField<String>("title", parsedFields);
    final titles = json.parseMapField<String>("titles", parsedFields);
    final description = json.parseField<String>("description", parsedFields);
    final descriptions =
        json.parseMapField<String>("descriptions", parsedFields);
    final uriVariables = json.parseDataSchemaMapField(
      "uriVariables",
      prefixMapping,
      parsedFields,
    );

    final safe = json.parseField<bool>("safe", parsedFields) ?? false;
    final idempotent =
        json.parseField<bool>("idempotent", parsedFields) ?? false;
    final synchronous = json.parseField<bool>("synchronous", parsedFields);
    final input =
        json.parseDataSchemaField("input", prefixMapping, parsedFields);
    final output =
        json.parseDataSchemaField("output", prefixMapping, parsedFields);

    final forms = json.parseAffordanceForms(prefixMapping, parsedFields);
    final additionalFields =
        json.parseAdditionalFields(prefixMapping, parsedFields);

    final action = Action(
      forms: forms,
      title: title,
      titles: titles,
      description: description,
      descriptions: descriptions,
      uriVariables: uriVariables,
      safe: safe,
      idempotent: idempotent,
      synchronous: synchronous,
      input: input,
      output: output,
      additionalFields: additionalFields,
    );

    return action;
  }

  /// The schema of the [input] data this [Action] accepts.
  final DataSchema? input;

  /// The schema of the [output] data this [Action] produces.
  final DataSchema? output;

  /// Indicates whether the Action is idempotent (=true) or not.
  ///
  /// Informs whether the Action can be called repeatedly with the same result,
  /// if present, based on the same input.
  final bool idempotent;

  /// Signals if the Action is safe (=true) or not.
  ///
  /// Used to signal if there is no internal state (cf. resource state) is
  /// changed when invoking an Action. In that case responses can be cached as
  /// example.
  final bool safe;

  /// Indicates whether the action is synchronous (=true) or not.
  ///
  /// A synchronous action means that the response of action contains all the
  /// information about the result of the action and no further querying about
  /// the status of the action is needed. Lack of this keyword means that no
  /// claim on the synchronicity of the action can be made.
  final bool? synchronous;
}
