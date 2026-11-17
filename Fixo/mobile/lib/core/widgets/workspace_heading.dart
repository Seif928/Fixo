import 'package:material_ui/material_ui.dart';
import '../theme/fixo_colors.dart';
import '../theme/fixo_workspace_theme.dart';

/// A shared visual language with task-specific identity, not a role selector.
class WorkspaceHeading extends StatelessWidget {
  const WorkspaceHeading({
    super.key,
    required this.workspace,
    required this.isArabic,
    this.action,
  });
  final FixoWorkspace workspace;
  final bool isArabic;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = context.fixoPalette;
    return Container(
      key: ValueKey('workspace-${workspace.name}'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        border: Border.all(color: palette.subtleBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  workspace.icon,
                  color: palette.primaryBrand,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workspace.label(isArabic),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      workspace.description(isArabic),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.mutedText,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}
