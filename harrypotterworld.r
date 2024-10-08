title: "Harry Potter Categorical Data Analysis"
author: "Dawn Daras, MS, ABD/Ph.D."
date: "`r Sys.Date()`"
output: 
    html_document:
        html_document:
        css: bootstrappink.css
        code_folding: hide
        
---

```{r setup, warning=FALSE}
knitr::opts_chunk$set(warning = FALSE)
```




<style type="text/css">
  body{
  font-size: 12pt;
}
</style>


![https://dawn-daras.com](Dawn.png)

```{r}
knitr::include_graphics("HP.gif")

```


## We will be working with a largely categorical dataset - Harry Potter.  So, the analysis and tables will be simple and focus on presentation

<br>

![Description of the Variables in the Harry Potter Dataset](datanames.png)
<br>
## You can find the downloadable dataset at this link: 
[Harry Potter Dataset](https://github.com/dawndarasms/RStatsColab/blob/main/HarryPotter.csv)

<br>
<br>

## Our Roadmap will be:
<br>

### 1) Bring in the data
### 2) Run our Exploratory Data Analysis
### 3) Clean the data and make changes so we can create good visualizations and analyses
### 4) Create visualizations and tables
### 5) Run some non parametric analyses on our categorical data

<br>
<br>

## What is a non-parametric test?  

<br>

## Well, most statistics classes focus on parametric tests, which are based on the assumptions of the normal distribution and that the sample size is sufficiently large to produce a valid result.

## A statistical method is called non-parametric if it makes no assumption on the population distribution or sample size.

## This is in contrast with most parametric methods in elementary statistics that assume the data is quantitative, the population has a normal distribution and the sample size is sufficiently large.

## In general, conclusions drawn from non-parametric methods are not as powerful as the parametric ones. Non-parametric tests are statistical assessments that can be used to analyze categorical data and data that are not normally distributed.We are going to use them here, because besides having a small sample the majority of our data is categorical.

## For every parametric test, its non-parametric cousin can be used when the assumptions cannot be fulfilled for the parametric test.
<br>

![PARAMETRIC vs NONPARAMETRIC Tests](nonparametric.png)




```{r include=FALSE}
library(devtools)
library(gtsummary)
library(ggplot2)
library(magick)
library(gmodels)
library(plyr)
library(dplyr)
library(DT)
library(tidyverse)
library(rmarkdown)
library(C50)
library(dplyr)
library(magrittr)
library(htmltools)
library(vembedr)
library(ggpubr)

```



```{r include=FALSE}

library(ggplot2)
library(tibble)
library(rstatix)
library(formattable)
library(data.table)
library(table1)
library(factoextra)
```


### Bringing in our data

```{r}

HarryPotter <- read.csv("/cloud/project/HPExport.csv", header=TRUE, stringsAsFactors=FALSE)
head(HarryPotter ,5)

```


### Let's look at datatypes and see if we need to make any changes

```{r}
str(HarryPotter)
```

### Dropping some variables that we won't need for tables or analysis:
```{r}
HarryPotter <- subset(HarryPotter, select = -c(Name, Birthdate, Deathdate.or.Censor, Days))
```



## Changing Age to Numeric

```{r}
HarryPotter$Age <- as.integer(HarryPotter$Age)
```


```{r}
str(HarryPotter)
```




### Removing any rows with "NA's"
```{r}

HarryPotter <- na.omit(HarryPotter)

```



```{r}
HarryPotter2 <- HarryPotter[HarryPotter$Age >= 5, ]
```


### Running a quick EDA's (exploratory data analysis)
```{r}
str(HarryPotter2)
```


```{r}
summary(HarryPotter2)
```




### Removing Beaubatons Academy of Magic and Durmstrang because they're outliers

```{r}
HPHouse=HarryPotter2[!grepl("Beauxbatons Academy of Magic",HarryPotter2$House),]

head(HPHouse,5)
```

```{r}
HPHouse=HPHouse[!grepl("Durmstrang Institute",HPHouse$House),]
```


### Checking the changes we just made
```{r}

print(freq_table(HPHouse$House))
```


### Removing where Loyal is unknown
```{r}

HPHouse=HPHouse[!grepl("Unknown",HPHouse$Loyalty),]
head(HPHouse,2)
```



```{r}

print(freq_table(HPHouse$Loyalty))
```



### Barplot of Houses

```{r}

counts <- sort(table(HPHouse$House), decreasing = TRUE)  
# Number of states in each region
percentages <- 100 * counts / length(HPHouse$House)

```



```{r}

barplot(percentages, ylab = "Percentage", col = "purple")
text(x=seq(0.7, 5, 1.2), 2, paste("n=", counts))      

```


### Changing Houses to Factors
```{r}

HPHouse$House <- as.factor(HPHouse$House)
levels(HPHouse$House)[levels(HPHouse$House) == "Gryffindor"] <- "Gryffindor"
levels(HPHouse$House)[levels(HPHouse$House) == "Hufflepuff"] <- "Hufflepuff"
levels(HPHouse$House)[levels(HPHouse$House) == "Slytherin"] <- "Slytherin"
levels(HPHouse$House)[levels(HPHouse$House) == "Ravenclaw"] <- "Ravenclaw"
str(HPHouse$House)
```

### Blood status freq counts

```{r}


print(freq_table(HPHouse$Blood.status))
```



### Changing Blood Status to Factors
```{r}

HPHouse$Blood.status <- as.factor(HPHouse$Blood.status)
levels(HPHouse$Blood.status)[levels(HPHouse$Blood.status) == "Half-blood"] <- "Half-blood"
levels(HPHouse$Blood.status)[levels(HPHouse$Blood.status) == "Muggle-born"] <- "Muggle-born"
levels(HPHouse$Blood.status)[levels(HPHouse$Blood.status) == "Part-Goblin"] <- "Part-Goblin"
levels(HPHouse$Blood.status)[levels(HPHouse$Blood.status) == "Pure-blood"] <- "Pure-blood"
levels(HPHouse$Blood.status)[levels(HPHouse$Blood.status) == "Unknown"] <- "Unknown"
str(HPHouse$Blood.status)
```

```{r}

lbls <- c( "<5", "6-10", "11-15", "16-20", "21-30","31-40","41-55","56-75","76-100","101-1600" )
HPHouse$Age_Cat <- cut( HPHouse$Age, breaks = c( -Inf, 6, 11, 16, 21, 31, 41,56,76,101, Inf ), labels = lbls, right = FALSE )

head(HPHouse,5)
```

### Changing Age_Cat into ordinal data
### Ordinal data is when the order of the categories matters, not just the categories themselves in analysis
```{r}

factor(HPHouse$Age_Cat, ordered = TRUE)
```



### Changing Loyalty to Factors
```{r}

HPHouse$Loyalty <- as.factor(HPHouse$Loyalty)
levels(HPHouse$Loyalty)[levels(HPHouse$Loyalty) == "Dumbledore"] <- "Dumbledore"
levels(HPHouse$Loyalty)[levels(HPHouse$Loyalty) == "Voldemort"] <- "Voldemort"
str(HPHouse$Loyalty)
```

### Checking datatypes after our changes

```{r}

str(HPHouse)
```



```{r}

print(freq_table(HPHouse$Sex))
```



```{r}

print(freq_table(HPHouse$Age_Cat))
```


### Removing observation where Sex is blank
```{r}

HPHouse <- HPHouse[-which(HPHouse$Sex == ""), ]

```


```{r}

print(freq_table(HPHouse$Sex))
```
 

### Building a Custom Table of Frequency Counts by Loyalty, Age Category and Status (Alive by the End of the Series or Died)
```{r}

LoyaltyAge <- HPHouse %>%
  group_by(Loyalty, House, Status) %>%
  tally()
```

<br> 

```{r}

head(LoyaltyAge,5)
```


```{r}

#Rename columns 
colnames(LoyaltyAge)[1] <- "Loyalty" 
colnames(LoyaltyAge)[2] <-"House"
colnames(LoyaltyAge)[3] <- "Status"              
colnames(LoyaltyAge)[4] <- "Count"
head(LoyaltyAge, 5)
```



```{r}

datatable(LoyaltyAge,extensions = 'Buttons',
options = list(dom='Bfrtip',
buttons=c('copy', 'csv', 'excel', 'print', 'pdf')))
```
 

<br>

## Non-Parametric Tests

### We are going to conduct two non parametric statistical tests - if you look at the chart at the beginning - the first we will be conducting is the Mann-Whitney U.  This is the non parametric test analogous to the Unpaired T-Test.  It compares the medians of two independent samples.  

### Our H0 (Null Hypothesis) is that Loyalty to Voldemort and Loyalty to Dumbledore are identitical (ages of death in Potterworld) populations

### Our HA (Alternative Hypothesis) is that Loyalty to Voldemort and Loyalty to Dumbledore are non identical populations


<br>


### We will be examining the variables Age and Loyalty


<br>

### First we will examine the median scores by each loyalty group and create boxplots

```{r}

# loading the package
group_by(HPHouse,Loyalty) %>%
  summarise(
    count = n(),
    median = median(Age, na.rm = TRUE),
    IQR = IQR(Age, na.rm = TRUE))
```

```{r}

ggboxplot(HPHouse, x = "Loyalty", y = "Age", 
          color = "Loyalty", palette = c("purple","hotpink"),
          ylab = "Age", xlab = "Loyalty")
```


### Next we will conduct the Mann Whitney U Test
```{r}

res <- wilcox.test(Age ~ Loyalty, conf.int = T, data = HPHouse)
res 

```




### From the p value being less than .05, we can reject the null hypothesis and accept the alternative that loyalty to Voldemort and Loyalty to Dumbledore are non identical populations when it comes to age (or age of death in PotterWorld)

<br>

### Next we are going to conduct the Kruskal-Wallis.  The Kruskal Wallis is the rank-based, non parametric cousin to the ANOVA (analysis of variance).  Remember how we created ranking and factoring for the difference categorical variables above? 

### We consider the variable Age. We wish to compare the Age in four different Hogwarts Houses (Gryffindor, Hufflepuff, Ravenclaw, and Slytherin).

### HO: the distribution of Age is the same in all groups (the medians of Age in the four Houses are the same)
### HA: there is at least one group with Age distribution different from the others (there is at least one House with median Age different from the others)

```{r}
library(doBy)
library(rstatix)
library(gtsummary)
library(tidyverse)
```

<br>

```{r}
summaryBy(Age ~ House,
  data = HPHouse,
  FUN = median,
  na.rm = TRUE
)
```

### Boxplot by House
```{r}

ggplot(HPHouse) +
  aes(x = House, y = Age, fill = House) +
  geom_boxplot() +
  theme(legend.position = "none")

```


### Kruskal Wallace Test
```{r}

kruskal.test(Age ~ House, data = HPHouse)

```

### Given the p is less than .05 we can reject the null and accept the HA that there are differences in ages at death among at least one of the Houses.


### To see which groups differ between each other, we can conduct the Pairwise comparisons using Wilcoxon rank sum test 
```{r}
pairwise.wilcox.test(HPHouse$Age, HPHouse$House,
                 p.adjust.method = "BH")
```

### After we conduct this test we see that Gryffindor differs signficantly from Ravenclaw, and Gryffindor differs signifcantly from Slytherin.




<br>


## References

### Bougioukas, K. (2024). Practical Statistics in Medicine with R. [Rstats Textbook](https://practical-stats-med-r.netlify.app/)

### University of Wisconsin, at Madison (2024). Categorical Data Wrangling with R. [Categorical Data](https://sscc.wisc.edu/sscc/pubs/dwr/categorical.html)

<br>


```{r}
embed_url("https://youtu.be/dxKLEOMfUL4?si=JSwO4RvGaRVF4_sb")
```


<br>
<br>



