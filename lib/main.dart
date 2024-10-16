import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Safety Data',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FoodSafetyTable(),
    );
  }
}

class FoodSafetyTable extends StatefulWidget {
  const FoodSafetyTable({super.key});

  @override
  _FoodSafetyTableState createState() => _FoodSafetyTableState();
}

class _FoodSafetyTableState extends State<FoodSafetyTable> {
  List<dynamic> _data = [];
  List<dynamic> _filteredData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // 필터링 선택을 위한 변수
  String? _selectedRegion;
  String? _selectedIndustry;

  // 업종 필터 옵션 (라디오 버튼용)
  final List<String> _industryOptions = ['음식점업', '제과점업', '기타']; // 예시 업종

  // 지역 필터 옵션 (드롭다운 리스트용)
  final List<String> _regionOptions = ['서울', '경기', '부산', '대구']; // 예시 지역

  final String keyId = '92610ee3912f44b28eaf'; // 사용자의 API 키
  final String serviceId = 'I2832'; // 사용할 서비스 ID
  final String dataType = 'json'; // 데이터 형식 (json 또는 xml)
  final int startIdx = 1; // 시작 인덱스
  final int endIdx = 100; // 종료 인덱스 (한 번에 가져올 최대 데이터 양)

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // 필터 파라미터 설정
    String regionFilter = _selectedRegion ?? '';
    String industryFilter = _selectedIndustry ?? '';

    // API URL 동적 생성
    String url =
        'http://openapi.foodsafetykorea.go.kr/api/$keyId/$serviceId/$dataType/$startIdx/$endIdx';

    // 필터링을 위한 추가 요청 인자
    if (regionFilter.isNotEmpty || industryFilter.isNotEmpty) {
      url += '?';
      if (regionFilter.isNotEmpty) {
        url += 'LOCP_ADDR=$regionFilter&'; // 지역 필터 추가
      }
      if (industryFilter.isNotEmpty) {
        url += 'INDUTY_NM=$industryFilter&'; // 업종 필터 추가
      }
    }

    try {
      print('Fetching data from API: $url');
      final response = await http.get(Uri.parse(url));
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        print('Decoded data: $decodedData');
        setState(() {
          _data = decodedData['I2832']['row'];
          _filteredData = _data; // 초기에는 전체 데이터를 보여줌
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to load data with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    setState(() {
      _filteredData = _data.where((item) {
        final regionMatches = _selectedRegion == null ||
            item['LOCP_ADDR'].toString().contains(_selectedRegion!);
        final industryMatches =
            _selectedIndustry == null || item['INDUTY_NM'] == _selectedIndustry;
        return regionMatches && industryMatches;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building widget tree');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Safety Data Table'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 지역 선택 (드롭다운 리스트)
                          DropdownButton<String>(
                            hint: const Text('지역 선택'),
                            value: _selectedRegion,
                            items: _regionOptions.map((String region) {
                              return DropdownMenuItem<String>(
                                value: region,
                                child: Text(region),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedRegion = newValue;
                              });
                              _filterData(); // 지역 변경 시 필터링
                            },
                          ),
                          const SizedBox(height: 20),
                          // 업종 선택 (라디오 버튼)
                          const Text('업종 선택'),
                          Column(
                            children: _industryOptions.map((industry) {
                              return RadioListTile<String>(
                                title: Text(industry),
                                value: industry,
                                groupValue: _selectedIndustry,
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedIndustry = newValue;
                                  });
                                  _filterData(); // 업종 변경 시 필터링
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: fetchData,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('인허가번호')),
                                DataColumn(label: Text('업소명')),
                                DataColumn(label: Text('대표자명')),
                                DataColumn(label: Text('업종')),
                                DataColumn(label: Text('허가일자')),
                                DataColumn(label: Text('주소')),
                                DataColumn(label: Text('기관명')),
                              ],
                              rows: _filteredData.map(
                                (item) {
                                  return DataRow(cells: [
                                    DataCell(Text(item['LCNS_NO'] ?? '정보 없음')),
                                    DataCell(Text(item['BSSH_NM'] ?? '정보 없음')),
                                    DataCell(
                                        Text(item['PRSDNT_NM'] ?? '정보 없음')),
                                    DataCell(
                                        Text(item['INDUTY_NM'] ?? '정보 없음')),
                                    DataCell(Text(item['PRMS_DT'] ?? '정보 없음')),
                                    DataCell(
                                        Text(item['LOCP_ADDR'] ?? '정보 없음')),
                                    DataCell(Text(item['INSTT_NM'] ?? '정보 없음')),
                                  ]);
                                },
                              ).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
