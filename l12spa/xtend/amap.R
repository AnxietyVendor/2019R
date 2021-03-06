####################################################
##########                                ##########
##########        空间数据可视化          ##########
##########                                ##########
####################################################
# 李丁  中国人民大学 社会与人口学院 整理
# liding@ruc.edu.cn

#1、绘制基础地图
#2、基于空间数据格式（shapefile）文件绘图
#3、基于json数据作图
#4、基于高德、百度、google地图数据作图
#5、基于栅格图片作图

####################################################
##########                                ##########
##########         SECTION 1              ##########
##########                                ##########
####################################################

#########################################
####           基础地图              ####
#########################################

##加载现成的基础地图
# install.packages("ggplot2")
# install.packages("maps")
library(ggplot2)
# 欧美常用初级地图
library(maps) 

# 美国地图数据
states_map <- map_data("state")
head(states_map)
# geom_polygon()
ggplot(states_map, aes(x=long,y=lat,group=group)) +
  geom_polygon(fill="white",colour="black") +
  labs(title = "USA Map")

#中国地图,93 95
if (!require('mapdata')) install.packages("mapdata")
china <- map_data("china")

map("china", col = "red4", panel.first = grid())
title("China Map")

# 有点问题，连线
ggplot(china, aes(x=long,y=lat,group=group)) +
  geom_polygon(fill="white",colour="black") +
  labs(title = "china Map")

# 世界地图
# 世界地图数据
world_map <- map_data("world")
head(world_map)
#plot(world_map)
#par(mfcol=c(1,1))
# 绘制指定区域的地图数据
# 绘制欧洲足球五大联赛所在地
# 位置和映射有点问题

euro <- map_data("world", region = c("UK","France", "Spain","Germany", "Italy"))
# euro <-arrange(euro,group,order)
ggplot(euro, aes(x=long, y = lat, group=group,fill=region)) +
  geom_polygon(colour="black") +
  scale_fill_brewer(palette = "Set2") +
  scale_y_continuous(limits=c(40,60)) +
  scale_x_continuous(limits=c(-25,25)) +
  labs(title = " Euorpe's Big Five Football Leagues")

#########################################
#示例美国分县失业率
#Make a US County Thematic Map Using R
#https://gist.github.com/hadley/233134

# 整理数据
# First (and most annoying) task - get matching state and county variables for both datasets.  And unfortauntely it's not quite right, as you can see from the finish product - some counties are missing.
unemp <- read.csv("http://datasets.flowingdata.com/unemployment09.csv", header = F, stringsAsFactors = F)
names(unemp) <- c("id", "state_fips", "county_fips", "name", "year", 
                  "?", "?", "?", "rate")
unemp$county <- tolower(gsub(" County, [A-Z]{2}", "", unemp$name))
unemp$state <- gsub("^.*([A-Z]{2}).*$", "\\1", unemp$name)

county_df <- map_data("county")
names(county_df) <- c("long", "lat", "group", "order", "state_name", "county")
county_df$state <- state.abb[match(county_df$state_name, tolower(state.name))]
county_df$state_name <- NULL

state_df <- map_data("state")

# 合并数据 Combine together 
choropleth <- merge(county_df, unemp, by = c("state", "county"))
choropleth <- choropleth[order(choropleth$order), ]
# Discretise rate to use with Brewer colour scheme - many options here
# choropleth$rate_d <- cut_number(choropleth$rate, 5)
# choropleth$rate_d <- cut_interval(choropleth$rate, 5)
# Nathan's choice is a little odd:
choropleth$rate_d <- cut(choropleth$rate, breaks = c(seq(0, 10, by = 2), 35))

# Once you have the data in the right format, recreating the plot is straight forward.
# 美国地图，非常快！
ggplot(choropleth, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = rate_d), colour = alpha("white", 1/2), size = 0.2) + 
  geom_polygon(data = state_df, colour = "white", fill = NA) +
  scale_fill_brewer(palette = "PuRd")

ggplot(choropleth, aes(long, lat, group = group)) +
  geom_polygon(aes(fill = rate_d), colour = "gray85", size = 0.2) + 
  geom_polygon(data = state_df, colour = "white", fill = NA) +
  scale_fill_brewer(palette = "PuRd")

#########################################
#示例 2 美国监禁犯人
#分层设色
head(USArrests) # 1973年的数据
crimes <- data.frame(state= tolower(rownames(USArrests)), USArrests)
# 合并数据集
crime_map <- merge(states_map,crimes,by.x="region",by.y = "state")
# head(crime_map)
library(plyr) # 加载数据清洗软件包
# 按照 group, order排序
crime_map <- arrange(crime_map,group,order)
# head(crime_map)
ggplot(crime_map, aes(x=long,y=lat, group = group, fill = Assault)) +
  geom_polygon(colour = "black") +
  coord_map("polyconic") +
  labs(title = "USA Map")

