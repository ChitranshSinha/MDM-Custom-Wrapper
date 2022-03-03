%dw 2.0
import * from dw::core::Binaries

fun fLookupCodeExtract(field, joinValue, defaultval) =
  if ((field == null or field..value == null or field..value == ""))
    defaultval
  else
    (field..lookupCode joinBy joinValue)
fun performnullCheck(field, defaultval) =
  if ((field == null or field == ""))
    defaultval
  else
    field
fun performDoubleDotCheckWithArrayJoin(field, joinValue, defaultval) =
  if ((field == null or field..value == null or field..value == ""))
    defaultval
  else
    (field..value joinBy joinValue)
fun performArrayNullCheckWithArrayJoin(field, joinValue, defaultval) =
  if ((field == null or field.value == null or field.value == ""))
    defaultval
  else
    (field.value joinBy joinValue)
fun performArrayNullCheckWithArrayJoinCheckingPresence(fieldName, field, joinValue) =
  {
    ("$(fieldName)": (field..value joinBy joinValue)) if (not field == null and not field == [] and not field..value == null and not field..value == [] and not field..value == "")
  }
fun performArrayCodeCheckWithArrayJoin(fieldName, field, joinValue) =
  {
    ("$(fieldName)": (field..lookupCode joinBy joinValue)) if (not field == null and not field == [] and not field..lookupCode == null and not field..lookupCode == [] and not field..lookupCode == "")
  }
fun createNewUri(fieldName, baseUri, field, joinChar) =
  {
    ("$(fieldName)": (baseUri ++ "#" ++ ((field..uri joinBy joinChar) replace /^(.*)\/([^\/]*)$/ with ($[2])))) if (not field == null and not field == [] and not field..uri == null and not field..uri == "")
  }
  
fun createNewTypeUri(fieldName, baseUri, Type , field, joinChar) =
  {
    ("$(fieldName)": (baseUri ++ "#" ++ Type ++ "#" 
    	++ ((field..uri  default [] joinBy joinChar) replace /^(.*)\/([^\/]*)$/ with ($[2]))
    )) if ((not field == null) and (not field == []) and (not field..uri == null) and (not field..uri == ""))
  }
  
fun specialtyExtract(value01, value02) =
  (flatten((value01 default [])) map (value01, index01) -> {
    lookupCode: value01.value.SpecialtyType[0].lookupCode default "",
    Specialty: value01.value.Specialty[0].lookupCode default "",
    Rank: value01.value.Rank[0].value default 1,
    ClientIndividualIdentifier: value02 default "",
    Type: value01.value.SpecialtyType[0].lookupCode default "",
    GroupCode: value01.value.Group[0].lookupCode default ""
  }) orderBy $.Rank 
fun concatValues(list) =
  if ((not list == null and ((sizeOf(list default [])) > 0 ) and not list.value == null))
    list[0].value
  else
    null
fun isNotEmptyList(list) =
  (not list == null and (sizeOf(list)) > 0)
fun uri(value) =
  (value default "" splitBy "/")[1]
fun concatCodes(list) =
  if ((isNotEmptyList(list)))
    (if ((not list[0].lookupCode == "" and not list[0].lookupCode == null))
      list[0].lookupCode
    else
      null)
  else
    null
fun verifyTime(dateAndTime) =
  (if ((dateAndTime == null))
    null
  else (if ((dateAndTime contains "24:00:00"))
    (dateAndTime as String)[0 to 10] ++ "23:59:59" ++ (dateAndTime as String)[19]
  else (if (((sizeOf(dateAndTime)) == 10))
    (dateAndTime as String) ++ "T00:00:00Z"
 else
    dateAndTime as String)))
fun ComplianceIdentifier(uri, sourceName, Category, Rank) =
  [
    uri,
    sourceName,
    Category,
    Rank
  ] filter not $ == null joinBy "#"
fun EducationIdentifier(uri, sourceName, typecode) =
  [
    uri,
    sourceName,
    typecode
  ] filter not $ == null joinBy "#"
fun amsFilter(value) =
  (value.Identifiers.*value.Type..value default []) contains "AMS"
fun substringBefore(lookupKey, delimiter) =
  (lookupKey splitBy (delimiter))[0]
