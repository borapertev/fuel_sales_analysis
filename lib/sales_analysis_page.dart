import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import './sales_chart.dart';
import 'package:flutter/services.dart';
import './ada_sales_chart.dart';
import './payment_chart.dart';
import './traffic_chart.dart';

class SalesAnalysisPage extends StatefulWidget {
  const SalesAnalysisPage({super.key});

  @override
  State<SalesAnalysisPage> createState() => _SalesAnalysisPageState();
}

class _SalesAnalysisPageState extends State<SalesAnalysisPage> {
  XmlDocument? xmlData;
  List<SaleTransaction> transactions = [];
  Map<String, double> fuelSales = {};
  double totalAmount = 0;
  double totalLiters = 0;
  Map<String, double> adaSales = {};
  Map<String, double> adaSalesMoney = {};
  Map<String, double> hourlyDistribution = {};
  Map<String, double> paymentTypes = {};
  Map<String, double> shiftSales = {};
  Set<String> uniquePlates = {};
  Map<String, double> fuelAveragePrices = {};
  DateTime? startDate;
  DateTime? endDate;
  String? timeRange;
  double totalStockChange = 0;  // Depo miktarı değişimi için ekle
  Map<String, int> hourlyTraffic = {};

  @override
  void initState() {
    super.initState();
    // initState'te direkt çağırmak yerine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDefaultXML();
    });
  }

  Future<void> loadDefaultXML() async {
    try {
      // XML dosyasını binary olarak oku
      final ByteData data = await rootBundle.load('assets/Sale.xml');
      // Windows-1254 encoding ile decode et
      final List<int> bytes = data.buffer.asUint8List();
      final String xmlString = String.fromCharCodes(bytes);
      
      setState(() {
        xmlData = XmlDocument.parse(xmlString);
        parseXMLData();
      });
    } catch (e) {
      print('XML yüklenirken hata: $e');
    }
  }

  void parseXMLData() {
    transactions.clear();
    fuelSales.clear();
    totalAmount = 0;
    totalLiters = 0;
    adaSales.clear();
    adaSalesMoney.clear();
    hourlyDistribution.clear();
    paymentTypes.clear();
    shiftSales.clear();
    uniquePlates.clear();
    fuelAveragePrices.clear();
    Map<String, int> fuelCounts = {};

    // Yakıt ortalama fiyatları için
    Map<String, double> fuelTotals = {};  // Toplam tutarlar
    Map<String, double> fuelLiters = {};  // Toplam litreler

    final txns = xmlData?.findAllElements('Txn');
    
    if (txns != null && txns.isNotEmpty) {
      final firstTxn = txns.first.findElements('SaleDetails').first;
      final lastTxn = txns.last.findElements('SaleDetails').first;
      
      final startTime = firstTxn.findElements('DateTime').first.text;
      final endTime = lastTxn.findElements('DateTime').first.text;
      
      timeRange = '${startTime.substring(8, 10)}:${startTime.substring(10, 12)} - '
                '${endTime.substring(8, 10)}:${endTime.substring(10, 12)} Arası İşlemler';
    }
    
    txns?.forEach((txn) {
      try {
        final saleDetailsElements = txn.findElements('SaleDetails');
        if (saleDetailsElements.isEmpty) return;
        
        final saleDetails = saleDetailsElements.first;
        
        // Gerekli elementleri güvenli bir şekilde al
        final dateTimeElement = saleDetails.findElements('DateTime').firstOrNull;
        final amountElement = saleDetails.findElements('Amount').firstOrNull;
        final totalElement = saleDetails.findElements('Total').firstOrNull;
        final plateElement = saleDetails.findElements('ECRPlate').firstOrNull;
        final fuelTypeElement = saleDetails.findElements('FuelType').firstOrNull;
        final receiptElement = saleDetails.findElements('ReceiptNr').firstOrNull;
        final pumpElement = saleDetails.findElements('PumpNr').firstOrNull;
        final paymentElement = saleDetails.findElements('PaymentType').firstOrNull;
        final shiftElement = saleDetails.findElements('ShiftNr').firstOrNull;

        // Eğer gerekli elementler eksikse, bu işlemi atla
        if (dateTimeElement == null || amountElement == null || 
            totalElement == null || fuelTypeElement == null) {
          return;
        }

        // Değerleri parse et
        String dateStr = dateTimeElement.text;
        String timeLabel = '${dateStr.substring(8, 10)}:${dateStr.substring(10, 12)}';
        double amount = double.parse(amountElement.text) / 100;
        double total = double.parse(totalElement.text) / 100;
        String plate = plateElement?.text ?? 'Bilinmeyen';
        String fuelType = fuelTypeElement.text;
        String receiptNo = receiptElement?.text ?? '';

        String fuelName = getFuelTypeName(fuelType);
        fuelSales[fuelName] = (fuelSales[fuelName] ?? 0) + amount;

        totalAmount += total;
        totalLiters += amount;

        transactions.add(SaleTransaction(
          receiptNo: receiptNo,
          plate: plate,
          fuelType: fuelName,
          liters: amount,
          total: total,
          time: timeLabel,
        ));

        // Ek veriler için güvenli kontroller
        if (pumpElement != null) {
          String adaNo = pumpElement.text;
          adaSales[adaNo] = (adaSales[adaNo] ?? 0) + amount;
          adaSalesMoney[adaNo] = (adaSalesMoney[adaNo] ?? 0) + total;
        }

        // Saatlik dağılım için
        String hourStr = timeLabel.substring(0, 2);
        hourlyDistribution[hourStr] = (hourlyDistribution[hourStr] ?? 0) + amount;

        if (paymentElement != null) {
          String paymentType = paymentElement.text;
          String paymentName = getPaymentTypeName(paymentType);
          paymentTypes[paymentName] = (paymentTypes[paymentName] ?? 0) + total;
        }

        if (shiftElement != null) {
          String shift = shiftElement.text;
          shiftSales['Vardiya $shift'] = (shiftSales['Vardiya $shift'] ?? 0) + amount;
        }

        // Plaka sayısı
        if (plate != 'Bilinmeyen') {
          uniquePlates.add(plate);
        }

        // Yakıt ortalama fiyatları (litre başına tutar)
        fuelTotals[fuelName] = (fuelTotals[fuelName] ?? 0) + total;
        fuelLiters[fuelName] = (fuelLiters[fuelName] ?? 0) + amount;

        fuelCounts[fuelName] = (fuelCounts[fuelName] ?? 0) + 1;

        // Depo miktarını güncelle (satışlar eksi olarak)
        totalStockChange -= amount;  // Her satışı eksi olarak ekle

        // Yarım saatlik trafik için
        String timeSlot;
        int minute = int.parse(timeLabel.substring(3));
        int currentHour = int.parse(timeLabel.substring(0, 2));

        // 08:17 geldiğinde -> 08:30'da göster (08:00-08:30 arası)
        // 08:45 geldiğinde -> 09:00'da göster (08:30-09:00 arası)
        if (minute < 30) {
          timeSlot = '${currentHour.toString().padLeft(2, '0')}:30';  // İlk yarım saat
        } else {
          currentHour += 1;  // Sonraki saatin başı
          timeSlot = '${currentHour.toString().padLeft(2, '0')}:00';
        }

        hourlyTraffic[timeSlot] = (hourlyTraffic[timeSlot] ?? 0) + 1;
      } catch (e) {
        // Hata durumunda bu işlemi atla ve devam et
        print('İşlem parse edilirken hata: $e');
      }
    });

    // Ortalama fiyatları hesapla (toplam tutar / toplam litre)
    fuelLiters.forEach((fuel, liters) {
      if (liters > 0) {
        fuelAveragePrices[fuel] = fuelTotals[fuel]! / liters;
      }
    });
  }

  String getFuelTypeName(String code) {
    switch (code) {
      case '04': return 'Benzin';
      case '05': return 'LPG';
      case '06': return 'Motorin';
      default: return 'Bilinmeyen';
    }
  }

  String getPaymentTypeName(String code) {
    switch (code) {
      case '1': return 'Kredi Kartı';
      case '2': return 'Nakit';
      case '3': return 'TTS';
      default: return 'Diğer';
    }
  }

  Color _getPaymentColor(String paymentType) {
    switch (paymentType) {
      case 'Kredi Kartı':
        return Colors.blue.shade300;
      case 'Nakit':
        return Colors.green.shade300;
      case 'TTS':
        return Colors.purple.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Yakıt Satış Analizi'),
            if (timeRange != null)
              Text(
                timeRange!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        backgroundColor: colorScheme.surfaceVariant,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transactions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Toplam Satış',
                      '₺${totalAmount.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'İşlem',
                      transactions.length.toString(),
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Litre',
                      totalLiters.toStringAsFixed(2),
                      Icons.local_gas_station,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Tekil Araç',
                      uniquePlates.length.toString(),
                      Icons.directions_car,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      'Depo Miktarı',
                      totalStockChange.toStringAsFixed(2),  // Eksi olarak gösterilecek
                      Icons.inventory,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 340,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yakıt Tipine Göre Satışlar',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: SalesChart(
                                  fuelSales: fuelSales,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 340,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ödeme Tipleri',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: PaymentChart(
                                  paymentTypes: paymentTypes,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ortalama Fiyatlar',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              ...fuelAveragePrices.entries.map((e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key),
                                    Text('₺${e.value.toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Son İşlemler',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 12,
                                    horizontalMargin: 0,
                                    headingRowHeight: 32,
                                    dataRowHeight: 32,
                                    headingTextStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    dataTextStyle: const TextStyle(
                                      fontSize: 12,
                                    ),
                                    headingRowColor: MaterialStateProperty.all(
                                      Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Fiş')),
                                      DataColumn(label: Text('Saat')),
                                      DataColumn(label: Text('Plaka')),
                                      DataColumn(label: Text('Yakıt')),
                                      DataColumn(label: Text('Lt')),
                                      DataColumn(label: Text('₺')),
                                    ],
                                    rows: transactions.reversed
                                        .take(3)
                                        .map((txn) => DataRow(
                                          cells: [
                                            DataCell(Text(txn.receiptNo)),
                                            DataCell(Text(txn.time)),
                                            DataCell(Text(txn.plate)),
                                            DataCell(Text(txn.fuelType)),
                                            DataCell(Text(txn.liters.toStringAsFixed(1))),
                                            DataCell(Text(txn.total.toStringAsFixed(0))),
                                          ],
                                        )).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gelecek Özellik',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text('Yakında...'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ada Satışları',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: AdaSalesChart(
                                adaSales: adaSales,
                                adaSalesMoney: adaSalesMoney,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yarım Saatlik Araç Trafiği',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 300,
                              child: TrafficChart(
                                hourlyTraffic: hourlyTraffic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, 
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SaleTransaction {
  final String receiptNo;
  final String time;
  final String plate;
  final String fuelType;
  final double liters;
  final double total;

  SaleTransaction({
    required this.receiptNo,
    required this.time,
    required this.plate,
    required this.fuelType,
    required this.liters,
    required this.total,
  });
} 