# 更改配色
ggplot(crimes, aes(map_id = state, fill = Assault)) +
  geom_map(map = states_map, colour = "black") +
  scale_fill_gradient(low="#FFFFFF", high = "#BB4444") +
  expand_limits(x = states_map$long, y = states_map$lat)

# 离散颜色标度
qa <- quantile(crimes$Assault, c(0,0.2,0.4,0.6,0.8,1.0))
qa

# 新增一个分位数类别变量
crimes$Assault_q <- cut(crimes$Assault, qa, labels = c("0-20%", "20-40%","40-60%","60-80%", "80-100%"),
                        include.lowest = TRUE)
states <- ddply(states_map, .(region),summarise, lat = mean(lat,na.rm = TRUE),
                long = mean(long,na.rm = TRUE))
crimes <- merge(crimes, states, by.x = "state", by.y = "region")

# 绘制离散分类地图
p <- ggplot(crimes, aes(map_id = state, fill = Assault_q)) +
  geom_map(map = states_map, colour = "black") +
  scale_fill_brewer(palette = "Set2") +
  expand_limits(x = states_map$long, y =states_map$lat) +
  coord_map("polyconic") +
  labs(fill="Assault Rate\nPercentile", title = "USA Map")
p
# 加入州名对应的标签
p + geom_text(aes(x=long,y=lat,label=state),size=3,colour="black") +
  theme_bw() +
  xlab("long") + ylab("lat")

# 创建空白背景地图
theme_clean <- function(base_size=12){
  require(grid)
  theme_grey(base_size)
  theme(
    axis.title = element_blank(),
    axis.text = element_blank(),
    panel.background = element_blank(),
    panel.grid = element_blank(),
    axis.ticks.length = unit(0, "cm"),
    axis.ticks.margin = unit(0, "cm"),
    panel.margin = unit(0, "lines"),
    plot.margin = unit(c(0,0,0,0), "lines"),
    complete = TRUE
  )
}
p + theme_clean()



#https://gis.stackexchange.com/questions/144356/how-to-read-arcgis-files-in-r 

require(rgdal)
require(ggplot2)
require(rgeos)
require(ggmap)
require(RColorBrewer)

# Read shapefile using OGR
shp = "/Users/liding/E/Bdata/2019R/l12spa/intro/world.shp"


myshp = readOGR(shp, layer = basename(strsplit(shp, "\\.")[[1]])[1]) # This is a fancy way of being lazy, so I do not need to type the layer name in
proj4string(myshp) <- CRS("+proj=longlat +datum=WGS84")
# Convert to lat long
#myshp_proj = spTransform(myshp, CRS("+proj=longlat +datum=WGS84"))

# Find polygon centroid (This centers the map)
#google 地图国内登录不了
centroid = gCentroid(myshp_proj)
register_google(key = "AIzaSyDzbTtAijGTrGdYxbU3FGuxnwwO3Vkmixg")
# Get the Google basemap
mapImageData1 = get_map(location = c(lon = centroid$x, lat = centroid$y),
                        color = "color",
                        source = "google",
                        maptype = "satellite",
                        zoom = 1)

# Convert shapefile to format ggmap can work with
polys = fortify(myshp_proj)

# Define the color scheme for mapping shp
colors = brewer.pal(9, "OrRd")

# create the final map
ggmap(mapImageData1) +
  geom_polygon(aes(x = long, y = lat, group = group),
               data = polys,
               color = colors[9],
               fill = colors[6],
               alpha = 0.5) +
  labs(x = "Longitude", y = "Latitude")

####################################################
##########                                ##########
##########         SECTION 2              ##########
##########                                ##########
####################################################

#########################################
####       用shp文件作图             ####
#########################################
### 见chinamap.R介绍如何做带有南海诸岛的地
#########################################

#火星坐标系统是一种国家保密插件，也叫做加密插件或者加偏或者SM模组，其实就是对真实坐标系统进行人为的加偏处理，按照特殊的算法，将真实的坐标加密成虚假的坐标，而这个加偏并不是线性的加偏，所以各地的偏移情况都会有所不同。而加密后的坐标也常被人称为火星坐标系统。
#所有的电子地图、导航设备，都需要加入国家保密插件。第一步，地图公司测绘地图，测绘完成后，送到国家测绘局，将真实坐标的电子地图，加密成“火星坐标”，这样的地图才是可以出版和发布的，然后才可以让GPS公司处理。第二步，所有的GPS公司，只要需要汽车导航的，需要用到导航电子地图的，都需要在软件中加入国家保密算法，将COM口读出来的真实的坐标信号，加密转换成国家要求的保密的坐标。这样，GPS导航仪和导航电子地图就可以完全匹配，GPS也就可以正常工作了。


