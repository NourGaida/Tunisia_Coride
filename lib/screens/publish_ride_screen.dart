import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../widgets/gradient_button.dart';

class PublishRideScreen extends StatefulWidget {
  const PublishRideScreen({super.key});

  @override
  State<PublishRideScreen> createState() => _PublishRideScreenState();
}

class _PublishRideScreenState extends State<PublishRideScreen> {
  // Contrôleurs pour les champs
  final _departController = TextEditingController();
  final _arriveeController = TextEditingController();
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Valeurs sélectionnées
  int _placesDisponibles = 2;
  int _prixParPersonne = 30;
  String _musique = 'Oui';
  String _animaux = 'Non accepté';
  String _bagages = 'Moyen';

  // État de publication
  bool _isPublishing = false;

  // Date et heure sélectionnées (pour Firebase)
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    // Initialiser la date par défaut (aujourd'hui)
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _updateDateDisplay();
    _updateTimeDisplay();
  }

  @override
  void dispose() {
    _departController.dispose();
    _arriveeController.dispose();
    _dateController.dispose();
    _heureController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateDateDisplay() {
    if (_selectedDate != null) {
      _dateController.text =
          '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}';
    }
  }

  void _updateTimeDisplay() {
    if (_selectedTime != null) {
      final hour =
          _selectedTime!.hourOfPeriod == 0 ? 12 : _selectedTime!.hourOfPeriod;
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      _heureController.text = '$hour:$minute $period';
    }
  }

  Future<void> _publierTrajet() async {
    // Validation des champs
    if (_departController.text.trim().isEmpty ||
        _arriveeController.text.trim().isEmpty) {
      _showSnackBar(
        'Veuillez remplir les champs Départ et Arrivée',
        isError: true,
      );
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar(
        'Veuillez sélectionner une date et une heure',
        isError: true,
      );
      return;
    }

    // Vérifier si l'utilisateur est connecté
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackBar(
        'Vous devez être connecté pour publier un trajet',
        isError: true,
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      // Combiner date et heure en un seul DateTime
      final tripDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Créer l'objet trajet pour Firestore
      final tripData = {
        'driverId': currentUser.uid,
        'driverName': currentUser.displayName ??
            currentUser.email?.split('@')[0] ??
            'Conducteur',
        'driverEmail': currentUser.email,
        'departureLocation': _departController.text.trim(),
        'arrivalLocation': _arriveeController.text.trim(),
        'date': Timestamp.fromDate(tripDateTime),
        'availableSeats': _placesDisponibles,
        'price': _prixParPersonne,
        'description': _descriptionController.text.trim(),
        'preferences': {
          'music': _musique,
          'pets': _animaux,
          'luggage': _bagages,
        },
        'status': 'upcoming',
        'popularityScore': 0, // Pour le tri des trajets populaires
        'bookings': [], // Liste des réservations
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Sauvegarder dans Firestore
      await FirebaseFirestore.instance.collection('trips').add(tripData);

      if (!mounted) return;

      // Message de succès
      _showSnackBar('Trajet publié avec succès !', isError: false);

      // Retour à l'écran précédent après un court délai
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Erreur lors de la publication du trajet: $e');
      if (mounted) {
        _showSnackBar(
          'Erreur lors de la publication. Veuillez réessayer.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Publier un trajet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Départ
            _buildLocationField(
              label: 'Départ',
              controller: _departController,
              hint: 'Ville de départ',
              icon: Icons.location_on,
              color: AppColors.success,
            ),

            const SizedBox(height: 20),

            // Arrivée
            _buildLocationField(
              label: 'Arrivée',
              controller: _arriveeController,
              hint: "Ville d'arrivée",
              icon: Icons.location_on,
              color: AppColors.error,
            ),

            const SizedBox(height: 20),

            // Date et Heure
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Date',
                    controller: _dateController,
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateTimeField(
                    label: 'Heure',
                    controller: _heureController,
                    icon: Icons.access_time,
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Places et Prix
            Row(
              children: [
                Expanded(
                  child: _buildNumberPicker(
                    label: 'Places disponibles',
                    icon: Icons.people,
                    value: _placesDisponibles,
                    onChanged: (value) {
                      setState(() => _placesDisponibles = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPricePicker(
                    label: 'Prix par personne',
                    value: _prixParPersonne,
                    onChanged: (value) {
                      setState(() => _prixParPersonne = value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Description
            _buildDescriptionField(),

            const SizedBox(height: 32),

            // Préférences
            _buildPreferencesSection(),

            const SizedBox(height: 32),

            // Bouton Publier
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'Publier le trajet',
                onPressed: _isPublishing ? () {} : _publierTrajet,
                isLoading: _isPublishing,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Champ de localisation (Départ/Arrivée)
  Widget _buildLocationField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: color),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Champ Date/Heure
  Widget _buildDateTimeField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Sélecteur de nombre (places)
  Widget _buildNumberPicker({
    required String label,
    required IconData icon,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: value,
                    isExpanded: true,
                    items: [1, 2, 3, 4, 5, 6, 7, 8]
                        .map((int val) => DropdownMenuItem<int>(
                              value: val,
                              child: Text('$val places'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) onChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Sélecteur de prix
  Widget _buildPricePicker({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money,
                  color: AppColors.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: value,
                    isExpanded: true,
                    items: [5, 10, 15, 20, 25, 30, 35, 40, 50]
                        .map((int val) => DropdownMenuItem<int>(
                              value: val,
                              child: Text('$val TND'),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) onChanged(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Champ description
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Ajoutez des détails sur votre trajet, point de rendez-vous, etc.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Section Préférences
  Widget _buildPreferencesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Préférences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreferenceRow(
            label: 'Musique',
            value: _musique,
            options: ['Oui', 'Non'],
            onChanged: (val) => setState(() => _musique = val),
          ),
          const SizedBox(height: 12),
          _buildPreferenceRow(
            label: 'Animaux',
            value: _animaux,
            options: ['Accepté', 'Non accepté'],
            onChanged: (val) => setState(() => _animaux = val),
          ),
          const SizedBox(height: 12),
          _buildPreferenceRow(
            label: 'Bagages',
            value: _bagages,
            options: ['Non', 'Petit', 'Moyen', 'Grand'],
            onChanged: (val) => setState(() => _bagages = val),
          ),
        ],
      ),
    );
  }

  // Ligne de préférence
  Widget _buildPreferenceRow({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              items: options
                  .map((String val) => DropdownMenuItem<String>(
                        value: val,
                        child: Text(
                          val,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Sélecteur de date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDateDisplay();
      });
    }
  }

  // Sélecteur d'heure
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _updateTimeDisplay();
      });
    }
  }
}
