library(plotly)
library(Cairo)
library(xgboost)
options(shiny.usecairo=T)


if(FALSE){
  install.packages("matlib")
}



if(FALSE){
  #To run this app
  library(shiny)
  runApp(".")
}


server <- function(input, output, session) {


  ##############################################################################
  ########### General functions ################################################
  ##############################################################################
  
  
  getDataTable <- reactive({    
    current_ds <- input$input_ds
    available_datasets[[current_ds]]
  })
  
  getTrainingIndex <- reactive({    
    thedat <- getDataTable()
    set.seed(input$random_seed)
    usepoint <- sample(1:nrow(thedat), input$num_training_point)
    usepoint
  })
  
  getTestIndex <- reactive({
    setdiff(1:nrow(getDataTable()), getTrainingIndex())
  })
  
  
  getTrainingPoints <- reactive({
    getDataTable()[getTrainingIndex(),,drop=FALSE]
  })
  
  getTestPoints <- reactive({
    getDataTable()[getTestIndex(),,drop=FALSE]
  })
  

  
  
  ##############################################################################
  ########### Callbacks - dataset ##############################################
  ##############################################################################
  
  observeEvent(c(input$input_ds),{
    thedat <- getDataTable()
    numparam <- ncol(thedat)-1
    
    ######### Side bar
    updateSliderInput(session, "num_training_point", min=0, max=nrow(thedat), value = nrow(thedat), step = 1)
    updateSelectizeInput(session, 'input_predict', choices = colnames(thedat), server = TRUE, selected="Outcome")
    

  })
  
  
  
  
  solution <- reactive({    
    
    thedat <- getDataTable()
    all_param_name <- colnames(thedat)[colnames(thedat) != input$input_predict]
    
    set.seed(input$random_seed)
    
    thedat <- sapply(thedat,as.numeric)
    dtrain <- xgb.DMatrix(
      data = as.matrix(thedat[getTrainingIndex(),all_param_name,drop=FALSE]),  
      label = thedat[getTrainingIndex(),input$input_predict]
    )
    dtest <- xgb.DMatrix(
      data = as.matrix(thedat[getTestIndex(),all_param_name,drop=FALSE]),  
      label = thedat[getTestIndex(),input$input_predict]
    )
    watchlist <- list(train=dtrain, test=dtest)
    
    model <- xgb.train(
      data=dtrain, 
      max.depth = input$max.depth, 
      eta = input$learning_rate, 
      nthread = 2, 
      nrounds = input$nrounds, 
      watchlist=watchlist,
      verbose=0
      #, 
#      objective = "binary:logistic"
    )

    all_param_name <- colnames(thedat)[colnames(thedat) != input$input_predict]
    pred <- predict(model, as.matrix(thedat[,all_param_name]))

    list(
      model=model,
      indata=thedat,
      pred=pred
    )
    
  })
#  solution()

  
  
  ##############################################################################
  ########### Callbacks - dataset & outcome ####################################
  ##############################################################################
  
  observeEvent(c(input$input_ds, input$input_predict, input$num_layers),{
    thedat <- getDataTable()
    numparam <- ncol(thedat)-1
    all_param_name <- colnames(thedat)[colnames(thedat) != input$input_predict]

    ######### Scatter plot
    updateSelectizeInput(session, 'input_scatter_x', choices = colnames(thedat), server = TRUE)
    updateSelectizeInput(session, 'input_scatter_y', choices = colnames(thedat), server = TRUE)
    
  })
  
  
  ##############################################################################
  ########### Data table tab ###################################################
  ##############################################################################
  
  output$plotDataTable <- renderTable(getTrainingPoints())
  
  
  ##############################################################################
  ########### Scatter plot tab #################################################
  ##############################################################################

  output$plotScatter <- renderPlot({
    
    thedat <- getTrainingPoints()
    
    if(input$input_scatter_x %in% colnames(thedat) & 
       input$input_scatter_y %in% colnames(thedat) &
       input$input_scatter_c %in% colnames(thedat)){
      
      ds <- data.frame(
        x=thedat[,input$input_scatter_x],
        y=thedat[,input$input_scatter_y],
        c=thedat[,input$input_scatter_c]
      )
      
      ggplotly(ggplot(ds,aes(x,y, color=c))+geom_point()) 
      
    } else {
      ds <- data.frame(x=c(),y=c())
      ggplotly(ggplot()) 
    }
    

  })
  
  
  
  ##############################################################################
  ########### Tree plot tab ####################################################
  ##############################################################################

  output$plotTrees <- renderGrViz({
    sol <- solution()
    p <- xgb.plot.tree(model = sol$model, render=TRUE)
    p
  })
  
  
  
  ##############################################################################
  ########### Convergence plot tab #############################################
  ##############################################################################
  
  output$plotConvergence <- renderPlot({
    sol <- solution()
    model <- sol$model
    
    df <- rbind(
      data.frame(
        iter=model$evaluation_log$iter,
        mse=model$evaluation_log$train_rmse,
        type="Training"
      ),
      data.frame(
        iter=model$evaluation_log$iter,
        mse=model$evaluation_log$test_rmse,
        type="Testing"
      )
    )
    
    ggplot(df, aes(iter, mse, color=type)) + 
      geom_line() + geom_point() +
      xlab("Round (iteration)") +
      ylab("MSE (mean square error)")
  })
  
  ##############################################################################
  ########### Importance plot tab ##############################################
  ##############################################################################
  
  output$plotImportance <- renderPlot({
    sol <- solution()
    importance_matrix <- xgb.importance(model = sol$model)
    xgb.plot.importance(importance_matrix = importance_matrix)
  })
  
  
}



