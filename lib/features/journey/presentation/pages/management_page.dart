import 'package:flutter/material.dart';
import 'package:TBConsult/features/journey/presentation/pages/add_plan_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medication_plan_entity.dart';
import '../widgets/plan_card.dart';

class ManagementPage extends StatelessWidget {
  const ManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data, nantinya diload via Cubit/BLoC dari API backend lo
    final List<MedicationPlanEntity> plans = [
      MedicationPlanEntity(
        title: "Rifampicin & Isoniazid",
        dateRange: "Oct 2023 - Apr 2024",
        status: PlanStatus.active,
        trackStatus: "On Track",
      ),
      MedicationPlanEntity(
        title: "Standard TB Regimen",
        dateRange: "Jan 2023 - Jul 2023",
        status: PlanStatus.completed,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Panah back warna hitam
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Journeys',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Active medication plans',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // List Card Plan
              Expanded(
                child: ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    return PlanCard(plan: plans[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Tombol FAB (+) di kanan bawah dengan sudut melengkung
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPlanPage())
          );
        },
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Bikin bentuknya squircle
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}