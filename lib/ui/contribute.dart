import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsdroid/bloc/ui_bloc.dart';

class ContributePage extends StatelessWidget {
  final String repoUrl = 'https://github.com/heckmon/vsdroid';

  const ContributePage({super.key});

  void _launchRepo() async {
    final uri = Uri.parse(repoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.read<AppThemeBloc>().state.appTheme.selectScreenCardTextColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute'),
        titleTextStyle: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 20
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volunteer_activism, color: Colors.pinkAccent, size: 56),
                    const SizedBox(height: 18),
                    Text(
                      'Contribute to VSDroid!',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'This is an open source project.\n\nIf you would like to contribute or have any issues, please create a PR or issue on this repo:',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: color.withAlpha(220)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 4,
                      ),
                      onPressed: _launchRepo,
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      label: const Text(
                        'Go to GitHub',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}