import 'package:flutter/material.dart';
import '../../models/form_component.dart';
import '../../services/mixins/data_source_mixin.dart';

/// A shared widget to handle the loading, error, and loaded states
/// of components that fetch data from a [DataSource].
class DataSourceStateBuilder extends StatelessWidget {
  final DataSourceMixin logic;
  final FormComponent component;
  final WidgetBuilder builder;

  const DataSourceStateBuilder({
    super.key,
    required this.logic,
    required this.component,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // If no dataSource is configured, render the main content directly.
    // This removes unnecessary state listeners for static components.
    if (component.dataSource == null) {
      return builder(context);
    }

    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) {
        switch (logic.dsState) {
          case DataSourceState.loading:
            return _buildLoading(context);
          case DataSourceState.error:
            return _buildError(context);
          case DataSourceState.loaded:
          case DataSourceState.initial:
            return builder(context);
        }
      },
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          logic.dsError ?? 'Failed to load data',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
