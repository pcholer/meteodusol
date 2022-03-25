# 
#           script meteodusol_EM50.r
#           version 20220323
#           Philippe Choler
#


# Ce script gÃ©nÃ¨re deux fichiers csv contenant (1) les mÃ©tadonnÃ©es et (2) les donnÃ©es de teneur en eau du sol pour leur bancarisation dans OSUG-DC dans le cadre du projet climaplant.

# Les mesures sont rÃ©alisÃ©es avec les enresgistreurs EM50

# PrÃ©-requis
# 1. un fichier contenant les attributs des sites (mysite_EM50.csv)
#  SourceID = nom du site attribuÃ© par le fournisseur de donnÃ©es
#  X_WGS84  = longitude en degrÃ©s dÃ©cimaux
#  Y_WGS84  = latitude en degrÃ©s dÃ©cimaux
#  loggerID   = numÃ©ro de sÃ©rie de l'enregistreur


# 2. un rÃ©pertoire (DIR.CSV) contenant les fichiers export des enregistreurs TOMST-TMS 
# le nom des fichiers est du type "loggerID_xxxxx.csv", le loggerID ne doit pas contenir le caractÃ¨re "_"
# colonne 1 : numÃ©ro de ligne
# colonne 2 : DATA HEURE GMT+00:00" (par exemple 2017-05-18 11:00:00)
# colonne 4 Ã  6 : tempÃ©rature en Â°C. (par exemple 10,2 et non pas 10.2)
# colonne 7 : valeurs brutes (raw values) de teneur en eau
# ...
# le sÃ©parateur de colonnes est ;

# IMPORTANT : ParamÃ¨tres Ã  ajuster par chaque utilisateur

# You need first to set working directory (WD) to source file location
setwd("WD")

# a. DIR.CSV le chemin du rÃ©pertoire contenant les fichiers csv des enregistreurs Hobo
DIR.CSV    <- "./CSV_EM50/"
# b. mysite = le chemin d'accÃ¨s au fichier mysite
mysite     <- "./mysite_EM50.csv"

# c. dataset  = le nom du lot de donnÃ©es
dataset    <- "pne"   

# d. DIR.OUT = le chemin du rÃ©pertoire contenant les fichiers de sortie
DIR.EXPORT  <- "./EXPORT_EM50/"

# e. initialisation du lot pour incrÃ©mentation
INIT <- 1

# vÃ©rification des fichiers d'entrÃ©e
FILES.CSV  <- list.files(DIR.CSV,pattern=".csv",full=T)
FILES.CSVs <- list.files(DIR.CSV,pattern=".csv",full=F)
NAMES      <- unlist(lapply(strsplit(FILES.CSVs,"_"),function(x) x[1]))

(SITE           <- read.table(mysite,sep=";",stringsAsFactors = F,header=T))
colnames(SITE) <- c("SourceID","X_WGS84","Y_WGS84") # renomme les colonnes

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
  SourceID  <- NAMES[i]
  META      <- SITE[match(SourceID,SITE$SourceID),]
  NL        <- nrow(TS)
  ID        <- round(runif(1,10^9,10^10)) 
  
  # metadata
  TMPmd <- data.frame(
    INCREMENT     = paste0(dataset,INIT+i-1),
    ID            = ID,
    X             = round(META$"X_WGS84",5),
    Y             = round(META$"Y_WGS84",5),
    sensor_type   = "DECAGON",
    date_start    = DAY[1],
    date_end      = DAY[NL],
    subdataset    = dataset,
    sourceID      = META$SourceID
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
  
  nam  <- expand.grid(c("VWC","TEMP"),1:4)
  colnames(TMPdata)[-(1:3)] <- paste0(nam[,1],nam[,2])
  data  <- rbind(data,TMPdata)

} # end of CSV files


# sauvegarde des fichiers
write.csv(md,paste0(DIR.EXPORT,DOY,"-",dataset,"-metadata-eau-soil.csv"),row.names=F,quote=F)
write.csv(data,paste0(DIR.EXPORT,DOY,"-",dataset,"-data-eau-soil.csv"),row.names=F,quote=F)
