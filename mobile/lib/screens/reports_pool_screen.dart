import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../services/auth_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import 'report_creation/report_form_screen.dart';

class ReportsPoolScreen extends StatefulWidget {
  const ReportsPoolScreen({super.key});

  @override
  State<ReportsPoolScreen> createState() => _ReportsPoolScreenState();
}

class _ReportsPoolScreenState extends State<ReportsPoolScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedReportType = 'Hepsi';
  String _selectedTransformerType = 'Hepsi';

  List<Report> _reportsList = <Report>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _searchController.addListener(_loadReports);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    
    String? typeParam;
    if (_selectedTransformerType == 'Hermetik') typeParam = 'HERMETIK';
    if (_selectedTransformerType == 'Kuru Tip') typeParam = 'KURU_TIP';
    if (_selectedTransformerType == 'Genleşme Tanklı (GT)') typeParam = 'GT';

    String? subTypeParam;
    if (_selectedReportType == 'Bakım') subTypeParam = 'maintenance';
    if (_selectedReportType == 'Yalnızca Test') subTypeParam = 'test';

    final List<Report> reports = await service.getReports(
      search: _searchController.text,
      reportType: typeParam,
      maintenanceType: subTypeParam,
    );

    if (mounted) {
      setState(() {
        _reportsList = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadExcel(Report report) async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${report.title}.xlsx" dosyası hazırlanıyor...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    final File? downloadedFile = await service.downloadExcelFile(report.id, report.title);

    if (downloadedFile != null && mounted) {
      _showPostProductionModal(context, downloadedFile, report.title);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel dosyası indirilirken hata oluştu.', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showPostProductionModal(BuildContext context, File excelFile, String title) {
    final ReportService service = Provider.of<ReportService>(context, listen: false);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 64),
              const SizedBox(height: 12),
              Text(
                'Excel Raporu Hazır!',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Action buttons per PRD §21.4: Aç | Paylaş | Kapat
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        service.openExcelFile(excelFile);
                      },
                      icon: const Icon(Icons.file_open_outlined),
                      label: const Text('Excel\'i Aç'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        service.shareExcelFile(excelFile, title);
                      },
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Paylaş'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Kapat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewReportDetail(Report report) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final Map<String, dynamic> data = report.dataJson;
        return AlertDialog(
          title: Text(report.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildDetailRow('Müşteri Adı:', report.customerName),
                  _buildDetailRow('Trafo Etiketi:', report.trafoLabel),
                  _buildDetailRow('Trafo Tipi:', report.transformerType.toUpperCase()),
                  _buildDetailRow('Rapor Kapsamı:', report.reportType.toUpperCase()),
                  _buildDetailRow('Durum:', report.status == 'final' ? 'Kesinleşti' : 'Taslak'),
                  _buildDetailRow('Test Tarihi:', data['test_date']?.toString() ?? '-'),
                  _buildDetailRow('Teknisyen:', report.creatorDisplayName ?? data['operator_name']?.toString() ?? '-'),
                  const Divider(height: 24),
                  Text('Rapor Detay Verileri (data_json):', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      const JsonEncoder.withIndent('  ').convert(data),
                      style: GoogleFonts.firaCode(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Kapat'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _downloadExcel(report);
              },
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Excel İndir'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 130,
            child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textLight)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(Report report) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Raporu Sil', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('"${report.title}" raporunu silmek istediğinizden emin misiniz?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ReportService service = Provider.of<ReportService>(context, listen: false);
      await service.deleteDraft(report.id);
      await _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapor silindi.', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapor Havuzu', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Banner if in offline/mock mode
            if (authService.isMockMode)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.wifi_off_rounded, color: Colors.blue.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Çevrimdışı / Simülasyon Modu: Yerel cihaz kayıtları gösteriliyor.',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            // Search and Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Rapor Ara',
                        hintText: 'Müşteri adı, trafo etiketi veya teknisyen...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedReportType,
                            decoration: const InputDecoration(labelText: 'Rapor Kapsamı'),
                            items: <String>['Hepsi', 'Bakım', 'Yalnızca Test']
                                .map((String type) => DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (String? val) {
                              if (val != null) {
                                setState(() {
                                  _selectedReportType = val;
                                });
                                _loadReports();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedTransformerType,
                            decoration: const InputDecoration(labelText: 'Trafo Tipi'),
                            items: <String>['Hepsi', 'Hermetik', 'Kuru Tip', 'Genleşme Tanklı (GT)']
                                .map((String type) => DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (String? val) {
                              if (val != null) {
                                setState(() {
                                  _selectedTransformerType = val;
                                });
                                _loadReports();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header for Results
            Text(
              'Kesinleşmiş Raporlar Havuzu (${_reportsList.length})',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Results List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reportsList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz rapor bulunmuyor.',
                                style: GoogleFonts.inter(color: AppTheme.textLight, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : isTablet
                          ? _buildTableView(authService.currentUser?.isAdmin ?? false)
                          : _buildListView(authService.currentUser?.isAdmin ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableView(bool isAdmin) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: AppTheme.borderLight, width: 1),
          ),
          children: <TableRow>[
            TableRow(
              decoration: const BoxDecoration(color: AppTheme.backgroundColor),
              children: <Widget>[
                _buildTableCell('Müşteri / Şalt Sahası', isHeader: true),
                _buildTableCell('Rapor Türü', isHeader: true),
                _buildTableCell('Tarih', isHeader: true),
                _buildTableCell('Teknisyen', isHeader: true),
                _buildTableCell('İşlemler', isHeader: true, align: TextAlign.center),
              ],
            ),
            ..._reportsList.map((Report report) {
              final String typeLabel = report.transformerType == 'hermetik'
                  ? 'Hermetik'
                  : report.transformerType == 'kuru_tip'
                      ? 'Kuru Tip'
                      : 'GT';

              final String date = report.dataJson['test_date']?.toString() ?? '';
              final String creator = report.creatorDisplayName ?? report.dataJson['operator_name']?.toString() ?? 'Bilinmeyen';

              return TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          report.customerName.isNotEmpty ? report.customerName : report.title,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Text(
                          report.trafoLabel,
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ),
                  _buildTableCell(typeLabel),
                  _buildTableCell(date),
                  _buildTableCell(creator),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, color: AppTheme.secondaryColor),
                          onPressed: () => _viewReportDetail(report),
                          tooltip: 'Görüntüle',
                        ),
                        IconButton(
                          icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryColor),
                          onPressed: () => _downloadExcel(report),
                          tooltip: 'Excel İndir',
                        ),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                            onPressed: () => _deleteReport(report),
                            tooltip: 'Sil',
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(bool isAdmin) {
    return ListView.builder(
      itemCount: _reportsList.length,
      itemBuilder: (BuildContext context, int index) {
        final Report report = _reportsList[index];
        final String typeLabel = report.transformerType == 'hermetik'
            ? 'Hermetik'
            : report.transformerType == 'kuru_tip'
                ? 'Kuru Tip'
                : 'Genleşme Tanklı';

        final String date = report.dataJson['test_date']?.toString() ?? '';
        final String creator = report.creatorDisplayName ?? report.dataJson['operator_name']?.toString() ?? 'Teknisyen';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              report.customerName.isNotEmpty ? report.customerName : report.title,
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${report.trafoLabel} - $typeLabel'),
                Text('Teknisyen: $creator | Tarih: $date', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'download') {
                  _downloadExcel(report);
                } else if (value == 'view') {
                  _viewReportDetail(report);
                } else if (value == 'edit') {
                  final ReportService service = Provider.of<ReportService>(context, listen: false);
                  service.resumeReport(report);
                  Navigator.of(context).push(
                    MaterialPageRoute<dynamic>(builder: (BuildContext context) => const ReportFormScreen()),
                  );
                } else if (value == 'delete') {
                  _deleteReport(report);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'view',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.remove_red_eye_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Görüntüle'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'download',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.file_download_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Excel İndir'),
                    ],
                  ),
                ),
                if (isAdmin) ...<PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Düzenle (Admin)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
                        SizedBox(width: 8),
                        Text('Sil', style: TextStyle(color: AppTheme.errorColor)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? AppTheme.textLight : AppTheme.textDark,
          fontSize: isHeader ? 13 : 14,
        ),
        textAlign: align,
      ),
    );
  }
}
