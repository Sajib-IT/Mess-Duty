import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/mess_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/shared_widgets.dart';

class SearchInviteView extends StatelessWidget {
  const SearchInviteView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MessController>();
    final searchCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Invite Members'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchCtrl,
              onChanged: (v) {
                if (v.trim().length >= 2) ctrl.searchUsers(v.trim());
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => ctrl.isSearching.value
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const SizedBox()),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final results = ctrl.searchResults;
              if (results.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.person_search,
                  title: 'Search for members',
                  subtitle: 'Type at least 2 characters to search users not in any mess.',
                );
              }
              return ListView.builder(
                itemCount: results.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (ctx, i) => _UserResultCard(user: results[i], ctrl: ctrl),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _UserResultCard extends StatefulWidget {
  final UserModel user;
  final MessController ctrl;
  const _UserResultCard({required this.user, required this.ctrl});

  @override
  State<_UserResultCard> createState() => _UserResultCardState();
}

class _UserResultCardState extends State<_UserResultCard> {
  bool _invited = false;

  @override
  Widget build(BuildContext context) {
    final mess = widget.ctrl.currentMess.value;
    final alreadyMember = mess?.memberIds.contains(widget.user.uid) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AppAvatar(photoUrl: widget.user.photoUrl, name: widget.user.name),
        title: Text(widget.user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(widget.user.email, style: const TextStyle(fontSize: 12)),
        trailing: alreadyMember
            ? const Chip(label: Text('Member'))
            : _invited
                ? const Chip(
                    label: Text('Invited'),
                    backgroundColor: Color(0xFFE8F5E9),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      await widget.ctrl.inviteUser(widget.user);
                      setState(() => _invited = true);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Invite'),
                  ),
      ),
    );
  }
}


