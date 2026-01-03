import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../utils/notification_helper.dart';

class DriverRatingScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String? driverAvatar;

  const DriverRatingScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    this.driverAvatar,
  });

  @override
  State<DriverRatingScreen> createState() => _DriverRatingScreenState();
}

class _DriverRatingScreenState extends State<DriverRatingScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _selectedRating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasAlreadyRated = false;
  bool _isLoading = true;
  double? _previousRating;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyRated();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _checkIfAlreadyRated() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Vérifier si l'utilisateur a déjà noté ce conducteur
      final ratingDoc = await _firestore
          .collection('users')
          .doc(widget.driverId)
          .collection('ratings')
          .doc(currentUser.uid)
          .get();

      if (ratingDoc.exists) {
        final data = ratingDoc.data()!;
        setState(() {
          _hasAlreadyRated = true;
          _previousRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
          _selectedRating = _previousRating!;
          _commentController.text = data['comment'] as String? ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur vérification notation: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRating() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showSnackBar('Vous devez être connecté pour noter', isError: true);
      return;
    }

    if (_selectedRating == 0.0) {
      _showSnackBar('Veuillez sélectionner une note', isError: true);
      return;
    }

    // Empêcher de noter son propre profil
    if (currentUser.uid == widget.driverId) {
      _showSnackBar('Vous ne pouvez pas noter votre propre profil',
          isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Récupérer les infos de l'utilisateur qui note
      final userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final userName = userData?['name'] as String? ?? 'Utilisateur';

      // Enregistrer ou mettre à jour la note
      await _firestore
          .collection('users')
          .doc(widget.driverId)
          .collection('ratings')
          .doc(currentUser.uid)
          .set({
        'rating': _selectedRating,
        'comment': _commentController.text.trim(),
        'ratedBy': currentUser.uid,
        'ratedByName': userName,
        'createdAt': _hasAlreadyRated ? null : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Calculer la nouvelle moyenne
      await _updateDriverAverageRating();

      if (!_hasAlreadyRated) {
        await NotificationHelper.createRatingNotification(
          userId: widget.driverId,
          raterId: currentUser.uid,
          raterName: userName,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
        );
      }

      if (!mounted) return;

      _showSnackBar(
        _hasAlreadyRated
            ? 'Votre note a été mise à jour'
            : 'Merci pour votre évaluation !',
        isError: false,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context,
            true); // Retourner true pour indiquer qu'une note a été ajoutée
      }
    } catch (e) {
      debugPrint('Erreur soumission notation: $e');
      if (mounted) {
        _showSnackBar('Erreur lors de l\'enregistrement de la note',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _updateDriverAverageRating() async {
    try {
      // Récupérer toutes les notes du conducteur
      final ratingsSnapshot = await _firestore
          .collection('users')
          .doc(widget.driverId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        // Aucune note, mettre à 0.0
        await _firestore.collection('users').doc(widget.driverId).update({
          'rating': 0.0,
          'totalRatings': 0,
        });
        return;
      }

      // Calculer la moyenne
      double totalRating = 0.0;
      for (var doc in ratingsSnapshot.docs) {
        final rating = (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
        totalRating += rating;
      }

      final averageRating = totalRating / ratingsSnapshot.docs.length;

      // Mettre à jour le profil du conducteur
      await _firestore.collection('users').doc(widget.driverId).update({
        'rating': double.parse(
            averageRating.toStringAsFixed(1)), // Arrondir à 1 décimale
        'totalRatings': ratingsSnapshot.docs.length,
      });

      debugPrint(
          '✅ Note moyenne mise à jour: ${averageRating.toStringAsFixed(1)}');
    } catch (e) {
      debugPrint('❌ Erreur calcul moyenne: $e');
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Évaluation'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _hasAlreadyRated ? 'Modifier votre note' : 'Évaluer le conducteur',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar et nom du conducteur
            _buildDriverInfo(),

            const SizedBox(height: 40),

            // Sélection des étoiles
            _buildRatingStars(),

            const SizedBox(height: 16),

            // Texte de la note sélectionnée
            _buildRatingText(),

            const SizedBox(height: 40),

            // Champ de commentaire
            _buildCommentField(),

            const SizedBox(height: 40),

            // Bouton soumettre
            _buildSubmitButton(),

            if (_hasAlreadyRated) ...[
              const SizedBox(height: 16),
              Text(
                'Vous avez déjà noté ce conducteur.\nVous pouvez modifier votre note.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage:
              widget.driverAvatar != null && widget.driverAvatar!.isNotEmpty
                  ? NetworkImage(widget.driverAvatar!)
                  : null,
          child: (widget.driverAvatar == null || widget.driverAvatar!.isEmpty)
              ? Text(
                  widget.driverName.isNotEmpty
                      ? widget.driverName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          widget.driverName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _hasAlreadyRated
              ? 'Votre note actuelle: ${_previousRating?.toStringAsFixed(1)} ⭐'
              : 'Comment évaluez-vous ce conducteur ?',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = (index + 1).toDouble();
        final isHalfStar =
            _selectedRating >= starValue - 0.5 && _selectedRating < starValue;
        final isFullStar = _selectedRating >= starValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = starValue;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              isFullStar
                  ? Icons.star
                  : isHalfStar
                      ? Icons.star_half
                      : Icons.star_border,
              size: 48,
              color: isFullStar || isHalfStar
                  ? AppColors.warning
                  : AppColors.textMuted,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRatingText() {
    String ratingText = '';
    if (_selectedRating == 0.0) {
      ratingText = 'Aucune note sélectionnée';
    } else if (_selectedRating <= 1.0) {
      ratingText = 'Très décevant';
    } else if (_selectedRating <= 2.0) {
      ratingText = 'Décevant';
    } else if (_selectedRating <= 3.0) {
      ratingText = 'Correct';
    } else if (_selectedRating <= 4.0) {
      ratingText = 'Bien';
    } else {
      ratingText = 'Excellent';
    }

    return Column(
      children: [
        Text(
          _selectedRating > 0
              ? '${_selectedRating.toStringAsFixed(1)} / 5.0'
              : '',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ratingText,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: _selectedRating == 0.0
                ? AppColors.textMuted
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commentaire (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Partagez votre expérience avec ce conducteur...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              counterStyle: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
              _isSubmitting || _selectedRating == 0.0 ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey.shade300,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _hasAlreadyRated
                      ? 'Mettre à jour'
                      : 'Soumettre l\'évaluation',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
