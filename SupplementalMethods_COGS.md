SupplementalMethods_COGS
================
Tommy Tran (KLemonLab)
Last updated: 09/20/2022

# COG ANALYSIS WITH PPanGGOLiN partitions BINS

## Data Import

This is an interactive Notebook, therefore it has to be knitted with
parameters. That way we can read the output of `anvi-summarize` for one
pangenome at a time and the output files get named based on species.
There are copies of the Anvi’o summary files on the
“main_outputs/Anvio7” folder.

This reads the parameters into objects:

``` r
Pangenome <- read.delim(params$data)
Species <- params$species
```

For editing the file you can run code for a specific pangenome with
this:

``` r
#Pangenome <- read.delim("main_outputs/COGs/PAN_Cpse_gene_clusters_summary.txt.gz")
#Species <- "Cpse"
```

## Data Cleaning

We select the most relevant variables for the functional analysis:

``` r
Pangenome <- Pangenome %>%
  select(-functional_homogeneity_index, -geometric_homogeneity_index, -combined_homogeneity_index, -aa_sequence)
```

In the new variable “bins_PPanGGOLiN” we define “Persistent” and
“Accessory” (as shell”+“cloud”):

``` r
Pangenome <- Pangenome %>%
  mutate(bins_PPanGGOLiN = ifelse(grepl("persistent", PPanGGOLiN), "Persistent", "Accessory"))
```

Number and percentage of Persistent vs Accessory:

``` r
vPersistent <- nrow(Pangenome %>% group_by(gene_cluster_id) %>% filter(bins_PPanGGOLiN =="Persistent") %>% summarise)
vAccesory <- nrow(Pangenome %>% group_by(gene_cluster_id) %>% filter(bins_PPanGGOLiN =="Accessory") %>% summarise)

vPersistent.p <- round(100*vPersistent/(vAccesory+vPersistent), 1)
vAccesory.p <- round(100*vAccesory/(vAccesory+vPersistent), 1)
```

``` r
vPersistent.p
vAccesory.p
```

``` r
There are `r vAccesory` gene clusters (GC) (`r vAccesory.p`%) in the "Accessory" vs. `r vPersistent` (`r vPersistent.p`%) in the "Persistent" at the pangenome level
```

## COG Analysis at the Gene Level

We define a new variable `COGs` to use in the plots. This variable is
based on `COG20_CATEGORY` but with a cleaner definition of unclassified,
uninformative, or mixed assignments:

-   COG categories “Function Unknown” and “General function predictions
    only” were considered as “Uninformative”.
-   If the COG category is mix (e.g., G\|S\|M) it gets labeled as
    “Ambiguous”.
-   Missing values (NA) are labeled as “Unclassified”.

``` r
Pangenome$COGs <- Pangenome$COG20_CATEGORY_ACC
Pangenome$COGs[Pangenome$COGs =="S"]<- "Uninformative"
Pangenome$COGs[Pangenome$COGs =="R"]<- "Uninformative"
Pangenome$COGs[grepl('|', Pangenome$COGs,fixed=TRUE)]<-"Ambiguous"
Pangenome$COGs[Pangenome$COGs ==""]<-"Unclassified"
```

Summary of COG annotated genes:

## COG Analysis at the Gene Cluster Level

This analysis was done at the pangenomic gene cluster level (GC). Since
many gene clusters had mixed COG category assignments a solution is to
assign each individual gene call to their corresponding
Genome/bins_PPanGGOLiN/COG grouping weighting their contribution by
dividing their count by the number of genes in their GC.

### GCs by COG Category and Genome

The table “GCsbyCOG_Genome” groups the genes by genome; and inside
genomes by “Accessory” vs. “Persistent” status, and nested inside as the
COG category. But, in this case, instead of counting the elements in
each group we calculated the sum of 1/`num_genes_in_gene_cluster`.

``` r
Pangenome$COGs <- as.factor(Pangenome$COGs)
GCsbyCOG_Genome <- Pangenome %>%
  group_by(genome_name, bins_PPanGGOLiN, COGs, .drop=FALSE) %>%
  summarise(num_corrected_genes=sum(1/num_genes_in_gene_cluster))
```

The total sum of all values in the `num_corrected_genes` variable should
add up to the number of CGs:

``` r
sum(GCsbyCOG_Genome$num_corrected_genes)
nrow(Pangenome %>% group_by(gene_cluster_id) %>% summarise)
```

Adding extra column to label the gray scale portion of the plots:

``` r
GCsbyCOG_Genome <- GCsbyCOG_Genome %>%
  mutate(Assignment=ifelse(COGs!="Uninformative" & COGs!="Ambiguous" & COGs!="Unclassified", "Informative", as.character(COGs)))
```

#### Summary of GOC annotated GCs in the Accessory vs. Persistent

``` r
TableGC <- GCsbyCOG_Genome %>% 
  group_by(bins_PPanGGOLiN, Assignment) %>%
  summarize(corrected_genes=sum(num_corrected_genes))

TableGC$Percentages <- round(100*TableGC$corrected_genes/sum(TableGC$corrected_genes), 1)

kable(TableGC)
```

#### Summary of GOC annotated GCs in the Accessory

``` r
TableGCAccessory <- GCsbyCOG_Genome %>% 
  filter(bins_PPanGGOLiN =="Accessory") %>%
  group_by(bins_PPanGGOLiN, Assignment) %>%
  summarize(corrected_genes=sum(num_corrected_genes))

TableGCAccessory$Percentages <- round(100*TableGCAccessory$corrected_genes/sum(TableGCAccessory$corrected_genes), 1)

kable(TableGCAccessory)
```

#### Summary of GOC annotated GCs in the Persistent

``` r
TableGCPersistent <- GCsbyCOG_Genome %>% 
  filter(bins_PPanGGOLiN =="Persistent") %>%
  group_by(bins_PPanGGOLiN, Assignment) %>%
  summarize(corrected_genes=sum(num_corrected_genes))

TableGCPersistent$Percentages <- round(100*TableGCPersistent$corrected_genes/sum(TableGCPersistent$corrected_genes), 1)

kable(TableGCPersistent)
```

#### Summary of GOC annotated GCs by Genome in the Accessory vs. Persistent

``` r
TableGenomes <- GCsbyCOG_Genome %>% 
  group_by(genome_name, bins_PPanGGOLiN) %>% 
  summarize(corrected_genes=sum(num_corrected_genes))

kable(TableGenomes)
```

#### Renaming and ordering variables factor levels for plotting:

``` r
GCsbyCOG_Genome$bins_PPanGGOLiN <- factor(GCsbyCOG_Genome$bins_PPanGGOLiN, levels =c("Persistent", "Accessory"))

GCsbyCOG_Genome$COGs <- recode_factor(GCsbyCOG_Genome$COGs, "Q"="Secondary metabolites biosynthesis, transport, and catabolism","P"="Inorganic ion transport and metabolism","I"="Lipid transport and metabolism","H"="Coenzyme transport and metabolism","G"="Carbohydrate transport and metabolism","F"="Nucleotide transport and metabolism","E"="Amino acid transport and metabolism","C"="Energy production and conversion","X"="Mobilome: prophages, transposons","L"="Replication, recombination and repair","K"="Transcription","J"="Translation, ribosomal structure and biogenesis","V"="Defense mechanisms","U"="Intracellular trafficking, secretion, and vesicular transport","T"="Signal transduction mechanisms","O"="Post-translational modification, protein turnover, and chaperones","N"="Cell Motility","M"="Cell wall/membrane/envelope biogenesis","D"="Cell cycle control, cell division, chromosome partitioning","A"="RNA processing and modification","W"="Extracellular structures","Uninformative"="Uninformative","Ambiguous"="Ambiguous","Unclassified"="Unclassified", .ordered = TRUE)

GCsbyCOG_Genome$Assignment <- recode_factor(GCsbyCOG_Genome$Assignment,  "Informative"=" ", "Uninformative"="Uninformative", "Ambiguous"="Ambiguous", "Unclassified"="Unclassified", .ordered = TRUE)
```

### GCs by COG Category

The table “GCsbyCOG” groups the genes by “Accessory” vs. “Persistent”
status, and nested inside as the COG category.

``` r
GCsbyCOG <- Pangenome %>%
  group_by(bins_PPanGGOLiN, COGs) %>%
  summarise(num_corrected_genes=sum(1/num_genes_in_gene_cluster))
```

#### Renaming and ordering variables factor levels for plotting:

