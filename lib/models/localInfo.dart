class LocalInfos {
  //sql table name
  final String tableName;
  //sql table comparision parameter
  final String compParam;
  final String? primaryKeyField;
  final dynamic primaryKeyValue;
  //if update model is not null and there is any updated doc, this function will be triggered
  LocalInfos( {required this.tableName, required this.compParam,this.primaryKeyField, this.primaryKeyValue,});
}
