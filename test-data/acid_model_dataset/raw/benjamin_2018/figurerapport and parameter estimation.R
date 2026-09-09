####### SCRIPT DONNANT LES FIGURES DU RAPPORT DE STAGE M2
#
#
#
#
#
#
# chargement des packages necessaires aux fonctions utilisés
library(Metrics) #for function RMSE
library(deSolve)
library(ggplot2)
library(nleqslv)
library(optimx)
library(cowplot)  #to merge figrues of ggplots
library(dplyr)
#
###Liste des figures (les scripts ne sont pas dans l'ordre ):
#####figure 3 80; figure 4 21; figure 5 370; figure 6 2068; figure 7 530; figure 8 973; figure 9 2580 
###############Chargement des jeux de données#########################
wd="D:/EGFV/Experiment/2018/2018_1_acid model/resum_02July2018/data"
setwd(wd)
Kliewer.29.01_Dai <- read.csv("Kliewer 29-01_Dai.csv",sep=",",dec=".",skip=1)
Grenache.2007 <- read.csv("Grenache 2007.csv", dec=".",skip=1)
Grenache7.2 <- read.csv("Grenache7.2.csv",dec=".",skip=1)# cleaned data after remvoing lines with NA for K+ and for treatments not used in the current work.
Sangiovese12 <- read.csv("Sangiovese.csv",dec=".",skip=1)
Soyer.23.01...copie <- read.csv("Soyer.csv",skip=1)

##### figure 4 : DGATP IM, evolution de DGATP en fonction de T et time 


# Fonction qui calcul DGATP 

GATP<-function(PH=PH, Temp=Temp, a=0.47, K2=10^(-5.11), K1=10^(-3.4), R=8.314, FF=96500, Malvac=Malvac, pHcyt=7.5,Malcyt=0.001,A=0.3,B=-0.12,no=4){
  n=no+A*(PH-7)+B*10^(pHcyt-7)
  h=10^(-PH)
  K=(K1*K2+h*K1+h^2)/(K1*K2)
  DGATP= n*R*Temp*2.3*(PH-pHcyt)-(n*R*Temp/2)*log(((a*Malvac/K)/Malcyt),exp(1))
  DGATP}

# inputs : Mal, pH, T
DS<-Soyer.23.01...copie
DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
#DS1=DS1[DS1$Localisation=='LAB']
# T doit être en Kalvin, le malate en mol.L-1
pH=DS1$pH
Tem=(DS1$T)+273.35
Malvac1=DS1$Malate/134 

#Lance la fonction 
DGATP.pre=GATP(PH=pH,Temp=Tem,Malvac=Malvac1)
## plot pour vizualiser 
plot(DS1$pH,DGATP.pre,col=2,xlab="pH", ylab="DGATP",main="Cabernet Sauvignon")
plot(DS1$T,DGATP.pre,col=2,xlab="Temperature", ylab="DGATP",main="Cabernet Sauvignon")
plot(DS1$Jour,DGATP.pre,col=2,xlab="Jour", ylab="DGATP",main="Cabernet Sauvignon")
### permet d'extraire la regression linéaire
model<-lm(DGATP.pre~ Tem)
summary(model)

## encore des plots pour visualiser mais en ggplot 
Jour<-DS1$Jour
Temperature<-DS1$T
don = data.frame (DGATP.pre,Jour,Temperature)
ggplot(data=don, aes(Temperature, DGATP.pre))+geom_point()+theme_minimal()
ggplot(data=don, aes(Temperature, DGATP.pre))+geom_point()+theme_classic()+ theme_light()



## Trop de points, on utilise dplyr pour avoir un meileur visuel : moyenne ± sd
new =  don %>% group_by(Temperature,Jour) %>% summarise_at(vars(DGATP.pre),funs(mean,sd),na.rm=TRUE)
new