#示例2通过Baidu API自己获取shp坐标
# https://mp.weixin.qq.com/s/cD6yjE0T_GYRSo9OblTt8g
# 坐标转换
#https://zhuanlan.zhihu.com/p/40355546
# 需要处理存在多个地理单元的问题，例如河北省
# 
devtools::install_github("caijun/geoChina")
library(leaflet)
library(leafletCN)
library(geoChina)
library(maptools)

setwd("/Users/liding/E/Bdata/rtemp/")
bj <- readLines("hebeib.txt")
bjd <- strsplit(bj, ';')[[1]]

bjll <- strsplit(bjd, ',')
# 有3个区
table(lengths(bjll))
# 可以根据这个lengths信息，进一步拆分
# 
bjll <- as.data.frame(t(data.frame(bjd)))
rownames(bjll) <- 1:length(bjll[,1])
names(bjll) <- c("lon","lat")
bjll[,1] <- as.numeric(as.character(bjll[,1]))
bjll[,2] <- as.numeric(as.character(bjll[,2]))
describe(bjll)

mapgbj=bd2gcj(bjll$lat,bjll$lon)

leaflet() %>% 
  amap() %>%
  addPolylines(data=mapgbj,~lng,~lat,color="blue")


####################################################
##########                                ##########
##########         SECTION 3              ##########
##########                                ##########
####################################################
#########################################
####       用json数据作图            ####
#########################################

## json行政区地图-分省地图
## 地图数据来源 http://datav.aliyun.com/static/tools/atlas/#&lat=33.521903996156105&lng=104.29849999999999&zoom=3
library(dplyr)
library(geojsonio)
library(rgdal)
library(sf)
library(ggplot2)
library(maptools)
library(htmltools)
library(psych)

library(jsonlite)
library(leaflet)
library(plyr)
options(stringsAsFactors=FALSE,warn=FALSE)
setwd("/Users/liding/E/Bdata/liding17/2018R/l14spa/map/")

#读入数据
#geojson2<-fromJSON("中国.json",simplifyVector=FALSE)  #不强转化为数据框。
geojson3<-readLines("中国.json",warn=FALSE,encoding="UTF-8")%>%paste(collapse="\n")%>%fromJSON(simplifyVector=FALSE)

#
mdata <- read.clipboard.tab()
#mdata<-read.delim("/Users/liding/E/Bdata/rtemp/c1617birth.csv",sep="\t")

#向list对象中添加数据
#如果更改变量在264行和282行做对应修改
geojson3$features<-lapply(geojson3$features,function(feat){
  feat$properties$scale<-mdata$jianren[mdata$pid==feat$properties$adcode]
  feat
})

#从list对象中读取数据
mydata<-ldply(geojson3$features,function(feat){ 
  name<-feat$properties$name
  id<- feat$properties$adcode
  mydata<-data.frame(name,id)
})

mydata <- left_join(mydata,mdata,by = c("id" = "pid"))

# Default styles for all features  
geojson3$style=list(weight=1,color="#555555",opacity=1,fillOpacity=0.8)
# Color by scale using quantiles
# mydata$type<-cut(mydata$p2317,c(0,50,60,70,80,100),replace=TRUE)
pal<-colorQuantile("Greens",mydata$jianren)

# Add a properties$style list to each feature
geojson3$features <- lapply(geojson3$features, function(feat) {
  feat$properties$style<-list(
    fillColor=pal(feat$properties$scale)
  )
  feat
})

leaflet()%>%
  setView(mydata,lng=116.38,lat=39.9,zoom=3)%>%
  addGeoJSON(geojson3,group="GeoJSON")




#########################################
####       用json数据作市级图            ####
#########################################
## json行政区地图
## 地图数据来源 http://datav.aliyun.com/static/tools/atlas/#&lat=33.521903996156105&lng=104.29849999999999&zoom=3
library("jsonlite")
library("ggplot2")
library(plyr)
library(dplyr)
setwd("/Users/liding/E/Bdata/liding17/2018R/l14spa/map/")
## 安徽省的地图 
anhui_data <- fromJSON("安徽省.json")
anhui_city_data1<-anhui_data$features$properties[,1:2]
anhui_city_data2<-anhui_data$features$properties$center
anhui_city<-cbind(anhui_city_data1,anhui_city_data2)
names(anhui_city)[2]<-"code"
anhui_city$id<-1:nrow(anhui_city)
anhui_city$sale<-round(rnorm(nrow(anhui_city),100,20),0)
anhui_map_data<-anhui_data $features$geometry$coordinates

