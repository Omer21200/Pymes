import 'package:flutter/material.dart';
import 'widgets/access_header.dart';
import 'widgets/search_institutions.dart';
import 'widgets/institutions_grid.dart';
import 'empresa_login_selection.dart';
import 'widgets/admin_button.dart';

class AccessSelectionPage extends StatelessWidget {
	const AccessSelectionPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFFF7F7F8),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							AccessHeader(),
							const SizedBox(height: 8),
							const Text(
								'Selecciona tu tipo de acceso',
								textAlign: TextAlign.center,
								style: TextStyle(fontSize: 14, color: Colors.black87),
							),
							const SizedBox(height: 16),
							SearchInstitutions(),
							const SizedBox(height: 18),
														InstitutionsGrid(
															onEmpresaSelected: (empresa) {
																Navigator.push(
																	context,
																	MaterialPageRoute(
																		builder: (_) => EmpresaLoginSelection(empresa: empresa),
																	),
																);
															},
														),
							const SizedBox(height: 24),
							AdminButton(),
						],
					),
				),
			),
		);
	}
}
