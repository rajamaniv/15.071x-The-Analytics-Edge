NewsTrain = read.csv("NYTimesBlogTrain.csv", stringsAsFactors=FALSE)
NewsTest = read.csv("NYTimesBlogTest.csv", stringsAsFactors=FALSE)

library(tm)
library(SnowballC)

CorpusHeadline = Corpus(VectorSource(c(NewsTrain$Headline, NewsTest$Headline)))

CorpusHeadline = tm_map(CorpusHeadline, tolower)

CorpusHeadline = tm_map(CorpusHeadline, PlainTextDocument)
CorpusHeadline = tm_map(CorpusHeadline, removePunctuation)
CorpusHeadline = tm_map(CorpusHeadline, removeWords, stopwords("english"))
CorpusHeadline = tm_map(CorpusHeadline, stemDocument)

CorpusSnippet = Corpus(VectorSource(c(NewsTrain$Headline, NewsTest$Headline)))
CorpusSnippet = tm_map(CorpusSnippet, tolower)
CorpusSnippet = tm_map(CorpusSnippet, PlainTextDocument)
CorpusSnippet = tm_map(CorpusSnippet, removePunctuation)
CorpusSnippet = tm_map(CorpusSnippet, removeWords, stopwords("english"))
CorpusSnippet = tm_map(CorpusSnippet, stemDocument)

CorpusAbstract = Corpus(VectorSource(c(NewsTrain$Headline, NewsTest$Headline)))
CorpusAbstract = tm_map(CorpusAbstract, tolower)
CorpusAbstract = tm_map(CorpusAbstract, PlainTextDocument)
CorpusAbstract = tm_map(CorpusAbstract, removePunctuation)
CorpusAbstract = tm_map(CorpusAbstract, removeWords, stopwords("english"))
CorpusAbstract = tm_map(CorpusAbstract, stemDocument)

dtmHeadline = DocumentTermMatrix(CorpusHeadline)
dtmHeadline = removeSparseTerms(dtmHeadline, 0.99)
Headline = as.data.frame(as.matrix(dtmHeadline))
colnames(Headline) = make.names(colnames(Headline))
colnames(Headline) = paste("H", colnames(Headline))
colnames(Headline) = make.names(colnames(Headline))

dtmSnippet = DocumentTermMatrix(CorpusSnippet)
dtmSnippet = removeSparseTerms(dtmSnippet, 0.99)
Snippet = as.data.frame(as.matrix(dtmSnippet))
colnames(Snippet) = make.names(colnames(Snippet))
colnames(Snippet) = paste("S", colnames(Snippet))
colnames(Snippet) = make.names(colnames(Snippet))

dtmAbstract = DocumentTermMatrix(CorpusAbstract)
dtmAbstract = removeSparseTerms(dtmAbstract, 0.99)
Abstract = as.data.frame(as.matrix(dtmAbstract))
colnames(Abstract) = make.names(colnames(Abstract))
colnames(Abstract) = paste("A", colnames(Abstract))
colnames(Abstract) = make.names(colnames(Abstract))

news = cbind(Headline, Snippet, Abstract)

news$NewsDesk = as.factor(c(NewsTrain$NewsDesk, NewsTest$NewsDesk))
news$SectionName = as.factor(c(NewsTrain$SectionName, NewsTest$SectionName))
news$SubsectionName = as.factor(c(NewsTrain$SubsectionName, NewsTest$SubsectionName))
news$WordCount = c(NewsTrain$WordCount, NewsTest$WordCount)
news$Weekday = c(strptime(NewsTrain$PubDate, "%Y-%m-%d %H:%M:%S"), strptime(NewsTest$PubDate, "%Y-%m-%d %H:%M:%S"))$wday
news$Month = c(strptime(NewsTrain$PubDate, "%Y-%m-%d %H:%M:%S"), strptime(NewsTest$PubDate, "%Y-%m-%d %H:%M:%S"))$mon
news$UniqueID = c(NewsTrain$UniqueID, NewsTest$UniqueID)

Train = head(news, nrow(NewsTrain))
NewsTest = tail(news, nrow(NewsTest))
Train$Popular = NewsTrain$Popular
NewsTrain = Train

set.seed(144)
library(caTools)


spl = sample.split(NewsTrain$Popular, SplitRatio = 0.7)

train = subset(NewsTrain, spl == TRUE)
test = subset(NewsTrain, spl == FALSE)

table(train$Popular)
3807 / (3807 + 765)

log = glm(Popular ~ . -UniqueID, data = train, family = "binomial")
summary(log)

predictLog = predict(log, newdata = test, type = "response")
predictLog
table(test$Popular, predictLog >= 0.5)
(1550 + 227) / (1550 + 227 + 101 + 82)

library(ROCR)

ROCRpred = prediction(predictLog, test$Popular)
ROCRperf = performance(ROCRpred, "tpr", "fpr")

auc = as.numeric(performance(ROCRpred, "auc")@y.values)
auc
plot(ROCRperf, colorize = TRUE)

table(test$Popular, predictLog >= 0.3)
(1523 + 243) / (1523 + 243 + 85 + 109)

logModel = glm(Popular ~ . -UniqueID, data = NewsTrain, family = "binomial")
predictLog = predict(logModel, newdata = NewsTest, type = "response")

MySubmission = data.frame(UniqueID = NewsTest$UniqueID, Probability1 = as.numeric(predictLog >= 0.3))
write.csv(MySubmission, "SubmissionLogMinimal.csv", row.names=FALSE)
