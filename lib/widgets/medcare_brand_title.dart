import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../state/medical_store.dart';

class MedCareBrandTitle extends StatelessWidget {
  const MedCareBrandTitle({super.key, this.pageTitle});

  final String? pageTitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E7FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: Color(0xFF0057CD),
            size: 21,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                pageTitle ?? 'MedCare Hospital',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0057CD),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Cơ sở 1 • Q. Hoàn Kiếm',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MedCareHeaderActions extends StatelessWidget {
  const MedCareHeaderActions({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MedicalScope.of(context);
    final unread = store.unreadNotificationCount;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () {
            store.refreshNotificationsFromBackend();
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            backgroundColor: const Color(0xFFBA1A1A),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFFE2E7FF),
            child: Icon(Icons.person, color: Color(0xFF0057CD), size: 20),
          ),
        ),
      ],
    );
  }
}
