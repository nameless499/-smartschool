// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kDebugMode; // ✅ added
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';

// class DebugRoleSwitcher extends StatelessWidget {
//   const DebugRoleSwitcher({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Only show in debug mode
//     if (!kDebugMode) return const SizedBox.shrink();

//     final authProvider = context.watch<AuthProvider>();
//     final currentRole = authProvider.role ?? 'student';

//     return Container(
//       margin: const EdgeInsets.only(top: 16),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.yellow.shade100,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.yellow.shade700),
//       ),
//       child: Column(
//         children: [
//           const Text(
//             '🔧 DEBUG: Override Role',
//             style: TextStyle(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 4),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildRoleChip(context, 'student', currentRole),
//               const SizedBox(width: 8),
//               _buildRoleChip(context, 'registrar', currentRole),
//               const SizedBox(width: 8),
//               _buildRoleChip(context, 'admin', currentRole),
//             ],
//           ),
//           const SizedBox(height: 4),
//           const Text(
//             '(Only visible in debug mode)',
//             style: TextStyle(fontSize: 10, color: Colors.grey),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRoleChip(BuildContext context, String role, String currentRole) {
//     final isSelected = role == currentRole;
//     return GestureDetector(
//       onTap: () {
//         final authProvider = context.read<AuthProvider>();
//         authProvider.setDebugRole(role);
//         // Rebuild the UI
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Text(
//           role.toUpperCase(),
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.black,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }
// }
