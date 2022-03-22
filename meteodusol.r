# 
#           script meteodusol.r
#           version 20220322
#           Philippe Choler
#


# Ce script génère deux fichiers csv contenant (1) les métadonnées et (2) les données de température du sol pour leur bancarisation dans OSUG-DC dans le cadre du projet climaplant.

# Pré-requis
# 1. un répertoire (DIR.RAW) contenant les fichiers export des enregistreurs Hobo selon un format défini (nom du fichier et structure -> voir example)

# 2. un fichier csv (mysite) contenant les attributs des sites 
#  SourceID = nom du site attribué par le fournisseur de données
#  X_WGS84  = longitude en degrés décimaux
#  Y_WGS84  = latitude en degrés décimaux


# IMPORTANT : Paramètres à ajuster par chaque utilisateur

# a. DIR.RAW le chemin du répertoire contenant les fichiers export
# DIR.RAW    <- "~/CLIMATO/DATA/PNE/CLOTILDE/"

# b. mysite = le chemin d'accès au fichier mysite
# mysite     <- "~/CLIMATO/DATA/PNE/SoilTemp_data submission_FR_CS_2020-10-26.csv"

# c. dataset  = le nom du jeu de données
# dataset  <- "pne"   

# d. DIR.OUT = le chemin du répertoire contenant les fichiers de sortie
# DIR.OUT  <- "~/CLIMATO/DATA/OSUG_DC/FILES/"


# vérification des fichiers d'entrée
FILES.RAW  <- list.files(DIR.RAW,pattern=".csv",full=T)
FILES.RAWs <- list.files(DIR.RAW,pattern=".csv",full=F)
NAMES      <- unlist(lapply(strsplit(FILES.RAWs,"_"),function(x) x[1]))

SITE       <- read.csv(mysite,sep=";",stringsAsFactors = F,skip=1)[,1:3]
colnames(SITE) <- c("SourceID","X_WGS84","Y_WGS84")
SITE$SourceID  <- gsub("FR_CS_","FR-",SITE$SourceID)

# prepare data and metadata
md         <- NULL
data       <- NULL
DOY        <- gsub("-","",Sys.Date())   # date
set.seed(1967)

# import files and produce data and metadata
for (i in 1:length(FILES.RAW)){
  print(i)
  TS        <- read.csv(FILES.RAW[i])[,1:2]
  TS        <- TS[complete.cases(TS),]
  TIME      <- as.POSIXct(TS[,1],format="%Y-%m-%d %H:%M:%S",tz="GMT")
  DAY       <- as.Date(TIME)
  sourceID  <- NAMES[i]
  META      <- SITE[match(sourceID,SITE$SourceID),]
  NL        <- nrow(TS)
  ID        <- round(runif(1,10^9,10^10)) 
  
  # metadata
  TMPmd <- data.frame(
    ID            = ID,
    X             = round(META$"X_WGS84",5),
    Y             = round(META$"Y_WGS84",5),
    sensor_type   = "hobo",
    date_start    = DAY[1],
    date_end      = DAY[NL],
    subdataset    = "PNE",
    sourceID      = sourceID
  )
  md <- rbind(md,TMPmd)
  
  # data
  TMPdata <- data.frame(
    ID            = ID,
    date_time     = format(TIME,"%Y-%m-%d %H:%M"),
    temperature   = round(TS[,2],1)
  )
  data <- rbind(data,TMPdata)
  
}

# sauvegarde des fichiers
setwd(DIR.OUT)
write.csv(md,paste(DOY,dataset,"metadata-temp-soil.csv",sep="-"),row.names=F,quote=F)
write.csv(data,paste(DOY,dataset,"data-temp-soil.csv",sep="-"),row.names=F,quote=F)