mapdata1<-data.frame()
mapdata2<-data.frame()

#  注意下面的参数中 50是 因为有些地区下面还有多个地块，是list格式数据
#  如果作图的时候出现将离散值用于连续变量的提示，就有可能是这里出了问题
#  一个地块的坐标点通常会超过20个

for( i in 1:length(anhui_map_data)){
  citymapdata<-anhui_map_data[[i]]
  if (length(citymapdata)<50){
    for(m in 1:length(citymapdata)){
      citymapt <- citymapdata[[m]]
      dim(citymapt)=c(length(citymapdata[[m]])/2,2)
      citymapdata1<-data.frame(citymapt)
      names(citymapdata1)<-c("lon","lat")
      citymapdata1$id<-i
      citymapdata1$group<-as.numeric(paste0(i,".",m,1))
      citymapdata1$order<-1:dim(citymapdata1)[1]
      mapdata1<-rbind(mapdata1,citymapdata1)
    }
  }else{
    dim(citymapdata)=c(length(citymapdata)/2,2)
    citymapdata2<-data.frame(citymapdata);names(citymapdata2)<-c("lon","lat")
    citymapdata2$id<-i
    citymapdata2$group<-as.numeric(paste0(i,".",1))
    citymapdata2$order<-1:dim(citymapdata2)[1]
    mapdata2<-rbind(mapdata2,citymapdata2)
  }
  mydatanew<-rbind(mapdata1,mapdata2)
}

mydatanew<-arrange(mydatanew,id,order)
mydatanew_map_data<-merge(mydatanew,anhui_city[,c(-3,-4)],by="id")

ggplot(mydatanew_map_data,aes(lon,lat,group=group,fill=sale))+geom_polygon(col="white")+
  theme(               
    panel.grid = element_blank(),
    panel.background = element_blank(),
    axis.text = element_blank(),
    axis.ticks = element_blank(),
    axis.title = element_blank()
  )

####################################################
##########                                ##########
##########         SECTION 4              ##########
##########                                ##########
####################################################

#########################################
####       用网页地图数据作图        ####
#########################################

# 利用高德地图API获取行政边界
if (!require('RCurl')) install.packages("RCurl")
if (!require('rjson')) install.packages("rjson")
if (!require('plyr')) install.packages("plyr")
if (!require('stringr')) install.packages("stringr")
if (!require('ggplot2')) install.packages("ggplot2")
library(sp)
library(rgeos)

# get data
url <- "http://restapi.amap.com/v3/config/district?key=88e5280248b518ac3f7eaec5d6f68183&keywords=原州区&level=city&subdistrict=3&extensions=all"
json <- getURL(url)
list <- fromJSON(json)

# 中心点
center<-list$districts[[1]]$center
cname<-list$districts[[1]]$name
cpoint <- as.numeric(unlist(str_split(center , ",")))
lon <-cpoint[[1]]  
lat <-cpoint[[2]] 

cpoint <- data.frame(lon = lon, lat = lat,cname= cname)
#下属区域
dist <- list$districts[[1]]$districts[[1]]$districts
dname<- sapply(dist, function(x)x[3])
dname<-unlist(dname)
dpoint <- sapply(dist, function(x)x[4])
dpoint <- str_split(dpoint , ",")
lon <- sapply(dpoint, function(x)x[1])
lat <- sapply(dpoint, function(x)x[2])
dpoint <- data.frame(lon = lon, lat = lat,dname= dname)

dpoint[, 1:2] <- sapply(dpoint[, 1:2], function(x)as.numeric(as.character(x)))

# 边界线
line <- list$districts[[1]]$polyline
line <- str_replace(line, '\"', "")
line <- str_split(line, ";")
line <- line[[1]]
line <- str_split(line, ",")
lon <- sapply(line, function(x)x[1])
lat <- sapply(line, function(x)x[2])
point <- data.frame(lon = lon, lat = lat)

amap_table <- data.frame()
point$order <- 1:dim(point)[1]
point[, 1:3] <- sapply(point[, 1:3], function(x)as.numeric(as.character(x)))
amap_table <- rbind(amap_table, point)

# plot the map
#par(family='STKaiti')
ggplot(amap_table, aes(x = lon, y = lat, group = 1)) +
  geom_polygon(colour = 'grey10', fill = 'grey70') +
  geom_point(data=dpoint,aes(x=lon,y=lat)) +
  geom_text(data=dpoint,aes(label = dpoint$dname),family='STKaiti') +
  theme_bw()
#  geom_point(data=cpoint,aes(x=lon,y=lat),colour="red") +

write.table(beijing, "beijing.csv", row.names=FALSE, sep=",")

