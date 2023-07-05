# mise à jour incluant les profondeurs et les métadonnées sol - souvenirs de mon passage à Charance le 5 juillet 2023

# 
#           script meteodusol_EM50.r
#           version 20230705
#           Philippe Choler
#


# Ce script génère deux fichiers csv contenant (1) les métadonnées et (2) les données de teneur en eau du sol pour leur bancarisation dans OSUG-DC dans le cadre du projet climaplant.

# Les mesures sont réalisées avec les enresgistreurs EM50

# Pré-requis
# 1. un fichier contenant les attributs des sites (mysite_EM50.csv)
#  SourceID = nom du site attribué par le fournisseur de données
#  X_WGS84  = longitude en degrés décimaux
#  Y_WGS84  = latitude en degrés décimaux
#  loggerID   = numéro de série de l'enregistreur

# 2. un répertoire (DIR.CSV) contenant les fichiers export des enregistreurs TOMST-TMS 
# le nom des fichiers est du type "loggerID_xxxxx.csv", le loggerID ne doit pas contenir le caractère "_"
# colonne 1 : numéro de ligne
# colonne 2 : DATA HEURE GMT+00:00" (par exemple 2017-05-18 11:00:00)
# colonne 4 à 6 : température en °C. (par exemple 10,2 et non pas 10.2)
# colonne 7 : valeurs brutes (raw values) de teneur en eau
# ...
# le séparateur de colonnes est ;

# IMPORTANT : Paramètres à ajuster par chaque utilisateur

# You need first to set working directory (WD) to source file location
# setwd("~/CLIMATO/DATA/DATA_ECH2O/METEODUSOL")
setwd("WD")

# a. DIR.CSV le chemin du répertoire contenant les fichiers csv des enregistreurs Hobo
DIR.CSV    <- "./CSV_EM50/"
# b. mysite = le chemin d'accès au fichier mysite
mysite     <- "./mysite_EM50_full.csv"

# c. dataset  = le nom du lot de données
dataset    <- "pne"   

# d. DIR.OUT = le chemin du répertoire contenant les fichiers de sortie
DIR.EXPORT  <- "./EXPORT_EM50/"

# e. initialisation du lot pour incrémentation
INIT <- 1

# vérification des fichiers d'entrée
FILES.CSV      <- list.files(DIR.CSV,pattern=".csv",full=T)
FILES.CSVs     <- list.files(DIR.CSV,pattern=".csv",full=F)
NAMES          <- unlist(lapply(strsplit(FILES.CSVs,"_"),function(x) x[1]))
SERIESstart     <-unlist(lapply(strsplit(FILES.CSVs,"_"),function(x) x[6]))

(SITE          <- read.table(mysite,sep=";",stringsAsFactors = F,header=T))
colnames(SITE) <- c("SourceID","X_WGS84","Y_WGS84") # renomme les colonnes
START          <- gsub("-","",as.Date(SITE$Start_date,format="%d/%m/%Y"))

# prepare data and metadata
md         <- NULL
data       <- NULL
DOY        <- gsub("-","",Sys.Date())   # date

set.seed(2067)

# import files and produce data and metadata
for (i in 1:length(FILES.CSV)){
  print(i)
  TS        <- read.csv(FILES.CSV[i],skip=2,sep=",",header=T)
  TIME      <- as.POSIXct(TS[,1],format = '%d/%m/%Y %H:%M:%S',tz="UTC")
  DAY       <- as.Date(TIME)
  myID      <- NAMES[i]
  mystart   <- START[i]
  
  METAport    <- which(START==mystart & SITE$SRC_ID==myID) 
  
  META    <- SITE[METAport[1],]

  
  NL        <- nrow(TS)
  ID        <- round(runif(1,10^9,10^10))

  # metadata
  TMPmd <- data.frame(
    INCREMENT     = paste0(dataset,INIT+i-1),
    ID            = ID,
    X             = round(META$"X",5),
    Y             = round(META$"Y",5),
    sensor_type   = "DECAGON",
    date_start    = DAY[1],
    date_end      = DAY[NL],
    subdataset    = dataset,
    sourceID      = META$SRC_ID
  )
  
  TMPmd <- cbind.data.frame(TMPmd,META[c("sand","silt","clay","MO","Bulk_density","Textural_class","Coarse","Cal_type","a","b","c")]
  )
  md <- rbind(md,TMPmd)
  
  # data
  for (j in 2:ncol(TS)) TS[,j] <- as.numeric(gsub(",",".",TS[,j]))
  TMPdata <- data.frame(
    INCREMENT     = paste0(dataset,INIT+i-1),
    ID            = ID,
    date_time     = format(TIME,"%Y-%m-%d %H:%M"),
    eau           = round(TS[,-1],2)
  )

  mydepth <- SITE[METAport,"Depth"]
  for (k in 1:length(METAport)) TMPdata   <- cbind.data.frame(TMPdata,mydepth[k])
  
  nam  <- expand.grid(c("VWC-port","TEMP-port"),1:4)
  nam  <- rbind(nam,expand.grid("Depth-port",1:4))
  
  colnames(TMPdata)[-(1:3)] <- paste0(nam[,1],nam[,2])
  data  <- rbind(data,TMPdata)

} # end of CSV files


# sauvegarde des fichiers
write.csv(md,paste0(DIR.EXPORT,DOY,"-",dataset,"-metadata-soil-vwc.csv"),row.names=F,quote=F)
write.csv(data,paste0(DIR.EXPORT,DOY,"-",dataset,"-data-soil-vwc.csv"),row.names=F,quote=F)
