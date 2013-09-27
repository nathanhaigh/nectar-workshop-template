#!/bin/bash
usage="USAGE: $(basename $0) [-h] [-t <template NX session filename>] -i <ip or hostname> -u <username> -p <password> -o <output NX session filename>

Using a hostname to IP address map file called hostname2ip.txt:
  xargs: xargs -L 1 -a <(awk 'BEGIN{OFS=\"\t\"}{print \" -i \"\$2 \" -o \"\$1\".nxs\"}' < hostname2ip.txt) ./generate_nx_session_files.sh -t template.nxs -u username -p password

  where:
    -h Show this help text
    -t NX Session template filename [Default: template.nxs]
    -i IP/hostname of remote machine
    -u Username
    -p Password
    -o Output NX Session filename
"
# Default command line argument values
#####
NXS_TEMPLATE_FILE="template.nxs"
USER_NAME=
USER_PASSWORD=
OUTPUT_SESSION_FILE=
HOST_IP=

# parse any command line options to change default values
while getopts ":ht:i:u:p:o:" opt; do
case ${opt} in
    h) echo "${usage}"
       exit
       ;;
    t) NXS_TEMPLATE_FILE=${OPTARG}
       ;;
    i) HOST_IP=${OPTARG}
       ;;
    u) USER_NAME=${OPTARG}
       ;;
    p) USER_PASSWORD=${OPTARG}
       ;;
    o) OUTPUT_SESSION_FILE=${OPTARG}
       ;;
    ?) printf "Illegal option: '-%s'\n" "${OPTARG}" >&2
       echo "${usage}" >&2
       exit 1
       ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      echo "${usage}" >&2
      exit 1
      ;;
  esac
done

# Ensure we have all the required variables set 
if [[ -z ${NXS_TEMPLATE_FILE} ]] || [[ -z ${USER_NAME} ]] || [[ -z ${USER_PASSWORD} ]] || [[ -z ${OUTPUT_SESSION_FILE} ]] || [[ -z ${HOST_IP} ]]
then
  echo "${usage}" >&2
  exit 1
fi

NX_PASSWORD_SCRAMBLER_SCRIPT=`mktemp --tmpdir=/tmp`
cat > ${NX_PASSWORD_SCRAMBLER_SCRIPT} <<'__NX_PASSWORD_SCRAMBLER__'
#!/usr/bin/perl
# Obtained from: http://www.nomachine.com/ar/view.php?ar_id=AR01C00125
use strict;

use Time::localtime;

$::numValidCharList = 85;
$::dummyString = "{{{{";

#
#FOR TEST
#
my $password = $ARGV[0];
#print $password,"\n";
my $scrambled_string = scrambleString($password);
print $scrambled_string;

sub getvalidCharList {
  my $pos = shift;
  my @validCharList =
  (
    "!",  "#", "\$",  "%",  "&",  "(", ")",  "*",  "+",  "-",
    ".",  "0",   "1",  "2",   "3",  "4",  "5",  "6", "7", "8",
    "9", ":",  ";",  "<",  ">",  "?",  "@",  "A",  "B", "C",
    "D",  "E",  "F",  "G",  "H",  "I",  "J",  "K",  "L", "M",
    "N", "O",  "P",  "Q",  "R",  "S",  "T", "U", "V", "W",
    "X",  "Y",  "Z",  "[", "]",  "_",  "a",  "b",  "c",  "d",
    "e",  "f",  "g",  "h",  "i",  "j",  "k",  "l",  "m",  "n",
    "o",  "p",  "q",  "r",  "s",  "t",  "u",  "v",  "w",  "x",
    "y",  "z",  "{",  "|",  "}"
  );
  return $validCharList[$pos];
}

sub encodePassword {
  my $p = shift;
  my $sPass = ":";
  my $sTmp = "";


  if (!$p) {
    return "";
  }
  for (my $i = 0; $i < length($p); $i++) {
    my $c = substr($p,$i,1);
    my $a=ord($c);

    $sTmp=($a+$i+1).":";
    $sPass .=$sTmp;
    $sTmp = "";
  }

  return $sPass;
}

sub findCharInList {
  my $c = shift;
  my $i = -1;

  for (my $j = 0; $j < $::numValidCharList; $j++) {
    my $randchar = getvalidCharList($j);
    if ($randchar eq $c) {
      $i = $j;
      return $i;
    }
  }


  return $i;
}


sub getRandomValidCharFromList
{
  my $tm = localtime;
  my $k = ($tm->sec);

  return getvalidCharList($k);
}


sub scrambleString
{
  my $s = shift;
  my $sRet = "";

  if (!$s) {
    return $s;
  }
  my $str = encodePassword($s);
  if (length($str) < 32) {
    $sRet .= $::dummyString;
  }

  for ( my $iR = (length($str) - 1); $iR >= 0; $iR--) {
    #
    #Reverse string.
    #
    $sRet .= substr($str,$iR,1);
  }

  if (length($sRet) < 32) {
    $sRet .= $::dummyString;
  }

  my $app=getRandomValidCharFromList();
  my $k=ord($app);
  my $l=$k + length($sRet) -2;
  $sRet= $app.$sRet;

  for (my $i1 = 1; $i1 < length($sRet); $i1++) {

    my $app2=substr($sRet,$i1,1);
    my $j = findCharInList($app2);
    if ($j == -1) {
      return $sRet;
    }
    my $i = ($j + $l * ($i1 + 1)) % $::numValidCharList;
    my $car=getvalidCharList($i);

    $sRet=substr_replace($sRet,$car,$i1,1);

  }

  my $c = (ord(getRandomValidCharFromList())) + 2;
  my $c2=chr($c);

  $sRet=$sRet.$c2;

  return URLEncode($sRet);
}

sub URLEncode {
  my $theURL = $_[0];
  $theURL =~ s/&/&amp;/g;
  $theURL =~ s/\"\"/&quot;/g;
  $theURL =~ s/\'/&#039;/g;
  $theURL =~ s/</&lt;/g;
  $theURL =~ s/>/&gt;/g;
  return $theURL;
}

sub substr_replace {
  my $str = shift;
  my $ch = shift;
  my $pos = shift;
  my $qt = shift;

  my @list = split (//,$str);
  my $count = 0;
  my $tmp_str = '';
  foreach my $key(@list) {
    if ($count != $pos) {
      $tmp_str .= $key;
    } else {
      $tmp_str .= $ch;
    }
    $count++;
  }
  return $tmp_str;
}
__NX_PASSWORD_SCRAMBLER__
USER_PASSWORD=$(perl ${NX_PASSWORD_SCRAMBLER_SCRIPT} ${USER_PASSWORD} | sed -e "s/[\@&]/\\&/g" && rm ${NX_PASSWORD_SCRAMBLER_SCRIPT})

sed -e "s@<option key=\"Server host\" value=\"\" />@<option key=\"Server host\" value=\"${HOST_IP}\" />@; s@<option key=\"User\" value=\"\"@<option key=\"User\" value=\"${USER_NAME}\"@; s@<option key=\"Auth\" value=\"EMPTY_PASSWORD\"@<option key=\"Auth\" value=\""${USER_PASSWORD}"\"@" < ${NXS_TEMPLATE_FILE} > ${OUTPUT_SESSION_FILE}

