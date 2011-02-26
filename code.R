require(ggplot2)
require(maptools)
require(rgdal)
require(RColorBrewer)

gpclibPermit()

# based heavily(completely?) on 
# https://github.com/hadley/ggplot2/wiki/plotting-polygon-shapefiles
## thanks again hwickamn

# read the precinct results
df <- read.csv("precincts.csv")
# make a combined ward-precinct identifier to make the shape lookup easier
df$WARD_PRECINCT <- sprintf("%d-%d",df$ward,df$precinct)

# read the shapefile
shp <- readShapeSpatial("Precincts/Precincts")
# make a combined ward-precinct identifier
shp$WARD_PRECINCT <- sprintf("%d-%d", shp$WARD,shp$PRECINCT)

# assign an ID to each polygon, and pull out the individual points
shp@data$id <- rownames(shp@data)
pts <- fortify(shp,region="id")

# merge in the other shapefile data
shp.df <- merge(pts,shp,by="id")

# merge in the election results
shp.df <- merge(shp.df,df,by="WARD_PRECINCT")

# shp.df is all kinds of out of order right now. need to order by WARD_PRECINCT,order
# or we end up with a broken polygon path
shp.df <- shp.df[order(shp.df$id,shp.df$order),]

# make new factor variables for candidate vote %

shp.df$emanuel_pct_f <- cut(shp.df$emanuel_pct,breaks=seq(0,100,20),include.lowest=T)
shp.df$delvalle_pct_f <- cut(shp.df$delvalle_pct,breaks=seq(0,100,20),include.lowest=T)
shp.df$braun_pct_f <- cut(shp.df$braun_pct,breaks=seq(0,100,20),include.lowest=T)
shp.df$chico_pct_f <- cut(shp.df$chico_pct,breaks=seq(0,100,20),include.lowest=T)
shp.df$watkins_pct_f <- cut(shp.df$watkins_pct,breaks=seq(0,100,20),include.lowest=T)
shp.df$walls_pct_f <- cut(shp.df$walls_pct,breaks=seq(0,100,20),include.lowest=T)


# store off an opts() strucure that blanks out the parts of the map we dont want
blank_opts <- opts(panel.grid.major=theme_blank(),panel.grid.minor=theme_blank(),
				   panel.background=theme_blank(),axis.ticks=theme_blank(),
				   axis.text.x=theme_blank(),axis.text.y=theme_blank(),
				   axis.title.x=theme_blank(),axis.title.y=theme_blank(),
				   panel.margin = unit(0, "lines"))

# plot the map w/ each candidates win percentage 
png("emanuel.png",width=620,height=620)
ggplot(shp.df,aes(long,lat,group=group)) + geom_polygon(aes(fill=emanuel_pct_f)) + 
	coord_equal() + scale_fill_brewer(palette="Blues",name="Emanuel %") + blank_opts + opts(title="Chicago Mayoral Race 2011")
dev.off()

png("delvalle.png",width=620,height=620)
ggplot(shp.df,aes(long,lat,group=group)) + geom_polygon(aes(fill=delvalle_pct_f)) + 
	coord_equal() + scale_fill_brewer(palette="Blues",name="DelValle %") + blank_opts + opts(title="Chicago Mayoral Race 2011")
dev.off()

png("braun.png",width=620,height=620)
ggplot(shp.df,aes(long,lat,group=group)) + geom_polygon(aes(fill=braun_pct_f)) + 
	coord_equal() + scale_fill_brewer(palette="Blues",name="Braun %") + blank_opts + opts(title="Chicago Mayoral Race 2011")
dev.off()

png("chico.png",width=620,height=620)
ggplot(shp.df,aes(long,lat,group=group)) + geom_polygon(aes(fill=chico_pct_f)) + 
	coord_equal() + scale_fill_brewer(palette="Blues",name="Chico %") + blank_opts + opts(title="Chicago Mayoral Race 2011")
dev.off()
		
png("watkins.png",width=620,height=620)
ggplot(shp.df,aes(long,lat,group=group)) + geom_polygon(aes(fill=watkins_pct_f)) + 
	coord_equal() + scale_fill_brewer(palette="Blues",name="Watkins %") + blank_opts + opts(title="Chicago Mayoral Race 2011")
dev.off()

png("walls.png",width=620,height=620)
ggplot(shp.df,aes(long,lat,group=group)) + geom_polygon(aes(fill=walls_pct_f)) + 
	coord_equal() + scale_fill_brewer(palette="Blues",name="Walls %") + blank_opts + opts(title="Chicago Mayoral Race 2011")
dev.off()

# melt the data frame from wide to long form by WARD_PRECINCT for each election % return
df.m <- melt(df,"WARD_PRECINCT", c("emanuel_pct","delvalle_pct","braun_pct","chico_pct","watkins_pct","walls_pct"))

# generate one precincts-votes plot for emanuel
png("emanuel_sv.png",width=620,height=620)
qplot(emanuel_pct,data=df,geom=c("density","rug"),main="Precincts-Votes Curve, Chicago Mayor 2011",xlab="Vote %",ylab="Density")
dev.off()
		
# generate a combined precincts-votes plot for all candidates
png("all_sv.png",width=620,height=620)
qplot(x=value,group=variable,color=variable,data=df.m,geom="density",
		main="Precincts-Votes Curve, Chicago Mayor 2011",xlab="Vote %",ylab="Density") + 
		scale_color_brewer(palette="Set3",name="Candidate")
dev.off()

# Candidates Walls, Watkins, and Braun performed very poorly in a majority of precincts so the scale is off for the rest of the candidates. 
# Exclude those candidates to better understand the performance of the top 3 candidates
png("emanuel_delvalle_chico_sv.png",width=620,height=620)
qplot(x=value,group=variable,color=variable,data=subset(df.m,variable != 'walls_pct' & variable != 'braun_pct' & variable != 'watkins_pct'),
 		geom="density",main="Precincts-Votes Curve, Chicago Mayor 2011",xlab="Vote %",ylab="Density") + 
 		scale_color_brewer(palette="Set3",name="Candidate", labels=c("Emanuel", "Del Valle", "Chico"),
		breaks=c("emanuel_pct", "delvalle_pct","chico_pct"))
dev.off()