write.table(amap_table, "guyuan.csv", row.names=FALSE, sep=",")


# 计算点之间的距离
sp.dpoint<-dpoint
coordinates(sp.dpoint) <- ~lon+lat
sp.cpoint<-cpoint
coordinates(sp.cpoint) <- ~lon+lat

class(sp.dpoint)
#计算距离
d <- gDistance(sp.dpoint,sp.cpoint, byid=T)
d2km <- function(d){
  out <- d*60*1.852
  return(out)
}
dkm<-d2km(d) ## 1 degree
colnames(dkm)<-dpoint$dname
dkm[1,]

####################################################
##########                                ##########
##########         SECTION 5              ##########
##########                                ##########
####################################################

#########################################
####       用Baidu地图数据作图        ####
#########################################
library(devtools)
install_github('badbye/baidumap')
install_github('lchiffon/REmap')
devtools::install_github("dkahle/ggmap")
#devtools::install_github("hadley/ggplot2")

options(baidumap.key = '9c9978a893e2dd6c3be3d3241f8e8f61')
library(baidumap)
library(ggmap)
#  lizi https://github.com/dkahle/ggmap

us <- c(left = -125, bottom = 25.75, right = -67, top = 49)
map <- get_stamenmap(us, zoom = 5, maptype = "toner-lite")
ggmap(map)

#http://blog.csdn.net/lotterychampion/article/details/51404364

#1.getBaiduMap函数
#2.getCoordinate函数:根据地址得到经纬度
#3.getLocation：通过经纬度得到地址
#4.getPlace函数：返回地图搜索结果
#5.getRoute函数:通过搜索得到路线

# 感觉精度不是特别准
q <- getBaiduMap('固原市彭堡镇', width=1000, height=1000, zoom=13, scale = 1, messaging=FALSE,color='bw')
pengpu<-c('彭堡镇姚磨村','彭堡镇硝沟村','彭堡镇申庄村','彭堡镇闫堡村','彭堡镇彭堡村','彭堡镇蒋口村','彭堡镇河东村','彭堡镇吴磨村','彭堡镇撒门村','彭堡镇臭水沟村','彭堡镇石碑村','彭堡镇里沟村','彭堡镇别庄村','彭堡镇杨忠堡村','彭堡镇曹洼村')
pengpugeo<-as.data.frame(getCoordinate(pengpu,formatted = T)) 
ggmap(q) + geom_point(data = pengpugeo, aes(longtitude, latitude)) #绘制地图

#获取北京大学的地图信息
#可以同时多个地点
getCoordinate(c('北京大学', '清华大学', '人民大学'), formatted = T)  

getCoordinate("北京市昌平区南口镇龙虎台村",formatted=T)
getLocation(c(118.12845, 24.57232),formatted = T)

#同样可以返回多个位置
getLocation(c(118.12845, 24.57232,116.31234,40.56125),formatted = T)

#百度地图返回JSON数据
# 进行处理
library(rjson)
js <- getLocation(c(116.31617,39.99775),output='json')  #json格式
fromJSON(js) #返回一个列表，包含了该地址下的

## 对于含多个经纬度的矩阵
loc = matrix(c(117.93780, 24.55730, 117.93291, 24.57745, 117.23530, 24.64210, 117.05890, 24.74860), byrow=T, ncol=2)

### 得到json格式
location_json = getLocation(loc, output='json')

### 设计一个函数返回district，即所属的区
getDistrict = function(x_json){
  x_list = fromJSON(x_json)     #json转化为list
  x_list$result$addressComponent$district  #返回所属的区
}

location_district = sapply(location_json, getDistrict) #运用上面的函数到这个json对象上
location_district

#查找北京的大学
bj_college = getPlace('大学','北京')
head(bj_college)

#google地图获取需要使用北大的vpn，人大的vpn不可用
library(ggmap)
q <- get_map("北京",zoom = 11,  source = "stamen",maptype = "toner")
#作图
ggmap(q) + 
  geom_point(data = bj_college, aes(lon, lat)) +
  theme(text = element_text(family = "STKaiti"))


# 盲人按摩 盲人按摩 洗脚
hd_massage = getPlace('足浴','北京市海淀区')
cy_massage = getPlace('足浴','北京市朝阳区')
tz_massage = getPlace('足浴','北京市通州区')
cp_massage = getPlace('足浴','北京市昌平区')
sj_massage = getPlace('足浴','北京市石景山区')
ft_massage = getPlace('足浴','北京市丰台区')
dx_massage = getPlace('足浴','北京市大兴区')
dc_massage = getPlace('足浴','北京市东城区')
xc_massage = getPlace('足浴','北京市西城区')

massage <- rbind(hd_massage,cy_massage,tz_massage,cp_massage,sj_massage,ft_massage,dx_massage,dc_massage,xc_massage)

