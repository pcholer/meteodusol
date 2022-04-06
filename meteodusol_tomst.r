# 
#           script meteodusol_tomst.r
#           version 20220323
#           Philippe Choler
#


# Ce script génère deux fichiers csv contenant (1) les métadonnées et (2) les données de teneur en eau du sol pour leur bancarisation dans OSUG-DC dans le cadre du projet climaplant.

# Les mesures sont réalisées avec les TOMST TMS

# Pré-requis
# 1. un fichier contenant les attributs des sites (mysite_tomst.csv)
#  SourceID = nom du site attribué par le fournisseur de données
#  X_WGS84  = longitude en degrés décimaux
#  Y_WGS84  = latitude en degrés décimaux
#  loggerID   = numéro de série de l'enregistreur


# 2. un répertoire (DIR.CSV) contenant les fichiers export des enregistreurs TOMST-TMS 
# le nom des fichiers est du type "data_loggerID_xxxxx.csv"
# colonne 1 : numéro de ligne
# colonne 2 : DATA HEURE GMT+00:00" (par exemple 2017-05-18 11:00:00)
# colonne 4 à 6 : température en °C. (par exemple 10.2 et non pas 10,2)
# colonne 7 : valeurs brutes (raw values) de teneur en eau
#...
# le séparateur de colonnes est ;


# IMPORTANT : Paramètres à ajuster par chaque utilisateur

# You need first to set working directory (WD) to source file location
setwd("WD")

# a. DIR.CSV le chemin du répertoire contenant les fichiers csv des enregistreurs Hobo
DIR.CSV    <- "./CSV_TOMST/"
# b. mysite = le chemin d'accès au fichier mysite
mysite     <- "./mysite_tomst.csv"

# c. dataset  = le nom du jeu de données
dataset    <- "bioclim"   

# d. DIR.OUT = le chemin du répertoire contenant les fichiers de sortie
DIR.EXPORT  <- "./EXPORT_TOMST/"

# e. initialisation du lot pour incrÃ©mentation
INIT <- 1

# vérification des fichiers d'entrée
FILES.CSV  <- list.files(DIR.CSV,pattern=".csv",full=T)
FILES.CSVs <- list.files(DIR.CSV,pattern=".csv",full=F)
NAMES      <- unlist(lapply(strsplit(FILES.CSVs,"_"),function(x) x[2]))

SITE           <- read.csv(mysite,sep=";",stringsAsFactors = F)
colnames(SITE) <- c("SourceID","X_WGS84","Y_WGS84","loggerID") # renomme les colonnes

# prepare data and metadata
md         <- NULL
data       <- NULL
DOY        <- gsub("-","",Sys.Date())   # date
set.seed(1967)

# import files and produce data and metadata
for (i in 1:length(FILES.CSV)){
  print(i)
  TS        <- read.csv(FILES.CSV[i],sep=";")[,c(2,7)]
  TS        <- TS[complete.cases(TS),]
  TIME      <- as.POSIXct(TS[,1],format = '%Y.%m.%d %H:%M',tz="UTC")
  DAY       <- as.Date(TIME)
  loggerID  <- NAMES[i]
  META      <- SITE[match(loggerID,SITE$loggerID),]
  NL        <- nrow(TS)
  ID        <- round(runif(1,10^9,10^10)) 
  
  # metadata
  TMPmd <- data.frame(
    INCREMENT     = paste0(dataset,INIT+i-1),
    ID            = ID,
    X             = round(META$"X_WGS84",5),
    Y             = round(META$"Y_WGS84",5),
    sensor_type   = "TMS",
    date_start    = DAY[1],
    date_end      = DAY[NL],
    subdataset    = dataset,
    sourceID      = META$SourceID
  )
  md <- rbind(md,TMPmd)
  
  # data
  TMPdata <- data.frame(
    INCREMENT     = paste0(dataset,INIT+i-1),
    ID            = ID,
    date_time     = format(TIME,"%Y-%m-%d %H:%M"),
    eau          = round(TS[,2],1)
  )
  data <- rbind(data,TMPdata)

} # end of CSV files

# sauvegarde des fichiers
write.csv(md,paste0(DIR.EXPORT,DOY,"-",dataset,"-metadata-eau-soil.csv"),row.names=F,quote=F)
write.csv(data,paste0(DIR.EXPORT,DOY,"-",dataset,"-data-eau-soil.csv"),row.names=F,quote=F)
