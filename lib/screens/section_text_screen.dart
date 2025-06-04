import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class SectionTextScreen extends StatelessWidget {
  final String sectionTitle;
  final String sectionTitleHindi;
  final String sectionText;
  final String sectionTextHindi;
  final String sectionNumber;

  const SectionTextScreen({
    Key? key,
    required this.sectionTitle,
    required this.sectionTitleHindi,
    required this.sectionText,
    required this.sectionTextHindi,
    required this.sectionNumber,
  }) : super(key: key);

  void _shareSection() {
    final String shareText = '''
Section $sectionNumber

${sectionTitleHindi.isNotEmpty ? '$sectionTitleHindi\n' : ''}$sectionTitle

${sectionTextHindi.isNotEmpty ? 'हिंदी में:\n$sectionTextHindi\n\n' : ''}In English:
$sectionText
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section $sectionNumber',
              style: const TextStyle(
                color: Color.fromRGBO(123, 109, 217, 1),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              sectionTitle,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share,
                color: Color.fromRGBO(123, 109, 217, 1)),
            onPressed: _shareSection,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hindi Title
            if (sectionTitleHindi.isNotEmpty)
              Text(
                sectionTitleHindi,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 8),
            // English Title
            Text(
              sectionTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Hindi Text
            if (sectionTextHindi.isNotEmpty) ...[
              const Text(
                'हिंदी में',
                style: TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color.fromRGBO(123, 109, 217, 1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                sectionTextHindi,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],
            // English Text
            const Text(
              'In English',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color.fromRGBO(123, 109, 217, 1),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sectionText,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
