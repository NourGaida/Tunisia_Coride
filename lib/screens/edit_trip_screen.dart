import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../widgets/gradient_button.dart';

class EditTripScreen extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> tripData;

  const EditTripScreen({
    super.key,
    required this.tripId,
    required this.tripData,
  });

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Contrôleurs
  final _departController = TextEditingController();
  final _arriveeController = TextEditingController();
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Valeurs
  int _placesDisponibles = 2;
  int _prixParPersonne = 30;
  String _musique = 'Oui';
  String _animaux = 'Non accepté';
  String _bagages = 'Moyen';

  bool _isSaving = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadTripData();
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

  void _loadTripData() {
    // Charger les données existantes
    _departController.text = widget.tripData['departureLocation'] ?? '';
    _arriveeController.text = widget.tripData['arrivalLocation'] ?? '';
    _descriptionController.text = widget.tripData['description'] ?? '';

    // Date et heure
    final date = (widget.tripData['date'] as Timestamp).toDate();
    _selectedDate = date;
    _selectedTime = TimeOfDay(hour: date.hour, minute: date.minute);
    _updateDateDisplay();
    _updateTimeDisplay();

    // Places et prix
    _placesDisponibles = widget.tripData['availableSeats'] ?? 2;
    _prixParPersonne = (widget.tripData['price'] as num?)?.toInt() ?? 30;

    // Préférences
    final prefs = widget.tripData['preferences'] as Map<String, dynamic>?;
    if (prefs != null) {
      _musique = prefs['music'] ?? 'Oui';
      _animaux = prefs['pets'] ?? 'Non accepté';
      _bagages = prefs['luggage'] ?? 'Moyen';
    }

    setState(() {});
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

  Future<void> _saveChanges() async {
    // Validation
    if (_departController.text.trim().isEmpty ||
        _arriveeController.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir les champs Départ et Arrivée',
          isError: true);
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      _showSnackBar('Veuillez sélectionner une date et une heure',
          isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Vérifier que l'utilisateur est bien le propriétaire
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Vous devez être connecté');
      }

      if (widget.tripData['driverId'] != currentUser.uid) {
        throw Exception('Vous n\'êtes pas autorisé à modifier ce trajet');
      }

      // Combiner date et heure
      final tripDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Préparer les données à mettre à jour
      final updates = {
        'departureLocation': _departController.text.trim(),
        'arrivalLocation': _arriveeController.text.trim(),
        'date': Timestamp.fromDate(tripDateTime),
        'time':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'availableSeats': _placesDisponibles,
        'price': _prixParPersonne,
        'description': _descriptionController.text.trim(),
        'preferences': {
          'music': _musique,
          'pets': _animaux,
          'luggage': _bagages,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Mettre à jour dans Firestore
      await _firestore.collection('trips').doc(widget.tripId).update(updates);

      if (!mounted) return;

      _showSnackBar('Trajet modifié avec succès !', isError: false);

      // Attendre un peu puis retourner
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context, true); // true = modifications enregistrées
      }
    } catch (e) {
      debugPrint('Erreur modification: $e');
      if (mounted) {
        _showSnackBar(
          e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Erreur lors de la modification',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteTrip() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le trajet'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce trajet ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      // Vérifier qu'il n'y a pas de réservations confirmées
      final bookings = await _firestore
          .collection('bookings')
          .where('tripId', isEqualTo: widget.tripId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (bookings.docs.isNotEmpty) {
        throw Exception(
          'Impossible de supprimer un trajet avec des réservations confirmées',
        );
      }

      // Supprimer le trajet
      await _firestore.collection('trips').doc(widget.tripId).delete();

      if (!mounted) return;

      _showSnackBar('Trajet supprimé', isError: false);

      // Retourner avec un code spécial pour indiquer la suppression
      Navigator.pop(context);
      Navigator.pop(context); // Retour à la liste des trajets
    } catch (e) {
      debugPrint('Erreur suppression: $e');
      if (mounted) {
        _showSnackBar(
          e.toString().contains('Exception:')
              ? e.toString().replaceAll('Exception: ', '')
              : 'Erreur lors de la suppression',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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
        title: const Text('Modifier le trajet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: _deleteTrip,
            tooltip: 'Supprimer le trajet',
          ),
        ],
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

            // Bouton Enregistrer
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'Enregistrer les modifications',
                onPressed: _isSaving ? () {} : _saveChanges,
                isLoading: _isSaving,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widgets réutilisables (mêmes que PublishRideScreen)
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
}