f1a<-ggplot(data=new, aes(x=Temperature,y=mean))+ ylab("ΔGATP j/mol")+xlab("T °C")+
  geom_pointrange(aes(x=Temperature,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+theme_minimal()+ theme_light()

f1b<- ggplot(data=new, aes(x=Jour,y=mean))+ ylab("ΔGATP j/mol")+xlab("Day")+
  geom_pointrange(aes(x=Jour,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+theme_minimal()+ theme_light()
plot_grid(f1a, f1b, labels=c("A", "B"), ncol = 2, nrow = 1)#### figure 4 sans légende 








# figure 3 Malate model + effet calibration sur CS K60
#### Sur tout les autres data set 

###Choix du jeu de données

DS<-Soyer.23.01...copie
DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
don=DS1[DS1$traitement=="K60",]






 #### Correction K1 <-> K2 : version qui aurait du être présente dans le rapport final 
MAL<-function(PH,Tem,K2=10^(-5.11),K1=10^(-3.4),R=8.314,FF=96500, a,b, pHcyt=7.5,M1,M2,A=0.3,B=-0.12,no=4){
  
  Malcyt=M1*PH+M2
  Te=Tem+273.5
  n=no+A*(PH-7)+B*10^(pHcyt-7)
  DGATP = a*Te+b
  DY=((-DGATP/(n*FF))+((R*Te*2.3)/FF)*(PH-pHcyt))
  h=10^(-PH)
  K=(K1*K2+h*K1+h^2)/(K1*K2) #### le K1 au nominateur multiplié par h devrait être 10^(-3.4)
  Mal.mol1=K*exp((2*FF*DY)/(R*Te))*Malcyt # in mol/L
  Mal=Mal.mol1*134 #g/L mg/g FW 
  res=Mal
}

mal.fruita <- don$Malate
runpH <- don$pH



#### Estimation des paramètres 

### Estimation de [Mal]cyt cte (M2, M1=0) à DGATP constant à -56 kJ/mol
fitdots<-nls(mal.fruita~MAL(PH=runpH,Tem=don$T, a=0, b= -56000,M1=0,M2=M2),start=list(M2=0),algorithm="port")
summary(fitdots)
#M2 9.849e-04  6.108e-05   16.12   <2e-16 ***

### Estimation de [Mal]cyt cte (M2, M1=0) à DGATP linéaire, a et b sont fixés (a=-298, b= 29815)
fitdots<-nls(mal.fruita~MAL(PH=runpH,Tem=don$T, a=-298, b= 29815,M1=0,M2=M2 ),start=list( M2= 0.0002),algorithm="port")
summary(fitdots)
#M2 5.359e-04  1.635e-05   32.78   <2e-16 ***


### Estimation de [Mal]cyt linéaire (M2, M1) à DGATP linéaire, a et b sont fixés (a=-298, b= 29815)

fitdots<-nls(mal.fruita~MAL(PH=runpH,Tem=don$T, a=-298, b= 29815,M1=M1,M2=M2 ),start=list( M1=0,M2= 0.0002),algorithm="port")
summary(fitdots)
#M1 -0.0003151  0.0000479  -6.577 1.04e-07 ***
#M2  0.0013920  0.0001306  10.655 7.92e-13 ***



### Calcul des valeurs de malate avec la fonction MAL, DGATP&[Mal]cyt sont constant 
predMal<-MAL(PH=don$pH,Tem=don$T, a=0, b= -56000,M1=0,M2=9.849e-04)

#### verification des tailles des vecteurs obtenus
length(predMal) #39
length(don$pH) #39

#### Calcul du RRMSE
mal.fruita <- don$Malate
rmse<-rmse(mal.fruita, predMal)
m <- mean(mal.fruita)
rrmse <- rmse/m
rrmse # 0.478

#### on prépare le data frame (don1) utilisé par dplyr puis par ggplot
pH <- c(don$pH, don$pH)
Mal <- c(mal.fruita, predMal)
sfac <- c(rep("obs", length(mal.fruita)),rep("pred", length(mal.fruita)))
Jour <- c(don$Jour,don$Jour)
don1 <- data.frame(Mal,pH,sfac,Jour)

# Evolution du malate en fonction du pH, on stock le graph sous f2a1
f2a1<- ggplot(data=don1, aes(pH,Mal , colour=sfac))+geom_point()+ylab("Malate mg/g")+ theme(legend.position='none')

new =  don1 %>% group_by(Jour,sfac) %>% summarise_at(vars(Mal),funs(mean,sd),na.rm=TRUE)
n = (length(mal.fruita))
n
new

#Evolution du malate en fonction des jours, on stock le graph sous f2a2
f2a2 <- ggplot(data=new, aes(x=Jour,y=mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=Jour,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ theme(legend.position='none')




### Calcul des valeurs de malate avec la fonction MAL, DGATP est linéaire, [Mal]cyt est constant 
predMal22<-MAL(PH=don$pH,Tem=don$T, a=-298, b= 29815,M1=0,M2=5.359e-04)


## calcul du RRMSE 
rmse<-rmse(mal.fruita, predMal22)
m <- mean(mal.fruita)
rrmse <- rmse/m
rrmse # 0.247

### Création du data frame (encore don1)
pH <- c(don$pH, don$pH)
Mal <- c(mal.fruita, predMal22)
sfac <- c(rep("observed", length(mal.fruita)),rep("predicted", length(mal.fruita)))
Jour <- c(don$Jour,don$Jour)
don1 <- data.frame(Mal,pH,sfac,Jour)
### Utilisation du data frame 
new =  don1 %>% group_by(Jour,sfac) %>% summarise_at(vars(Mal),funs(mean,sd),na.rm=TRUE)
n = (length(mal.fruita))
n
new

f2b1<-ggplot(data=don1, aes(pH,Mal , colour=sfac))+geom_point()+ylab("Malate mg/g")+ theme(legend.title = element_blank()) + theme(legend.position = c(0.6, 0.5))



f2b2 <- ggplot(data=new, aes(x=Jour,y=mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=Jour,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ theme(legend.position='none')





### Final plot : on combine les précedents graph stockés
plot_grid(f2a1,f2a2,f2b1,f2b2, labels=c("A", "B","C","D"), ncol = 2, nrow = 2)#### figure 2 sans légende 
#### Les valeurs des RRMSE sont rajoutés sur le ppt






#### Supp : faible évolution de la précision du fit si ajout du malate linéaire 
predMal2<-MAL(PH=don$pH,Tem=don$T, a=-298, b= 29815,M1=-0.0003151,M2=0.0013920)
plot(don$pH,predMal2)
points(don$pH,don$Malate, col= 2)

rmse<-rmse(mal.fruita, predMal2)
m <- mean(mal.fruita)
rrmse <- rmse/m
rrmse # 0.168
# les calibrations successives sont bien necessaires pour atteindre un rrmse < 0.20









#### figure 5 tartrate model 



##### Fonction ctar qui calcul la concentration en tartrate à partir du pH et de la tempèrature mesurés
ctar <- function(a,b,n0, alpha, bbeta, pHcyt, T1,T2,pHvac, K1,K2,Te)
{
  R<- 8.314; FF <- 96500 ; Te <- Te + 273.15
  DGATP = a*Te+b
  a2Tarcyt <- T1*pHvac + T2
  coeffa2vac<-1
  DY<-(-DGATP)/(FF*(n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)))+((R*Te)/FF)*log(10)*(pHvac-pHcyt)
  cTarvac<-(1/coeffa2vac)*a2Tarcyt *  exp((2*FF*DY)/(R*Te)) *  (K1*K2+K1*10^(-pHvac)+10^(-2*pHvac))/(K1*K2)
  cTarvac<-cTarvac*150
  c(cTarvac)  # sortie de la fonction
}


# Data set utilisé
DS<-Soyer.23.01...copie
DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
don=DS1[DS1$traitement=="K60",]

tar.fruita = don$Tartrate
runpH <- don$pH



#Estimation des paramètres 

## On commence par estimer le [Tar]cyt avec les valeurs genetic dependant a&b propre à CS
fitdots<-nls(tar.fruita ~ctar( T1 = 0, T2 = T2 ,pHvac=runpH,Te=don$T, K1= 10^(-2.98),K2=10^(-4.34), a=-298, b= 29815, n0=4, alpha=0.3, bbeta = -0.12,pHcyt=7.5),start=list(T2=0.001),algorithm="port")
summary(fitdots)
#T2 0.0036445  0.0001648   22.12   <2e-16 ***

### La valeur de DGATP constante qui correspond à cette valeur de [tar]cyt constant
fitdots<-nls(tar.fruita ~ctar( T1 = 0, T2 = 0.0036  ,pHvac=runpH,Te=don$T, K1= 10^(-2.98),K2=10^(-4.34), a=0, b= b, n0=4, alpha=0.3, bbeta = -0.12,pHcyt=7.5),start=list(b=-60000),algorithm="port")
summary(fitdots)
#b   -57662        155    -372   <2e-16 ***


fitdots<-nls(tar.fruita ~ctar( T1 = T1, T2 = T2 ,pHvac=runpH,Te=don$T, K1= 10^(-2.98),K2=10^(-4.34), a=-298, b= 29815, n0=4, alpha=0.3, bbeta = -0.12,pHcyt=7.5),start=list(T1=0,T2=0.001),algorithm="port")
summary(fitdots)

  #T1  0.0032134  0.0002226   14.44  < 2e-16 ***
  #T2 -0.0053346  0.0006254   -8.53 2.89e-10 ***




## prédiction du tartrate avec [Ta]cyt et DGATP constant 
pretar1 <- ctar ( T1 = 0, T2 = 0.0036 ,pHvac=runpH,Te=don$T, K1= 10^(-2.98),K2=10^(-4.34), a=0, b=-57662  , n0=4, alpha=0.3, bbeta = -0.12,pHcyt=7.5)


fac <- rep("observed" , length(pretar1))
fac2 <- rep("predicted" ,length(pretar1))

type<-c(fac,fac2)
ta <- c(don$Tartrate,pretar1)
pH <- c(don$pH,don$pH)
time <- c(don$Jour,don$Jour)
tot <- data.frame(pH,ta,type,time)

f3a1 <-ggplot(data=tot, aes(pH,ta, colour = type))+geom_point() +theme(legend.position='none')+ylab("Tartrate mg/g")#+scale_color_manual(values=c("red", "Blue"))
 
# 

f3a1

ggplot(data=tot, aes(time,ta, colour = type))+geom_point()



new =  tot %>% group_by(time,type) %>% summarise_at(vars(ta),funs(mean,sd),na.rm=TRUE)
n = 3
n
new
f3a2<- ggplot(data=new, aes(x=time,y=mean, colour= type))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=time,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ theme(legend.position='none')

f3a2


rmse <- rmse(tar.fruita, pretar1)
m<- mean(tar.fruita)
rrmse <- rmse / m 
rrmse #0.318


## prédiction du tartrate avec [Ta]cyt constant et DGATP linéaire

pretar2 <- ctar ( T1 = 0, T2 = 0.0036 ,pHvac=don$pH,Te=don$T, K1= 10^(-2.98),K2=10^(-4.34), a=-298, b= 29815, n0=4, alpha=0.3, bbeta = -0.12,pHcyt=7.5)

fac <- rep("observed" , length(pretar2))
fac2 <- rep("predicted" ,length(pretar2))

type<-c(fac,fac2)
ta <- c(don$Tartrate,pretar2)
pH <- c(don$pH,don$pH)
time <- c(don$Jour,don$Jour)
tot <- data.frame(pH,ta,type,time)
f3b1 <- ggplot(data=tot, aes(pH,ta, colour = type))+geom_point()+ theme(legend.position='none')+ylab("Tartrate mg/g")

f3b1

rmse <- rmse(tar.fruita, pretar2)
m<- mean(tar.fruita)
rrmse <- rmse / m 
rrmse #0.27

new =  tot %>% group_by(time,type) %>% summarise_at(vars(ta),funs(mean,sd),na.rm=TRUE)
n = 3
n
new
f3b2<- ggplot(data=new, aes(x=time,y=mean, colour= type))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=time,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ theme(legend.position='none')
f3b2

## prédiction du tartrate avec [Ta]cyt et DGATP linéaires

pretar3 <- ctar ( T1 = 0.0032, T2 = -0.0053 ,pHvac=don$pH,Te=don$T, K1= 10^(-2.98),K2=10^(-4.34), a=-298, b= 29815, n0=4, alpha=0.3, bbeta = -0.12,pHcyt=7.5)

fac <- rep("observed" , length(pretar3))
fac2 <- rep("predicted" ,length(pretar3))

type<-c(fac,fac2)
ta <- c(don$Tartrate,pretar3)
pH <- c(don$pH,don$pH)
time <- c(don$Jour,don$Jour)
tot <- data.frame(pH,ta,type,time)

f3c1<-ggplot(data=tot, aes(pH,ta, colour = type))+geom_point()+ theme(legend.title = element_blank()) + theme(legend.position = c(0.6, 0.5))+ylab("Tartrate mg/g")
f3c1

new =  tot %>% group_by(time,type) %>% summarise_at(vars(ta),funs(mean,sd),na.rm=TRUE)
n = 3
n
new
f3c2<- ggplot(data=new, aes(x=time,y=mean, colour= type))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=time,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ theme(legend.position='none')

f3c2

ggplot(data=tot, aes(Jour,ta, colour = type))+geom_point()


rmse <- rmse(tar.fruita, pretar3)
m<- mean(tar.fruita)
rrmse <- rmse / m 
rrmse #0.1


plot_grid(f3a1,f3b1,f3c1,f3a2,f3b2,f3c2, labels=c("A", "B","C","D","E","F"), ncol = 3, nrow = 2)#### figure 3 sans légende 






###### prediction du pH figure 7; certain plot sont en bonus 




#### Fonctions utilisés ; 
cmal<-function(a, b , n0, alpha , bbeta , pHcyt , a2Malcyt , i , pHvac , KK1, KK2 , Te)
{
  
  R<-8.314 ; FF<-96500; Te <- Te+273.15
  DGATP=a*Te+b
  coeffa2vac<- 10^(-0.509*4*((i^0.5/(1+i^0.5)-0.3*i)))
  DY<-(-DGATP)/(FF*(n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)))+((R*Te)/FF)*log(10)*(pHvac-pHcyt)
  cMalvac<-(1/coeffa2vac)* a2Malcyt *  exp((2*FF*DY)/(R*Te)) *  (KK1*KK2+KK1*10^(-pHvac)+10^(-2*pHvac))/(KK1*KK2)
  c(DY,cMalvac)  # sortie de la fonction
}

acid <- function(Mal , Ta, K, Te , param_model = NULL,a,b,a2Malcyt,A1, A2) 
{
  Mal.glob <<- NA
  DPsi.glob <<- NA
  
  Km1 <- 10^(-3.40) ; Km2 <- 10^(-5.11)                     # malic(-4.34),K2=10^(-2.98)
  Kt1 <- 10^(-2.98) ; Kt2 <- 10^(-4.34)
  dslnex <- function (x)
  {
    
    pMal2 <- function(x, Km1, Km2) { # tMal2 is the malate 2- proportion: [Mal2-]/[Maltotal] so no unity
      h <- 10^(-x[2]) ; tMal2 <- Km1*Km2/(h^2*(1+Km1/h+Km1*Km2/h^2))
      tMal2}
    pMal1 <-  function(x, Km1, Km2) {
      h  <- 10^(-x[2]) ; tMal1 <- Km1/(h*(1+Km1/h+Km1*Km2/h^2))
      tMal1}
    pMal0 <- function(x, Km1, Km2) {
      h <- 10^(-x[2]) ; tMal0 <- 1/(1*(1+Km1/h+Km1*Km2/h^2))
      tMal0}
    #Tartaric acid 
    pTa2 <- function(x, Kt1, Kt2) { # tTa2 is the tartrate 2- proportion: [Ta2-]/[Tatotal] so no unity
      h <- 10^(-x[2]) ; tTa2 <- Kt1*Kt2/(h^2*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa2}
    pTa1 <-  function(x, Kt1, Kt2) {
      h  <- 10^(-x[2]) ; tTa1 <- Kt1/(h*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa1}
    pTa0 <- function(x, Kt1, Kt2) {
      h <- 10^(-x[2]) ; tTa0 <- 1/(1*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa0}
    # activity coefficients
    a0 <- 1                                                 
    a1 <- 10^(-0.509*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )     
    a2 <- 10^(-0.509*4*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )   
    a3 <- 10^(-0.509*9*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )
    # apparent acidity constant
    Ka1Mal <- Km1*(a0/a1) ; Ka2Mal <- Km2*(a1/a2)                        	# malic
    Ka1Ta <- Kt1*(a0/a1) ; Ka2Ta <- Kt2*(a1/a2)                        
    # compute Malate and DPsi with the malate function
    if(is.null(Mal))
    {
      MalDpsi <- cmal( a=a,b=b,n0 = param_model$n0, pHvac=x[2], i=x[1], alpha = param_model$alpha , bbeta = param_model$bbeta , pHcyt = param_model$pHcyt, a2Malcyt = a2Malcyt, KK1=Ka1Mal, KK2=Ka2Mal , Te = Te)
      # store the values in the global variables
      DPsi.glob <<- MalDpsi[1]
      Mal <- MalDpsi[2]
      Mal.glob <<- Mal
    }else{
      Mal.glob <<- Mal
    }
    pEMal2 <- pMal2(x,Ka1Mal,Ka2Mal) ; EMal2 <- Mal*pEMal2
    pEMal1 <- pMal1(x,Ka1Mal,Ka2Mal) ; EMal1 <- Mal*pEMal1
    pEMal0 <- pMal0(x,Ka1Mal,Ka2Mal) ; EMal0 <- Mal*pEMal0
    
    pETa2 <- pTa2(x,Ka1Ta,Ka2Ta) ; ETa2 <- Ta*pETa2
    pETa1 <- pTa1(x,Ka1Ta,Ka2Ta) ; ETa1 <- Ta*pETa1
    pETa0 <- pTa0(x,Ka1Ta,Ka2Ta) ; ETa0 <- Ta*pETa0
    
    mu <-  0.5*(4*( ETa2 + EMal2) + EMal1 + ETa1 + 10^(-x[2]) + 10^(x[2]-14) + K + 4 *(A1*K+A2)) # Avec A1 = 0, A2 est la constante qui mime la présence de Ca++ et Mg++
    
    
    #  mu <-  0.5*(4*( ETa2 + EMal2) + EMal1 + ETa1 + 10^(-x[2]) + 10^(x[2]-14) + K )
    
    AnionsSum <- Ta*(2*pETa2+pETa1) + Mal*(2*pEMal2+pEMal1)+ 10^(x[2] - 14)
    
    y <- numeric(2)
    y[1] <- mu-x[1]                                     # F1
    #y[2] <- AnionsSum - (10^(-x[2])+ K ) #+ (2*Mg)+ (2*Ca))          # F2
    #test : ajout d'une constante correspondant à la somme Mg + Ca en mol/L
    y[2] <- AnionsSum - (10^(-x[2])+ K + 2*(A1*K+A2)) #+ (2*Mg)+ (2*Ca))          # F2
    
    
    #y[1] = 0; y[2] = 0 #(L)
    # write results on a file
    data.out <- data.frame(ETa1, ETa2, EMal2 , EMal1 , K,Ta)
    names(data.out) <- c("ETa1" , "ETa2" , "EMal2" , "EMal1" , "K" ,"Ta")
    write.table(data.out , "out_ph.csv" , row.names=F,sep=",",dec=".")
    #write.table(res.f,"PN33.csv",row.names=F,sep=",",dec=".")
    data.out2 <- data.frame(x[2], x[1], y[2] , y[1] , K)
    names(data.out2) <- c("pH" , "I" , "=0" , " =0" , "K" )
    write.table(data.out2 , "out_ph2.csv" , row.names=F,sep=",",dec=".")
    
    return(y)
  }
  xstart <-c(0.001 , 1.5)           # initial values  ____ En suppimant la ligne (L) (juste au dessus), le model tourne : donne une valeur de pH peu importe la valeur d'entrée 
  res <- nleqslv(xstart, dslnex, control=list(btol=.01))      # solve the system
  
  # use the estimated pH to compute the global variables pH and mu
  pH <- res$x[2]
  mu <- res$x[1]
  # run the dslnex to have the last and correct values of Mal and Dpsi
  dslnex(as.numeric(res$x))
  # the function results are malate, DPsi , pH and mu
  return(data.frame(malate = Mal.glob , DPsi = DPsi.glob , pH = pH , mu = mu))
}

run_mal <- function(param_model_run , input,a,b,a2Malcyt,A1,A2)
{
  vb <- rep(NA , nrow(input))
  res <- data.frame(Age_h = vb , malate = vb , DPsi = vb , pH = vb , mu = vb)
  for(i in 1:nrow(input))
  {
    Te.in <- input$T[i]
    Ta.in <- input$Tartrate[i]        #Cit.in <- input$Cit[i]; Pho.in <- input$Pho[i]; Glu.in <- input$Glu[i]
    K.in <- input$K[i]
    M.in <- input$Malate[i]
    pred.mal <- as.numeric(acid(Ta=Ta.in, K = K.in ,
                                Te = Te.in ,Mal=M.in, param_model = param_model_run,a=a,b=b,a2Malcyt=a2Malcyt,A1=A1,A2=A2))
    res[i , ] <- c(input$Age_h[i] , pred.mal)
  }
  #
  return(res)
  #return(res$pH)
  #return(res$malate)
}


DS<-Soyer.23.01...copie
DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="K60",]
imput=DS1.122


parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  
Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./39 #mol/L
Tem=imput$T   
Mal2=imput$Malate/134
don14=data.frame(T=imput$T, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)
res15=run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,a2Malcyt=0.000434,A1=0,A2=0.008) ### A2 : valeurs pour la constante
str(res15)




fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH

pHobs <- imput$pH
pH <- c(pHcalc,pHobs)
Malcalc=res15$Malate
malobs=imput$Malate
Mal=c(Malcalc,malobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
f<-ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+theme(legend.position='none')+ xlab("day")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815 Malcyt : 0.434  mM A1=-0.000849,A2=0.010951 rrmse:0.42")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.038 #F7,B



### Pas de cte : figure 7,A
res15=run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,a2Malcyt=0.000434,A1=0,A2=0)
str(res15)




fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH

pHobs <- imput$pH
pH <- c(pHcalc,pHobs)
Malcalc=res15$Malate
malobs=imput$Malate
Mal=c(Malcalc,malobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
#the figure was called "l" (L)
l<-ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ theme(legend.title = element_blank())+ theme(legend.position = c(0.7, 0.4))+ xlab("day")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815 Malcyt : 0.434  mM A1=-0.000849,A2=0.010951 rrmse:0.42")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.09


plot_grid(l,f)


#### Sur grenache
don=Grenache.2007
imput1=don[don$jaa!="17",]
imput=imput1[imput1$jaa!="45",]
parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)   #### A GARDER EN M2MOIRE rrmse : 0.42

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./(39*1000) #mol/L
Tem=imput$T   
Mal2=imput$Malate/134
don14=data.frame(T=imput$T, Age_h=imput$jaa,Tartrate=Tartrate2,K=K2,Malate=Mal2)
res15=run_mal(param_model_run  =parms, input=don14,a=-372,b=53466,a2Malcyt=0.434,A1=0,A2=0)
str(res15)




fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH

pHobs <- imput$pH
pH <- c(pHcalc,pHobs)
Malcalc=res15$Malate
Malobs=imput$Malate
Mal=c(Malcalc,malobs)
sfac=c(fac2,fac)
day=imput$jaa
jour=c(day,day)
sum41=data.frame(Mal,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
f<-ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+theme(legend.position='none')+ xlab("day")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815 Malcyt : 0.434  mM A1=-0.000849,A2=0.010951 rrmse:0.42")##### pH calc = pH obs 
new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(pH),funs(mean,sd),na.rm=TRUE)
n = 3
n
new



ggplot(data=new, aes(jour,mean, colour=sfac))+
  geom_pointrange(aes(x=jour,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ggtitle("")+xlab("jaa") + ylab("pH")+ theme(legend.title = element_blank()) + theme(legend.position = c(0.8, 0.5))



rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.075




res15=run_mal(param_model_run  =parms, input=don14,a=-372,b=53466,a2Malcyt=0.434,A1=0,A2=0.003)
str(res15)




fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH

pHobs <- imput$pH
pH <- c(pHcalc,pHobs)
Malcalc=res15$Malate
malobs=imput$Malate
Mal=c(Malcalc,malobs)
sfac=c(fac2,fac)
day=imput$jaa
jour=c(day,day)
sum41=data.frame(Mal,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(pH),funs(mean,sd),na.rm=TRUE)

ggplot(data=new, aes(jour,mean, colour=sfac))+theme_classic()+
  geom_pointrange(aes(x=jour,y=mean,ymin=mean - sd, ymax= mean + sd ), size = 0.5)+ggtitle("")+xlab("jaa") + ylab("pH")+ theme(legend.title = element_blank()) + theme(legend.position = c(0.8, 0.5))


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.078

l


plot_grid(l,f)







##### On Sangiovese
don = Sangiovese12
imput=don[don$DAF!="105",]



parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)   

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./(39.1*1000) #mol/L
Tem=imput$T   
Mal2=imput$Malate/134
don14=data.frame(T=imput$T, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)
res15=run_mal(param_model_run  =parms, input=don14,a=-396,b=61360,a2Malcyt=0.000434,A1=0,A2=0.00472)
str(res15)




fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH

pHobs <- imput$pH
pH <- c(pHcalc,pHobs)
Malcalc=res15$Malate
malobs=imput$Malate
Mal=c(Malcalc,malobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+theme(legend.position='none')+ xlab("day")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815 Malcyt : 0.434  mM A1=-0.000849,A2=0.010951 rrmse:0.42")##### pH calc = pH obs 

new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(pH),funs(mean,sd),na.rm=TRUE)
n = 3
n
new



f<-ggplot(data=new, aes(jour,mean, colour=sfac))+theme_classic()+
  geom_pointrange(aes(x=jour,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ggtitle("")+xlab("DOY") + ylab("pH")+ theme(legend.title = element_blank()) + theme(legend.position = c(0.7, 0.2))


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.036




res15=run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,a2Malcyt=0.000434,A1=0,A2=0)
str(res15)




fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH

pHobs <- imput$pH
pH <- c(pHcalc,pHobs)
Malcalc=res15$Malate
malobs=imput$Malate
Mal=c(Malcalc,malobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ theme(legend.title = element_blank())+ theme(legend.position = c(0.7, 0.4))+ xlab("day")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815 Malcyt : 0.434  mM A1=-0.000849,A2=0.010951 rrmse:0.42")##### pH calc = pH obs 

new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(pH),funs(mean,sd),na.rm=TRUE)
n = 3
n
new



l<-ggplot(data=new, aes(jour,mean, colour=sfac))+theme_classic()+
  geom_pointrange(aes(x=jour,y=mean,ymin=mean - sd, ymax=mean + sd), size = 0.5)+ggtitle("")+xlab("DOY") + ylab("pH")+ theme(legend.position = 'none') 

rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # NaN, because malate was used as inputs, Malcalc==Malobs.

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.064


plot_grid(l,f)








#### figure 8 Model final 
### les plot d'évolution de pH, mal, et tar vont être mis en place et rassembler pour les 5 data sets (CS K60 (a), CS K120 (b), CS K0(d), Sangiovese (e), grenache (f))

#### Verification : K1  (10^(-2.98)) et KK1  (10^(-3.4)) sont tout deux au nominateur, multiplié par h (10^(-pHvac))


cmal<-function(a, b , n0, alpha , bbeta , pHcyt ,M1,M2 , i , pHvac , KK1, KK2 , Te)
#Te temperature in oC

{
  a2Malcyt <- M1*pHvac+M2
  R<-8.314 ; FF<-96500; Te <- Te+273.15
  DGATP=a*Te+b
  coeffa2vac<- 10^(-0.509*4*((i^0.5/(1+i^0.5)-0.3*i)))
  DY<-(-DGATP)/(FF*(n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)))+((R*Te)/FF)*log(10)*(pHvac-pHcyt)
  cMalvac<-(1/coeffa2vac)* a2Malcyt *  exp((2*FF*DY)/(R*Te)) *  (KK1*KK2+KK1*10^(-pHvac)+10^(-2*pHvac))/(KK1*KK2)
  c(DY,cMalvac)  # sortie de la fonction
}

ctar <- function(a,b,n0, alpha, bbeta, pHcyt, T1,T2,i,pHvac, K1,K2,Te)
{
  a2Tarcyt <- T1*pHvac+T2
  R<- 8.314; FF <- 96500 ; Te <- Te + 273.15
  DGATP = a*Te+b
  coeffa2vac<- 10^(-0.509*4*((i^0.5/(1+i^0.5)-0.3*i)))
  DY<-(-DGATP)/(FF*(n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)))+((R*Te)/FF)*log(10)*(pHvac-pHcyt)
  cTarvac<-(1/coeffa2vac)*a2Tarcyt *  exp((2*FF*DY)/(R*Te)) *  (K1*K2+K1*10^(-pHvac)+10^(-2*pHvac))/(K1*K2)
  cTarvac<-cTarvac
  c(cTarvac)  # sortie de la fonction
}

acid <- function(Mal = NULL , Ta = NULL , K, Te , param_model = NULL,a,b,M1,M2,T1,T2,A1,A2) 
{
  
  Ta.glob <<- NA
  Mal.glob <<- NA
  DPsi.glob <<- NA
  
  Km1 <- 10^(-3.40) ; Km2 <- 10^(-5.11)                     # malic(-4.34),K2=10^(-2.98)
  Kt1 <- 10^(-2.98) ; Kt2 <- 10^(-4.34)
  dslnex <- function (x)
  {
    
    pMal2 <- function(x, Km1, Km2) { # tMal2 is the malate 2- proportion: [Mal2-]/[Maltotal] so no unity
      h <- 10^(-x[2]) ; tMal2 <- Km1*Km2/(h^2*(1+Km1/h+Km1*Km2/h^2))
      tMal2}
    pMal1 <-  function(x, Km1, Km2) {
      h  <- 10^(-x[2]) ; tMal1 <- Km1/(h*(1+Km1/h+Km1*Km2/h^2))
      tMal1}
    pMal0 <- function(x, Km1, Km2) {
      h <- 10^(-x[2]) ; tMal0 <- 1/(1*(1+Km1/h+Km1*Km2/h^2))
      tMal0}
    #Tartaric acid 
    pTa2 <- function(x, Kt1, Kt2) { # tTa2 is the tartrate 2- proportion: [Ta2-]/[Tatotal] so no unity
      h <- 10^(-x[2]) ; tTa2 <- Kt1*Kt2/(h^2*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa2}
    pTa1 <-  function(x, Kt1, Kt2) {
      h  <- 10^(-x[2]) ; tTa1 <- Kt1/(h*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa1}
    pTa0 <- function(x, Kt1, Kt2) {
      h <- 10^(-x[2]) ; tTa0 <- 1/(1*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa0}
    # activity coefficients
    a0 <- 1                                                 
    a1 <- 10^(-0.509*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )     
    a2 <- 10^(-0.509*4*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )   
    #  a3 <- 10^(-0.509*9*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )
    # apparent acidity constant
    Ka1Mal <- Km1*(a0/a1) ; Ka2Mal <- Km2*(a1/a2)                          # malic
    Ka1Ta <- Kt1*(a0/a1) ; Ka2Ta <- Kt2*(a1/a2)                        
    # compute Malate and DPsi with the malate function
    if(is.null(Mal)&is.null(Ta))
    {
      MalDpsi <- cmal( a=a,b=b,n0 = param_model$n0, pHvac=x[2], i=x[1], alpha = param_model$alpha , bbeta = param_model$bbeta , pHcyt = param_model$pHcyt, M1=M1,M2=M2, KK1=Ka1Mal, KK2=Ka2Mal , Te = Te)
      Ta <- ctar ( a=a,b=b,n0 = param_model$n0, pHvac=x[2], i=x[1], alpha = param_model$alpha , bbeta = param_model$bbeta , pHcyt = param_model$pHcyt, T1=T1,T2=T2, K1=Ka1Ta, K2=Ka2Ta , Te = Te)
      
      # store the values in the global variables
      DPsi.glob <<- MalDpsi[1]
      Mal <- MalDpsi[2]
      Mal.glob <<- Mal
      Ta.glob <<- Ta
    }else{
      Mal.glob <<- Mal
      Ta.glob <<- Ta
    }
    pEMal2 <- pMal2(x,Ka1Mal,Ka2Mal) ; EMal2 <- Mal*pEMal2
    pEMal1 <- pMal1(x,Ka1Mal,Ka2Mal) ; EMal1 <- Mal*pEMal1
    pEMal0 <- pMal0(x,Ka1Mal,Ka2Mal) ; EMal0 <- Mal*pEMal0
    
    pETa2 <- pTa2(x,Ka1Ta,Ka2Ta) ; ETa2 <- Ta*pETa2
    pETa1 <- pTa1(x,Ka1Ta,Ka2Ta) ; ETa1 <- Ta*pETa1
    pETa0 <- pTa0(x,Ka1Ta,Ka2Ta) ; ETa0 <- Ta*pETa0
    
    
    mu <-  0.5*(4*( ETa2 + EMal2) + EMal1 + ETa1 + 10^(-x[2]) + 10^(x[2]-14) + K + 4 *(A1*K+A2))
    
    AnionsSum <- Ta*(2*pETa2+pETa1) + Mal*(2*pEMal2+pEMal1)+ 10^(x[2] - 14)
    
    y <- numeric(2)
    y[1] <- mu-x[1]                                     # F1
    #y[2] <- AnionsSum - (10^(-x[2])+ K ) #+ (2*Mg)+ (2*Ca))          # F2
    #test : ajout d'une constante correspondant ?  la somme Mg + Ca en mol/L
    y[2] <- AnionsSum - (10^(-x[2])+ K + 2*(A1*K+A2)) #+ (2*Mg)+ (2*Ca))          # F2
    
    
    # y[1] = 0; y[2] = 0 #(L)
    # write results on a file
    data.out <- data.frame(ETa1, ETa2, EMal2 , EMal1 , K,Ta)
    names(data.out) <- c("ETa1" , "ETa2" , "EMal2" , "EMal1" , "K" ,"Ta")
    write.table(data.out , "out_ph.csv" , row.names=F,sep=",",dec=".")
    #write.table(res.f,"PN33.csv",row.names=F,sep=",",dec=".")
    data.out2 <- data.frame(x[2], x[1], y[2] , y[1] , K)
    names(data.out2) <- c("pH" , "I" , "=0" , " =0" , "K" )
    write.table(data.out2 , "out_ph2.csv" , row.names=F,sep=",",dec=".")
    
    return(y)
  }
  xstart <-c(0.001 ,2.5)           # initial values  ____ En suppimant la ligne (L) (juste au dessus), le model tourne : donne une valeur de pH peu importe la valeur d'entrée 
  res <- nleqslv(xstart, dslnex, control=list(btol=.01))      # solve the system
  
  # use the estimated pH to compute the global variables pH and mu
  pH <- res$x[2]
  mu <- res$x[1]
  # run the dslnex to have the last and correct values of Mal and Dpsi
  dslnex(as.numeric(res$x))
  # the function results are malate, DPsi , pH and mu
  return(data.frame(malate = Mal.glob ,tartrate=Ta.glob, DPsi = DPsi.glob , pH = pH , mu = mu))
}

run_mal <- function(param_model_run , input,a,b,M1,M2,T1,T2,A1,A2)
{
  vb <- rep(NA , nrow(input))
  res <- data.frame(Age_h = vb , malate = vb , tartrate = vb , DPsi = vb , pH = vb , mu = vb)
  for(i in 1:nrow(input))
  {
    Te.in <- input$T[i]
    #Ta.in <- input$Tartrate[i]        #Cit.in <- input$Cit[i]; Pho.in <- input$Pho[i]; Glu.in <- input$Glu[i]
    K.in <- input$K[i]
    # ph.in<-input$pH[i] #; Mg.in <- input$Mg[i] ; Ca.in <- input$Ca[i]
    pred.mal <- as.numeric(acid( K = K.in ,
                                 Te = Te.in ,param_model = param_model_run,a=a,b=b,M1=M1,M2=M2,T1=T1,T2=T2,A1=A1,A2=A2))
    res[i , ] <- c(input$Age_h[i] , pred.mal)
  }
  #
  return(res)
  #return(res$pH)
  #return(c(res$malate,res$tartrate,res$pH))
  # return(res$tartrate)
  #return(res$malate)
}


DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="K60",]
imput=DS1.122
parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./39 #mol/L
Tem=imput$T   
Mal2=imput$Malate/134

don14=data.frame(T=imput$T,pH=imput$pH, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)

res15=run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,M1=-3.16e-04,M2=0.0013,A1=0  ,A2=0.008,T1=0.00258,T2=-0.0042)
str(res15)



res15$Malate=res15$malate*134
res15$Tartrate=res15$tartrate*150

sumaccalc=res15$malate+res15$tartrate

plot(imput$pH,sumaccalc)


fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH
pHobs <- imput$pH
pH <- c(pHcalc,pHobs)

Malcalc=res15$Malate
Malobs=imput$Malate
Mal=c(Malcalc,Malobs)
Tacalc=res15$Tartrate
Taobs=imput$Tartrate
Ta=c(Tacalc,Taobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,Ta,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.06")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.64")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Ta, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.32")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0.44

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.036

rmse<-rmse(Taobs,Tacalc)
m<-mean(Taobs)
rrmse<-rmse/m
rrmse # 0.14

sum41$org <- sum41$Mal+sum41$Ta


ggplot(data=sum41, aes(jour,org, colour=sfac))+geom_point()+ggtitle("CS K60 a=-298,b=29815,M1=-0.000243,M2=0.00114 \n T1=0.00261,T2=-0.0041,test=0.008,test=0.008 rrmse:0.35")##### pH calc = pH obs 
orgobs <- Taobs + Malobs
orgcalc <- Tacalc + Malcalc

rmse<-rmse(orgobs,orgcalc)
m<-mean(orgobs)
rrmse<-rmse/m
rrmse #0.3



new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(Ta,Mal,org,pH),funs(mean,sd),na.rm=TRUE)

f4a<- ggplot(data=new, aes(x=jour,y=Mal_mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Mal_mean,ymin=Mal_mean - Mal_sd, ymax=Mal_mean + Mal_sd), size = 0.5)+ theme(legend.position='none')
f4a

f4b<- ggplot(data=new, aes(x=jour,y=Ta_mean, colour= sfac))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Ta_mean,ymin=Ta_mean - Ta_sd, ymax=Ta_mean + Ta_sd), size = 0.5)+ theme(legend.position='none')
f4b

f4c<- ggplot(data=new, aes(x=jour,y=org_mean, colour= sfac))+ylab("Sum of organic acids mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=org_mean,ymin=org_mean - org_sd, ymax=org_mean + org_sd), size = 0.5)+ theme(legend.position='none')
f4c

f4d<- ggplot(data=new, aes(x=jour,y=pH_mean, colour= sfac))+ylab("pH")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=pH_mean,ymin=pH_mean - pH_sd, ymax=pH_mean + pH_sd), size = 0.5)+ theme(legend.title = element_blank()) + theme(legend.position = c(0.5, 0.3))
f4d

a<-plot_grid(f4d,f4a,f4b, labels=c("A", "B","C"), ncol = 3, nrow = 1)#### figure 3 sans légende 



#### la suite pour K120 :
DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="K120",]
imput=DS1.122
parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./39 #mol/L
Tem=imput$T   
Mal2=imput$Malate/134

don14=data.frame(T=imput$T,pH=imput$pH, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)

res15=run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,M1=-2.6e-04,M2=0.00118,A1=0  ,A2=0.008,T1=0.0027,T2=-0.0043)
str(res15)



res15$Malate=res15$malate*134
res15$Tartrate=res15$tartrate*150

sumaccalc=res15$malate+res15$tartrate

plot(imput$pH,sumaccalc)


fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH
pHobs <- imput$pH
pH <- c(pHcalc,pHobs)

Malcalc=res15$Malate
Malobs=imput$Malate
Mal=c(Malcalc,Malobs)
Tacalc=res15$Tartrate
Taobs=imput$Tartrate
Ta=c(Tacalc,Taobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,Ta,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.06")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.64")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Ta, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.32")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0.28

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.04

rmse<-rmse(Taobs,Tacalc)
m<-mean(Taobs)
rrmse<-rmse/m
rrmse # 0.13

sum41$org <- sum41$Mal+sum41$Ta


ggplot(data=sum41, aes(jour,org, colour=sfac))+geom_point()+ggtitle("CS K60 a=-298,b=29815,M1=-0.000243,M2=0.00114 \n T1=0.00261,T2=-0.0041,test=0.008,test=0.008 rrmse:0.35")##### pH calc = pH obs 
orgobs <- Taobs + Malobs
orgcalc <- Tacalc + Malcalc

rmse<-rmse(orgobs,orgcalc)
m<-mean(orgobs)
rrmse<-rmse/m
rrmse #0.19



new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(Ta,Mal,org,pH),funs(mean,sd),na.rm=TRUE)

new
f4a<- ggplot(data=new, aes(x=jour,y=Mal_mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Mal_mean,ymin=Mal_mean - Mal_sd, ymax=Mal_mean + Mal_sd), size = 0.5)+ theme(legend.position='none')
f4a

f4b<- ggplot(data=new, aes(x=jour,y=Ta_mean, colour= sfac))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Ta_mean,ymin=Ta_mean - Ta_sd, ymax=Ta_mean + Ta_sd), size = 0.5)+ theme(legend.position='none')
f4b

