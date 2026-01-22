class Project {
  String? id;
  String? municipality;
  String? district;
  String? projectName;
  String? projectAddress;
  String? ownerName;
  String? licenseNumber;
  String? plotNumber;
  String? planNumber;
  String? buildingType;
  String? buildingDescription;
  String? floorsCount;
  String? designerOffice;
  String? supervisorOffice;
  String? contractor;
  String? engineerName;
  String? reportDate;
  String? phaseResult;
  String? phoneNumber;
  Map<String, dynamic>? stagesStatus;
  Map<String, dynamic>? testsStatus;
  final double? latitude;
  final double? longitude;

  Project({
    this.id,
    this.municipality,
    this.district,
    this.projectName,
    this.projectAddress,
    this.ownerName,
    this.licenseNumber,
    this.plotNumber,
    this.planNumber,
    this.buildingType,
    this.buildingDescription,
    this.floorsCount,
    this.designerOffice,
    this.supervisorOffice,
    this.contractor,
    this.engineerName,
    this.reportDate,
    this.phaseResult,
    this.phoneNumber,
    this.stagesStatus,
    this.testsStatus,
    this.longitude,
    this.latitude,

  });

  // 🔁 Conversion de l’objet en Map pour Firestore ou API
  Map<String, dynamic> toMap() {
    return {
      'municipality': municipality,
      'district': district,
      'projectName': projectName,
      'projectAddress': projectAddress,
      'ownerName': ownerName,
      'licenseNumber': licenseNumber,
      'plotNumber': plotNumber,
      'planNumber': planNumber,
      'buildingType': buildingType,
      'buildingDescription': buildingDescription,
      'floorsCount': floorsCount,
      'designerOffice': designerOffice,
      'supervisorOffice': supervisorOffice,
      'contractor': contractor,
      'engineerName': engineerName,
      'reportDate': reportDate,
      'phaseResult': phaseResult,
      'phoneNumber':phoneNumber,
      'stagesStatus': stagesStatus,
      'testsStatus': testsStatus ?? {},
      "latitude": latitude,
      "longitude": longitude,
    };
  }

  // 🔄 Conversion inverse : Map -> Objet
  factory Project.fromMap(String id, Map<String, dynamic> map) {
    return Project(
      id: id,
      latitude: map["latitude"],
      longitude: map["longitude"],
      municipality: map['municipality'],
      district: map['district'],
      projectName: map['projectName'],
      projectAddress: map['projectAddress'],
      ownerName: map['ownerName'],
      licenseNumber: map['licenseNumber'],
      plotNumber: map['plotNumber'],
      planNumber: map['planNumber'],
      buildingType: map['buildingType'],
      buildingDescription: map['buildingDescription'],
      floorsCount: map['floorsCount'],
      designerOffice: map['designerOffice'],
      supervisorOffice: map['supervisorOffice'],
      contractor: map['contractor'],
      engineerName: map['engineerName'],
      reportDate: map['reportDate'],
      phaseResult: map['phaseResult'],
      phoneNumber: map['phoneNumber'],
      stagesStatus: map['stagesStatus'] != null
          ? Map<String, dynamic>.from(map['stagesStatus'])
          : {},
      testsStatus: map['testsStatus'] != null
          ? Map<String, dynamic>.from(map['testsStatus'])
          : {},

    );

  }
}
