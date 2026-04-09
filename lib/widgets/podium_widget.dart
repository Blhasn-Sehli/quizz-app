import 'package:flutter/material.dart';

class PodiumWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topPlayers;

  const PodiumWidget({
    Key? key,
    required this.topPlayers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top 3 podium
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Second place
              _buildPodiumPlayer(
                2,
                topPlayers.length > 1 ? topPlayers[1] : null,
                Colors.grey[400],
              ),
              const SizedBox(width: 20),
              // First place
              _buildPodiumPlayer(
                1,
                topPlayers.isNotEmpty ? topPlayers[0] : null,
                Colors.yellow[700],
                isWinner: true,
              ),
              const SizedBox(width: 20),
              // Third place
              _buildPodiumPlayer(
                3,
                topPlayers.length > 2 ? topPlayers[2] : null,
                Colors.orange[400],
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Medal icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              final medals = ['🥇', '🥈', '🥉'];
              final names = topPlayers.length > index ? topPlayers[index]['name'] : '';
              return Column(
                children: [
                  Text(
                    medals[index],
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    names,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlayer(
    int position,
    Map<String, dynamic>? player,
    Color? color,
    {bool isWinner = false}
  ) {
    if (player == null) {
      return Container(
        width: 80,
        height: 100 + (isWinner ? 30 : 0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 80,
      height: 100 + (isWinner ? 30 : 0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isWinner
            ? [
                BoxShadow(
                  color: Colors.yellow[700]!.withAlpha((0.6 * 255).round()),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            player['avatar'] ?? '👤',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            player['name'],
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${player['score']}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
