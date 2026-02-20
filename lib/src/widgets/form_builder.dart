import 'package:flutter/material.dart';

import '../controller/form_controller.dart';
import '../models/form_config.dart';
import '../registry/component_registry.dart';
import '../utils/form_constants.dart';

class FormDynamicBuilder extends StatefulWidget {
  final FormController controller;
  final EdgeInsetsGeometry? padding;

  const FormDynamicBuilder({
    super.key,
    required this.controller,
    this.padding,
  });

  @override
  State<FormDynamicBuilder> createState() => _FormDynamicBuilderState();
}

class _FormDynamicBuilderState extends State<FormDynamicBuilder> {
  late FormController _controller;
  late final ComponentRegistry _registry;

  @override
  void initState() {
    super.initState();
    _registry = ComponentRegistry();
    _attachController(widget.controller);
  }

  @override
  void didUpdateWidget(covariant FormDynamicBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController(widget.controller);
    }
  }

  @override
  void dispose() {
    _detachController(_controller);
    super.dispose();
  }

  void _attachController(FormController controller) {
    _controller = controller;
    _controller.addListener(_onControllerChange);
  }

  void _detachController(FormController controller) {
    controller.removeListener(_onControllerChange);
  }

  void _onControllerChange() => setState(() {});

  FormConfig get _config => _controller.config;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              title: _config.title,
              description: _config.description,
            ),
            const SizedBox(height: 8),
            ...(_config.type == FormConstants.formTypeWizard
                ? _buildWizard(context)
                : _buildFlat(context)),
          ],
        ),
      ),
    );
  }

  // ---------- RENDER MODES ----------

  List<Widget> _buildFlat(BuildContext context) {
    return _buildComponents(_config.components);
  }

  List<Widget> _buildWizard(BuildContext context) {
    // kalau currentStep valid -> render 1 step; kalau tidak -> render semua step (fallback)
    final steps = _config.steps;
    final int i = _controller.currentStep;

    if (i >= 0 && i < steps.length) {
      return [_StepSection(step: steps[i], buildComponents: _buildComponents)];
    }

    return steps
        .map((s) => _StepSection(step: s, buildComponents: _buildComponents))
        .toList();
  }

  // ---------- COMMON BUILDER ----------

  List<Widget> _buildComponents(List components) {
    // NOTE: kalau kamu punya tipe model component spesifik, ganti `List` jadi `List<FormComponentConfig>` dll.
    return components
        .where((c) => _controller.isComponentVisible(c))
        .map<Widget>(
          (c) => KeyedSubtree(
            key: ValueKey(c.key),
            child: _registry.build(c, _controller),
          ),
        )
        .toList();
  }
}

// =============== SMALL WIDGETS ===============

class _Header extends StatelessWidget {
  final String title;
  final String description;

  const _Header({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (title.isNotEmpty) {
      children.add(Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ));
    }

    if (description.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(Text(
        description,
        style: Theme.of(context).textTheme.bodyMedium,
      ));
      children.add(const SizedBox(height: 16));
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _StepSection extends StatelessWidget {
  final dynamic step;
  final List<Widget> Function(List components) buildComponents;

  const _StepSection({
    required this.step,
    required this.buildComponents,
  });

  @override
  Widget build(BuildContext context) {
    final title = step.title as String? ?? '';
    final components = step.components as List? ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ...buildComponents(components),
      ],
    );
  }
}
