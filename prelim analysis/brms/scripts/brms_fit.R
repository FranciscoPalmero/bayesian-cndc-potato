library(tidyverse)
library(brms)
library(tidybayes)
# library(shinystan)

library(future)
plan(multisession)

# library(pushoverr)

data_cndc <- read_csv("data/analysis/data_cndc.csv",col_types="cccccccdcdd") 
data_cndc_index <- read_csv("data/analysis/data_cndc_index.csv",col_types="ccccccc") 

run_fits <- function(){
  
  brms_fit <- function(data,model.name,index.list,formula,priors="default",iter,warmup,adapt_delta){
    
    d <- data %>%
      filter(index%in%index.list)
    
    if (class(priors)[[1]]!="brmsprior"){priors <- get_prior(formula, family = gaussian, data = d)}
    
    # pushover(message=model.name,
    #          title=paste("brms started!",as.character(Sys.time())),
    #          app="aywd2zcms7exp9b1bzuu4k2kucvgw7",
    #          user="us7sp3iysh1q843wedps638pcvepib")
    
    fit <- brm(formula = formula, data = d, family = gaussian, prior = priors,
               cores = 4, chains = 4, iter = iter, warmup = warmup,
               control = list(adapt_delta = adapt_delta, max_treedepth = 15),
               seed=52624,
               file=paste("brms/models/",model.name,sep=""))
    
    # pushover(message=model.name,
    #          title=paste("brms finished!",as.character(Sys.time())),
    #          app="aywd2zcms7exp9b1bzuu4k2kucvgw7",
    #          user="us7sp3iysh1q843wedps638pcvepib")
    
    return(fit)
    
  }
  
  model <- brms_fit(data=data_cndc,
                    model.name="model",
                    index=data_cndc_index %>%
                      pull(index),
                    formula=bf(W ~ fmin(Bmax + Si * (N - (alpha1*(Bmax^(-alpha2)))), Bmax),
                               Bmax + Si ~ 1 + (1|index),
                               alpha1 + alpha2 ~ 1 + (1|location/variety),
                               nl = T),
                    priors=c(set_prior("normal(7.0,1.0)", class = "sd", nlpar = "Bmax", group = "index"),
                             set_prior("normal(1.0,0.1)", class = "sd", nlpar = "Si", group = "index"),
                             set_prior("normal(0.10,0.02)", nlpar = "alpha1", class = "sd", group ="location"),
                             set_prior("normal(0.05,0.02)", nlpar = "alpha2", class = "sd", group ="location"),
                             set_prior("normal(0.05,0.01)", nlpar = "alpha1", class = "sd", group ="location:variety"),
                             set_prior("normal(0.02,0.01)", nlpar = "alpha2", class = "sd", group ="location:variety"),
                             set_prior("normal(8.0,0.1)", nlpar = "Bmax", lb = 1),
                             set_prior("normal(6.0,0.1)", nlpar = "Si", lb = 0),
                             set_prior("normal(5.3,0.1)", nlpar = "alpha1", lb = 0),
                             set_prior("normal(0.40,0.01)", nlpar = "alpha2", lb = 0, ub = 1),
                             set_prior("student_t(3,1.0,0.1)", class = "sigma")),
                    iter = 5000,
                    warmup = 2000,
                    adapt_delta = 0.99)
  
}

fits %<-% run_fits()


