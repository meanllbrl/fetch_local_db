# Fetch Local Database Package

This package is designed to help reduce Firebase usage and lower Google bills by efficiently managing data synchronization between Firestore and a local SQLite database. It primarily focuses on fetching data from Firestore that is missing in the local SQLite database, reducing the Firestore document read count.

## Features

- SqlLiteFirestoreBridge retrieves data from Firestore that is not present in the local SQLite database using the `onFinished` function.
- It provides a mechanism for updating local data in response to changes in Firestore, ensuring data consistency between the two databases.

## Getting Started

To use this package, you need to ensure the following prerequisites:

- Firebase must be successfully installed and configured in your Flutter project.
- If the comparison parameter is not of type `DATE` or `TIMESTAMP`, set the `isItDate` parameter to `false`.
- For update control, where the package checks if hosted data matches local data, you must initialize an `UpdateModel`.
- The `localCompParam` in the `UpdateModel` must be of integer type and not a `Timestamp`. If using `Timestamp`, ensure the conversion to milliseconds since epoch is provided.

## Semantic Overview

![Semantic Diagram](https://user-images.githubusercontent.com/83311854/155860360-26652368-885a-4182-95fb-77cb4855c835.png)

1. The system requests the local database to return the latest data row creation date if the comparison type is `DATE`.
2. The local database returns the latest date or the largest index.
3. The system sends a request for data that is newer than the local latest date to Firebase.
4. Firebase returns the documents that are newer.
5. The system retrieves the newly returned data and inserts it into the local database.
6. The system reads all local data and writes it to a provider or other state management solution.

## Detailed Flow

The Fetch Local Database package follows a specific flow to efficiently manage data synchronization between Firestore and the local SQLite database. This flow can be summarized as follows:

1. **Initialization**:
   - Configure the `SqlLiteFirestoreBridge` instance with the necessary parameters, including database information, comparison types, and update control settings.

2. **Local Database Check**:
   - Determine the comparison element based on whether it's a date or not. If data exists in the local database, retrieve the latest date or the largest index as the comparison element.
   - If the comparison parameter is of type `DATE`, the package handles date conversion and validation.

3. **Firestore Query**:
   - Query Firestore to retrieve documents that have a comparison element greater than the one in the local database.
   - You can also use a custom Firestore query function if provided via `fbQuery`.

4. **Data Retrieval and Insertion**:
   - Retrieve the new documents returned from Firestore.
   - Insert these new documents into the local SQLite database.

5. **Update Control (Optional)**:
   - If an `UpdateModel` is provided, the package performs additional checks for updates.
   - The `UpdateModel` includes settings for local and Firebase comparison parameters, primary keys, and custom Firebase queries.
   - It checks if hosted data matches local data and updates the local database if necessary.

6. **Completion**:
   - Once the synchronization process is complete, the `onFinished` callback function is triggered, passing the retrieved Firestore documents and a list of skipped document IDs.

7. **Data Consumption**:
   - With the updated local database, the application can consume data as needed, ensuring that it has the latest information from both Firestore and the local SQLite database.

This flow ensures that data is efficiently managed between Firestore and the local SQLite database, reducing Firebase usage and improving data consistency.


## Usage

### Basic Usage

In this example, data that exists in Firestore but is missing in the local database will be returned with the `onFinished` method. Please note that updates that occurred outside the application lifecycle are not checked.

```dart
SqlLiteFirestoreBridge _fetch = SqlLiteFirestoreBridge(
   // If the local comparison parameter is stored as milliseconds since epoch...
  isItDate: false,
  // Local database information (SQLite)
  localDatabase: LocalInfos(tableName: "tableName", compParam: "index"),
  fbDatabase: FirebaseInfos(collectionName: "collectionName", compParam: "index"),
  onFinished: (value, skips) async {
    // The data that exists on Firebase and doesn't exist in the local database
  }
);
await _fetch.fetch();
```

### Detailed Usage

In this example, in addition to fetching missing data, updates (outside the app lifecycle) are also checked. If some updated documents exist, they will be replaced with the updated ones.

```dart
SqlLiteFirestoreBridge _fetch = SqlLiteFirestoreBridge(
   // If the updateModel is provided, possible updates will be checked
   updateModel: UpdateModel(
      insertDataWithFBDocs: (value) {
        // The method that inserts Firebase documents into the SQL database should be provided here
      },
      // Local primary key
      localTableId: "id",
      // Firebase primary key
      fbDocId: "id",
      // The field that only exists in updated documents
      fbCompParam: "updateDate",
      // Table creation attribute
      localCompParam: "createdAt",
      // A custom Firebase query can be provided manually; if not, the query will order the collection with fbCompParam
      fbQuery: _data
          .collection("giveAways")
          .where("isFinished", isEqualTo: true)
          .orderBy("updateDate")
          .get()),
   ...
);
await _fetch.fetch();
```