f4c<- ggplot(data=new, aes(x=jour,y=org_mean, colour= sfac))+ylab("Sum of organic acids mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=org_mean,ymin=org_mean - org_sd, ymax=org_mean + org_sd), size = 0.5)+ theme(legend.position='none')
f4c

f4d<- ggplot(data=new, aes(x=jour,y=pH_mean, colour= sfac))+ylab("pH")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=pH_mean,ymin=pH_mean - pH_sd, ymax=pH_mean + pH_sd), size = 0.5)+ theme(legend.title = element_blank()) + theme(legend.position = c(0.5, 0.3))
f4d

b<-plot_grid(f4d,f4a,f4b, labels=c("D", "E","F"), ncol = 3, nrow = 1)#### figure 3 sans légende 




## pour K0 : 

DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="Temoin K0",]
imput=DS1.122
parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./39 #mol/L
Tem=imput$T   
Mal2=imput$Malate/134

don14=data.frame(T=imput$T,pH=imput$pH, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)



#estimating parameters with optimx!
####### Exemple d'estimation de paramètre avec optimx

fitness2  <- function(par=par,param_model_run  =parms, input=don14,a,b,M1,M2,T1,T2,A1,A2){
  
  
  out  <- run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,M1=par[1],M2=par[2],A1=0,A2=0.008,T1=par[3],T2=par[4])
  Malout <- out[,2]
  
  Tarout <- out[,3]
  Tarobs <- don14$Tartrate
  Malobs  <- don14$Malate
  
  
  
  calc <- c(Malout,Tarout)
  obs <- c(Malobs,Tarobs)
  
  res<- sum(((obs-calc)^2)^(0.5))   
  return(res)
}
partest=c(-3e-04,0.00125  ,0.00269,-0.004 )
testfitness <- fitness2(param_model_run  =parms, input=don14,a,b,M1,M2,T1,T2,test,par=partest)
testfitness # 3.49

