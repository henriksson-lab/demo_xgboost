input <- list(
  input_ds="diabetes.csv",
  
  random_seed=1,
  num_training_point=100,

  max.depth = 2,
  nrounds = 50,
  learning_rate = 0.3,
  
  input_predict="Outcome"
  
)

reactive <- function(f) function() f

################################################################################




################################################################################
########### General functions ##################################################
################################################################################

dat <- data.frame(
  x=1:100
)
dat$y <- rnorm(sin(dat$x/100),0.1)
write.csv(dat, "data/trivial.csv", row.names = FALSE)

