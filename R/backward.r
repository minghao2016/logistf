#' Backward Elimination/Forward Selection of Model Terms in logistf Models
#'
#' These functions provide simple backward elimination/forward selection procedures for logistf models.
#' 
#' The variable selection is simply performed by repeatedly calling add1 or drop1 methods for logistf, 
#' and is based on penalized likelihood ratio test. It can also properly handle variables that were 
#' defined as factors in the original data set.
#' 
#' @param object A fitted logistf model object. To start with an empty model, create a model fit 
#' with a formula=<y>~1, pl=FALSE. (Replace <y> by your response variable.)
#' @param scope The scope of variables to add/drop from the model. If left blank, backward will use 
#' the terms of the object fit, and forward will use all variables in object$data not identified as 
#' the response variable. Alternatively, an arbitrary vector of variable names can be given, to allow 
#' that only some of the variables will be competitively selected or dropped.
#' @param steps The number of forward selection/backward elimination steps.
#' @param slstay For \code{backward}, the significance level to stay in the model.
#' @param slentry For \code{forward}, the significance level to enter the model.
#' @param trace If \code{TRUE}, protocols selection steps.
#' @param printwork If \code{TRUE}, prints each working model that is visited by the selection procedure.
#' @param pl For forward, computes profile likelihood confidence intervals for the final model if \code{TRUE}.
#' @param ... Further arguments to be passed to methods.
#'
#'
#' @return An updated \code{logistf} fit with the finally selected model.
#'
#' @examples 
#' data(sex2) 
#' fit<-logistf(data=sex2, case~1, pl=FALSE) 
#' fitf<-forward(fit) 
#' 
#' fit2<-logistf(data=sex2, case~age+oc+vic+vicl+vis+dia) 
#' fitb<-backward(fit2)
#' 
#' @rdname backward
#' @export backward
backward<-function(object, scope, steps=1000, slstay=0.05, trace=TRUE, printwork=FALSE, ...){
  istep<-0 #index of steps
  working<-object
  if(trace){
    cat("Step ", istep, ": starting model\n")
    if(printwork) {
      print(working)
      cat("\n\n")
    }
  }
  if(missing(scope)) scope<-attr(terms(working),"term.labels") #scope missing - use terms of object fit
  #    if(missing(scope)) scope<-names(coef(working))
  
  while(istep<steps & working$df>=1){
    istep<-istep+1
    mat<-drop1(working)
    if(all(mat[,3]<slstay)) break #check p-value of variables in scope
    inscope<-match(scope,rownames(mat))
    inscope<-inscope[!is.na(inscope)]
    removal<-rownames(mat)[mat[,3]==max(mat[inscope,3])] #remove highest pvalue
    #check if object$formula contains a dot shortcut i.e. last character: 
    if (sapply(grepl("\\.", working$formula), tail, 1)){
      char <- paste(working$terms[-1], collapse=" + ") #get variables from data without intercept
      variables <- paste(char, removal, sep="-") #remove target variable
      newform <- as.formula(paste("", variables, sep="~")) #coerce to formula
    }
    else {
      newform=as.formula(paste("~.-",removal))
    }
    
    if(working$df==1 | working$df==mat[mat[,3]==max(mat[,3]),2]){
      working<-update(working, formula=newform, pl=FALSE, data=object$data)
    }
    else {
      working<-update(working, formula=newform, data=object$data)
    }
    if(trace){
      cat("Step ", istep, ": removed ", removal, " (P=", max(mat[,3]),")\n")
      if(printwork) {
        print(working)
        cat("\n\n")
      }
    }
  }
  if(trace) cat("\n")
  return(working)
}
#' @export forward
#' @describeIn backward Forward Selection 
forward<-function(object, scope, steps=1000, slentry=0.05, trace=TRUE, printwork=FALSE, pl=TRUE, ...){
  istep<-0
  working<-object
  if(missing(scope)) scope<-colnames(object$data)
  if(is.numeric(scope)) scope<-colnames(object$data)[scope]
  scope<-scope[-(match(colnames(model.frame(object$formula,data=object$data))[1],scope))]
  if(trace){
    cat("Step ", istep, ": starting model\n")
    if(printwork) {
        print(working)
        cat("\n\n")
        }
    }
  if(missing(scope)) stop("Please provide scope (vector of variable names).\n")
  inscope<-scope
  while(istep<steps & length(inscope)>=1){
    istep<-istep+1
    mat<-add1(working, scope=inscope)
    #if(printwork)   print(mat)
    if(all(mat[,3]>slentry)) break
    index<-(1:nrow(mat))[mat[,3]==min(mat[,3])]
    if(length(index)>1) index<-index[mat[index,1]==max(mat[index,1])]
    addvar<-rownames(mat)[index]
    newform=as.formula(paste("~.+",addvar))
    working<-update(working, formula=newform, pl=FALSE)
    newindex<-is.na(match(inscope, attr(terms(object),"term.labels")))
    if(all(is.na(newindex)==TRUE)) break
    inscope<-inscope[-index]
    if(trace){
      cat("Step ", istep, ": added ", addvar, " (P=", mat[addvar,3],")\n")
      if(printwork) {
        print(working)
        cat("\n\n")
        }
      }
    }
   if(pl) working<-update(working, pl=TRUE)
   if(trace) cat("\n")
   return(working)
}