partest=c(-3.16e-04,0.0013,0.00258,-0.0042)
testfitness <- fitness2(param_model_run  =parms, input=don14,a,b,M1,M2,T1,T2,test,par=partest)
testfitness # 2.83 < 3.49 donc ce set de paramètre est plus précis que le précedent



(result<- optimx(par=partest,fitness2,method=c("Nelder-Mead","nmkb"),control =list(save.failures=TRUE)))

 #               p1          p2            p3           p4        value
#Nelder-Mead -0.0002809834 0.001141839  0.002537729 -0.004644695 1.239842
#nmkb        -0.0003247985 0.001220359 0.002483810 -0.004179508 1.598255








res15=run_mal(param_model_run  =parms, input=don14,a=-298,b=29815,M1=-3e-04,M2=0.00117,A1=0  ,A2=0.008,T1=0.00245,T2=-0.00423)
str(res15)



res15$Malate=res15$malate*134
res15$Tartrate=res15$tartrate*150

sumaccalc=res15$malate+res15$tartrate

plot(imput$pH,sumaccalc)


fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH
pHobs <- imput$pH
pH <- c(pHcalc,pHobs)

Malcalc=res15$Malate
Malobs=imput$Malate
Mal=c(Malcalc,Malobs)
Tacalc=res15$Tartrate
Taobs=imput$Tartrate
Ta=c(Tacalc,Taobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,Ta,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.06")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.64")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Ta, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.32")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0.5

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.057

rmse<-rmse(Taobs,Tacalc)
m<-mean(Taobs)
rrmse<-rmse/m
rrmse # 0.17

sum41$org <- sum41$Mal+sum41$Ta


ggplot(data=sum41, aes(jour,org, colour=sfac))+geom_point()+ggtitle("CS K60 a=-298,b=29815,M1=-0.000243,M2=0.00114 \n T1=0.00261,T2=-0.0041,test=0.008,test=0.008 rrmse:0.35")##### pH calc = pH obs 
orgobs <- Taobs + Malobs
orgcalc <- Tacalc + Malcalc

rmse<-rmse(orgobs,orgcalc)
m<-mean(orgobs)
rrmse<-rmse/m
rrmse #0.36



new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(Ta,Mal,org,pH),funs(mean,sd),na.rm=TRUE)
n = 3
n
new
f4a<- ggplot(data=new, aes(x=jour,y=Mal_mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Mal_mean,ymin=Mal_mean - Mal_sd, ymax=Mal_mean + Mal_sd), size = 0.5)+ theme(legend.position='none')
f4a

f4b<- ggplot(data=new, aes(x=jour,y=Ta_mean, colour= sfac))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Ta_mean,ymin=Ta_mean - Ta_sd, ymax=Ta_mean + Ta_sd), size = 0.5)+ theme(legend.position='none')
f4b

f4c<- ggplot(data=new, aes(x=jour,y=org_mean, colour= sfac))+ylab("Sum of organic acids mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=org_mean,ymin=org_mean - org_sd, ymax=org_mean + org_sd), size = 0.5)+ theme(legend.position='none')
f4c

f4d<- ggplot(data=new, aes(x=jour,y=pH_mean, colour= sfac))+ylab("pH")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=pH_mean,ymin=pH_mean - pH_sd, ymax=pH_mean + pH_sd), size = 0.5)+ theme(legend.title = element_blank()) + theme(legend.position = c(0.5, 0.3))
f4d

c<-plot_grid(f4d,f4a,f4b, labels=c("I", "J","K"), ncol = 3, nrow = 1)#### figure 3 sans légende 
c








### plot pour sangiovese ; 
don = Sangiovese12
imput=don[don$DAF!="105",]



parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./(39.1*1000) #mol/L
Tem=imput$T   
Mal2=imput$Malate/134

don14=data.frame(T=imput$T,pH=imput$pH, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)

