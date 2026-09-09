###fittage Kliewer avec Lobit
#### Pour les 2 cépages, 2 conditions de temperature : 20 et 30 pour 2 conditions d'éclairages : HL et LL
## Donc 8 conditions différentes C1-C4 et PN1-PN4



####le fichier est celui de Kliewer 
wd="C:\\Users\\zhanwu\\Dropbox\\2018_M2_Benjamin\\Stage M2 BTT\\Acid Model\\Plot Kliewer\\Fit" #Zhanwu  
              setwd(wd)
              library(ggplot2)
Kliewer.29.01=read.csv("Kliewer 29-01_Dai.csv",header=T,sep=",",dec=".")#Zhanwu

###C1  on a le malate pour les conditions : Cardinal, HL à 30     

DKl<-Kliewer.29.01_Dai
DKlC1=DKl[DKl$cepage!="pinot noir",]
DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
DKlC1.11=DKlC1.1[DKlC1.1$T!="20",]
ggplot(data=DKlC1.11, aes(Mois, Malate))+geom_point() 

MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
      n=no+A*(PH-7)+B*10^(pHcyt-7)
       DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
       h=10^(-PH)
       K=(K1*K2+h*K1+h^2)/(K1*K2)
       Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
       
         #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
         Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
      
           Mal}
 mal.fruit=DKlC1.11$Malate
 ph=DKlC1.11$pH
 
   par(mfrow=c(1,1))
  
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
      #abline(0,1,lwd=2,col=2)
    fitdots<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.3,Malcyt=0.5),start=list(DGATP=-56000),algorithm="port")
       plot(DKlC1.11$pH,DKlC1.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, HL, 30°")
       points(ph,fitted(fitdots),col=4,pch=3)
      summary(fitdots)
      rmse<-rmse(DKlC1.11$Malate,fitted(fitdots))
      
      m1<-mean(mal.fruit) 
      
      rrmse<-rmse/m1 
      rrmse
         
  ###Fit forcé 
      DKl<-Kliewer.29.01_Dai
      DKlC1=DKl[DKl$cepage!="pinot noir",]
      DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
      DKlC1.11=DKlC1.1[DKlC1.1$T!="20",]
     # ggplot(data=DKlC1.11, aes(Mois, Malate))+geom_point() 
      
      MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.005,A=0.3,B=-0.12,no=4){
        n=no+A*(PH-7)+B*10^(pHcyt-7)
        DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
        h=10^(-PH)
        K=(K1*K2+h*K1+h^2)/(K1*K2)
        Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
        
        #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
        Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
        
        Mal}
      mal.fruit=DKlC1.11$Malate
      ph=DKlC1.11$pH
      
      par(mfrow=c(1,2))
      
      fitdots<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.3,Malcyt=0.00005),start=list(DGATP=-90000),algorithm="port")
      plot(DKlC1.11$pH,DKlC1.11$Malate,col=2,xlab="pH", ylab="Malate", main="Cardinal HL 30")
      points(ph,fitted(fitdots),col=4,pch=3)
      plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
      abline(0,1,lwd=2,col=2)
     library(Metrics)
       rmse(DKlC1.11$Malate,fitted(fitdots))
      
      summary(fitdots)
      
   ####evolution du fit forcé : on rassemble HL et LL pour avoir une estimation du Malcyt par Temperature     
    
      ####30°c
        DKl<-Kliewer.29.01_Dai
      DKlC1=DKl[DKl$cepage!="pinot noir",]
      #DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
      DKlC1.30=DKlC1[DKlC1$T!="20",]
      # ggplot(data=DKlC1.11, aes(Mois, Malate))+geom_point() 
      
      MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=Malcyt,A=0.3,B=-0.12,no=4){
        n=no+A*(PH-7)+B*10^(pHcyt-7)
        DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
        h=10^(-PH)
        K=(K1*K2+h*K1+h^2)/(K1*K2)
        Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
        
        #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
        Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
        
        Mal}
      mal.fruit=DKlC1.30$Malate
      ph=DKlC1.30$pH
      par(mfrow=c(1,1))
      plot(DKlC1.30$pH,DKlC1.30$Malate,col=2,xlab="pH", ylab="[Malate](mg/g)", main="Cardinal 30 HL&LL",ylim = c(1,9))
      
     fitdots1<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=2),start=list(DGATP=-40000),algorithm="port")
       points(ph,fitted(fitdots1),col=4,pch=2)
       fitdots2<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=1),start=list(DGATP=-50000),algorithm="port")
       points(ph,fitted(fitdots2),col=1,pch=3)
       fitdots3<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.5),start=list(DGATP=-60000),algorithm="port")
       points(ph,fitted(fitdots3),col=3,pch=4)
       fitdots4<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.05),start=list(DGATP=-70000),algorithm="port")
       points(ph,fitted(fitdots4),col=5,pch=5)
       fitdots5<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.005),start=list(DGATP=-80000),algorithm="port")
       points(ph,fitted(fitdots5),col=6,pch=6)
       fitdots6<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.0005),start=list(DGATP=-90000),algorithm="port")
       points(ph,fitted(fitdots6),col=7, pch=7)
       legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=2mM, DGATP=-48 kJ/mol", "[Mal]cyt=1mM,DGATP=-48 kJ/mol", "[Mal]cyt=0,5mM,DGATP=-53,2 kJ/mol","[Mal]cyt=0,05mM,DGATP=-60,9 kJ/mol", "[Mal]cyt=0,005mM,DGATP=-68,5 kJ/mol", "[Mal]cyt=0,0005mM,DGATP=-76,2 kJ/mol"), pch=c(1,2,3,4,5,6,7),col=c(2,4,1,3,5,6,7),text.col = par("col"),xjust = 1)
       #legend("topright",text.col = par("col"),cex=0.6,legend = c("Observed","[Mal]cyt=2mM, DGATP=-48 kJ/mol,RRMSE=0,26", "[Mal]cyt=1mM,DGATP=-48 kJ/mol,RRMSE=0,26", "[Mal]cyt=0,5mM,DGATP=-53,2 kJ/mol,RRMSE=0,24","[Mal]cyt=0,05mM,DGATP=-60,9 kJ/mol,RRMSE=0,21", "[Mal]cyt=0,005mM,DGATP=-68,5 kJ/mol,RRMSE=0,18", "[Mal]cyt=0,0005mM,DGATP=-76,2 kJ/mol,RRMSE=0,15"), pch=c(1,2,3,4,5,6,7),col=c(2,4,1,3,5,6,7),xjust = 0)
       summary(fitdots1)
       summary(fitdots2) 
       summary(fitdots3)
       summary(fitdots4)
       summary(fitdots5)
       summary(fitdots6)
       
       
       m1<-mean(mal.fruit) 
       rmse1<-rmse(DKlC1.30$Malate,fitted(fitdots1)) 
       rmse2<-rmse(DKlC1.30$Malate,fitted(fitdots2)) 
       rmse3<-rmse(DKlC1.30$Malate,fitted(fitdots3)) 
       rmse4<-rmse(DKlC1.30$Malate,fitted(fitdots4)) 
      rmse5<-rmse(DKlC1.30$Malate,fitted(fitdots5)) 
       rmse6<-rmse(DKlC1.30$Malate,fitted(fitdots6)) 
       rrmse1<-rmse1/m1 
       rrmse2<-rmse2/m1
       rrmse3<-rmse3/m1
       rrmse4<-rmse4/m1
       rrmse5<-rmse5/m1
       rrmse6<-rmse6/m1
       
       rrmse1
       rrmse2
       rrmse3
       rrmse4
       rrmse5
       rrmse6
       
       
       ###20°C
       DKl<-Kliewer.29.01_Dai
       DKlC1=DKl[DKl$cepage!="pinot noir",]
      # DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
       DKlC1.20=DKlC1[DKlC1$T!="30",]
       # ggplot(data=DKlC1.11, aes(Mois, Malate))+geom_point() 
       
       MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=Malcyt,A=0.3,B=-0.12,no=4){
         n=no+A*(PH-7)+B*10^(pHcyt-7)
         DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
         h=10^(-PH)
         K=(K1*K2+h*K1+h^2)/(K1*K2)
         Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
         
         #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
         Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
         
         Mal}
       mal.fruit=DKlC1.20$Malate
       ph=DKlC1.20$pH
       
       par(mfrow=c(1,1))
       plot(DKlC1.20$pH,DKlC1.20$Malate,col=2,xlab="pH", ylab="[Malate](mg/g)", main="Cardinal 20 HL&LL",ylim=c(3,9))
       
       fitdots11<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=2),start=list(DGATP=-40000),algorithm="port")
       points(ph,fitted(fitdots1),col=4,pch=2)
       fitdots22<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=1),start=list(DGATP=-40000),algorithm="port")
       points(ph,fitted(fitdots2),col=1,pch=3)
       fitdots33<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.5),start=list(DGATP=-60000),algorithm="port")
       points(ph,fitted(fitdots3),col=3,pch=4)
       fitdots44<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.05),start=list(DGATP=-70000),algorithm="port")
       points(ph,fitted(fitdots4),col=5,pch=5)
       fitdots55<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.005),start=list(DGATP=-80000),algorithm="port")
       points(ph,fitted(fitdots5),col=6,pch=6)
       fitdots66<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.0005),start=list(DGATP=-90000),algorithm="port")
       points(ph,fitted(fitdots6),col=7, pch=7)
       legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=2mM, DGATP=-47,1 kJ/mol", "[Mal]cyt=1mM,DGATP=-49,3 kJ/mol", "[Mal]cyt=0,5mM,DGATP=-51,5 kJ/mol","[Mal]cyt=0,05mM,DGATP=-58,8 kJ/mol", "[Mal]cyt=0,005mM,DGATP=-66,1 kJ/mol", "[Mal]cyt=0,0005mM,DGATP=-73,4 kJ/mol"), pch=c(1,2,3,4,5,6,7),col=c(2,4,1,3,5,6,7),text.col = par("col"),xjust = 1)
       #legend("topright",text.col = par("col"),cex=0.6,legend = c("Observed","[Mal]cyt=2mM, DGATP=-48 kJ/mol,RRMSE=0,26", "[Mal]cyt=1mM,DGATP=-48 kJ/mol,RRMSE=0,26", "[Mal]cyt=0,5mM,DGATP=-53,2 kJ/mol,RRMSE=0,24","[Mal]cyt=0,05mM,DGATP=-60,9 kJ/mol,RRMSE=0,21", "[Mal]cyt=0,005mM,DGATP=-68,5 kJ/mol,RRMSE=0,18", "[Mal]cyt=0,0005mM,DGATP=-76,2 kJ/mol,RRMSE=0,15"), pch=c(1,2,3,4,5,6,7),col=c(2,4,1,3,5,6,7),xjust = 0)
       summary(fitdots11)
       summary(fitdots22) 
       summary(fitdots33)
       summary(fitdots44)
       summary(fitdots55)
       summary(fitdots66)
       
       
       m1<-mean(mal.fruit) 
       rmse11<-rmse(DKlC1.20$Malate,fitted(fitdots11)) 
       rmse22<-rmse(DKlC1.20$Malate,fitted(fitdots22)) 
       rmse33<-rmse(DKlC1.20$Malate,fitted(fitdots33)) 
       rmse44<-rmse(DKlC1.20$Malate,fitted(fitdots44)) 
       rmse55<-rmse(DKlC1.20$Malate,fitted(fitdots55)) 
       rmse66<-rmse(DKlC1.20$Malate,fitted(fitdots66)) 
       rrmse11<-rmse11/m1 
       rrmse22<-rmse22/m1
       rrmse33<-rmse33/m1
       rrmse44<-rmse44/m1
       rrmse55<-rmse55/m1
       rrmse66<-rmse66/m1
       rrmse11
       rrmse22
       rrmse33
       rrmse44
       rrmse55
       rrmse66
       
  
       
       
       
       
       
      plot(DKlC1.11$Malate,fitted(fitdots1),xlim=c(0,7),ylim=c(0,7)) 
      abline(0,1,lwd=2,col=2) 
    
      
      m1<-mean(mal.fruit) 
      rmse1<-rmse(DKlC1.11$Malate,fitted(fitdots1)) 
      rrmse1<-rmse1/m1 
      rrmse1 
      summary(fitdots1) 
      
   
 ### put all dots in the same figure for Cordinal
      ###assemble traitement T et light 
 DKlC1$treat2=paste(DKlC1$T,DKlC1$traitement) 
 
      ### un calcul de DGAPT puis courbes pour les 2 temps
