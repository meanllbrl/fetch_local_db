
This package is a solution for preventing heavy Firebase usage to have decreased Google bills. Solution is simply, request data from Firestore which is not exist on SQL Lite service. As a conclusion the doc count that we get from Firestore will be minimized.

- But What İf The Data Which Already Writed On SQL Lite, Updated Somehow?
    * Because the data already exist, the package will not get the old data from Firebase.
    * Some users will have old data that not fits with the updated one.

+ As a solution, this package(if user entered an UpdateModel) checks some docs that have special fields to look if local and hosted databases matches. If not, the local data will be updated on SQL Lite service.

## Features

* FetchLocalFF returns the data which is exist on Firestore but not in Sql Lite with the onFinished function.
* FetchLocalFF provide service that if some data is updated on Firestore; the data which is already exist on SQL Lite will be updated as well.



## Getting started

* Firebase must be installed successfully!
* If comparision parameter is not DATE or TIMESTAMP, isItDate must be false.
* For update control (checks if hosted data matches local data), UpdateModel must be initialized.
* UpdateModel/localCompParam must be an integer not Timestamp. If Timestamp is used, milliseconssinceach... should be given.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