fun substringAfter(lookupKey, delimiter) =
  ((lookupKey splitBy (delimiter)) filter (not $$ == 0)) joinBy (delimiter)
fun Extract(lookupKey = "", lookupObj) =
  if ((lookupKey contains "."))
    Extract(substringAfter(lookupKey, "."), lookupObj[substringBefore(lookupKey, ".")])
  else
    lookupObj[lookupKey]
fun subnode(aRoot, aSub) =
  if ((aSub == ""))
    aRoot
  else
    Extract(aSub, aRoot)[0]
fun firstsubnode(aRoot, aSub) =
  if ((aSub == ""))
    aRoot
  else
    Extract(aSub, aRoot)
fun extractWrap(aDef, aNode) =
  Extract(aDef.fld, if (aDef.nst == "1")
    subnode(aNode, aDef.sbnde)
  else
    firstsubnode(aNode, aDef.sbnde))
fun getallnodes(aEntity, arryObjNodes, arrObjFields, rootnode) =
  (arryObjNodes filter $.prnt == aEntity map (aNode) -> ({
    ((aNode.sec)) : firstsubnode(rootnode, aNode.reltnode) map (aRecord) -> ((arrObjFields filter $.sec == aNode.sec map (aDef) -> {
        ((aDef.tgt)) : extractWrap(aDef, aRecord)[0]
      }) reduce (item, accumulator = {}) -> accumulator ++ item)
  })) reduce (item, accumulator = {}) -> item ++ accumulator
fun getNodesandFields(aSec, arryObjNodes, arrObjFields, payload) =
  getallnodes(aSec, arryObjNodes, arrObjFields, payload) ++ getFields(aSec, arrObjFields, payload)
fun getFields(aSec, arrObjFields, payload) =
  (arrObjFields filter $.sec == aSec map (aDef) -> {
    ((aDef.tgt)) : 
      if (aDef.nst == "2")
        (extractWrap(aDef, payload))
      else
        (extractWrap(aDef, payload)[0])
  }) reduce (item, accumulator = {}) -> accumulator ++ item

fun arraySplitAndJoin(field, splitValue) =
  (field map {
    key: ($ splitBy splitValue)[2]
  }.key)
  

fun decode64 (value) = (read (fromBase64(value),"application/json") ) 
fun createVarAuth (cred) = "basic " ++ toBase64 ( (decode64(cred).clientId) 
									++ ":" ++  (decode64(cred).clientSecret))   

fun ExtractBrick(data) =  if (data == null or data == []) ({
"RCHMnBrick" : null,
"RCHMcBrick" : null
    })
else 
((((flatten( data) ) default [] map (v,k) -> {
    ("RCHMnBrick" : v.BrickValue.lookupCode[0]) if (v.Type.lookupCode[0] == "MINI_BRICK" or v.Type.lookupCode[0] == "UG2") ,
    ("RCHMcBrick" : v.BrickValue.lookupCode[0]) if (v.Type.lookupCode[0] == "MICRO_BRICK" or v.Type.lookupCode[0] == "UG3")
}) reduce (item,acc={}) -> acc ++ item ) )
---

{
getNodesandFields : getNodesandFields ,
getallnodes : getallnodes,
getFields   : getFields ,

concatValues : concatValues,
isNotEmptyList : isNotEmptyList,
uri : uri ,
concatCodes : concatCodes ,
verifyTime : verifyTime ,
ComplianceIdentifier : ComplianceIdentifier ,
EducationIdentifier : EducationIdentifier,
amsFilter : amsFilter,

fLookupCodeExtract : fLookupCodeExtract,
performnullCheck : performnullCheck,	
performDoubleDotCheckWithArrayJoin : performDoubleDotCheckWithArrayJoin,
performArrayNullCheckWithArrayJoin : performArrayNullCheckWithArrayJoin ,
performArrayNullCheckWithArrayJoinCheckingPresence : performArrayNullCheckWithArrayJoinCheckingPresence ,
performArrayCodeCheckWithArrayJoin : performArrayCodeCheckWithArrayJoin ,
createNewUri : createNewUri ,
createNewTypeUri : createNewTypeUri,
specialtyExtract : specialtyExtract ,

arraySplitAndJoin : arraySplitAndJoin,

decode64 : decode64 ,
createVarAuth : createVarAuth,
ExtractBrick : ExtractBrick
 
}