mal.fruit=DKlC1$Malate 
ph=DKlC1$pH 
 TEM=(DKlC1$T)+273.35 
 par(mfrow=c(1,2)) 
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=TEM,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-53000),algorithm="port") 
  # fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=20+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
 
   #mal.fruit=DKlC1$Malate[DKlC1$T==30]
   #ph=DKlC1$pH[DKlC1$T==30]
   #TEM=30+273.35
   #par(mfrow=c(1,2))
   #fitdots30<-nls(mal.fruit~MAL(PH=ph, Tem=TEM,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-53000),algorithm="port")
   
    
 plot(DKlC1$pH,DKlC1$Malate,col=as.numeric(factor(DKlC1$treat2)))  
legend("topright",legend=levels(factor(DKlC1$treat2)),col=1:4,pch=1)

 ph.pre=seq(2.7,3.5,by=0.1)
 mal.20=MAL(PH=ph.pre, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
  lines(ph.pre,mal.20,col=1)
 mal.30=MAL(PH=ph.pre, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
  lines(ph.pre,mal.30,col=4)

 
  
  plot(DKlC1$Mois,DKlC1$Malate,col=as.numeric(factor(DKlC1$treat2)),type="p")  
legend("topright",legend=levels(factor(DKlC1$treat2)),col=1:4,pch=1)
 
#ph.pre=loess(DKlC1$pH~DKlC1$Mois)


#plot(DKlC1$pH~DKlC1$Mois)
lm1=with(DKlC1[DKlC1$treat2=="20 HL",],lm(pH~Mois))
lm2=with(DKlC1[DKlC1$treat2=="20 LL",],lm(pH~Mois))
lm3=with(DKlC1[DKlC1$treat2=="30 HL",],lm(pH~Mois))
lm4=with(DKlC1[DKlC1$treat2=="30 LL",],lm(pH~Mois))
#abline(lm1,col=1)
ph.20HL=predict(lm1,newdata=data.frame(Mois=seq(1,5,by=0.1)))
ph.20LL=predict(lm2,newdata=data.frame(Mois=seq(1,5,by=0.1)))
ph.30HL=predict(lm3,newdata=data.frame(Mois=seq(1,5,by=0.1)))
ph.30LL=predict(lm4,newdata=data.frame(Mois=seq(1,5,by=0.1)))

 mal.30HL=MAL(PH=ph.30HL, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
 mal.30LL=MAL(PH=ph.30LL, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
 mal.20HL=MAL(PH=ph.20HL, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
 mal.20LL=MAL(PH=ph.20LL, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 




 lines(seq(1,5,by=0.1),mal.20HL,col=1)
 lines(seq(1,5,by=0.1),mal.20LL,col=2)
lines(seq(1,5,by=0.1),mal.30HL,col=3)
lines(seq(1,5,by=0.1),mal.30LL,col=4)

  
###importance de l'effet lumière Cardinal + 2 DGATP différents


DKlC1$treat2=paste(DKlC1$T,DKlC1$traitement)

mal.fruit=DKlC1$Malate[DKlC1$T==20]
ph=DKlC1$pH[DKlC1$T==20]
TEM=20+273.5

fitdots20<-nls(mal.fruit~MAL(PH=ph, Tem=TEM,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
#DGATPcalc = -53,23 kJ/mol

mal.fruit=DKlC1$Malate[DKlC1$T==30]
ph=DKlC1$pH[DKlC1$T==30]
TEM=30+273.5

par(mfrow=c(1,2))
fitdots30<-nls(mal.fruit~MAL(PH=ph, Tem=TEM,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
#DGATPcalc = -54,99 kJ/mol
plot(DKlC1$pH,DKlC1$Malate,col=as.numeric(factor(DKlC1$treat2)))  
legend("topright",legend=levels(factor(DKlC1$treat2)),col=1:4,pch=1)

ph.pre=seq(2.7,3.5,by=0.1)
mal.20=MAL(PH=ph.pre, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots20), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
lines(ph.pre,mal.20,col=1)
mal.30=MAL(PH=ph.pre, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots30), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
lines(ph.pre,mal.30,col=4)

plot(DKlC1$Mois,DKlC1$Malate,col=as.numeric(factor(DKlC1$treat2)),type="p")  
legend("topright",legend=levels(factor(DKlC1$treat2)),col=1:4,pch=1)

  
#plot(DKlC1$pH~DKlC1$Mois)
lm1=with(DKlC1[DKlC1$treat2=="20 HL",],lm(pH~Mois))
lm2=with(DKlC1[DKlC1$treat2=="20 LL",],lm(pH~Mois))
lm3=with(DKlC1[DKlC1$treat2=="30 HL",],lm(pH~Mois))
lm4=with(DKlC1[DKlC1$treat2=="30 LL",],lm(pH~Mois))
#abline(lm1,col=1)
ph.20HL=predict(lm1,newdata=data.frame(Mois=seq(1,5,by=0.1)))
ph.20LL=predict(lm2,newdata=data.frame(Mois=seq(1,5,by=0.1)))
ph.30HL=predict(lm3,newdata=data.frame(Mois=seq(1,5,by=0.1)))
ph.30LL=predict(lm4,newdata=data.frame(Mois=seq(1,5,by=0.1)))

mal.30HL=MAL(PH=ph.30HL, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots30), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
mal.30LL=MAL(PH=ph.30LL, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots30), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
mal.20HL=MAL(PH=ph.20HL, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots20), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
mal.20LL=MAL(PH=ph.20LL, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots20), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 




lines(seq(1,5,by=0.1),mal.20HL,col=1)
lines(seq(1,5,by=0.1),mal.20LL,col=2)
lines(seq(1,5,by=0.1),mal.30HL,col=3)
lines(seq(1,5,by=0.1),mal.30LL,col=4)

   
   ######C2   on a le malate pour les conditions : Cardinal, HL à 20
   
   DKl<-Kliewer.29.01_Dai
   DKlC2=DKl[DKl$cepage!="pinot noir",]
   DKlC2.1=DKlC2[DKlC2$traitement!="LL",]
   DKlC2.11=DKlC2.1[DKlC2.1$T!="30",]
   ggplot(data=DKlC2.11, aes(Mois, Malate))+geom_point()
   
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlC2.11$Malate
   ph=DKlC2.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=20+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlC2.11$pH,DKlC2.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, HL, 20°")
   points(ph,fitted(fitdots),col=4,pch=3, ylim=c(3.5,42))
   summary(fitdots)
   plot(DKlC2.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   #C3    on a le malate pour les conditions : Cardinal, LL à 30
   
   DKl<-Kliewer.29.01_Dai
   DKlC3=DKl[DKl$cepage!="pinot noir",]
   DKlC3.1=DKlC3[DKlC3$traitement!="HL",]
   DKlC3.11=DKlC3.1[DKlC3.1$T!="20",]
   ggplot(data=DKlC3.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
       Mal}
   mal.fruit=DKlC3.11$Malate
   ph=DKlC3.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=30+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlC3.11$pH,DKlC3.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, LL, 30°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlC3.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   
   #C4    on a le malate pour les conditions : Cardinal, LL à 20
   
   DKl<-Kliewer.29.01_Dai
   DKlC4=DKl[DKl$cepage!="pinot noir",]
   DKlC4.1=DKlC4[DKlC4$traitement!="HL",]
   DKlC4.11=DKlC4.1[DKlC4.1$T!="30",]
   ggplot(data=DKlC4.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlC4.11$Malate
   ph=DKlC4.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=20+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlC4.11$pH,DKlC4.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, LL, 20°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlC4.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   
   #PN1   on a le malate pour les conditions : Pinot noir, HL à 30
   
   DKl<-Kliewer.29.01_Dai
   DKlPN1=DKl[DKl$cepage!="Cardinal",]
   DKlPN1.1=DKlPN1[DKlPN1$traitement!="LL",]
   DKlPN1.11=DKlPN1.1[DKlPN1.1$T!="20",]
   ggplot(data=DKlPN1.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlPN1.11$Malate
   ph=DKlPN1.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=30+273.35,a=1,  DGATP=DGATP,Malcyt=0.3),start=list(DGATP=-56000),algorithm="port")
   plot(DKlPN1.11$pH,DKlPN1.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Pinot noir, HL, 30°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlPN1.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   
   m1<-mean(mal.fruit) 
  
   rmse<-rmse(DKlPN1.11$Malate,fitted(fitdots)) 
   rrmse<-rmse/m1 
   rrmse
   
   #PN2   on a le malate pour les conditions : Pinot noir, HL à 20
   
   DKl<-Kliewer.29.01_Dai
   DKlPN2=DKl[DKl$cepage!="Cardinal",]
   DKlPN2.1=DKlPN2[DKlPN2$traitement!="LL",]
   DKlPN2.11=DKlPN2.1[DKlPN2.1$T!="30",]
   ggplot(data=DKlPN2.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlPN2.11$Malate
   ph=DKlPN2.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=20+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlPN2.11$pH,DKlPN2.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Pinot noir, HL, 20°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlPN2.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   #PN3   on a le malate pour les conditions : Pinot noir, LL à 30
   
   DKl<-Kliewer.29.01_Dai
   DKlPN3=DKl[DKl$cepage!="Cardinal",]
   DKlPN3.1=DKlPN3[DKlPN3$traitement!="HL",]
   DKlPN3.11=DKlPN3.1[DKlPN3.1$T!="20",]
   ggplot(data=DKlPN3.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlPN3.11$Malate
   ph=DKlPN3.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=30+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlPN3.11$pH,DKlPN3.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Pinot noir LL, 30°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlPN3.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   #PN4   on a le malate pour les conditions : Pinot noir, LL à 20
   
   DKl<-Kliewer.29.01_Dai
   DKlPN4=DKl[DKl$cepage!="Cardinal",]
   DKlPN4.1=DKlPN4[DKlPN4$traitement!="HL",]
   DKlPN4.11=DKlPN4.1[DKlPN4.1$T!="30",]
   ggplot(data=DKlPN4.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlPN4.11$Malate
   ph=DKlPN4.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=20+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlPN4.11$pH,DKlPN4.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Pinot noir, LL, 20°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlPN4.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   ### put all dots in the same figure for Pinot Noir
 
  
   
   ###importance de l'effet lumière Pinot noir
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
  
   
    mal.fruit2=DKlPN1$Malate[DKlPN1$T==20]
   ph=DKlPN1$pH[DKlPN1$T==20]
   TEM=20+273.5
   
   par(mfrow=c(1,2))
   fitdots20<-nls(mal.fruit2~MAL(PH=ph, Tem=TEM,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   summary(fitdots20)
    #DGATPcalc = - 54,8 KJ/mol
   mal.fruit3=DKlPN1$Malate[DKlPN1$T==30]
      ph=DKlPN1$pH[DKlPN1$T==30]
       TEM=30+273.5
       
         par(mfrow=c(1,2))
       fitdots30<-nls(mal.fruit3~MAL(PH=ph, Tem=TEM,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
    summary(fitdots30)
   #DGATPcalc = -56,8 KJ/mol
   
   
   
   DKlPN1$treat2=paste(DKlPN1$T,DKlPN1$traitement)
 #  plot(DKlPN1$pH,DKlPN1$Malate,col=as.numeric(factor(DKlPN1$treat2)))  
    plot(DKlPN1$pH,DKlPN1$Malate,col=as.numeric(factor(DKlPN1$treat2)))  
    
   legend("topright",legend=levels(factor(DKlPN1$treat2)),col=1:4,pch=1)
   ph.pre=seq(2.7,3.8,by=0.1)
   mal.20=MAL(PH=ph.pre, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots20), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
   lines(ph.pre,mal.20,col=1)
   mal.30=MAL(PH=ph.pre, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots30), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
   lines(ph.pre,mal.30,col=4)
   
   plot(DKlPN1$Mois,DKlPN1$Malate,col=as.numeric(factor(DKlPN1$treat2)),type="p")  
   legend("topright",legend=levels(factor(DKlPN1$treat2)),col=1:4,pch=1)
   
   #ph.pre=loess(DKlC1$pH~DKlC1$Mois)
   
   
   #plot(DKlC1$pH~DKlC1$Mois)
   lm1=with(DKlPN1[DKlPN1$treat2=="20 HL",],lm(pH~Mois))
   lm2=with(DKlPN1[DKlPN1$treat2=="20 LL",],lm(pH~Mois))
   lm3=with(DKlPN1[DKlPN1$treat2=="30 HL",],lm(pH~Mois))
   lm4=with(DKlPN1[DKlPN1$treat2=="30 LL",],lm(pH~Mois))
   #abline(lm1,col=1)
   ph.20HL=predict(lm1,newdata=data.frame(Mois=seq(1,5,by=0.1)))
   ph.20LL=predict(lm2,newdata=data.frame(Mois=seq(1,5,by=0.1)))
   ph.30HL=predict(lm3,newdata=data.frame(Mois=seq(1,5,by=0.1)))
   ph.30LL=predict(lm4,newdata=data.frame(Mois=seq(1,5,by=0.1)))
   
   mal.30HL=MAL(PH=ph.30HL, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots30), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
   mal.30LL=MAL(PH=ph.30LL, Tem=30+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots30), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
   mal.20HL=MAL(PH=ph.20HL, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots20), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
   mal.20LL=MAL(PH=ph.20LL, Tem=20+273.5,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=coef(fitdots20), pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4) 
   
   
   
   
   lines(seq(1,5,by=0.1),mal.20HL,col=1)
   lines(seq(1,5,by=0.1),mal.20LL,col=2)
   lines(seq(1,5,by=0.1),mal.30HL,col=3)
   lines(seq(1,5,by=0.1),mal.30LL,col=4)
   
   
   
   GATP<-function(PH=PH, Temp=Temp, a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, Malvac=Malvac, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     DGATP= n*R*Temp*2.3*(PH-pHcyt)-(n*R*Temp/2)*log(((a*Malvac/K)/Malcyt),exp(1))
     DGATP}
   
   
   
   #####fittage Soyer
   
   
   DKl<-Kliewer.29.01_Dai
   DKlC3=DKl[DKl$cepage!="pinot noir",]
   DKlC3.1=DKlC3[DKlC3$traitement!="HL",]
   DKlC3.11=DKlC3.1[DKlC3.1$T!="20",]
   ggplot(data=DKlC3.11, aes(Mois, Malate))+geom_point() 
   MAL<-function(PH=PH,Tem=Tem,a=0.47,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal}
   mal.fruit=DKlC3.11$Malate
   ph=DKlC3.11$pH
   
   fitdots<-nls(mal.fruit~MAL(PH=ph, Tem=30+273.35,a=0.47, K1=10^(-5.11), K2=10^(-3.4), R=8.314, FF=96000, DGATP=DGATP, pHcyt=7.2,Malcyt=0.14,A=0.3,B=-0.12,no=4),start=list(DGATP=-56000),algorithm="port")
   plot(DKlC3.11$pH,DKlC3.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, LL, 30°")
   points(ph,fitted(fitdots),col=4,pch=3)
   summary(fitdots)
   plot(DKlC3.11$Malate,fitted(fitdots))
   abline(0,1,lwd=2,col=2)
   
   
   ### [mal]cyt = 0,58 et 3,33 mM  pour les 4 cépages, avec traitement
   ####objectif : comparer les RRMSE et les DGATP obtenues 
   ### Kliewer 
                  ###Cardinal HL, LL 30
   ##Cardinal HL, 30
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.12=DKlC1.1[DKlC1.1$T!="20",]
   ggplot(data=DKlC1.11, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.12$Malate
   ph=DKlC1.12$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.12$pH,DKlC1.12$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, HL, 30°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   #legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-52,3 kJ/mol, rrmse = 0,26", "[Mal]cyt=3,33mM,DGATP=-46,5 kJ/mol,rrmse = 0,29"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   legend("top",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-52,3 kJ/mol, rrmse = 0,26", "[Mal]cyt=3,33mM,DGATP=-46,5 kJ/mol,rrmse = 0,29"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.12$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.12$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   ###Cardinal HL 20
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.12=DKlC1.1[DKlC1.1$T=="20",]
   ggplot(data=DKlC1.12, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
    Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DKlC1.12$Malate
   ph=DKlC1.12$pH
   par(mfrow=c(1,1))
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.12$pH,DKlC1.12$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, HL, 20°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("top",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-50,9 kJ/mol, rrmse = 0,17", "[Mal]cyt=3,33mM,DGATP=-45,4 kJ/mol,rrmse = 0,18"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.12$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.12$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   
   
   
   ##Cardinal LL, 30
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement=="LL",]
   DKlC1.12=DKlC1.1[DKlC1.1$T!="20",]
   ggplot(data=DKlC1.11, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.12$Malate
   ph=DKlC1.12$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.12$pH,DKlC1.12$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, LL, 30°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   #legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-52,3 kJ/mol, rrmse = 0,26", "[Mal]cyt=3,33mM,DGATP=-46,5 kJ/mol,rrmse = 0,29"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   legend("top",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-53,0 kJ/mol, rrmse = 0,18", "[Mal]cyt=3,33mM,DGATP=-47,2 kJ/mol,rrmse = 0,21"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.12$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.12$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   ###Cardinal LL 20
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement=="LL",]
   DKlC1.12=DKlC1.1[DKlC1.1$T=="20",]
   ggplot(data=DKlC1.12, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DKlC1.12$Malate
   ph=DKlC1.12$pH
   par(mfrow=c(1,1))
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.12$pH,DKlC1.12$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, LL, 20°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("top",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-51,2 kJ/mol, rrmse = 0,14", "[Mal]cyt=3,33mM,DGATP=-45,6 kJ/mol,rrmse = 0,15"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.12$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.12$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   
   
   
   ##Cardinal HL et LL 30
   
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T!="20",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, HL&LL, 30°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-52,7 kJ/mol, rrmse = 0,24", "[Mal]cyt=3,33mM,DGATP=-46,9 kJ/mol,rrmse = 0,26"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   
   ##Cardinal HL et LL 20
   
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T!="30",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Cardinal, HL&LL, 20°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-51,0 kJ/mol, rrmse = 0,16", "[Mal]cyt=3,33mM,DGATP=-45,5 kJ/mol,rrmse = 0,17"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   
   
   ##Pinot Noir HL et LL 30
   
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage=="pinot noir",]
  # DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T=="30",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Pinot noir, HL&LL, 30°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-54,5 kJ/mol, rrmse = 0,20", "[Mal]cyt=3,33mM,DGATP=-48,7 kJ/mol,rrmse = 0,25"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   
   
   ##Pinot Noir HL et LL 20
   
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage=="pinot noir",]
   # DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T!="30",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de KLiewer, condition : Pinot noir, HL&LL, 20°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-52,7 kJ/mol, rrmse = 0,12", "[Mal]cyt=3,33mM,DGATP=-47,2 kJ/mol,rrmse = 0,14"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   #### On fait de même avec Data de Soyer 
   ####Carbernet Sauvignon,en séparant les traitements 
   DS<-Soyer.23.01...copie
   DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
   DS1.1=DS1[DS1$traitement=="K60",]
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
   Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DS1.1$Malate
   ph=DS1.1$pH
   par(mfrow=c(1,1))
   Temp=DS1.1$T+273.35

   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-70000),algorithm="port")
   
   plot(DS1.1$pH,DS1.1$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de SOYER, CS K60")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("topright",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-53,1 kJ/mol, rrmse = 0,39", "[Mal]cyt=3,33mM,DGATP=-47,7 kJ/mol,rrmse = 0,41"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DS1.1$Malate,fitted(fitdots1))
   rmse2<-rmse(DS1.1$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   ###K120
   
   DS<-Soyer.23.01...copie
   DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
   DS1.1=DS1[DS1$traitement=="K120",]
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DS1.1$Malate
   ph=DS1.1$pH
   par(mfrow=c(1,1))
   Temp=DS1.1$T+273.35
   
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-70000),algorithm="port")
   
   plot(DS1.1$pH,DS1.1$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de SOYER, CS K120")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   legend("top",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-53,3 kJ/mol, rrmse = 0,35", "[Mal]cyt=3,33mM,DGATP=-47,9 kJ/mol,rrmse = 0,36"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   rmse1<-rmse(DS1.1$Malate,fitted(fitdots1))
   rmse2<-rmse(DS1.1$Malate,fitted(fitdots2))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse1
   rrmse2
   
   #####Soyer K0 témoin 
   DS<-Soyer.23.01...copie
   DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
   DS1.122=DS1[DS1$traitement!="K120",]
   DS1.12=DS1.122[DS1.122$Localisation=="LAB",]
   DS1.11=DS1.12[DS1.12$traitement=="K60",]
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     Mal=Mal.mol1*0.8*134/1000 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DS1.11$Malate
   ph=DS1.11$pH
   par(mfrow=c(1,1))
   Temp=DS1.11$T+273.35
   
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.5,Malcyt=0.01),start=list(DGATP=-70000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7,Malcyt=0.01),start=list(DGATP=-70000),algorithm="port")
   fitdots3<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=6.8,Malcyt=0.01),start=list(DGATP=-70000),algorithm="port")
   
   plot(DS1.11$pH,DS1.11$Malate,col=2,xlab="pH", ylab="Malate", main="CS K60 [Mal]cyt=0,01mM",ylim=c(0,40))
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   points(ph,fitted(fitdots3),col=3,pch=3)
   legend("top",cex=0.8,legend = c("Observed",",pHcyt = 7.5 DGATP=-70 kJ/mol, rrmse = 0,48", "pHcyt =7,DGATP=-70,8 kJ/mol,rrmse = 0,43","pHcyt=6.8,DGATP=-69,2 kJ/mol,rrmse = 0,42"), pch=c(1,3,3,3),col=c(2,4,1,3),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   rmse1<-rmse(DS1.11$Malate,fitted(fitdots1))
   rmse2<-rmse(DS1.11$Malate,fitted(fitdots2))
   rmse3<-rmse(DS1.11$Malate,fitted(fitdots3))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1
   rrmse1
   rrmse2
   rrmse3
   
   #####Soyer K60  
   DS<-Soyer.23.01...copie
   DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
   DS1.11=DS1[DS1$traitement=="K60",]
  # DS1.12=DS1.122[DS1.122$Localisation=="LAB",]
  # DS1.11=DS1.122[DS1.12$traitement!="K60",]
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DS1.11$Malate
   ph=DS1.11$pH
   par(mfrow=c(1,1))
   Temp=DS1.11$T+273.35
   
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.5,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   fitdots3<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=6.8,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   
   plot(DS1.11$pH,DS1.11$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de SOYER, CS K60 [Mal]cyt=0,58mM",ylim=c(3,35))
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   points(ph,fitted(fitdots3),col=3,pch=3)
   legend("top",cex=0.9,legend = c("Observed",",pHcyt = 7.5 DGATP=-53,0 kJ/mol, rrmse = 0,38", "pHcyt =7,DGATP=-51,7 kJ/mol,rrmse = 0,41","pHcyt=6.8,DGATP=-49,6 kJ/mol,rrmse = 0,43"), pch=c(1,3,3,3),col=c(2,4,1,3),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   rmse1<-rmse(DS1.11$Malate,fitted(fitdots1))
   rmse2<-rmse(DS1.11$Malate,fitted(fitdots2))
   rmse3<-rmse(DS1.11$Malate,fitted(fitdots3))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1
   rrmse1
   rrmse2
   rrmse3
   
   
   #####Soyer K120 
   DS<-Soyer.23.01...copie
   DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
   DS1.11=DS1[DS1$traitement=="K120",]
   #DS1.12=DS1.122[DS1.122$Localisation=="LAB",]
   #DS1.11=DS1.12[DS1.12$traitement!="K60",]
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mmol/L
     Mal=Mal.mol1*0.8 #mmol/Kg FW  correspond à des mg/g en comparant avec les premiers graphs  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DS1.11$Malate
   ph=DS1.11$pH
   par(mfrow=c(1,1))
   Temp=DS1.11$T+273.35
   
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7.5,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=7,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   fitdots3<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, DGATP=DGATP, pHcyt=6.8,Malcyt=0.58),start=list(DGATP=-70000),algorithm="port")
   
   plot(DS1.11$pH,DS1.11$Malate,col=2,xlab="pH", ylab="[Malate]mg/g", main="Donnée de SOYER, CS K120 [Mal]cyt=0,58mM",ylim=c(2.5,40))
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   points(ph,fitted(fitdots3),col=3,pch=3)
   legend("top",cex=0.8,legend = c("Observed",",pHcyt = 7.5 DGATP=-53,20 kJ/mol, rrmse = 0,35", "pHcyt =7,DGATP=-51,9 kJ/mol,rrmse = 0,36","pHcyt=6.8,DGATP=-49,8 kJ/mol,rrmse = 0,38"), pch=c(1,3,3,3),col=c(2,4,1,3),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   rmse1<-rmse(DS1.11$Malate,fitted(fitdots1))
   rmse2<-rmse(DS1.11$Malate,fitted(fitdots2))
   rmse3<-rmse(DS1.11$Malate,fitted(fitdots3))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1
   rrmse1
   rrmse2
   rrmse3
   
   
  ####test sur Kliewer des 3 pH  
   ##pour commencer sur Cardinal, 30° Hl LL 
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
  # DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T!="20",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.5,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots3<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=6.8,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="[Malate] mg/g", main="Cardinal, HL&LL, 30° [Mal]cyt=0,58 mM")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   points(ph,fitted(fitdots3),col=3,pch=3)
   
   legend("top",cex=0.9,legend = c("Observed",",pHcyt = 7.5 DGATP=-53,20 kJ/mol, rrmse = 0,20", "pHcyt =7,DGATP=-51,0 kJ/mol,rrmse = 0,26","pHcyt=6.8,DGATP=-48,6 kJ/mol,rrmse = 0,28"), pch=c(1,3,3,3),col=c(2,4,1,3),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   rmse3<-rmse(DKlC1.13$Malate,fitted(fitdots3))
   
    m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1
   rrmse1
   rrmse2
   rrmse3
   
   
   
   
   
   
   
   ##pour commencer sur Cardinal, 20° Hl LL 
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   # DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T=="20",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.58,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1/(134*1000) #mmol/Kg FW  (considering water content at 0.8)
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.5,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   fitdots3<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=6.8,Malcyt=0.58),start=list(DGATP=-56000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="[Malate] mg/g", main="Cardinal, HL&LL, 20° [Mal]cyt=0,58 mM")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   points(ph,fitted(fitdots3),col=3,pch=3)
   
   legend("top",cex=0.9,legend = c("Observed",",pHcyt = 7.5 DGATP=-51,4 kJ/mol, rrmse = 0,14", "pHcyt =7,DGATP=-49,5 kJ/mol,rrmse = 0,17","pHcyt=6.8,DGATP=-47,2 kJ/mol,rrmse = 0,18"), pch=c(1,3,3,3),col=c(2,4,1,3),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   rmse3<-rmse(DKlC1.13$Malate,fitted(fitdots3))
   
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1
   rrmse1
   rrmse2
   rrmse3
   
   
   #### A faire : idem pour Pinor Noir
   
   
   
   
   
   
   
   #### Fit Cardinal,HL, 30° RRMSE avant modif = 0,25
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.11=DKlC1.1[DKlC1.1$T!="20",]
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     #Mal=Mal.mol*134 # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal.mol1/(134*1000)#mmol/Kg FW  (considering water content at 0.8)
     
     Mal}
   mal.fruit=DKlC1.11$Malate
   ph=DKlC1.11$pH
   
   par(mfrow=c(1,1))
   
   fitdots1<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.58),start=list(DGATP=-86000),algorithm="port")
   fitdots2<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=3.33),start=list(DGATP=-86000),algorithm="port")
   fitdots3<-nls(mal.fruit~MAL(PH=ph,a=1, Tem=30+273.35, DGATP=DGATP, pHcyt=7.2,Malcyt=0.01),start=list(DGATP=-86000),algorithm="port")
   
   
   
   plot(DKlC1.11$pH,DKlC1.11$Malate,col=2,xlab="pH", ylab="[Malate] mg/g", main=" Cardinal, HL, 30°")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=3,pch=3)
   points(ph,fitted(fitdots3),col=1,pch=3)
   
   
   
   legend("top",cex=0.9,legend = c("Observed","[Mal]cyt=0,58 mM DGATP=-90,8 kJ/mol, rrmse = 0,1", "[Mal]cyt=3,33 mM,DGATP=-85 kJ/mol,rrmse = 0,12","[Mal]cyt=0,01 mM,DGATP=-104 kJ/mol,rrmse = 0,07"), pch=c(1,3,3,3),col=c(2,4,3,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   
   
   rmse1<-rmse(DKlC1.11$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.11$Malate,fitted(fitdots2))
   rmse3<-rmse(DKlC1.11$Malate,fitted(fitdots3))
   
   m1<-mean(mal.fruit) 
   
   rrmse2<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1 
   
   rrmse1
   rrmse2
   rrmse3
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
    ####test 
   
   DKl<-Kliewer.29.01_Dai
   DKlC1=DKl[DKl$cepage!="pinot noir",]
   # DKlC1.1=DKlC1[DKlC1$traitement!="LL",]
   DKlC1.13=DKlC1[DKlC1$T=="20",]
   ggplot(data=DKlC1.13, aes(Mois, Malate))+geom_point() 
   
   MAL<-function(PH=PH,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=3.33,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/a)*exp((2*FF*DY)/(R*Tem))*Malcyt # in mol/L
     
     Mal1=Mal.mol1/(134*1000) # mg/g considering a density of 1  -> Both Malcyt and a are already in mmol #Benjamin
     Mal=Mal1  
     
     #resul=c(Mal,DY)
     #resul
     Mal
   }
   mal.fruita=DKlC1.13$Malate
   ph=DKlC1.13$pH
   par(mfrow=c(1,1))
   
   #plot(DKlC1.11$Malate,fitted(fitdots),xlim=c(0,7),ylim=c(0,7))
   #abline(0,1,lwd=2,col=2)
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7.5,Malcyt=3.33),start=list(DGATP=-96000),algorithm="port")
   fitdots2<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=7,Malcyt=3.33),start=list(DGATP=-96000),algorithm="port")
   fitdots3<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=20+273.35, DGATP=DGATP, pHcyt=6.8,Malcyt=3.33),start=list(DGATP=-96000),algorithm="port")
   
   plot(DKlC1.13$pH,DKlC1.13$Malate,col=2,xlab="pH", ylab="[Malate] mg/g", main="Cardinal, HL&LL, 20° [Mal]cyt=3,33 mM")
   points(ph,fitted(fitdots1),col=4,pch=3)
   points(ph,fitted(fitdots2),col=1,pch=3)
   points(ph,fitted(fitdots3),col=3,pch=3)
   
   legend("top",cex=0.9,legend = c("Observed",",pHcyt = 7.5 DGATP=-80,2 kJ/mol, rrmse = 0,10", "pHcyt =7,DGATP=-81,4 kJ/mol,rrmse = 0,11","pHcyt=6.8,DGATP=-79,7 kJ/mol,rrmse = 0,12"), pch=c(1,3,3,3),col=c(2,4,1,3),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   summary(fitdots2)
   summary(fitdots3)
   
   rmse1<-rmse(DKlC1.13$Malate,fitted(fitdots1))
   rmse2<-rmse(DKlC1.13$Malate,fitted(fitdots2))
   rmse3<-rmse(DKlC1.13$Malate,fitted(fitdots3))
   
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse2<-rmse2/m1 
   rrmse3<-rmse3/m1
   rrmse1
   rrmse2
   rrmse3
   
   
   

   
      MAL<-function(PH=PH,Tem=Tem,times=times,k=k,k2=k2,k3=k3, a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     ifelse(PH < "2.5",Malcyt=k*times,Malcyt=k2*exp(-k3*times))
     Mal.mol1=((K/a)*exp((2*FF*DY)/(R*Tem)+1))*Malcyt  # in mol/L
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   don=test.6fev
   PH1=don$pH
   par(mfrow=c(1,1))
   Temp=30+273.35
   t=don$t
   don$mal.pre=MAL(PH=PH1,Tem=Temp,times=t)
     plot(don$t,don$mal.pre,col=2,xlab="Jour", ylab="Malate.pre")
   
 
   
   
   
     fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp,P=P, L=L, DGATP=-50000, pHcyt=7.2,Malcyt=0.58),start=list(L=12,P=1),algorithm="port")
 
   plot(DS1.1$pH,DS1.1$Malate,col=2,xlab="pH", ylab="Malate", main="Donnée de SOYER, CS K120")
   points(ph,fitted(fitdots1),col=4,pch=3)
   legend("top",cex=0.8,legend = c("Observed","[Mal]cyt=0,58mM, DGATP=-53,3 kJ/mol, rrmse = 0,35", "[Mal]cyt=3,33mM,DGATP=-47,9 kJ/mol,rrmse = 0,36"), pch=c(1,3,3),col=c(2,4,1),text.col = par("col"),xjust = 1)
   
   summary(fitdots1)
   rmse1<-rmse(DS1.1$Malate,fitted(fitdots1))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse1
   
   
   
   
   DS<-Soyer.23.01...copie
   DS1=DS[DS$Cepage=="Cabernet Sauvignon",]
   DS1.1=DS1[DS1$traitement=="K60",]
   MAL<-function(PH=PH,L=L,Tem=Tem,a=1,K1=10^(-5.11),K2=10^(-3.4),R=8.314,FF=96000, DGATP=-56000, pHcyt=7.2,Malcyt=0.5,A=0.3,B=-0.12,no=4){
     n=no+A*(PH-7)+B*10^(pHcyt-7)
     DY=((-DGATP/(n*FF))+((R*Tem*2.3)/FF)*(PH-pHcyt))
     h=10^(-PH)
     dMalcyt=L
     K=(K1*K2+h*K1+h^2)/(K1*K2)
     Mal.mol1=(K/2*a)*exp((2*FF*DY)/(R*Tem))*Malcyt# in mol/L
     Mal=Mal.mol1*0.8 #mmol/Kg FW  (considering water content at 0.8)
     Mal
   }
   mal.fruita=DS1.1$Malate
   ph=DS1.1$pH
   par(mfrow=c(1,1))
   Temp=DS1.1$T+273.35
   
   fitdots1<-nls(mal.fruita~MAL(PH=ph,a=1, Tem=Temp, L=L, DGATP=-50000, pHcyt=7.2,Malcyt=Malcyt),start=list(L=10000,Malcyt=0.3),algorithm="port")
   
   plot(DS1.1$Jour,DS1.1$Malate,col=2,xlab="Jour", ylab="Malate", main="Donnée de SOYER, CS K120",ylim=c(1,35))
   points(DS1.1$Jour,fitted(fitdots1),col=4,pch=3)
   
   summary(fitdots1)
   rmse1<-rmse(DS1.1$Malate,fitted(fitdots1))
   m1<-mean(mal.fruita) 
   
   rrmse1<-rmse1/m1 
   rrmse1
   