write.csv(massage,"/Users/liding/E/Bdata/rtemp/data/massage.csv")

ggmap(q) + 
  geom_point(data =massage , aes(lon, lat)) +
  theme(text = element_text(family = "STKaiti"))



## Mcdonald's in shanghai
sh_mcdonald = getPlace('麦当劳', '上海')
head(sh_mcdonald)

pengbu = getPlace('彭堡', '固原')
head(pengbu)

# 路径
bjMap = getBaiduMap('北京',color = 'bw')
df = getRoute('首都国际机场', '北京南苑机场')
ggmap(bjMap) + geom_path(data = df, aes(lon, lat), alpha = 0.5, col = 'red')
head(df)  #此处对getRoute有一个直观认识，得到的是路线上的经纬度



#########################################
#示例1：莆田医院的可视化
##http://www.xueqing.tv/cms/article/199
##获取数据
raw = readLines("http://news.ifeng.com/mainland/special/ptxyy/",
                encoding = "UTF-8")
rawHospital = raw[123 : 238]
## 数据整理
extFun = function(x){
  split = strsplit(x, "','")
  out = strsplit(split[[1]][2], "<br/>")
  return(out)
}
extFun(rawHospital[1])
hosList = sapply(rawHospital,extFun)
hospital = c()
for(i in 1:length(hosList)) hospital = append(hospital, hosList[[i]])
## 获取经纬度
library(baidumap)
blackHospital = getCoordinate(hospital, formatted = T)
blackHospital = na.omit(blackHospital)
plotdata = data.frame(lon = blackHospital[,1],
                      lat = blackHospital[,2],
                      city = rownames(blackHospital))
## 绘制地图
library(REmap)
remapB(markPointData = data.frame(plotdata$city),
       markPointTheme = markPointControl(symbol = "pin",
                                         effect=F,
                                         symbolSize = 5,
                                         color="red"),
       geoData = plotdata)


#########################################
#示例2：迁徙图 remapC
# https://ask.hellobi.com/blog/ecnuliuyang/5613
set.seed(20161126)
pop <- runif(19,0,1)
stu<-data.frame( district = mapNames('shanghai'), values = round(pop*100) )
stu<-stu[order(stu[,2],decreasing =T),]
head(stu)

library(REmap)
markLine_data <- data.frame(origin=rep("华东师范大学闵行校区",5), destination=stu[1:5,1] )
markPoint_data <- as.character(unlist(markLine_data[,2]))
remapC(stu, maptype = '上海',
       title="模拟的迁徙图", subtitle="迁徙人数前5的目标省份",
       theme=get_theme( theme="Dark", titleColor = "#FFFFFF"),
       maxdata = 100,mindata=0,
       color=c('#FF0000','#C0C0C0'),   #颜色渐变:红－>灰
       markLineData=markLine_data,   
       markLineTheme=markLineControl( symbolSize = 6, effect =T, color="white", lineWidth=4, lineType="dashed" ),
       markPointData=markPoint_data,
       markPointTheme=markPointControl( symbol = 'heart', symbolSize=12, effect=T, effectType = 'bounce', color="white")
)

#########################################
#示例3：热力图remapC
library(baidumap)
ll<-matrix(0,19,2)
for(i in 1:19)  ll[i,]<- get_city_coord(as(stu$district[i],'character')) # 比 getCoordinate 精度高
data<-cbind(stu,ll)[,c(3,4,2)]
theme <- get_theme(theme ="none", titleColor ="red", backgroundColor ="white", borderColor ="blue", labelShow = T)
remapH(data, title = '模拟热力图',
       maptype = '上海',
       theme = theme,
       blurSize = 60,
       color = "blackred",
       minAlpha= 1,
       opacity = 1
)


#########################################
####       用ggmap和google地图作图   ####
#########################################
# 使用google地图API，可能需要翻墙
#ggmap将ggplot2和map相结合。这样R语言用户能方便的获取各种静态地图数据，并在其基础上使用强大的ggplot绘图工具。
# ggmap包整合了四种地图资源，分别是Google、OpenStreetMaps、Stamen和Cloudmade。
# 加载扩展包
library(ggmap)
library(animation)
library(RCurl)
library(XML)

#ggmap包中geocode函数可以根据地名字符串来查询经纬度
ad1 <- as.numeric(geocode("福建省厦门市思明南路422",source = "google"))
xmu <- get_map("厦门市思明区",zoom = 13, maptype = "roadmap")
ggmap(xmu, extent = "normal") +
  geom_point(aes(x=ad1[1], y =ad1[2]))