res15=run_mal(param_model_run  =parms, input=don14,a=-396,b=61360,M1=-0.0002,M2=0.00097,A1=0,A2=0.00472,T1=0.0024,T2=-0.000134)
str(res15)



res15$Malate=res15$malate*134
res15$Tartrate=res15$tartrate*150

sumaccalc=res15$malate+res15$tartrate

plot(imput$pH,sumaccalc)


fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH
pHobs <- imput$pH
pH <- c(pHcalc,pHobs)

Malcalc=res15$Malate
Malobs=imput$Malate
Mal=c(Malcalc,Malobs)
Tacalc=res15$Tartrate
Taobs=imput$Tartrate
Ta=c(Tacalc,Taobs)
sfac=c(fac2,fac)
day=imput$Jour
jour=c(day,day)
sum41=data.frame(Mal,Ta,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.06")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.64")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Ta, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.32")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0.63

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.094

rmse<-rmse(Taobs,Tacalc)
m<-mean(Taobs)
rrmse<-rmse/m
rrmse # 0.32

sum41$org <- sum41$Mal+sum41$Ta


ggplot(data=sum41, aes(jour,org, colour=sfac))+geom_point()+ggtitle("CS K60 a=-298,b=29815,M1=-0.000243,M2=0.00114 \n T1=0.00261,T2=-0.0041,test=0.008,test=0.008 rrmse:0.35")##### pH calc = pH obs 
orgobs <- Taobs + Malobs
orgcalc <- Tacalc + Malcalc

rmse<-rmse(orgobs,orgcalc)
m<-mean(orgobs)
rrmse<-rmse/m
rrmse #0.45



new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(Ta,Mal,org,pH),funs(mean,sd),na.rm=TRUE)
n = 3
n
new
f4a<- ggplot(data=new, aes(x=jour,y=Mal_mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Mal_mean,ymin=Mal_mean - Mal_sd, ymax=Mal_mean + Mal_sd), size = 0.5)+ theme(legend.position='none')
f4a

f4b<- ggplot(data=new, aes(x=jour,y=Ta_mean, colour= sfac))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Ta_mean,ymin=Ta_mean - Ta_sd, ymax=Ta_mean + Ta_sd), size = 0.5)+ theme(legend.position='none')
f4b

f4c<- ggplot(data=new, aes(x=jour,y=org_mean, colour= sfac))+ylab("Sum of organic acids mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=org_mean,ymin=org_mean - org_sd, ymax=org_mean + org_sd), size = 0.5)+ theme(legend.position='none')
f4c

f4d<- ggplot(data=new, aes(x=jour,y=pH_mean, colour= sfac))+ylab("pH")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=pH_mean,ymin=pH_mean - pH_sd, ymax=pH_mean + pH_sd), size = 0.5)+ theme(legend.title = element_blank()) + theme(legend.position = c(0.5, 0.3))
f4d

d<-plot_grid(f4d,f4a,f4b, labels=c("L", "M","N"), ncol = 3, nrow = 1)#### figure 3 sans légende 




### Enin pour grenache ; 

imput=Grenache7.2  



parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./(39.1*1000) #mol/L
Tem=imput$T   
Mal2=imput$Malate/134

don14=data.frame(T=imput$T,pH=imput$pH, Age_h=imput$jaa,Tartrate=Tartrate2,K=K2,Malate=Mal2)

#a=-372,b=53466,M1=-4.5e-04,M2=0.00157,A1=0  ,A2=0.0014,T1=0.0035,T2=-0.004
res15=run_mal(param_model_run  =parms, input=don14,a=-372,b=53466,M1=-4.1e-04,M2=0.00169,A1=0  ,A2=0.006,T1=0.0031,T2=-0.0032)
str(res15)





res15$Malate=res15$malate*134
res15$Tartrate=res15$tartrate*150

sumaccalc=res15$malate+res15$tartrate

plot(imput$pH,sumaccalc)


fac <- rep("observed" , nrow(res15))
fac2 <- rep("predicted" ,nrow(res15))

pHcalc <- res15$pH
pHobs <- imput$pH
pH <- c(pHcalc,pHobs)

Malcalc=res15$Malate
Malobs=imput$Malate
Mal=c(Malcalc,Malobs)
Tacalc=res15$Tartrate
Taobs=imput$Tartrate
Ta=c(Tacalc,Taobs)
sfac=c(fac2,fac)
day=imput$jaa
jour=c(day,day)
sum41=data.frame(Mal,Ta,sfac,jour,pH)
#write.table(sum41 , "sum41.csv" , row.names=F,sep=",",dec=".")
ggplot(data=sum41, aes(jour,pH, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.06")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Mal, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.64")##### pH calc = pH obs 
ggplot(data=sum41, aes(jour,Ta, colour=sfac))+geom_point()+ggtitle("CS K120 a=-298,b=29815,M1=1.21e-04,M2=-9.31e-06, \n test=0.008,T1=0.0028,T2=-0.0042 rrmse:0.32")##### pH calc = pH obs 


rmse<-rmse(Malobs,Malcalc)
m<-mean(Malobs)
rrmse<-rmse/m
rrmse # 0.74

rmse<-rmse(pHobs,pHcalc)
m<-mean(pHobs)
rrmse<-rmse/m
rrmse #0.1

rmse<-rmse(Taobs,Tacalc)
m<-mean(Taobs)
rrmse<-rmse/m
rrmse # 0.25

sum41$org <- sum41$Mal+sum41$Ta


ggplot(data=sum41, aes(jour,org, colour=sfac))+geom_point()+ggtitle("CS K60 a=-298,b=29815,M1=-0.000243,M2=0.00114 \n T1=0.00261,T2=-0.0041,test=0.008,test=0.008 rrmse:0.35")##### pH calc = pH obs 
orgobs <- Taobs + Malobs
orgcalc <- Tacalc + Malcalc

rmse<-rmse(orgobs,orgcalc)
m<-mean(orgobs)
rrmse<-rmse/m
rrmse #0.42



new =  sum41 %>% group_by(jour,sfac) %>% summarise_at(vars(Ta,Mal,org,pH),funs(mean,sd),na.rm=TRUE)
n = 3
n
new
f4a<- ggplot(data=new, aes(x=jour,y=Mal_mean, colour= sfac))+ylab("Malate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Mal_mean,ymin=Mal_mean - Mal_sd, ymax=Mal_mean + Mal_sd), size = 0.5)+ theme(legend.position='none')
f4a

f4b<- ggplot(data=new, aes(x=jour,y=Ta_mean, colour= sfac))+ylab("Tartrate mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=Ta_mean,ymin=Ta_mean - Ta_sd, ymax=Ta_mean + Ta_sd), size = 0.5)+ theme(legend.position='none')
f4b

f4c<- ggplot(data=new, aes(x=jour,y=org_mean, colour= sfac))+ylab("Sum of organic acids mg/g")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=org_mean,ymin=org_mean - org_sd, ymax=org_mean + org_sd), size = 0.5)+ theme(legend.position='none')
f4c

f4d<- ggplot(data=new, aes(x=jour,y=pH_mean, colour= sfac))+ylab("pH")+xlab("Day")+
  geom_pointrange(aes(x=jour,y=pH_mean,ymin=pH_mean - pH_sd, ymax=pH_mean + pH_sd), size = 0.5)+ theme(legend.title = element_blank()) + theme(legend.position = c(0.5, 0.3))
f4d

e<-plot_grid(f4d,f4a,f4b, labels=c("O", "P","Q"), ncol = 3, nrow = 1)#### figure 3 sans légende 




#### Deuxième version de prédicton de la réponse à T 

### ici K1 et KK1 correspondent bien au valeurs de pKa les plus petites 


Org<-function(pHvac,Te,a ,b,K2=10^(-5.11),K1=10^(-3.4), K11= 10^(-2.98),K22=10^(-4.34),T1,T2,      R=8.314,FF=96000, pHcyt=7.5,M1 , M2,alpha=0.3,bbeta=-0.12,n0=4){
  Te = Te + 273.15
  DGATP = a * Te + b 
  Malcyt = M1 * pHvac + M2 
  Tarcyt <- T1*pHvac + T2
  n=n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)
  DY=((-DGATP/(n*FF))+((R*Te*2.3)/FF)*(pHvac-pHcyt))
  
  h=10^(-pHvac)
  K=(K1*K2+h*K1+h^2)/(K1*K2)
  
  Mal.mol=K*exp((2*FF*DY)/(R*Te))*Malcyt # in mol/L
  cTarvac<- Tarcyt *  exp((2*FF*DY)/(R*Te)) *  (K11*K22+K11*10^(-pHvac)+10^(-2*pHvac))/(K11*K22)
  Tar<-cTarvac*150
  Mal=Mal.mol*134 #g/L
  Mal
  res <- data.frame(DY,Mal,Tar)
}


########



############# Allez ligne 2270 : scipt pour figure 6 A,B 


####

##### resultat des fit x 3 avec cte cte cte

# Sur 20° et 30° 
don=Kliewer.29.01_Dai
don1=don[don$cepage=="pinot noir",]
don2 = don1[don1$T=="20",]
don3 = don1[don1$T=="30",]



