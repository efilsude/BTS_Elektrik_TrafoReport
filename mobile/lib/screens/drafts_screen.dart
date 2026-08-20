import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'report_creation/report_form_screen.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  List<Report> _draftList = <Report>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final List<Report> drafts = await service.getDrafts();
    setState(() {
      _draftList = drafts;
      _isLoading = false;
    });
  }

  void _resumeDraft(Report draft) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    service.resumeReport(draft);

    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const ReportFormScreen(),
      ),
    ).then((_) => _loadDrafts()); // Reload after editing
  }

  void _deleteDraft(Report draft) {
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Taslağı Sil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('"${draft.title}" taslağı kalıcı olarak silinecektir. Bu işlem geri alınamaz.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              final ReportService service = Provider.of<ReportService>(context, listen: false);
              await service.deleteDraft(draft.id);
              Navigator.pop(context);
              _loadDrafts();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Taslak silindi.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapor Taslakları', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Kaydedilmiş Taslaklarınız (${_draftList.length})',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Taslaklar sadece sizin tarafınızdan görülebilir ve düzenlenebilir.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _draftList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.edit_note_rounded, size: 72, color: AppTheme.textLight.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text(
                                'Kayıtlı taslak raporunuz bulunmamaktadır.',
                                style: GoogleFonts.inter(color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _draftList.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Report draft = _draftList[index];
                            final String typeLabel = draft.transformerType == 'hermetik'
                                ? 'Hermetik Bakım'
                                : draft.transformerType == 'kuru_tip'
                                    ? 'Kuru Tip Bakım'
                                    : 'Genleşme Tanklı (GT) Bakım';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            draft.customerName.isEmpty ? 'Müşteri Belirtilmedi' : draft.customerName,
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Adım ${draft.currentStep + 1}',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      typeLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: AppTheme.borderLight),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(
                                          'Son güncelleme: ${draft.updatedAt.day}.${draft.updatedAt.month}.${draft.updatedAt.year}',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                        Row(
                                          children: <Widget>[
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                                              onPressed: () => _deleteDraft(draft),
                                              tooltip: 'Taslağı Sil',
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () => _resumeDraft(draft),
                                              icon: const Icon(Icons.edit, size: 16),
                                              label: const Text('Devam Et'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
