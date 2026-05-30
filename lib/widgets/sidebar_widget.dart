import 'package:flutter/material.dart';

enum ViewType {
  agent,
  calendar,
  schedule,
}

class SidebarWidget extends StatelessWidget {
  final ViewType currentView;
  final ValueChanged<ViewType> onViewChanged;

  const SidebarWidget({
    super.key,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(context),
          const SizedBox(height: 32),
          Expanded(
            child: _buildMenuItems(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.calendar_today,
            size: 32,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '语音日历',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        _buildMenuItem(
          context,
          icon: Icons.chat,
          label: 'Agent对话框',
          viewType: ViewType.agent,
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          context,
          icon: Icons.calendar_month,
          label: '日历视图',
          viewType: ViewType.calendar,
        ),
        const SizedBox(height: 8),
        _buildMenuItem(
          context,
          icon: Icons.list,
          label: '日程视图',
          viewType: ViewType.schedule,
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ViewType viewType,
  }) {
    final isSelected = currentView == viewType;

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onViewChanged(viewType),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: isSelected
                    ? Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).primaryColor,
                        )
                    : Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}