``` r
GCsbyCOG$COGs <- recode_factor(GCsbyCOG$COGs, "Q"="Secondary metabolites biosynthesis, transport, and catabolism",
                               "P"="Inorganic ion transport and metabolism",
                               "I"="Lipid transport and metabolism",
                               "H"="Coenzyme transport and metabolism",
                               "G"="Carbohydrate transport and metabolism",
                               "F"="Nucleotide transport and metabolism",
                               "E"="Amino acid transport and metabolism",
                               "C"="Energy production and conversion",
                               "X"="Mobilome: prophages, transposons",
                               "L"="Replication, recombination and repair",
                               "K"="Transcription",
                               "J"="Translation, ribosomal structure and biogenesis",
                               "V"="Defense mechanisms",
                               "U"="Intracellular trafficking, secretion, and vesicular transport",
                               "T"="Signal transduction mechanisms",
                               "O"="Post-translational modification, protein turnover, and chaperones",
                               "N"="Cell Motility",
                               "M"="Cell wall/membrane/envelope biogenesis",
                               "D"="Cell cycle control, cell division, chromosome partitioning",
                               "A"="RNA processing and modification",
                               "W"="Extracellular structures",
                               "Uninformative"="Uninformative",
                               "Ambiguous"="Ambiguous",
                               "Unclassified"="Unclassified", .ordered = TRUE)
```

#### Summary of GOC annotated GCs GCs by COG Category:

New table “GCsbyCOG_PervsAcc” in wide format. % of each category
relative to the “Accessory” or “Persistent” was calculated (pTotal.
variables). Total GCs for each COG category calculated, and % of GCs in
the “Accessory” and “Persistent” relative to each category (p. values)
were calculated as well. The ratio between the number of GC in the
“Accessory” vs. the “Persistent” is calculated for each COG:

``` r
GCsbyCOG_PervsAcc <- spread(GCsbyCOG, bins_PPanGGOLiN, num_corrected_genes, fill=0)
GCsbyCOG_PervsAcc$pTotal.Accessory <- round(100*GCsbyCOG_PervsAcc$Accessory/sum(GCsbyCOG_PervsAcc$Accessory), 1)
GCsbyCOG_PervsAcc$pTotal.Persistent <- round(100*GCsbyCOG_PervsAcc$Persistent/sum(GCsbyCOG_PervsAcc$Persistent), 1)
GCsbyCOG_PervsAcc$total <- GCsbyCOG_PervsAcc$Accessory + GCsbyCOG_PervsAcc$Persistent
GCsbyCOG_PervsAcc$pTotal.total <- round(100*GCsbyCOG_PervsAcc$total/sum(GCsbyCOG_PervsAcc$total), 1)
GCsbyCOG_PervsAcc$p.accessory <- round(100*(GCsbyCOG_PervsAcc$Accessory/GCsbyCOG_PervsAcc$total), 1)
GCsbyCOG_PervsAcc$p.Persistent <- round(100*(GCsbyCOG_PervsAcc$Persistent/GCsbyCOG_PervsAcc$total), 1)
GCsbyCOG_PervsAcc$ratio <- round(GCsbyCOG_PervsAcc$Accessory/GCsbyCOG_PervsAcc$Persistent, 2)

kable(GCsbyCOG_PervsAcc)
```

## Plots

Color Palettes

``` r
getPalette <- colorRampPalette(brewer.pal(8, "Set1"))
CountTotalCOGs <- length(unique(GCsbyCOG_Genome$COGs))

palette1 <- c("grey60", "grey40", "grey20", getPalette(CountTotalCOGs-3)) # Colors + Grays
palette2 <- getPalette(CountTotalCOGs-3) # Colors
palette3 <- c("grey60", "grey40", "grey20", "white") # White + Grays
```

### Plots Accessory vs. Persistent

Panel A in main figure:

``` r
pA <- ggplot(GCsbyCOG_Genome, aes(x = bins_PPanGGOLiN, y = num_corrected_genes, fill = fct_rev(COGs))) +
  stat_summary(fun=sum ,geom="bar", position = "stack") +
  scale_x_discrete(labels = c("Persistent", "Accessory")) +
  scale_fill_manual(values = palette1) +
  scale_y_continuous(expand = c(0,0), breaks=seq(0, 2250, by = 250)) +
  labs(fill="COG Categories", x=" ", y= "Number of Gene Clusters") +
  theme_classic() +
  theme(axis.title = element_text(size = 9), axis.text = element_text(size=7), plot.margin=unit(c(10,0,10,20),"pt"), legend.position = "none") 
```

This plot is used for the grayscale legend:

``` r
pB <- ggplot(GCsbyCOG_Genome, aes(x = bins_PPanGGOLiN, y = num_corrected_genes, fill = fct_rev(Assignment))) +
  stat_summary(fun=sum ,geom="bar", position = "stack") +
  scale_x_discrete(labels = c("Persistent", "Accessory")) +
  scale_fill_manual(values = palette3) +
  scale_y_continuous(expand = c(0,0), breaks=seq(0, 2250, by = 250)) +
  labs(fill=" ", x=" ", y= "Number of Gene Clusters") +
  theme_classic() +
  theme(axis.title = element_text(size = 9), axis.text = element_text(size=7), plot.margin=unit(c(10,0,10,20),"pt"), legend.key.size = unit(0.7, "line"), legend.text = element_text(size = 7), legend.box.margin = margin(10,20,10,10)) +
  guides(fill=guide_legend(ncol=1, title.position = "top", title.hjust = 0.5))
```

### Plots by Genome (Accessory)

Panel A in supplemental figure:

``` r
pC <- ggplot(filter(GCsbyCOG_Genome, bins_PPanGGOLiN == "Accessory"), aes(x=genome_name, y=num_corrected_genes, fill = fct_rev(COGs))) +
  stat_summary(fun=sum ,geom="bar", position = "stack") +
  scale_fill_manual(values = palette1) +
  scale_y_continuous(expand = c(0,0)) + 
  labs(fill="COG Assignment", x="", y= "Number of Gene Clusters") +
  theme_classic() + 
  theme(axis.text.y = element_text(size=7), axis.text.x = element_text(size=8, angle=75, hjust=1)) +
  theme(legend.position = "none", plot.margin=unit(c(15,15,-10,20),"pt")) 
```

Panel B in supplemental figure:

``` r
pD <- ggplot(filter(GCsbyCOG_Genome %>% filter(COGs != "Uninformative", COGs !="Ambiguous", COGs != "Unclassified"), bins_PPanGGOLiN == "Accessory"), aes(x=genome_name, y=num_corrected_genes, fill = fct_rev(COGs))) +
  stat_summary(fun=sum ,geom="bar", position = "stack") +
  scale_y_continuous(expand = c(0,0)) + 
  scale_fill_manual(values = palette2) + 
  labs(fill="COG Categories", x="", y= "Number of Informative Gene Clusters") +
  theme_classic() + 
  theme(axis.text.y = element_text(size=7), axis.text.x = element_text(size=8, angle=75, hjust=1)) +
  theme(legend.position="bottom", legend.key.size = unit(0.7, "line"), legend.text = element_text(size = 8), plot.margin=unit(c(0,15,0,20),"pt")) +
  guides(fill=guide_legend(ncol=2, title.position = "top", title.hjust = 0.5)) 
```

This plot is used for the grayscale legend:

``` r
pE <- ggplot(filter(GCsbyCOG_Genome, bins_PPanGGOLiN == "Accessory"), aes(x=genome_name, y=num_corrected_genes, fill = fct_rev(Assignment))) +
  stat_summary(fun=sum ,geom="bar", position = "stack") +
  scale_fill_manual(values = palette3) +
  scale_y_continuous(expand = c(0,0)) + 
  labs(fill=paste("Accessory Genome COG Assignment (", Species, ")", sep =""), x="", y= "Number of Gene Clusters") +
  theme_classic() + 
  theme(axis.text.y = element_text(size=7), axis.text.x = element_text(size=8, angle=75, hjust=1)) +
  theme(legend.position="bottom", legend.key.size = unit(0.7, "line"), legend.text = element_text(size = 8), legend.title = element_text(face="bold", size = 12), plot.margin=unit(c(15,15,0,20),"pt")) +
  guides(fill=guide_legend(nrow=1, title.position = "top", title.hjust = -5))
```

### Plots by COG Category

In order to represent the Persistent on the left of the plot with
absolute values per COG category we create `per.neg`; a negative version
of the `persistent` variable in GCsbyCOG_PervsAcc. Table converted to
the long format for plotting.

``` r
GCsbyCOG_PervsAcc$per.neg <- -GCsbyCOG_PervsAcc$Persistent
GCsbyCOG_PervsAccLong <- gather(GCsbyCOG_PervsAcc, bins_PPanGGOLiN, plotting, per.neg, Accessory)
kable(GCsbyCOG_PervsAccLong)
```

Panel B in main figure:

``` r
pF <- ggplot(filter(GCsbyCOG_PervsAccLong, COGs != "Uninformative", COGs != "Ambiguous", COGs != "Unclassified"), aes(x = COGs, y = plotting, fill = COGs)) +
  geom_bar(stat="identity") + 
  scale_fill_manual(values = rev(palette2)) + 
  scale_x_discrete(position = "top") +
  labs(title= "COG Categories", x="", y= "Number of Gene Clusters") +
  coord_flip() +
  scale_y_continuous(limits = c(-200, 200), breaks = c(-150, -100, -50, 0, 50, 100, 150), label = c(150, 100, 50, 0, 50, 100, 150)) +
  geom_segment(aes(x=0,xend=19.5,y=0,yend=0), linetype=3, size=0.1) +
  geom_label(aes(x = 22.5, y = -95, label = "      Persistent       "), fontface="bold", size=3, fill = "grey90", label.size=NA, label.padding = unit(0.3, "lines")) +
  geom_label(aes(x = 22.5, y = 95, label = "     Accessory      "), fontface="bold", size=3, fill = "grey90", label.size=NA, label.padding = unit(0.3, "lines")) +
  theme_classic() +
  theme(axis.title = element_text(size = 9), axis.text.x = element_text(size=7), axis.ticks.y = element_blank(), axis.line.y = element_blank(), legend.position = "none", plot.margin=unit(c(5,10,10,25),"pt"), plot.title=element_text(face="bold", hjust=3, vjust=-3.9)) 

gpF <- ggplotGrob(pF)
gpF$layout$clip[gpF$layout$name=="panel"] <- "off"
```

Panel B in main figure without geom_labels

``` r
pG <- ggplot(filter(GCsbyCOG_PervsAccLong, COGs != "Uninformative", COGs != "Ambiguous", COGs != "Unclassified"), aes(x = COGs, y = plotting, fill = COGs)) +
  geom_bar(stat="identity") + 
  scale_fill_manual(values = rev(palette2)) + 
  scale_x_discrete(position = "top") +
  labs(title= "COG Categories", x="", y= "Number of Gene Clusters") +
  coord_flip() +
  scale_y_continuous(limits = c(-200, 200), breaks = c(-150, -100, -50, 0, 50, 100, 150), label = c(150, 100, 50, 0, 50, 100, 150)) +
  geom_segment(aes(x=0,xend=19.5,y=0,yend=0), linetype=3, size=0.1) +
  theme_classic() +
  theme(axis.title = element_text(size = 9), axis.text.x = element_text(size=7), axis.ticks.y = element_blank(), axis.line.y = element_blank(), legend.position = "none", plot.margin=unit(c(5,10,10,25),"pt"), plot.title=element_text(face="bold", hjust=3, vjust=-3.9)) 
```

## Output Files

### Combined Figures as . Files

``` r
pMain <- ggarrange(ggarrange(get_legend(pB), pA, ncol = 1, heights = c(0.2, 1)),
                   gpF, ncol = 2, labels = c("A", "B"), hjust=-0.5, vjust=2, widths = c(0.7, 2))

ggsave(paste("main_outputs/COGs/COG_summary_", Species, ".svg", sep =""), pMain, width = 9, height = 4, dpi = 150)
```

``` r
pSupple <- ggarrange(get_legend(pE),
                      ggarrange(pC+theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()), pD+theme(legend.position="none"), ncol = 1,  align = "v", labels = c("i", "ii"), hjust=-0.5, vjust=1, heights = c(1, 1)),
                      get_legend(pD), ncol = 1, heights = c(0.2, 2, 0.6))

ggsave(paste("main_outputs/COGs/COG_byGenome_", Species, ".svg", sep =""), pSupple, width = 8, height = 10, dpi = 150)
```

### R Objects

``` bash
mkdir -p "main_outputs/COGs/rds"
```

``` r
saveRDS(pA, file = paste("main_outputs/COGs/rds/pA_", Species, ".rds", sep =""))
saveRDS(pB, file = paste("main_outputs/COGs/rds/pB_", Species, ".rds", sep =""))
saveRDS(pC, file = paste("main_outputs/COGs/rds/pC_", Species, ".rds", sep =""))
saveRDS(pD, file = paste("main_outputs/COGs/rds/pD_", Species, ".rds", sep =""))
saveRDS(pE, file = paste("main_outputs/COGs/rds/pE_", Species, ".rds", sep =""))
saveRDS(pF, file = paste("main_outputs/COGs/rds/pF_", Species, ".rds", sep =""))
saveRDS(pG, file = paste("main_outputs/COGs/rds/pG_", Species, ".rds", sep =""))
```

<img src="images/Department-of-Molecular-Virology-&amp;-Microbiologyy-Horz-GRAY.png" align="left" width="200" height="90"/>