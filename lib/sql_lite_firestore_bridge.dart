import 'dart:developer';

import 'package:fetch_local_db/models/firebaseInfo.dart';
import 'package:fetch_local_db/models/localInfo.dart';
import 'package:fetch_local_db/models/updateModel.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mean_lib/local_db_helper.dart';

/// A class for bridging Firestore and local SQLite databases.
class SqlLiteFirestoreBridge {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDBService _local = LocalDBService(name: "batch.db");

  final LocalInfos localDatabase; // Information about the local database
  final FirebaseInfos fbDatabase; // Information about the Firebase database
  final bool isItDate; // Indicates whether the comparison field is a date
  final UpdateModel?
      updateModel; // Model for updating local data based on Firebase data
  final Future<void> Function(QuerySnapshot value, List<String> skips)
      onFinished; // Callback function when processing is complete
  final Future<QuerySnapshot> Function(dynamic compElement)?
      fbQuery; // Function for custom Firestore queries

  /// Create a `SqlLiteFirestoreBridge` instance to facilitate data synchronization.
  SqlLiteFirestoreBridge({
    required this.isItDate, // Specifies whether the comparison is based on dates
    this.updateModel, // Model for updating local data (optional)
    this.fbQuery, // Custom Firebase query function (optional)
    required this.localDatabase, // Information about the local database
    required this.fbDatabase, // Information about the Firebase database
    required this.onFinished, // Callback function for when the process is complete
  });

  /// Fetch missing data from Firestore and update the local SQLite database.
  ///
  /// This method fetches data from Firestore and updates the local SQLite database.
  ///
  /// It first determines the comparison element to be used in Firestore queries based
  /// on whether it's a date or not. It checks the local database for the number of documents,
  /// and if documents exist, it retrieves the largest comparison element from the local database.
  ///
  /// Then, it queries Firestore for new documents that have a comparison element greater than
  /// the one in the local database. It can also use a custom Firestore query provided by [fbQuery].
  ///
  /// If [updateModel] is provided, it performs additional checks to compare and update data.
  ///
  /// [onFinished] is a callback function called when the process is complete, passing the retrieved
  /// Firestore documents and a list of skipped document IDs.
  ///
  /// This method uses proper error handling and logs debug information when [kDebugMode] is enabled.
  Future<void> fetch() async {
    dynamic comparisonElement = isItDate ? DateTime(2000) : 0;
    int localDocCount = await _getCount();

    //If there is some documents
    if (localDocCount != 0) {
      comparisonElement = await _getBiggest();
      if (isItDate) {
        try {
          comparisonElement =
              Timestamp.fromMillisecondsSinceEpoch(comparisonElement + 1);
        } catch (e) {
          throw ErrorDescription(
              "Are You Sure That Is A Date(FrommillisecondsSinceEpoch)?");
        }
      }
    }

    //The documents list that already stored on sql lite
    List<String> skipWhileInserting = [];

    //the query that will run as "get" request from cloud_firestore
    var firebaseQuery = (fbQuery != null
        ? fbQuery!(comparisonElement)
        : _db
            .collection(fbDatabase.collectionName)
            .where(fbDatabase.compParam, isGreaterThan: comparisonElement)
            .get());

    await firebaseQuery.then((newDocs) async {
      //if we don't look for catching updates that may happened in data which previously stored in sql lite database
      if (updateModel == null) {
        await onFinished(newDocs, skipWhileInserting);
      } else {
        //looking for updated document
        log("the databases have to have updateDate param");
        try {
          if (kDebugMode) {
            log("*****UPDATE CONTROL: BEGINS");
          }
          List theData = await _local.read(
            parameters:
                "${updateModel!.localCompParam} AS comp,${updateModel!.localTableId} AS id",
            tableName: localDatabase.tableName,
          );
          if (theData[0].isNotEmpty) {
            var updateLookingFirebaseQuery = (updateModel!.fbQuery ??
                _db
                    .collection(fbDatabase.collectionName)
                    .orderBy(updateModel!.fbCompParam)
                    .get());
            //getting the update potentialed data
            await updateLookingFirebaseQuery.then((docsWithUpdateComp) async {
              if (kDebugMode) {
                log("*****UPDATE CONTROL: THE DOCS WHICH HAS UP. PARAM (${docsWithUpdateComp.docs.length})");
              }
              try {
                for (var fb in docsWithUpdateComp.docs) {
                  Map<String, dynamic>? singleDoc = theData[0]
                      .where((element) =>
                          element["id"] ==
                          (updateModel!.fbDocId != null
                              ? fb[updateModel!.fbDocId!]
                              : fb.id))
                      .first;
                  if (kDebugMode) {
                    log("singledoc: " + singleDoc.toString());
                  }
                  if (singleDoc != null) {
                    skipWhileInserting.add(singleDoc["id"]);
                    if (singleDoc["comp"] + 1 <
                        fb[updateModel!.fbCompParam]
                            .toDate()
                            .millisecondsSinceEpoch) {
                      if (kDebugMode) {
                        log("*****UPDATE CONTROL: DELETING FROM LOCAL");
                      }
                      _local.delete(
                        tableName: localDatabase.tableName,
                        whereStatement:
                            "WHERE ${updateModel!.localTableId} ='${singleDoc["id"]}'",
                      );
                      if (kDebugMode) {
                        log("*****UPDATE CONTROL: ADDING TO LOCAL");
                      }
                      updateModel!.insertDataWithFBDocs([fb]);
                    }
                  }
                }
                if (kDebugMode) {
                  log("iş bitti");
                }
              } catch (e) {
                if (kDebugMode) {
                  log("update control error ${e.toString()}");
                }
              }
            }).then((value) async {
              await onFinished(newDocs, skipWhileInserting);
            });
          } else {
            await onFinished(newDocs, skipWhileInserting);
          }
        } catch (e) {
          if (kDebugMode) {
            log("*****UPDATE CONTROL: ERROR  ${e.toString()}");
          }
        }
      }
    });
  }

