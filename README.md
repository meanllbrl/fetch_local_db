
This package is a solution for preventing heavy Firebase usage to have decreased Google bills. Solution is simply, request data from Firestore which is not exist on SQL Lite service. As a conclusion the doc count that we get from Firestore will be minimized.

- But What İf The Data Which Already Writed On SQL Lite, Updated Somehow?
    * Because the data already exist, the package will not get the old data from Firebase.
    * Some users will have old data that not fits with the updated one.

+ As a solution, this package(if user entered an UpdateModel) checks some docs that have special fields to look if local and hosted databases matches. If not, the local data will be updated on SQL Lite service.

## Features

* FetchLocalFF returns the data which exists on Firestore but not in Sql Lite with the onFinished function.
* FetchLocalFF provide service that if some data is updated on Firestore; the data which is already exist on SQL Lite will be updated as well.



## Getting started

* Firebase must be installed successfully!
* If comparision parameter is not DATE or TIMESTAMP, isItDate must be false.
* For update control (checks if hosted data matches local data), UpdateModel must be initialized.
* UpdateModel/localCompParam must be an integer not Timestamp. If Timestamp is used, milliseconssinceach... should be given.

## Semantic
* Getting New Data Which Only Doesn't Exist On SQL-Lite(Local Database)
![Untitled Diagram drawio](https://user-images.githubusercontent.com/83311854/155860360-26652368-885a-4182-95fb-77cb4855c835.png)

STEP 1: System asks Local Database to return ( if comparision type is DATE ) latest data row creation date.\n
STEP 2: Local Database returns latest date or biggest index.
STEP 3: System send request of data which is newer from local latest date.
STEP 4: Firebase returns the docs which are newer.
STEP 5: System gets returned new data and insert them into Local Database.
STEP 6: System read all local data and write 'em to Provider.

LIFE CYCLE: In the life-cycle we don't send any get request, and handle states locally. The changes will be set on Firebase and SQL-lite as well.

## Usage

* With this usage, data which exist in firestore and not exist on local database will be returned with onFinished method. Note: The possible updates which happened out of application lifecyle will not checked in the usage!

```dart
    FetchLocalFF _fetch = FetchLocalFF(
         // if local comp param is stored as millisecondsinceach...
        isItDate: false,
        //local database informations(SQL-LITE)
        localDatabase:
            LocalInfos(tableName: "tableName", compParam: "index"),
        fbDatabase:
            FirebaseInfos(collectionName: "collectionName", compParam: "index"),
        onFinished: (value, skippes) async {
          //fThe data which exist on Firebase and doesn't on Local
        });
    await _fetch.fetch();
```

* With this usage, as an addition the updates(out of app lifecycle) will be also checked, and if some updated docs exist; the docs will be replaced with updated ones.

```dart
    FetchLocalFF _fetch = FetchLocalFF(
         //if the upDateModel is given; possible updates will be checked
         updateModel: UpdateModel(
            insertDataWithFBDocs: (value) {
              //the method which insert firebase docs to sql database should be given here
            },
            //local primary key
            localTableId: "id",
            //firebase primary key
            fbDocId: "id",
            //the field which only be exist on updated docs
            fbCompParam: "updateDate",
            //table creation attribute
            localCompParam: "createdAt",
            //firebase query can be given manuelly; if not, the query will order the collection with fbCompParam
            fbQuery: _data
                .collection("giveAways")
                .where("isFinished", isEqualTo: true)
                .orderBy("updateDate")
                .get()),
         ...
       );
    await _fetch.fetch();
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
