input <- list(
  input_ds="diabetes.csv",
  
  random_seed=1,
  num_training_point=100,

  max.depth = 2,
  nrounds = 50,
  learning_rate = 0.3,
  
  input_predict="Outcome",
  
  
  "shapley_input Pregnancies"=1,
  "shapley_input Glucose"=1,
  "shapley_input BloodPressure"=1,
  "shapley_input SkinThickness"=1,
  "shapley_input Insulin"=1,
  "shapley_input BMI" =1,
  "shapley_input DiabetesPedigreeFunction"=1,
  "shapley_input Age" =1
  
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

