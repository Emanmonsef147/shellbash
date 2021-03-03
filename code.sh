#!/bin/bash
#our DBMS
mkdir DBMS 2>> ./.error.log
echo "Welcome To DBMS"

#Main Menu Chossing
mainMenu()
{
  echo "              Main Menu            "
  echo " 1. Create DB                      "
  echo " 2. List DBs                       "
  echo " 3. Drop DB                        "
  echo " 4. Exit                           "
  echo "___________________________________"
  echo "Enter Choice: "
  read your_ch
  case $your_ch in
    1)  createDB ;;
    2)  ls ./DBMS ; mainMenu;;
    3)  dropDB  ;;
    4)  exit ;;
    *)  echo " Wrong Choice " ; mainMenu;
  esac
}

#Creatiing DataBase
createDB()
{
  echo  "Enter Database Name To Create: \c"
  read dbName
  mkdir ./DBMS/$dbName
  if [[ $? == 0 ]]
  then
    echo "Database Created Successfully"
  else
    echo "Error Creating Database $dbName"
  fi
  mainMenu
}

#drop DataBase
 dropDB()
{
  echo  "Enter Database Name You Want To Delete : "
  read dbName
  rm -r ./DBMS/$dbName 2>>./.error.log
  if [[ $? == 0 ]]; then
    echo "Database Dropped Successfully"
  else
    echo "Database Not found"
  fi
  mainMenu
}


tablesMenu()
{
  echo "            Tables Menu            "
  echo " 1. Create New Table               "
  echo " 2. Show Existing Tables           "
  echo " 3. Drop Table                     "
  echo " 4. Insert Into Table              "
  echo " 5. Select From Table              "
  echo " 6. Delete From Table              "
  echo " 7. Back To Main Menu              "
  echo " 8. Exit                           "
  echo "___________________________________"
  echo  "Enter Choice: "
  read your_ch

  case $your_ch in
    1)  createTable ;;
    2)  ls .; tablesMenu ;;
    3)  dropTable;;
    4)  insert;;
    5)  clear; selectMenu ;;
    6)  deleteFromTable;;
    7) clear; cd ../.. 2>>./.error.log; mainMenu ;;
    8) exit ;;
    *) echo " Wrong Choice " ; tablesMenu;
  esac
}
tablesMenu
#Create Table
createTable()
{
  echo  "Table Name To Create: "
  read tableName
  if [[ -f $tableName ]]; then
    echo "table already existed ,choose another name"
    tablesMenu
  fi
  echo  "Number of Columns: "
  read colsNum
  counter=1
  sep="|"
  rSep="\n"
  pKey=""
  metaData="Field"$sep"Type"$sep"key"
  while [ $counter -le $colsNum ]
  do
    echo  "Name of Column No.$counter: "
    read colName

    echo  "Type of Column $colName: "
    select var in "int" "str"
    do
      case $var in
        int ) colType="int";break;;
        str ) colType="str";break;;
        * ) echo "Wrong Choice" ;;
      esac
    done
    if [[ $pKey == "" ]]; then
      echo  "Make PrimaryKey ? "
      select var in "yes" "no"
      do
        case $var in
          yes ) pKey="PK";
          metaData+=$rSep$colName$sep$colType$sep$pKey;
          break;;
          no )
          metaData+=$rSep$colName$sep$colType$sep""
          break;;
          * ) echo "Wrong Choice" ;;
        esac
      done
    else
      metaData+=$rSep$colName$sep$colType$sep""
    fi
    if [[ $counter == $colsNum ]]; then
      temp=$temp$colName
    else
      temp=$temp$colName$sep
    fi
    ((counter++))
  done
  touch .$tableName
  echo  $metaData  >> .$tableName
  touch $tableName
  echo  $temp >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Table Created Successfully"
    tablesMenu
  else
    echo "Error Creating Table $tableName"
    tablesMenu
  fi
}

#Drop Table
dropTable() 
{
  echo -e "Enter Table Name: \c"
  read tName
  rm $tName .$tName 2>>./.error.log
  if [[ $? == 0 ]]
  then
    echo "Table Dropped Successfully"
  else
    echo "Error Dropping Table $tName"
  fi
  tablesMenu
}

#Insert Into Table
insert()
{
  echo  "Table Name: "
  read tableName
  if ! [[ -f $tableName ]]; then
    echo "Table $tableName isn't existed ,choose another Table"
    tablesMenu
  fi
  colsNum=`awk 'END{print NR}' .$tableName`
  sep="|"
  rSep="\n"
  for (( i = 2; i <= $colsNum; i++ )); do
    colName=$(awk 'BEGIN{FS="|"}{ if(NR=='$i') print $1}' .$tableName)
    colType=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $2}' .$tableName)
    colKey=$( awk 'BEGIN{FS="|"}{if(NR=='$i') print $3}' .$tableName)
    echo  "$colName ($colType) = "
    read data

    # Validate Input
    if [[ $colType == "int" ]]; then
      while ! [[ $data =~ ^[0-9]*$ ]]; do
        echo -e "invalid DataType !!"
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    if [[ $colKey == "PK" ]]; then
      while [[ true ]]; do
        if [[ $data =~ ^[`awk 'BEGIN{FS="|" ; ORS=" "}{if(NR != 1)print $(('$i'-1))}' $tableName`]$ ]]; then
          echo -e "invalid input for Primary Key !!"
        else
          break;
        fi
        echo -e "$colName ($colType) = \c"
        read data
      done
    fi

    #Set row
    if [[ $i == $colsNum ]]; then
      row=$row$data$rSep
    else
      row=$row$data$sep
    fi
  done
  echo -e $row"\c" >> $tableName
  if [[ $? == 0 ]]
  then
    echo "Data Inserted Successfully"
  else
    echo "Error Inserting Data into Table $tableName"
  fi
  row=""
  tablesMenu
}

#Delete From Table
deleteFromTable() {
  echo -e "Enter Table Name: \c"
  read tName
  echo -e "Enter Column name: \c"
  read field
  fid=$(awk 'BEGIN{FS="|"}{if(NR==1){for(i=1;i<=NF;i++){if($i=="'$field'") print i}}}' $tName)
  if [[ $fid == "" ]]
  then
    echo "Not Found"
    tablesMenu
  else
    echo -e "Enter Condition Value: \c"
    read val
    res=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print $'$fid'}' $tName 2>>./.error.log)
    if [[ $res == "" ]]
    then
      echo "Value Not Found"
      tablesMenu
    else
      NR=$(awk 'BEGIN{FS="|"}{if ($'$fid'=="'$val'") print NR}' $tName 2>>./.error.log)
      sed -i ''$NR'd' $tName 2>>./.error.log
      echo "Row Deleted Successfully"
      tablesMenu
    fi
  fi
}
mainMenu
