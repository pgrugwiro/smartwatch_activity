#clear environment
rm(list = ls())


#install packages if necessary

if(!require(tidyverse)) install.packages("tidyverse", repos = "http://cran.us.r-project.org")
if(!require(caret)) install.packages("caret", repos = "http://cran.us.r-project.org")
if(!require(data.table)) install.packages("data.table", repos = "http://cran.us.r-project.org")
if(!require(randomForest)) install.packages("randomForest", repos = "http://cran.us.r-project.org")

#download the dataset and unzip the folder: there are 50 files in the folder
dl <- tempfile()
download.file("https://github.com/pgrugwiro/Activity_Monitor/raw/master/watch_accelerometer.zip", dl)
filenames <- unzip(dl)


#combine all the files in one file, skipping the rows in the files that do not contain useful data:
ez.read = function(file, ..., skip.rows=NULL){
  if (!is.null(skip.rows)) {
    tmp = readLines(file)
    tmp = tmp[-(skip.rows)]
    tmpFile = tempfile()
    on.exit(unlink(tmpFile))
    writeLines(tmp,tmpFile)
    file = tmpFile
  }
  result = read.csv(file, ...)
  
}

dataset_watch_accel <- do.call("rbind",lapply(filenames, FUN=function(files){
  ez.read(paste(files, sep = ","), 
          skip.rows = c(1:97), sep = ",", header = FALSE)
}))


#subset the dataset by selecting only the necessary columns: user, x, y, z, and activity, and name
#the columns appropriately
watch_accelerometer <- dataset_watch_accel %>% select(V1, V2, V33, V34, V93)
columns <- c("Activity", "x", "y", "z", "user")
colnames(watch_accelerometer) <- columns


#further subset the dataset by only selecting 4 activities out of 18: A, B, C, and P
activity_index <- which(watch_accelerometer$Activity %in% c("A", "B", "C", "P"))
watch_accelerometer <- watch_accelerometer %>% slice(activity_index)
watch_accelerometer$Activity <- factor(watch_accelerometer$Activity)
watch_accelerometer$user <- as.factor(watch_accelerometer$user)

#remove the unused objects to save memory
rm(dataset_watch_accel, columns, dl, filenames, ez.read, activity_index)

####################################


# Exploratory Data Analysis

#data overview
str(watch_accelerometer) 
head(watch_accelerometer) %>% knitr::kable()

#Take a look at the predictors by studying the signature of accelerometer 
#value averages per user for each of the 4 activities:
#This confirms the individuality of the users
watch_accelerometer %>% group_by(user, Activity) %>% summarize(n=n(), 
                                                               x=mean(x),
                                                               y=mean(y),
                                                               z=mean(z)) %>%
  ggplot(aes(as.numeric(user))) +
  geom_line(aes(y=y, col = "red")) +
  geom_line(aes(y=x, col = "blue")) +
  geom_line(aes(y=z)) +
  facet_wrap(.~Activity) +
  xlab("Individual User 1-50") +
  ylab("Accelerometer Measurement, X, Y, &Z") +
  theme(legend.position = "none")



#Study the correlation between the predictors
#Helps determine if any predictors should be dropped

options(warn = -1)
watch_accelerometer %>% group_by(user, Activity) %>% 
  summarize(CORxy = cor(x,y), CORxz = cor(x,z), CORyz = cor(y,z))
options(warn = 0)

#One Example of Correlations for User 1600 & Activity B
watch_accelerometer %>% filter(user == 1600 & Activity == "B")%>%
  ggplot(aes(x,y)) + 
  geom_point(aes(x,y)) +
  geom_smooth(method = "lm", se=0)

watch_accelerometer %>% filter(user == 1600 & Activity == "B")%>%
  ggplot(aes(x,z)) + 
  geom_point() +
  geom_smooth(method = "lm", se=0)

watch_accelerometer %>% filter(user == 1600 & Activity == "B")%>%
  ggplot(aes(z,y)) + 
  geom_point() +
  geom_smooth(method = "lm", se =0)


#understand the variations within the data
watch_accelerometer %>% gather(coordinate, accelerometer, `x`:`z`) %>% filter(user == 1615 & Activity == "P") %>%
  group_by(coordinate) %>% summarize(mean= mean(accelerometer), se = sd(accelerometer)/sqrt(n())) %>% knitr::kable()


#Building an Activity Detection Model Based on Available Predictors: accelerometer & user:


#create training and testing sets:

set.seed(1, sample.kind = "Rounding")
test_index <- createDataPartition(y = watch_accelerometer$x, times = 1, p = 0.25, list = FALSE)

train_set <- watch_accelerometer %>% slice(-test_index)
test_set <- watch_accelerometer %>% slice(test_index)



## activity recognition by guessing 

set.seed(2, sample.kind = "Rounding") #set.seed(2) if using previous versions of R
guess_activity <- sample(rep(c("A", "B", "C", "P"),17),length(test_set$Activity), replace = T)
guessing <- confusionMatrix(test_set$Activity, as.factor(guess_activity))
guessing$table

prediction_accuracy <- data_frame(Method="Guessing",
                                     Accuracy = guessing$overall[1])


## activity recognition by applying the KNN model
fit_knn <- train(Activity~x+y+z+user, method = "knn",
                 data = train_set)

predicted_activity_knn <- predict(fit_knn, test_set)
knn <- confusionMatrix(predicted_activity_knn, test_set$Activity)
knn$table %>% knitr::kable()

prediction_accuracy <- bind_rows(prediction_accuracy,
                                 data_frame(Method="KNN Model",
                                            Accuracy = knn$overall[1]))


## activity recognition by applying the decision trees model
fit_rpart <- train(Activity ~ ., 
                   method = "rpart",
                   tuneGrid = data.frame(cp = 0.001),
                   data = train_set)
#ggplot(fit_rpart)

predicted_activity_rpart <- predict(fit_rpart, test_set)
rpart <- confusionMatrix(predicted_activity_rpart, test_set$Activity)
rpart$table


prediction_accuracy <- bind_rows(prediction_accuracy,
                                 data_frame(Method="RPART",
                                            Accuracy = rpart$overall[1]))


## activity recognition by applying the random forests model

#fit_rforest <- train(Activity~. ,method ="rf", 
#                     tuneGrid = data.frame(mtry = seq(10,110,20)),
#                     data = train_set)
#ggplot(fit_rforest)


fit_rforest <- train(Activity~. ,method ="rf", 
                     tuneGrid = data.frame(mtry = 30),
                     data = train_set)


predicted_activity_rforest <- predict(fit_rforest, test_set)
rfor <- confusionMatrix(predicted_activity_rforest, test_set$Activity) 
rfor$table

prediction_accuracy <- bind_rows(prediction_accuracy,
                                 data_frame(Method="RFOREST",
                                            Accuracy = rfor$overall[1]))


prediction_accuracy %>% arrange(desc(Accuracy)) %>% knitr::kable()
