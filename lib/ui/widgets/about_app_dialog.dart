import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AboutDialog(
      applicationIcon:
      SizedBox(width: 24, height: 24, child: Image.asset('assets/logo.png')),
      children: [
        AboutContent(),
        const Divider(),
        const Text("Created by: Teemu Puurunen"),
        GithubLink()
      ],
    );
  }
}

class AboutContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'About',
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.0),
        Text("App designed for simplistic task management. Manage tasks and task lists maintained on your local device."),
        SizedBox(height: 12.0),
        Text("Remember that mobile devices can be easily lost or stolen. To safeguard your privacy, avoid saving sensitive personal data within this app."),
        SizedBox(height: 12.0),
        Text("Task Swiper logo was created with the assistance of DALL·E 2")
      ],
    );
  }
}

class GithubLink extends StatelessWidget {
  final String url = 'https://github.com/temedeus/task_swiper';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Text(
        url,
        style: const TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
      ),
    );
  }
}
