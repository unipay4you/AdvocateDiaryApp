import 'package:flutter/material.dart';

class MasterAdminPanel extends StatelessWidget {
  const MasterAdminPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'Master Admin Panel',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Master Admin Panel Content',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
