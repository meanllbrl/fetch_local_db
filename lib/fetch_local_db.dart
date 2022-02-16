library fetch_local_db;
import 'package:fetch_local_db/models/firebaseInfo.dart';
import 'package:fetch_local_db/models/localInfo.dart';
import 'package:fetch_local_db/models/updateModel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mean_lib/logger.dart';
import 'package:mean_lib/local_db_helper.dart';


class FetchLocalFF {
  //firestore instance for some processes
  FirebaseFirestore _db = FirebaseFirestore.instance;
  //local database service object for proccesses
  LocalDBService _local = LocalDBService(name: "batch.db");

  //this LocalInfos is the atr which will be used to compare local db and firebase
  final LocalInfos localDatabase;
  //this param is the atr which will be used to compare firebase and local
  final FirebaseInfos fbDatabase;
  //this is a bool var to know the comparision type will be a date
  final bool isItDate;
  //this param is for enabling looking for updated values on db
  final UpdateModel? updateModel;
  //the function will be triggered when process ok
  final Future<void> Function(
      QuerySnapshot<Map<String, dynamic>> value, List<String> skips) onFinished;
  //the firebase query can be given
  final Future<QuerySnapshot<Map<String, dynamic>>> Function(dynamic compElement)? fbQuery;

  FetchLocalFF(
      {required this.isItDate,
        this.updateModel,
        this.fbQuery,
        required this.localDatabase,
        required this.fbDatabase,
        required this.onFinished});

  //this class for fetching local database from firebase
  //it returns to functionality of getting missing data on local database
  Future<void> fetch() async {
    //comparisio element to use it on firebase query
    dynamic comparisionElement = isItDate ? DateTime(2000) : 0;
    //look to local database if any doc exists
    int localDocCount = await _getCount();
    //if any doc exist get the latest or biggest doc
    if (localDocCount != 0) {
      comparisionElement = await _getBiggest();
      if (isItDate) {
        try {
          comparisionElement =
              Timestamp.fromMillisecondsSinceEpoch(comparisionElement + 1);
        } catch (e) {
          throw ErrorDescription(
              "Are You Sure That Is A Date(Frommilliseconseachpo...)");
        }
      }
    }
    List<String> skipWhileInserting = [];
    //firebase query
    await(fbQuery!=null ? fbQuery!(comparisionElement) : _db
        .collection(fbDatabase.collectionName)
        .where(fbDatabase.compParam, isGreaterThan: comparisionElement)
        .get())
        .then((newDocs) async {
      //returned the values which hosted database has and local hasn't
      if (updateModel == null) {
        await onFinished(newDocs, skipWhileInserting);
      } 
      //if update model is not null
      else {
        Logger.warning("the databases have to have updateDate param");
        try {
          print("*****UPDATE CONTROL: BEGINS");
          //getting table data
          List theData = await _local.read(
              parameters:
              "${updateModel!.localCompParam} AS comp,${updateModel!.localTableId} AS id",
              tableName: localDatabase.tableName);
          //getting dcs which has firebase comparision params
          if (theData.isNotEmpty) {
            await (updateModel!.fbQuery ??  _db
                .collection(fbDatabase.collectionName)
                .orderBy(updateModel!.fbCompParam)
                .get())
                .then((docsWithUpdateComp) {
              print(
                  "*****UPDATE CONTROL: THE DOCS WHICH HAS UP. PARAM (${docsWithUpdateComp.docs.length})");
              try {
                //for each docs with has update compairision fields
                docsWithUpdateComp.docs.forEach((fb) async {
                  //getting the data which is old and from local database
                  Map<String, dynamic>? singleDoc = theData[0]
                      .where((element) =>
                  element["id"] == (updateModel!.fbDocId != null ? fb[updateModel!.fbDocId!] : fb.id))
                      .first;
                  print("singledoc: " + singleDoc.toString());
                  if (singleDoc != null) {
                    //the skip list is for developer to skip insert same doc again
                    skipWhileInserting.add(singleDoc["id"]);
                    //if the doc is old
                    if (singleDoc["comp"] + 1 <
                        fb[updateModel!.fbCompParam]
                            .toDate()
                            .millisecondsSinceEpoch) {
                      print("*****UPDATE CONTROL: DELETING FROM LOCAL");
                      //firstly deeting from local
                      _local.delete(
                          tableName: localDatabase.tableName,
                          whereStatement:
                          "WHERE ${updateModel!.localTableId} ='${singleDoc["id"]}'");
                      print("*****UPDATE CONTROL: ADDING TO LOCAL");
                      //adding to local
                      updateModel!.insertDataWithFBDocs([fb]);
                    }
                  }
                });
              } catch (e) {
                print("update control error ${e.toString()}");
              }
            }).then((value) async {
              await onFinished(newDocs, skipWhileInserting);
            });
          } else {
            await onFinished(newDocs, skipWhileInserting);
          }
        } catch (e) {
          print("*****UPDATE CONTROL: ERROR${e.toString()}");
        }
      }
    });
  }

  Future<dynamic> _getBiggest() async {
    try {
      List theData = await _local.read(
          parameters: localDatabase.compParam,
          tableName: localDatabase.tableName,
          lastStatement: "ORDER BY ${localDatabase.compParam} DESC LIMIT 1");
      return theData[0][0][localDatabase.compParam];
    } catch (e) {
      Logger.bigError(e.toString());
      throw ErrorDescription("Local Database _getBiggest crashed!!!");
    }
  }

  Future<int> _getCount() async {
    try {
      List theData = await _local.read(
          parameters: "COUNT(*) AS total", tableName: localDatabase.tableName);
      return theData[0][0]["total"];
    } catch (e) {
      Logger.bigError(e.toString());
      throw ErrorDescription("Local Database get count crashed!!!");
    }
  }
}