  /// Get the biggest value of the comparison field from the local database.
  ///
  /// This method retrieves the largest value of the specified comparison field
  /// from the local database table. It can be further filtered using the primary
  /// key field and value if provided.
  ///
  /// Returns the largest value of the comparison field.
  ///
  /// Throws an [ErrorDescription] if an error occurs during the process.
  Future<dynamic> _getBiggest() async {
    try {
      List theData = await _local.read(
        parameters: localDatabase.compParam,
        tableName: localDatabase.tableName,
        lastStatement: localDatabase.primaryKeyField != null
            ? "${localDatabase.primaryKeyField}='${localDatabase.primaryKeyValue.toString()}' ORDER BY ${localDatabase.compParam} DESC LIMIT 1"
            : "ORDER BY ${localDatabase.compParam} DESC LIMIT 1",
      );
      return theData[0][0][localDatabase.compParam];
    } catch (e) {
      log(e.toString());
      throw ErrorDescription("Local Database _getBiggest crashed!!!");
    }
  }

  /// Get the count of records in the local database table.
  ///
  /// This method retrieves the count of records in the specified local database table.
  /// It can be further filtered using the primary key field and value if provided.
  ///
  /// Returns the count of records in the table.
  ///
  /// Throws an [ErrorDescription] if an error occurs during the process.
  Future<int> _getCount() async {
    try {
      List theData = await _local.read(
        parameters: "COUNT(*) AS total",
        tableName: localDatabase.tableName,
        where: localDatabase.primaryKeyField != null
            ? "${localDatabase.primaryKeyField}='${localDatabase.primaryKeyValue}'"
            : "",
      );
      return theData[0][0]["total"];
    } catch (e) {
      log(e.toString());
      throw ErrorDescription("Local Database get count crashed!!!");
    }
  }
}
