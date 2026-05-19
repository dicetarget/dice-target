import 'package:dice/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../data/vs_head_to_head_service.dart';
import '../../domain/vs_head_to_head_model.dart';

class VsHeadToHeadCard extends StatefulWidget {
  final String myId;
  final String friendId;
  final String myName;
  final String friendName;

  const VsHeadToHeadCard({
    super.key,
    required this.myId,
    required this.friendId,
    required this.myName,
    required this.friendName,
  });

  @override
  State<VsHeadToHeadCard> createState() => _VsHeadToHeadCardState();
}

class _VsHeadToHeadCardState extends State<VsHeadToHeadCard> {
  final _service = VsHeadToHeadService();
  VsHeadToHeadModel? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.load(widget.myId, widget.friendId);
    if (mounted) setState(() { _data = data; _loading = false; });
  }

  bool get _iAmUserA => VsHeadToHeadModel.isUserA(widget.myId, widget.friendId);

  int get _myWins => _iAmUserA ? (_data?.userAWins ?? 0) : (_data?.userBWins ?? 0);
  int get _friendWins => _iAmUserA ? (_data?.userBWins ?? 0) : (_data?.userAWins ?? 0);
  String get _lastWinnerLabel {
    final id = _data?.lastWinnerId ?? '';
    if (id.isEmpty) return '—';
    if (id == widget.myId) return 'You';
    return widget.friendName;
  }

  String _lastPlayedLabel() {
    final dt = _data?.lastPlayedAt;
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return 'Last played: ${diff.inDays}d ago';
    if (diff.inHours >= 1) return 'Last played: ${diff.inHours}h ago';
    return 'Last played: just now';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 0.8),
      ),
      child: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.modeVS, strokeWidth: 2),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final noData = (_data?.totalMatches ?? 0) == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You vs ${widget.friendName}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.modeVS,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 14),
        if (noData)
          const Text(
            'No matches played yet',
            style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
          )
        else ...[
          Row(
            children: [
              _statBlock('Matches', '${_data!.totalMatches}'),
              _divider(),
              _statBlock('Wins', '$_myWins – $_friendWins'),
              _divider(),
              _statBlock('Last Winner', _lastWinnerLabel),
            ],
          ),
          if (_lastPlayedLabel().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _lastPlayedLabel(),
              style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
            ),
          ],
        ],
      ],
    );
  }

  Widget _statBlock(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: Colors.white.withValues(alpha: 0.08),
      );
}
