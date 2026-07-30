import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

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
  List<Report> _filteredReports = <Report>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinalReports();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFinalReports() async {
    final ReportService service = Provider.of<ReportService>(context, listen: false);
    final List<Report> dbReports = await service.getFinalReports();
    
    // Add default mock reports if database is empty to make it look realistic
    if (dbReports.isEmpty) {
      final List<Report> mockList = <Report>[
        Report(
          id: 'rep_1',
          title: 'ABC Tekstil - TR1 - 28.07.2026',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'hermetik',
          customerName: 'ABC Tekstil A.Ş.',
          trafoLabel: 'TR1 (1600 kVA)',
          status: 'final',
          dataJson: <String, dynamic>{
            'test_date': '28.07.2026',
            'operator_name': 'Ahmet Teknisyen',
          },
          currentStep: 6,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Report(
          id: 'rep_2',
          title: 'XYZ Metalurji - TR2 - 25.07.2026',
          reportType: 'bakim',
          subType: 'normal',
          transformerType: 'gt',
          customerName: 'XYZ Metalurji Sanayi',
          trafoLabel: 'TR2 (2500 kVA)',
          status: 'final',
          dataJson: <String, dynamic>{
            'test_date': '25.07.2026',
            'operator_name': 'Ahmet Teknisyen',
          },
          currentStep: 6,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
      setState(() {
        _reportsList = mockList;
        _filteredReports = mockList;
        _isLoading = false;
      });
    } else {
      setState(() {
        _reportsList = dbReports;
        _filteredReports = dbReports;
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredReports = _reportsList.where((Report report) {
        final bool matchesSearch = report.customerName.toLowerCase().contains(query) ||
            report.trafoLabel.toLowerCase().contains(query) ||
            (report.dataJson['operator_name']?.toString().toLowerCase().contains(query) ?? false);
            
        final bool matchesReportType = _selectedReportType == 'Hepsi' || 
            (_selectedReportType == 'Bakım' && report.reportType == 'bakim') ||
            (_selectedReportType == 'Yalnızca Test' && report.reportType == 'test');

        final bool matchesTransformer = _selectedTransformerType == 'Hepsi' ||
            (_selectedTransformerType == 'Hermetik' && report.transformerType == 'hermetik') ||
            (_selectedTransformerType == 'Kuru Tip' && report.transformerType == 'kuru_tip') ||
            (_selectedTransformerType == 'Genleşme Tanklı (GT)' && report.transformerType == 'gt');

        return matchesSearch && matchesReportType && matchesTransformer;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            // Search and Filter Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    // Search Input
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Rapor Ara',
                        hintText: 'Müşteri adı, trafo markası, teknisyen...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Quick Dropdown Filters
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
                                  _applyFilters();
                                });
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
                                  _applyFilters();
                                });
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
              'Kesinleşmiş Raporlar Havuzu (${_filteredReports.length})',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),

            // Results List / Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredReports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.folder_open_outlined, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text(
                                'Aradığınız kriterlere uygun rapor bulunamadı.',
                                style: GoogleFonts.inter(color: AppTheme.textLight),
                              ),
                            ],
                          ),
                        )
                      : isTablet
                          ? _buildTableView()
                          : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  // Tablet Optimized Table View
  Widget _buildTableView() {
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
            // Table Header
            TableRow(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
              ),
              children: <Widget>[
                _buildTableCell('Müşteri / Şalt Sahası', isHeader: true),
                _buildTableCell('Rapor Türü', isHeader: true),
                _buildTableCell('Tarih', isHeader: true),
                _buildTableCell('Teknisyen', isHeader: true),
                _buildTableCell('İşlem', isHeader: true, align: TextAlign.center),
              ],
            ),
            // Table Rows
            ..._filteredReports.map((Report report) {
              final String typeLabel = report.transformerType == 'hermetik'
                  ? 'Hermetik Bakım'
                  : report.transformerType == 'kuru_tip'
                      ? 'Kuru Tip Bakım'
                      : 'GT Bakım';

              final String date = report.dataJson['test_date']?.toString() ?? '';
              final String creator = report.dataJson['operator_name']?.toString() ?? 'Bilinmeyen';

              return TableRow(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          report.customerName,
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
                          icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryColor),
                          onPressed: () => _downloadExcel(report),
                          tooltip: 'Excel İndir',
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye_outlined, color: AppTheme.secondaryColor),
                          onPressed: () => _viewReport(report),
                          tooltip: 'Görüntüle',
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

  // Mobile list view
  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredReports.length,
      itemBuilder: (BuildContext context, int index) {
        final Report report = _filteredReports[index];
        final String typeLabel = report.transformerType == 'hermetik'
            ? 'Hermetik Bakım'
            : report.transformerType == 'kuru_tip'
                ? 'Kuru Tip Bakım'
                : 'Genleşme Tanklı Bakım';

        final String date = report.dataJson['test_date']?.toString() ?? '';
        final String creator = report.dataJson['operator_name']?.toString() ?? 'Bilinmeyen';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(
              report.customerName,
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
                  _viewReport(report);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'view',
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.remove_red_eye_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Detayları Gör'),
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

  void _downloadExcel(Report report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${report.title}.xlsx" dosyası indiriliyor...'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _viewReport(Report report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${report.title}" detayları görüntüleniyor...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }
}