out1<-Org(M1= 0, M2= 9.564e-04   ,T1= 0 , T2= 1.055e-02 ,a =0, b =  -56000, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T)
obsMa <- don1$Malate
rmse <- rmse(out1[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.32
obsTa <- don1$Tartrate
rmse <- rmse(out1[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.39



out2<-Org(M1= 0, M2= 9.564e-04   ,T1= 0 , T2= 1.055e-02 ,a =0, b =  -56000, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don2$pH, Te = don2$T)
#malpred2 <- out2[,2]
out3<-Org(M1= 0, M2= 9.564e-04   ,T1= 0 , T2= 1.055e-02,a =0, b =  -56000, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don3$pH, Te = don3$T)



malobs <- c(don2$Malate, don3$Malate)
tarobs <- c(don2$Tartrate , don3$Tartrate)

malpred <- c(out2[,2],out3[,2])
tarpred <- c(out2[,3],out3[,3])

Mal <- c(malobs , malpred)
Tar <- c(tarobs , tarpred)

origin <-rep("observed",length(malobs))
origin2 <- rep("predicted",length(malpred))
sfac <- c(origin, origin2)

Temp <- c(rep("20°C",length(don2$Malate)),rep("30°C",length(don3$Malate)))
Temperature <- c(Temp,Temp)

pH <- c(don2$pH,don2$pH,don2$pH,don2$pH)
time <- c(don2$Mois,don2$Mois,don2$Mois,don2$Mois)
gin <- data.frame (pH,Temperature,sfac,Mal,Tar,time)
M1 <- ggplot(data=gin, aes(time,Mal, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Malate mg/g")+theme(legend.title = element_blank()) + theme(legend.position = c(0.9, 0.7))+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))
#ggplot(data=gin, aes(time,Mal, colour = sfac, shape=Temperature))+geom_point()+theme_classic()+ ylab("Malate mg/g")+theme(legend.title = element_blank()) + theme(legend.position = c(0.9, 0.7))+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

T1 <- ggplot(data=gin, aes(time,Tar, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Tartrate mg/g")+theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

#write.table(gin , "testtorrmse.csv" , row.names=F,sep=",",dec=".")

m1 <- ggplot(data=gin, aes(pH,Mal, colour = sfac))+geom_point()+facet_wrap(~Temperature)+ ylab("Malate mg/g")+theme(legend.title = element_blank()) + theme(legend.position = c(0.7, 0.7))+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

t1 <- ggplot(data=gin, aes(pH,Tar, colour = sfac))+geom_point()+facet_wrap(~Temperature)+ ylab("Tartrate mg/g")+theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))



### RRMSE SUR 20°
obsMa <- don2$Malate
rmse <- rmse(out2[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.16


obsTa <- don2$Tartrate
rmse <- rmse(out2[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.24


### RRMSE SUR 30°
obsMa <- don3$Malate
rmse <- rmse(out3[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.56


obsTa <- don3$Tartrate
rmse <- rmse(out3[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.49








#M1 = -0.0007557,  M2 = 0.0032, T1 = 0.00211,T2 = 0.0043,a =-229, b = 11628.7

###2

don=Kliewer.29.01_Dai
don1=don[don$cepage=="pinot noir",]
don2 = don1[don1$T=="20",]
don3 = don1[don1$T=="30",]



out1<-Org(M1= 0, M2= 9.564e-04   ,T1= 0 , T2= 1.055e-02 ,a =-229, b = 11628.7, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T)
obsMa <- don1$Malate
rmse <- rmse(out1[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.23
obsTa <- don1$Tartrate
rmse <- rmse(out1[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.11


out2<-Org( M1= 0, M2= 9.564e-04   ,T1= 0 , T2= 1.055e-02 ,a =-229, b = 11628.7, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don2$pH, Te = don2$T)
out3<-Org(M1= 0, M2= 9.564e-04   ,T1= 0 , T2= 1.055e-02 ,a =-229, b = 11628.7, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don3$pH, Te = don3$T)



malobs <- c(don2$Malate, don3$Malate)
tarobs <- c(don2$Tartrate , don3$Tartrate)

malpred <- c(out2[,2],out3[,2])
tarpred <- c(out2[,3],out3[,3])

Mal <- c(malobs , malpred)
Tar <- c(tarobs , tarpred)

origin <-rep("observed",length(malobs))
origin2 <- rep("predicted",length(malpred))
sfac <- c(origin, origin2)

Temp <- c(rep("20°C",length(don2$Malate)),rep("30°C",length(don3$Malate)))
Temperature <- c(Temp,Temp)
day <- c(don2$Mois,don2$Mois,don2$Mois,don2$Mois)
pH2 <- c(don2$pH,don2$pH,don2$pH,don2$pH)
time <- c(don2$Mois,don2$Mois,don2$Mois,don2$Mois)
gin <- data.frame (pH,Temperature,sfac,Mal,Tar,time)
M2 <- ggplot(data=gin, aes(time,Mal, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Malate mg/g")+ theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

T2 <- ggplot(data=gin, aes(time,Tar, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Tartrate mg/g")+theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))



m2 <- ggplot(data=gin, aes(pH2,Mal, colour = sfac))+geom_point()+facet_wrap(~Temperature)+ylab("Malate mg/g")+geom_point()+facet_wrap(~Temperature)+ theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

t2 <- ggplot(data=gin, aes(pH2,Tar, colour = sfac))+geom_point()+facet_wrap(~Temperature)+ylab("Tartrate mg/g")+geom_point()+facet_wrap(~Temperature)+ theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))


ggplot(data=gin, aes(day,Mal, colour=Temperature))+geom_point()+facet_wrap(~sfac)
ggplot(data=gin, aes(day,Mal, colour = sfac))+geom_point()+facet_wrap(~Temperature)

ggplot(data=gin, aes(day,pH, colour = sfac))+geom_point()+facet_wrap(~Temperature)



### RRMSE SUR 20°
obsMa <- don2$Malate
rmse <- rmse(out2[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.16


obsTa <- don2$Tartrate
rmse <- rmse(out2[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.10


### RRMSE SUR 30°
obsMa <- don3$Malate
rmse <- rmse(out3[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.35


obsTa <- don3$Tartrate
rmse <- rmse(out3[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.11







################################ REPRISE 
##3 Juste : figure 6 A et B 

don=Kliewer.29.01_Dai
don1=don[don$cepage=="pinot noir",]
don2 = don1[don1$T=="20",]
don3 = don1[don1$T=="30",]



out1<-Org(M1 = -0.0007557,  M2 = 0.0032, T1 = 0.00211,T2 = 0.0043 ,a =-229, b = 11628.7, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T)
obsMa <- don1$Malate
rmse <- rmse(out1[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.12
obsTa <- don1$Tartrate
rmse <- rmse(out1[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.09


out2<-Org(M1 = -0.0007557,  M2 = 0.0032, T1 = 0.00211,T2 = 0.0043,a =-229, b = 11628.7, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don2$pH, Te = don2$T)
out3<-Org(M1 = -0.0007557,  M2 = 0.0032, T1 = 0.00211,T2 = 0.0043,a =-229, b = 11628.7, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don3$pH, Te = don3$T)




malobs <- c(don2$Malate, don3$Malate)
tarobs <- c(don2$Tartrate , don3$Tartrate)

malpred <- c(out2[,2],out3[,2])
tarpred <- c(out2[,3],out3[,3])

Mal <- c(malobs , malpred)
Tar <- c(tarobs , tarpred)

origin <-rep("observed",length(malobs))
origin2 <- rep("predicted",length(malpred))
sfac <- c(origin, origin2)

Temp <- c(rep("20°C",length(don2$Malate)),rep("30°C",length(don3$Malate)))
Temperature <- c(Temp,Temp)

pH <- c(don2$pH,don2$pH,don2$pH,don2$pH)
pH <- c(don2$pH,don2$pH,don2$pH,don2$pH)
time <- c(don2$Mois,don2$Mois,don2$Mois,don2$Mois)
gin <- data.frame (pH,Temperature,sfac,Mal,Tar,time)   ## observed and predicted!
## 09/07/2018# Output gin, reorganzie for final figure! ##
### make a figure for poster GBG 2018###
write.table(gin,"Kliewer.PN.Temp_obs et Simulated.csv",row.names=F,sep=",",dec=".")
PN.tem=read.csv("Kliewer.PN.Temp_obs et Simulated.csv",header=T,sep=",",dec=".")
library(sciplot)
library(doBy)
#lineplot.CI(time,mal.obs,group=temperature,data=PN.tem,type="p")
#calculate the mean!
pn.tem.mean=summaryBy(.~temperature+time,data=PN.tem,FUN=mean,keep.names=T)
#  mal obs vs simulated!
pdf("PN.tem.pdf",width=6,height=4,useDingbats=F)
par(mfrow=c(1,2))
lineplot.CI(time,mal.obs,group=temperature,data=pn.tem.mean,type="p",col=c(4,2),pch=c(15,16),ylim=c(0,16.5),x.cont=T,xlab="Weeks after treatment",ylab="Malate (g/L)")
lines(pn.tem.mean$time[1:5],pn.tem.mean$mal.sim[1:5],col=4)
lines(pn.tem.mean$time[6:10],pn.tem.mean$mal.sim[6:10],col=2)

#tar obs vs simulated!
lineplot.CI(time,tar.obs,group=temperature,data=pn.tem.mean,type="p",ylim=c(0,15),col=c(4,2),pch=c(15,16),x.cont=T,xlab="Weeks after treatment",ylab="Tartrate (g/L)")

lines(pn.tem.mean$time[1:5],pn.tem.mean$tar.sim[1:5],col=4)
lines(pn.tem.mean$time[6:10],pn.tem.mean$tar.sim[6:10],col=2)

dev.off()
### End for the poster GBG 2018 09/07/2018 ##


#found the Tar results are not so good! check with the report figure 6!
# all points for 20oc 
plot(PN.tem$time[1:10],PN.tem$tar.obs[1:10],ylim=c(8,15),col=c(rep(1,5),rep(2,5)))
points(PN.tem$time[1:10],PN.tem$tar.sim[1:10],ylim=c(8,15),col=c(rep(1,5),rep(2,5)),pch=c(rep(15,5),rep(16,5)))


plot(PN.tem$time[11:20],PN.tem$tar.obs[11:20],ylim=c(8,15),col=c(rep(1,5),rep(2,5)))
points(PN.tem$time[11:20],PN.tem$tar.sim[11:20],ylim=c(8,15),col=c(rep(1,5),rep(2,5)),pch=c(rep(15,5),rep(16,5)))


## As function of time
M3 <- ggplot(data=gin, aes(time,Mal, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Malate mg/g")+theme(legend.position='none') +theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

T3 <- ggplot(data=gin, aes(time,Tar, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Tartrate mg/g")+theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))


## as function of pH
m3 <- ggplot(data=gin, aes(pH,Mal, colour = sfac))+geom_point()+facet_wrap(~Temperature)+ylab("Malate mg/g")+ theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

t3 <- ggplot(data=gin, aes(pH,Tar, colour = sfac))+geom_point()+facet_wrap(~Temperature) +ylab("Tartrate mg/g")+theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))


### RRMSE SUR 20°
obsMa <- don2$Malate
rmse <- rmse(out2[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.12


obsTa <- don2$Tartrate
rmse <- rmse(out2[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.07


### RRMSE SUR 30°
obsMa <- don3$Malate
rmse <- rmse(out3[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.11


obsTa <- don3$Tartrate
rmse <- rmse(out3[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.1






#plot_grid(m1,t1,m2,t2,m3,t3, labels=c("A", "B","C","D","E","F"), ncol = 2, nrow =3 )#### figure 3 sans légende 
#plot_grid(M1,T1,M2,T2,M3,T3, labels=c("A", "B","C","D","E","F"), ncol = 2, nrow =3 )#### figure 3 sans légende 

























 # fitness function of optimx
Orgfit<-function(pHvac,Te,a ,b,K2=10^(-5.11),K1=10^(-3.4), K11= 10^(-2.98),K22=10^(-4.34),T1,T2,      R=8.314,FF=96000, pHcyt=7.5,M1 , M2,alpha=0.3,bbeta=-0.12,n0=4){
  Te = Te + 273.15
  DGATP = a * Te + b 
  Malcyt = M1 * pHvac + M2 
  Tarcyt <- T1*pHvac + T2
  n=n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)
  DY=((-DGATP/(n*FF))+((R*Te*2.3)/FF)*(pHvac-pHcyt))
  
  h=10^(-pHvac)
  K=(K1*K2+h*K1+h^2)/(K1*K2)
  
  Mal.mol=K*exp((2*FF*DY)/(R*Te))*Malcyt # in mol/L
  cTarvac<- Tarcyt *  exp((2*FF*DY)/(R*Te)) *  (K11*K22+K11*10^(-pHvac)+10^(-2*pHvac))/(K11*K22)
  Tar<-cTarvac*150
  Mal=Mal.mol*134 #g/L
  Mal
  res <- c(Mal,Tar)
}

don=Kliewer.29.01_Dai
don1=don[don$cepage!="pinot noir",]
don2 = don1[don1$T=="20",]
don3 = don1[don1$T=="30",]



obs <- c(don1$Malate,don1$Tartrate)




##### Estimation des paramètres
fitdots<-nls(obs~ Orgfit(T1= 0, T2= T2,M1= 0, M2= M2,a =0, b =-  56000, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T),start=list(M2=1.481e-04,T2= 1.229e-03),algorithm="port")
summary(fitdots)#
#M2 5.908e-04  6.517e-05   9.066 4.85e-11
#T2 7.537e-03  6.119e-04  12.319 7.68e-15

fitdots<-nls(obs~ Orgfit(T1= 0, T2= 7.537e-03,M1= 0, M2= 5.908e-04,a =a, b =b, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T),start=list(a =0, b =-  56000),algorithm="port")
summary(fitdots)#

#a  -238.57      14.64 -16.292  < 2e-16
#b 14466.25    4361.44   3.317  0.00201

fitdots<-nls(obs~ Orgfit(T1= 0, T2= 7.537e-03,M1= M1, M2= M2,a =-238, b =14466, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T),start=list(M1= 0, M2= 5.908e-04),algorithm="port")
summary(fitdots)#
#M1 -0.0010192  0.0001443  -7.061 2.03e-08
#M2  0.0036751  0.0004344   8.460 2.87e-10


fitdots<-nls(obs~ Orgfit(T1= T1, T2=T2,M1=-0.001019, M2= 0.00367,a =-238, b =14466, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T),start=list(T1= 0, T2= 7.537e-03),algorithm="port")
summary(fitdots)#
#T1 0.0006554  0.0010280   0.637   0.5276
#T2 0.0060751  0.0031170   1.949   0.0587

fitdots<-nls(obs~ Orgfit(T1= T1, T2= T2,M1= M1, M2= M2,a =-238, b =14466, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T),start=list(T1= 0, T2= 7.537e-03,M1= 0, M2= 5.908e-04),algorithm="port")
summary(fitdots)#
#T1  0.0006554  0.0010550   0.621   0.5384
#T2  0.0060751  0.0031989   1.899   0.0656
#M1 -0.0010192  0.0001267  -8.042 1.49e-09
#M2  0.0036751  0.0003815   9.634 1.67e-11



##### resultat des fit x 3 avec cte cte cte

# Sur 20° et 30° 






out1<-Org(M1=-0.001019, M2= 0.00367  ,T1= 0.00065 , T2= 6.0e-03 ,a =-238, b =14466, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don1$pH, Te = don1$T)
obsMa <- don1$Malate
rmse <- rmse(out1[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.105
obsTa <- don1$Tartrate
rmse <- rmse(out1[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.085



out2<-Org(M1=-0.001019, M2= 0.00367  ,T1= 0.00065 , T2= 6.0e-03 ,a =-238, b =14466, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don2$pH, Te = don2$T)
#malpred2 <- out2[,2]
out3<-Org(M1=-0.001019, M2= 0.00367  ,T1= 0.00065 , T2= 6.0e-03 ,a =-238, b =14466, n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5, pHvac = don3$pH, Te = don3$T)



malobs <- c(don2$Malate, don3$Malate)
tarobs <- c(don2$Tartrate , don3$Tartrate)

malpred <- c(out2[,2],out3[,2])
tarpred <- c(out2[,3],out3[,3])

Mal <- c(malobs , malpred)
Tar <- c(tarobs , tarpred)

origin <-rep("observed",length(malobs))
origin2 <- rep("predicted",length(malpred))
sfac <- c(origin, origin2)

Temp <- c(rep("20°C",length(don2$Malate)),rep("30°C",length(don3$Malate)))
Temperature <- c(Temp,Temp)

pH <- c(don2$pH,don2$pH,don2$pH,don2$pH)
time <- c(don2$Mois,don2$Mois,don2$Mois,don2$Mois)
gin <- data.frame (pH,Temperature,sfac,Mal,Tar,time)
M1 <- ggplot(data=gin, aes(time,Mal, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Malate mg/g")+theme(legend.title = element_blank()) + theme(legend.position = c(0.9, 0.7))+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

T1 <- ggplot(data=gin, aes(time,Tar, colour = sfac))+geom_point()+theme_classic()+facet_wrap(~Temperature)+ ylab("Tartrate mg/g")+theme(legend.position='none')+theme(strip.background = element_rect(colour="white", fill="white", size=1, linetype="solid"))

#write.table(gin , "testtorrmse.csv" , row.names=F,sep=",",dec=".")




### RRMSE SUR 20°
obsMa <- don2$Malate
rmse <- rmse(out2[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.1


obsTa <- don2$Tartrate
rmse <- rmse(out2[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.07


### RRMSE SUR 30°
obsMa <- don3$Malate
rmse <- rmse(out3[,2],obsMa)
m <- mean(obsMa)
rrmse <- rmse /m
rrmse #0.09


obsTa <- don3$Tartrate
rmse <- rmse(out3[,3],obsTa)
m <- mean(obsTa)
rrmse <- rmse /m
rrmse #0.09


plot_grid(M1,T1,M3,T3)

plot_grid(M1,T1,M3,T3, labels=c("A", "B","C","D"), ncol = 2, nrow =2 )#### figure 6 sans légende 


##### /!\ sur le rapport : cardinal et PN ont été inversé dans la légende 










########Figure 9 

cmal<-function(a, b , n0, alpha , bbeta , pHcyt ,M1,M2 , i , pHvac , KK1, KK2 , Te)
{
  a2Malcyt <- M1*pHvac+M2
  R<-8.314 ; FF<-96500; Te <- Te+273.15
  DGATP=a*Te+b
  coeffa2vac<- 10^(-0.509*4*((i^0.5/(1+i^0.5)-0.3*i)))
  DY<-(-DGATP)/(FF*(n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)))+((R*Te)/FF)*log(10)*(pHvac-pHcyt)
  cMalvac<-(1/coeffa2vac)* a2Malcyt *  exp((2*FF*DY)/(R*Te)) *  (KK1*KK2+KK1*10^(-pHvac)+10^(-2*pHvac))/(KK1*KK2)
  c(DY,cMalvac)  # sortie de la fonction
}

ctar <- function(a,b,n0, alpha, bbeta, pHcyt, T1,T2,i,pHvac, K1,K2,Te)
{
  a2Tarcyt <- T1*pHvac+T2
  R<- 8.314; FF <- 96500 ; Te <- Te + 273.15
  DGATP = a*Te+b
  coeffa2vac<- 10^(-0.509*4*((i^0.5/(1+i^0.5)-0.3*i)))
  DY<-(-DGATP)/(FF*(n0+alpha*(pHvac-7)+bbeta*10^(pHcyt-7)))+((R*Te)/FF)*log(10)*(pHvac-pHcyt)
  cTarvac<-(1/coeffa2vac)*a2Tarcyt *  exp((2*FF*DY)/(R*Te)) *  (K1*K2+K1*10^(-pHvac)+10^(-2*pHvac))/(K1*K2)
  cTarvac<-cTarvac
  c(cTarvac)  # sortie de la fonction
}

acid <- function(Mal = NULL , Ta = NULL , A,B,to,jour,Jajust, Te , param_model = NULL,a,b,M1,M2,T1,T2,A1,A2) 
{
  
  DGATP = a*Te+b
  
  
  j<-jour-Jajust
  K1<- A*(exp(-j/to))+B
  K <- K1/39.1
  Ta.glob <<- NA
  Mal.glob <<- NA
  DPsi.glob <<- NA
  
  Km1 <- 10^(-3.40) ; Km2 <- 10^(-5.11)                     # malic(-4.34),K2=10^(-2.98)
  Kt1 <- 10^(-2.98) ; Kt2 <- 10^(-4.34)
  dslnex <- function (x)
  {
    
    pMal2 <- function(x, Km1, Km2) { # tMal2 is the malate 2- proportion: [Mal2-]/[Maltotal] so no unity
      h <- 10^(-x[2]) ; tMal2 <- Km1*Km2/(h^2*(1+Km1/h+Km1*Km2/h^2))
      tMal2}
    pMal1 <-  function(x, Km1, Km2) {
      h  <- 10^(-x[2]) ; tMal1 <- Km1/(h*(1+Km1/h+Km1*Km2/h^2))
      tMal1}
    pMal0 <- function(x, Km1, Km2) {
      h <- 10^(-x[2]) ; tMal0 <- 1/(1*(1+Km1/h+Km1*Km2/h^2))
      tMal0}
    #Tartaric acid 
    pTa2 <- function(x, Kt1, Kt2) { # tTa2 is the tartrate 2- proportion: [Ta2-]/[Tatotal] so no unity
      h <- 10^(-x[2]) ; tTa2 <- Kt1*Kt2/(h^2*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa2}
    pTa1 <-  function(x, Kt1, Kt2) {
      h  <- 10^(-x[2]) ; tTa1 <- Kt1/(h*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa1}
    pTa0 <- function(x, Kt1, Kt2) {
      h <- 10^(-x[2]) ; tTa0 <- 1/(1*(1+Kt1/h+Kt1*Kt2/h^2))
      tTa0}
    # activity coefficients
    a0 <- 1                                                 
    a1 <- 10^(-0.509*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )     
    a2 <- 10^(-0.509*4*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )   
    #  a3 <- 10^(-0.509*9*( ( x[1]^0.5/(1+x[1]^0.5))-(0.3*x[1]) ) )
    # apparent acidity constant
    Ka1Mal <- Km1*(a0/a1) ; Ka2Mal <- Km2*(a1/a2)                          # malic
    Ka1Ta <- Kt1*(a0/a1) ; Ka2Ta <- Kt2*(a1/a2)                        
    # compute Malate and DPsi with the malate function
    if(is.null(Mal)&is.null(Ta))
    {
      MalDpsi <- cmal( a=a,b=b,n0 = param_model$n0, pHvac=x[2], i=x[1], alpha = param_model$alpha , bbeta = param_model$bbeta , pHcyt = param_model$pHcyt, M1=M1,M2=M2, KK1=Ka1Mal, KK2=Ka2Mal , Te = Te)
      Ta <- ctar ( a=a,b=b,n0 = param_model$n0, pHvac=x[2], i=x[1], alpha = param_model$alpha , bbeta = param_model$bbeta , pHcyt = param_model$pHcyt, T1=T1,T2=T2, K1=Ka1Ta, K2=Ka2Ta , Te = Te)
      
      # store the values in the global variables
      DPsi.glob <<- MalDpsi[1]
      Mal <- MalDpsi[2]
      Mal.glob <<- Mal
      Ta.glob <<- Ta
    }else{
      Mal.glob <<- Mal
      Ta.glob <<- Ta
    }
    pEMal2 <- pMal2(x,Ka1Mal,Ka2Mal) ; EMal2 <- Mal*pEMal2
    pEMal1 <- pMal1(x,Ka1Mal,Ka2Mal) ; EMal1 <- Mal*pEMal1
    pEMal0 <- pMal0(x,Ka1Mal,Ka2Mal) ; EMal0 <- Mal*pEMal0
    
    pETa2 <- pTa2(x,Ka1Ta,Ka2Ta) ; ETa2 <- Ta*pETa2
    pETa1 <- pTa1(x,Ka1Ta,Ka2Ta) ; ETa1 <- Ta*pETa1
    pETa0 <- pTa0(x,Ka1Ta,Ka2Ta) ; ETa0 <- Ta*pETa0
    
    
    mu <-  0.5*(4*( ETa2 + EMal2) + EMal1 + ETa1 + 10^(-x[2]) + 10^(x[2]-14) + K + 4 *(A1*K+A2))
    
    AnionsSum <- Ta*(2*pETa2+pETa1) + Mal*(2*pEMal2+pEMal1)+ 10^(x[2] - 14)
    
    y <- numeric(2)
    y[1] <- mu-x[1]                                     # F1
    #y[2] <- AnionsSum - (10^(-x[2])+ K ) #+ (2*Mg)+ (2*Ca))          # F2
    #test : ajout d'une constante correspondant ?  la somme Mg + Ca en mol/L
    y[2] <- AnionsSum - (10^(-x[2])+ K + 2*(A1*K+A2)) #+ (2*Mg)+ (2*Ca))          # F2
    
    
    # y[1] = 0; y[2] = 0 #(L)
    # write results on a file
    data.out <- data.frame(ETa1, ETa2, EMal2 , EMal1 , K,Ta)
    names(data.out) <- c("ETa1" , "ETa2" , "EMal2" , "EMal1" , "K" ,"Ta")
    write.table(data.out , "out_ph.csv" , row.names=F,sep=",",dec=".")
    #write.table(res.f,"PN33.csv",row.names=F,sep=",",dec=".")
    data.out2 <- data.frame(x[2], x[1], y[2] , y[1] , K)
    names(data.out2) <- c("pH" , "I" , "=0" , " =0" , "K" )
    write.table(data.out2 , "out_ph2.csv" , row.names=F,sep=",",dec=".")
    
    return(y)
  }
  xstart <-c(0.001 ,2.5)           # initial values  ____ En suppimant la ligne (L) (juste au dessus), le model tourne : donne une valeur de pH peu importe la valeur d'entrée 
  res <- nleqslv(xstart, dslnex, control=list(btol=.01))      # solve the system
  
  # use the estimated pH to compute the global variables pH and mu
  pH <- res$x[2]
  mu <- res$x[1]
  # run the dslnex to have the last and correct values of Mal and Dpsi
  dslnex(as.numeric(res$x))
  # the function results are malate, DPsi , pH and mu
  return(data.frame(malate = Mal.glob ,tartrate=Ta.glob, DPsi = DPsi.glob , pH = pH , mu = mu,Kcalc = K))
}

run_mal <- function(param_model_run , input,a,b,M1,M2,T1,T2,A1,A2, A,B,to,Jajust)
{
  vb <- rep(NA , nrow(input))
  res <- data.frame(Age_h = vb , malate = vb , tartrate = vb , DPsi = vb , pH = vb , mu = vb,Kcalc = vb)
  for(i in 1:nrow(input))
  {
    Te.in <- input$T[i]
    #Ta.in <- input$Tartrate[i]        #Cit.in <- input$Cit[i]; Pho.in <- input$Pho[i]; Glu.in <- input$Glu[i]
    # K.in <- input$K[i]
    jour.in <- input$Age_h[i]
    # ph.in<-input$pH[i] #; Mg.in <- input$Mg[i] ; Ca.in <- input$Ca[i]
    pred.mal <- as.numeric(acid(
      Te = Te.in ,jour = jour.in, param_model = param_model_run,a=a,b=b,M1=M1,M2=M2,T1=T1,T2=T2,A1=A1,A2=A2,A=A,B=B,to=to,Jajust=Jajust))
    res[i , ] <- c(input$Age_h[i] , pred.mal)
  }
  #
  return(res)
  #return(res$pH)
  #return(c(res$malate,res$tartrate,res$pH))
  # return(res$tartrate)
  #return(res$malate)
}











# Présentation des paramètres accessoire 
# Objectif : comparer DPSI, I, DGATP, org acid dans le cytosl entre les 4 différentes prédictions


imputg=Grenache7.2

parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imputg$Tartrate/150 ###mol/L
K2=imputg$K./(39.*1000) #mol/L
Tem=imputg$T   
Mal2=imputg$Malate/134


don14=data.frame(T=imputg$T,pH=imputg$pH, Age_h=imputg$jaa,Tartrate=Tartrate2,K=K2,Malate=Mal2)
resgre=run_mal(A=-3, B = 2.2, to =37,Jajust=0,param_model_run  =parms, input=don14,a=-372,b=53466,M1=-0.000448,M2=0.00166,A1=0  ,A2=0.003,T1=0.00372,T2=-0.00387)
str(resgre)






DB1<-Sangiovese12
DS1.11=DB1
imputs=DS1.11#[DS1.11$traitement=="12L",]



parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imputs$Tartrate/150 ###mol/L
K2=imputs$K./(39.*1000) #mol/L
Tem=imputs$T   
Mal2=imputs$Malate/134


don14=data.frame(T=imputs$T,pH=imputs$pH, Age_h=imputs$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)
resSa=run_mal(A=-1.2,B=2.3,to=110,Jajust=193,param_model_run  =parms, input=don14,a=-396,b=61360,M1=-  2.09e-04,M2=0.00097,A1=0 ,A2=0.004,T1=0.0024,T2= -1.42e-04)
str(resSa)



DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="K120",]

imput12=DS1.122

parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput12$Tartrate/150 ###mol/L
K2=imput12$K./39 #mol/L
Tem=imput12$T   
Mal2=imput12$Malate/134


don14=data.frame(T=imput12$T,pH=imput12$pH, Age_h=imput12$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)
resK12=run_mal(A=-1.5,B=2.3,to=40,Jajust=193,param_model_run  =parms, input=don14,a=-298,b=29815,M1=-0.000265,M2=0.00111,A1=0  ,A2=0.008,T1=0.0026,T2=-0.0038)
str(resK12)


DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="K60",]

imput6=DS1.122

parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput6$Tartrate/150 ###mol/L
K2=imput6$K./39 #mol/L
Tem=imput6$T   
Mal2=imput6$Malate/134


don14=data.frame(T=imput6$T,pH=imput6$pH, Age_h=imput6$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)
resK6=run_mal(A=-1.5,B=2.3,to=40,Jajust=193,param_model_run  =parms, input=don14,a=-298,b=29815,M1=-0.000265,M2=0.00111,A1=0  ,A2=0.008,T1=0.0026,T2=-0.0038)
str(resK6)



DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
DS1.12=DS1[DS1$Localisation =="LAB",]
DS1.122=DS1.12[DS1.12$traitement=="Temoin K0",]

imput=DS1.122

parms=data.frame(n0=4,alpha=0.3,bbeta=-0.12,pHcyt=7.5)  

Tartrate2=imput$Tartrate/150 ###mol/L
K2=imput$K./39 #mol/L
Tem=imput$T   
Mal2=imput$Malate/134


don14=data.frame(T=imput$T,pH=imput$pH, Age_h=imput$Jour,Tartrate=Tartrate2,K=K2,Malate=Mal2)
resK0=run_mal(A=-1.26,B=1.8,to=120,Jajust=193,param_model_run  =parms, input=don14,a=-298,b=29815,M1=-0.0003,M2=0.00117,A1=0  ,A2=0.008,T1=0.00245,T2=-0.00423)
str(resK0)





CDGATP <- function(TT, a,b){a*(TT+273.15) + b}
DGATPCS <- CDGATP (TT=imput12$T, a = -298, b = 29815)
DGATPG <- CDGATP (TT=imputg$T, a = -372, b = 53466)
DGATPS <- CDGATP (TT=imputs$T, a = -396, b = 61360)

plot(imputg$T,DGATPG, ylim = c (-60000, -50000))
points(imputs$T, DGATPS, col = 2)
points(imput12$T, DGATPCS, col = 3)


#DGATPCS <- CDGATP (TT=imput$T, a = -298, b = 29815)
#DGATPG <- CDGATP (TT=imput$T, a = -372, b = 53466)
#DGATPS <- CDGATP (TT=imput$T, a = -396, b = 61360)#

#plot(imput$T,DGATPG, ylim = c (-60000, -50000))
#points(imput$T, DGATPS, col = 2)
#points(imput$T, DGATPCS, col = 3)


plot(imput$T, DGATPS, col = 2)

CMalcyt <- function(pHvac, M1,M2){M1*pHvac + M2}
CMalcytK0 <- CMalcyt(pHvac=resK0$pH, M1 = -0.0003, M2 = 0.00117)
CMalcytK12 <- CMalcyt(pHvac = resK12$pH, M1 = -0.000265, M2 = 0.00111)
CMalcytGre <- CMalcyt(pHvac = resgre$pH, M1 = -0.000448, M2 = 0.00166)
CMalcytSa <- CMalcyt(pHvac = resSa$pH, M1 = -0.000209, M2 = 0.00097)

plot(resgre$pH,CMalcytGre, ylim= c(0, 0.001))
points(resSa$pH, CMalcytSa, col = 2)
points(resK12$pH, CMalcytK12, col = 3)
points(resK0$pH, CMalcytK0, col = 6)



CMalcytK0.2 <- CMalcyt(pHvac=resK0$pH, M1 = -0.0003, M2 = 0.00117)
CMalcytK12.2 <- CMalcyt(pHvac = resK0$pH, M1 = -0.000265, M2 = 0.00111)
CMalcytGre.2 <- CMalcyt(pHvac = resK0$pH, M1 = -0.000448, M2 = 0.00166)
CMalcytSa.2 <- CMalcyt(pHvac = resK0$pH, M1 = -0.000209, M2 = 0.00097)

plot(resK0$pH,CMalcytGre.2, ylim= c(0, 0.001))
points(resK0$pH, CMalcytSa.2, col = 2)
points(resK0$pH, CMalcytK12.2, col = 3)
points(resK0$pH, CMalcytK0.2, col = 6)



plot(resK0$pH, CMalcytK0, col = 6)

CTacyt <- function(pHvac, T1,T2){T1*pHvac + T2}
CTacytK0 <- CTacyt(pHvac=resK0$pH, T1 = 0.00245, T2 = -0.00423)
CTacytK12 <- CTacyt(pHvac=resK12$pH, T1 = 0.0026, T2 = -0.0038)
CTacytGre <- CTacyt(pHvac=resgre$pH, T1 = 0.00372, T2 = -0.00387)
CTacytSa <- CTacyt(pHvac=resSa$pH, T1 = 0.0024, T2 = -0.000142)

plot(resgre$pH,CTacytGre, ylim = c(0.001, 0.013))
points(resSa$pH, CTacytSa, col = 2)
points(resK12$pH, CTacytK12, col = 3)
points(resK0$pH, CTacytK0, col = 6)



plot(resgre$pH,resgre$DPsi, xlim = c(2.2,3.7), ylim = c(-0.042, 0))
points(resSa$pH,resSa$DPsi, col = 2)
points(resK12$pH,resK12$DPsi, col = 3, pch=3)
points(resK6$pH,resK6$DPsi, col = 4)
points(resK0$pH,resK0$DPsi, col = 6)


plot(resgre$pH,resgre$mu, xlim = c(2.2,3.7), ylim = c(0.02, 0.1) )
points(resSa$pH,resSa$mu, col = 2)
points(resK12$pH,resK12$mu, col = 3, pch=3)
points(resK6$pH,resK6$mu, col = 4)
points(resK0$pH,resK0$mu, col = 6)


Tscale = c(imputg$T, imputs$T,imput12$T,imput$T)
pHscale = c(resgre$pH, resSa$pH, resK12$pH, resK0$pH)
DGATP = c(DGATPG,DGATPS,DGATPCS,DGATPCS)/1000
MALCYT = c(CMalcytGre,CMalcytSa,CMalcytK12,CMalcytK0)*1000
TACYT = c(CTacytGre,CTacytSa,CTacytK12,CTacytK0)*1000
MU = c(resgre$mu,resSa$mu,resK12$mu, resK0$mu)
DPSI = c (resgre$DPsi, resSa$DPsi,resK12$DPsi, resK0$DPsi)
San = rep("Sangiovese", length(resSa$pH))
gre = rep("Grenache", length(resgre$pH))
cs12 = rep("Cabernet Sauvignon K120", length(resK12$pH))
cs0 = rep("Cabernet Sauvignon K0", length(resK0$pH))

cepage = c(gre,San,cs12,cs0)
don = data.frame(Tscale, pHscale, DGATP,MALCYT, TACYT,MU,DPSI,cepage)



tg <- ggplot(data=don, aes(Tscale,DGATP, colour = cepage))+ geom_point()+ theme(legend.position='none')+xlab("T °C")+ylab("DGATP kJ/mol")
pm <- ggplot(data=don, aes(pHscale,MALCYT, colour = cepage))+ geom_point()+ theme(legend.position='none')+xlab("pH")+ylab("[Mal]cyt mM")
pt <- ggplot(data=don, aes(pHscale,TACYT, colour = cepage))+ geom_point()+ theme(legend.position='none')+xlab("pH")+ylab("[Ta]cyt mM")
pM <- ggplot(data=don, aes(pHscale,MU, colour = cepage))+ geom_point()+ theme(legend.position='none')+xlab("pH")+ylab("Ionic strength M")
pD <- ggplot(data=don, aes(pHscale,DPSI, colour = cepage))+ geom_point()+ theme(legend.title = element_blank(),legend.position = c(1.2, 0.4))+xlab("pH")+ylab("Electromotive force V")
plot_grid(tg,pm,pt,pM,pD,  ncol = 2, nrow = 3)











##### visualisation de la calibration : comparaison des paramètres estimés par data sets
##### utilisé dans le diapo de la soutenance 


imput = Soyer.23.01...copie


C_DGATP<-function(a,b,TT){a*(TT+273) + b }


DGgre <- C_DGATP(a=-372, b = 53466, TT=imput$T)
DGsa<- C_DGATP(a=-396, b =61360, TT=imput$T)
DGpn<- C_DGATP(a =-229, b = 11628.7, TT=imput$T)
DGcar<- C_DGATP(a =-238, b =14466, TT=imput$T)
DGcs<- C_DGATP(a=-298, b = 29815, TT=imput$T)

DGATP <- c(DGgre,DGsa, DGpn, DGcar, DGcs)
Genotype <- c(rep("Grenache", length(DGgre)),rep("Sangiovese", length(DGgre)),rep("Pinot Noir", length(DGgre)),rep("Cardinal", length(DGgre)),rep("Cabernet Sauvignon",length(DGgre)))

Temperature <- c(imput$T,imput$T,imput$T,imput$T,imput$T)

don <- data.frame(Genotype,Temperature,DGATP)

ggplot(data=don, aes(Temperature, DGATP, colour = Genotype))+geom_point()+ ylab("ΔGATP J/mol")




C_Malcyt <- function(M1,M2,pHvac){M1*pHvac + M2}
C_Tacyt <- function(T1,T2,pHvac){T1*pHvac + T2}

malgre<-C_Malcyt(M1=-0.00045,M2= 0.0018, pHvac = imput$pH)
malsa<-C_Malcyt(M1= -0.0002, M2= 0.00097, pHvac = imput$pH)
malpn<-C_Malcyt(M1 = -0.0007557,  M2 = 0.0032, pHvac = imput$pH)
malcar<-C_Malcyt(M1=-0.001019, M2= 0.00367, pHvac = imput$pH )
malcs<-C_Malcyt(M1=-0.000265, M2 = 0.00111, pHvac = imput$pH)

tagre<-C_Tacyt(T1= 0.0034, T2 = -0.0038, pHvac = imput$pH)
tasa<-C_Tacyt(T1 = 0.0024, T2= 0.000068, pHvac = imput$pH)
tapn<-C_Tacyt(T1 = 0.00211,T2 = 0.0043, pHvac = imput$pH)
tacar<-C_Tacyt(T1= 0.00065 , T2= 6.0e-03, pHvac = imput$pH)
tacs<-C_Tacyt(T1 = 0.0026, T2 = -0.0038, pHvac = imput$pH)

pH <- c(imput$pH,imput$pH,imput$pH,imput$pH,imput$pH)
Malate <- c(malgre,malsa,malpn,malcar,malcs)*1000
Tartrate <- c(tagre,tasa,tapn,tacar,tacs)*1000

don <- data.frame (pH,Malate,Tartrate,Genotype,DGATP,Temperature)
m<-ggplot(data=don, aes(pH,Malate, colour=Genotype))+geom_point()+theme(legend.position='none')+ylab("[Mal]cyt (mM)")
g<-ggplot(data=don, aes(Temperature, DGATP, colour = Genotype))+geom_point()+ ylab("ΔGATP (J/mol)")
t<-ggplot(data=don, aes(pH,Tartrate, colour=Genotype))+geom_point()+theme(legend.position='none')+ylab("[Ta]cyt (mM)")

plot_grid(m,t,g, ncol = 1, nrow = 3)









#### Evolution of 1/m(h) and 1/t(h) (Kmal, Ktar)

K = function(KK1,KK2,pHvac){(KK1*KK2+KK1*10^(-pHvac)+10^(-2*pHvac))/(KK1*KK2)}


# Mal : K2=10^(-5.11),K1=10^(-3.4), tar :  K11= 10^(-2.98),K22=10^(-4.34)


Kmal <- K(KK1=10^(-3.4),KK2=10^(-5.11),pHvac=imput$pH)
Ktar <- K(KK1= 10^(-2.98),KK2=10^(-4.34), pHvac=imput$pH)


jour <- c(imput$Jour, imput$Jour)
K2<- c(Kmal,Ktar)
acorg <- c(rep("Malate", length(Kmal)),rep("Tartrate", length(Ktar)))
pH <- c(imput$pH, imput$pH)

dt <- data.frame(pH,acorg, K2,jour)

ggplot(data=dt, aes(pH, K2, colour= acorg))+ geom_point()










DS<-Soyer.23.01...copie

DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
don=DS1[DS1$Localisation =="LAB",]

k<-ggplot(data=don, aes(Jour, K., colour=traitement))+geom_point()+xlab("Day of the year")+ylab("[K+] mg/g")+theme(legend.position='none')
t<-ggplot(data=don, aes(Jour, T, colour=traitement))+geom_point()+ylab("Temperature °C")+xlab("Day of the year")

plot_grid(k,t)