# gglocator类似于基本包中的locator，它根据鼠标的点选来返回其坐标值。
# mapdist函数，可以返回两点之间的地图距离和行驶时间。结合这几个函数可以直接在R中绘制地图，选择你的出发地和目标地，然后获得两地之间的距离。还可以配合GPS等其它数据，创造出其它有意思的图形。
#http是普通超文本协议，其信息室明文传送，而https就是安全超文本传输协议，需要证书和提供安全连接，https是嵌套了SSL加密的http连接，其内容会由SSL先加密，然后再传送。
## 计算不同地点的交通距离
#https://stackoverflow.com/questions/1042885/using-google-maps-api-to-get-travel-time-data
#https://developers.google.com/maps/documentation/distance-matrix/start
# google必须展示地图
#https://www.quora.com/Alternative-to-Google-Maps-Distance-Matrix-API
#https://developer.mapquest.com/documentation/directions-api/route-matrix/post/

## ggmap实例：罪案发生地信息图
# gmplot是简单快速版
library(dplyr)
# only violent crimes
violent_crimes <- filter(crime, 
                         offense != "auto theft", offense != "theft", offense != "burglary"
)
# rank violent crimes
violent_crimes$offense <- factor(
  violent_crimes$offense,
  levels = c("robbery", "aggravated assault", "rape", "murder")
)
# restrict to downtown
violent_crimes <- filter(violent_crimes,
                         -95.39681 <= lon & lon <= -95.34188,
                         29.73631 <= lat & lat <=  29.78400
)

#点图
qmplot(lon, lat, data = violent_crimes, maptype = "toner-lite", color = I("red"))
#等高线
qmplot(lon, lat, data = violent_crimes, maptype = "toner-lite", geom = "density2d", color = I("red"))
#热力
robberies <- violent_crimes %>% filter(offense == "robbery")

qmplot(lon, lat, data = violent_crimes, geom = "blank", zoom = 15, maptype = "toner-background", darken = .7, legend = "topleft") +
  stat_density_2d(aes(fill = ..level..), geom = "polygon", alpha = .3, color = NA) +
  scale_fill_gradient2("Robbery\nPropensity", low = "white", mid = "yellow", high = "red", midpoint = 650)

# 分面、分色
qmplot(lon, lat, data = violent_crimes, maptype = "toner-background", color = offense) + 
  facet_wrap(~ offense)

##ggmap 示例2 地震变化图
#https://web.archive.org/web/20130311084317/http://xccds1977.blogspot.com/2012/06/ggmap.html
# 本例是从地震信息网获取最近一周的地震数据，得到其经纬度，然后以散点形式绘制在google地图上，另外也显示地震发生的密度估计。
library(ggmap)
library(animation)
library(RCurl)
library(XML)
# 从网页上抓取数据，并进行清理
webpage <-'https://web.archive.org/web/20130305074751/http://data.earthquake.cn:80/datashare/globeEarthquake_csn.html'
#注意，得到的是文本
html<-getURL(webpage,.encoding='GB2312')
tables <- readHTMLTable(html,stringsAsFactors = FALSE)
raw <- tables[[9]]
data <- raw[-1,c(1,3,4)]
names(data) <- c('date','lan','lon')
data$lan <- as.numeric(data$lan)
data$lon <- as.numeric(data$lon)
data$date <- as.Date(data$date,  "%Y-%m-%d")
# 用ggmap包从google读取地图数据，并将之前的数据标注在地图上
# google 不可用，用stamen
chi2<-get_map(location = 'china', zoom=4,maptype='terrain',source = "stamen")

ggmap(chi2)+
  geom_point(data=data,aes(x=lon,y=lan),colour = 'red',alpha=0.7)+
  stat_density2d(aes(x=lon,y=lan,fill=..level..,alpha=..level..),
                 size=2,bins=4,data=data,geom='polygon')+
  options(legend.position = "none")

#更好玩的作法就是根据地震发生的日期，用animaiton包将其整合为一个gif动画。
# 制作动态图可以用更简单的方式，将前面的入门。
# 需要安装 GraphicsMagick
# mac中可以通过brew安装了GraphicsMagick，具体见相关文档
# https://github.com/aheckmann/gm/wiki/Installing-ImageMagick---GraphicsMagick
# https://brew.sh/
# https://stackoverflow.com/questions/17756587/installing-graphicsmagick-on-mac-os-x-10-8

# 将GraphicMagick的路径放到PATH变量中
# 修改方法：http://architectryan.com/2012/10/02/add-to-the-path-on-mac-os-x-mountain-lion/#.WV8AgNOGMnU
# 路径在 /usr/local/Cellar/graphicsmagick/1.3.25/bin/gm  

# animation安装新版本：https://github.com/yihui/animation/releases/tag/v2.5

