import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateModel {
  //firebase doc identifier
  final String? fbDocId;
  //sql table identifier
  final String localTableId;
  //local update comparision parameter
  final String localCompParam;
  //firebase update comparision parameter
  final String fbCompParam;
  //the function which gets the firebase docs and insert into the table
  final Function(List docs) insertDataWithFBDocs;
  //the firebase query can be given
  final Future<QuerySnapshot<Map<String, dynamic>>>? fbQuery;
  UpdateModel(
      {required this.insertDataWithFBDocs,
        this.fbDocId,
        this.fbQuery,
        required this.localTableId,
        this.localCompParam = "createdAt",
        this.fbCompParam = "updateDate"});
}