# 在R中查看系统属性
#Sys.getenv()
#Sys.setenv(https_proxy="")
#Sys.setenv(https_proxy="https://duotai:yR_nIc-U2XBs@marriott.h.xduotai.com:10369")
# 为了生成动画，先准备好一个绘图函数

Sys.getenv("PATH")
# Sys.setenv(PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/opt/local/bin")

plotfunc <- function(x) {
  df <- subset(data,date <= x)
  df$lan <- as.numeric(df$lan)
  df$lon <- as.numeric(df$lon)
  p <- ggmap(chi,extent='device') +
    geom_point(data=df,aes(x=lon,y=lan),colour = 'red',alpha=0.7)
}
# 获取地震的日期
time <- sort(unique(data$date))
# 生成并保存动画，HTML格式
#for( i in time) print(plotfunc(i))
saveHTML(for( i in time) print(plotfunc(i)),htmlfile='earthquake.html')
#参数设定
ani.options(gm.convert="/usr/local/Cellar/graphicsmagick/1.3.25/bin/")
ani.options(interval=1)
saveGIF(for( i in time) print(plotfunc(i)),movie.name = "ekanimation.gif",convert='gm convert')

## 一个简答的图
saveGIF({
  for (i in 1:10) plot(runif(10), ylim = 0:1)
},convert ='gm convert',movie.name='aplot')


## 交互式作图
require(devtools)
install_github('rCharts', 'ramnathv')
library(rCharts) 
names(iris) = gsub("\\.", "", names(iris))
p1 <- rPlot(SepalLength ~ SepalWidth | Species, data = iris, color = 'Species', type = 'point') 
p1

####################################################
##########                                ##########
##########         SECTION 5              ##########
##########                                ##########
####################################################

# 在栅格地图和卫片上制作地图
# 遥感图片分析
# 见文件 make-maps-in-r

## 回龙观的图书馆
hlglab <- c("昌平区图书馆回龙观第一分馆",
            "昌平区回龙观爱丁岛亲子悦读馆",
            "昌平区回龙观爱阅宝亲子图书馆",
            "昌平区回龙观樊登书店",
            "昌平区回龙观回+创业图书馆",
            "昌平区回龙观回龙观亲子图书馆",
            "昌平区回龙观三联回+书店",
            "昌平区回龙观桃园书馆",
            "昌平区回龙观玩美时光图书馆",
            "昌平区回龙观幸福树童书屋",
            "昌平区回龙观悦学思素质教育空间")
  
library(baidumap)
options(baidumap.key = '9c9978a893e2dd6c3be3d3241f8e8f61')
hllab = getCoordinate(hlglab, formatted = T)
hllab = na.omit(hllab)
plotdata = data.frame(lon = hllab[,1],
                      lat = hllab[,2],
                      city = rownames(hllab))
## 绘制地图
library(REmap)
remapB(markPointData = data.frame(plotdata$city),
       markPointTheme = markPointControl(symbol = "pin",
                                         effect=F,
                                         symbolSize = 5,
                                         color="red"),
       geoData = plotdata)

##  recharts 最快的一种方式
library(recharts)
mapData <- data.frame(province=c("上海", "江苏", "广东", "黑龙江"), 
                      val1=c(100, 200, 300, 500), val2=c(200,300,400,200), val3=c(1,2,3,5), stringsAsFactors=F)

## 全国地图
eMap(mapData, namevar=~province, datavar = ~val1+val2)

provinceMapData <- data.frame(city=c("扬州市", "南京市", "苏州市"), value=c(100, 200, 300),
                              val2=c(200,300,400), val3=c(1,2,3), stringsAsFactors=F)
## 省份地图
eMap(provinceMapData, namevar=~city, datavar = ~value+val2, region="江苏")


require(devtools)
devtools::install_github('cosname/recharts')
library(recharts)
mapData <-psych::read.clipboard.tab()
#pname	jianren
#北京	60.4
#天津	6.7
#河北	21.9
#山西	31.1
#内蒙古	10.1
#辽宁	30.7
#吉林	69.4
#黑龙江	18.9
#上海	27.9
#江苏	23.2
#浙江	6.2
#安徽	21.0
#福建	6.4
#江西	16.6
#山东	55.2
#河南	33.7
#湖北	91.8
#湖南	20.1
#广东	79.3
#广西	24.5
#海南	98.5
#重庆	3.0
#四川	3.4
#贵州	5.6
#云南	28.9
#西藏	40.7
#陕西	9.2
#甘肃	5.3
#青海	4.5
#宁夏	39.0
#新疆	55.0
## 全国地图
eMap(mapData, namevar=~pname, datavar = ~jianren, color = c("#238B45", "#f0ffff"),theme="purple-passion")

