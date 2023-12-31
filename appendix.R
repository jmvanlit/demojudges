### Libraries ------------------------------------------------------------------
library(dplyr)
library(haven)
library(ggplot2)
library(ggtext)
library(broom)
library(forcats)
library(purrr)
library(texreg)
library(kableExtra)
library(tidyr)
library(stringr)

##### Data import --------------------------------------------------------------
demojudges_raw <- read.csv("data/demojudges.csv") |> 
  as_tibble()

##### Data preparation  --------------------------------------------------------
demojudges <- demojudges_raw |> 
  mutate(
    # Convert to factor
    justification = as.factor(justification),
    action = as.factor(action),
    demdef = as.factor(demdef))

### Set reference categories
demojudges$justification <- relevel(demojudges$justification, ref = "none")
demojudges$action <- relevel(demojudges$action, ref = "media")
demojudges$demdef <- relevel(demojudges$demdef, ref = "no")

##### Hypothesis testing according to PAP
im.pap.eval <- lm(data = demojudges,
                  weights = weight,
                 
                  dv_eval ~ 
                    #treatments
                    justification + action + demdef + (action * demdef) + (demdef * justification) +
                    
                    # unbalanced covariates
                    # income_nl left out for now as it is very incomplete and skews the analysis heavily
                    post_libdem_frelect)

texreg(im.pap.eval,
       caption = "Alternative Model Specification for H3 and H4",
       caption.above = TRUE,
       label = "tab:pap-h3-h4")

##### Manipulation and Attention Checks ----------------------------------------
att <- demojudges |> 
  group_by(attention) |> 
  summarise(count = n()) |> 
  mutate(attention = case_when(
    attention == 0 ~ "Incorrect",
    TRUE ~ "correct"
  ))

man <- demojudges |> 
  group_by(manipulation) |> 
  summarise(count = n()) |> 
  mutate(manipulation = case_when(
    manipulation == 0 ~ "All incorrect",
    manipulation == 1 ~ "1 correct",
    manipulation == 2 ~ "2 correct",
    manipulation == 3 ~ "3 correct"
  ))

man.act <- demojudges |> 
  group_by(mc_action) |> 
  summarise(count = n()) |> 
  mutate(mc_action = case_when(
    mc_action == 0 ~ "Incorrect",
    TRUE ~ "Correct")) |> 
  rename("Manipulation Check" = mc_action,
         "Autocratic Action"= count)

man.dem <- demojudges |> 
  group_by(mc_demdef) |> 
  summarise(count = n()) |> 
  mutate(mc_demdef = case_when(
    mc_demdef == 0 ~ "Incorrect",
    TRUE ~ "Correct")) |> 
  rename("Manipulation Check" = mc_demdef,
         "Democratic Defence"= count)

man.jus <- demojudges |> 
  group_by(mc_justification) |> 
  summarise(count = n()) |> 
  mutate(mc_justification = case_when(
    mc_justification == 0 ~ "Incorrect",
    TRUE ~ "Correct")) |> 
  rename("Manipulation Check" = mc_justification,
         "Justification"= count)

man.spec <- man.act |> 
  left_join(man.dem) |> 
  left_join(man.jus)

# Tables
kable(att,
      col.names = c("Attention check", "Count"),
      caption = "Attention Check",
      label = "attention",
      format = "latex",
      booktabs = TRUE)

kable(man,
      col.names = c("Manipulation check", "Count"),
      caption = "Manipulation Check",
      label = "manipulation",
      format = "latex",
      booktabs = TRUE)

kable(man.spec,
      caption = "Manipulation Checks per Treatment",
      label = "manipulation2",
      format = "latex",
      booktabs = TRUE)

# Manipulation Checks
attention <- demojudges |> 
  # create specific manipulation items
  mutate(
    mc_corruption = case_when(
      justification =="corruption" & dj_mc_2 == "1" ~ 1,
      TRUE ~ 0),
    mc_selfserving = case_when(
      justification == "self-serving" & dj_mc_2 == "2" ~ 1,
      TRUE ~ 0),
    mc_none = case_when(
      justification == "none" & dj_mc_2 == "3" ~ 1,
      TRUE ~ 0),
    mc_yes = case_when(
      demdef == "yes" &  dj_mc_3 == "2" ~ 1,
      TRUE ~ 0),
    mc_judiciary = case_when(
      action == "judiciary" & dj_mc_1 == "2" ~ 1,
      TRUE ~ 0)) |> 
  
  # create integers from treatments
  mutate(
    action = case_when(
      action == "judiciary" ~ 1,
      action == "media" ~ 0),
    demdef = case_when(
      demdef == "yes" ~ 1,
      demdef == "no" ~ 0),
    corruption = case_when(
      justification == "corruption" ~ 1,
      TRUE ~ 0),
    self_serving = case_when(
      justification == "self-serving" ~ 1,
      TRUE ~ 0),
    none = case_when(
      justification == "none" ~ 1,
      TRUE ~ 0))

m.man.demdef <- lm(demdef ~ mc_yes,
                   data = attention,
                   weights = weight)

m.man.action <- lm(action ~ mc_judiciary,
                   data = attention,
                   weights = weight)

m.man.corruption <- lm(corruption ~ mc_corruption,
                       data = attention,
                       weights = weight)

m.man.selfserving <- lm(self_serving ~ mc_selfserving,
                        data = attention,
                        weights = weight)

m.man.none <- lm(none ~ mc_none,
                 data = attention,
                 weights = weight)

m.man <- list(m.att.demdef, m.att.action, m.att.corruption, m.att.selfserving, m.att.none)

texreg(m.man,
       caption = "Manipulation Checks",
       label = "tab:man",
       caption.above = TRUE,
       sideways = TRUE,
       custom.model.names = c("Democratic defence", "Action against judiciary", "Positively valenced justification", "Self-serving justification", "No justification"))

# Include attention in the models
# H1a, H1b, H2
sm.att <- lm(dv_eval ~ justification + action + demdef +
               attention,
               data = demojudges,
               weights = weight) 

# H3
sm.att.ad <- lm(dv_eval ~ justification + action + demdef + (action * demdef) + attention,
                  data = demojudges,
                  weights = weight)

# H4
sm.att.jd  <- lm(dv_eval ~ justification + action + demdef + (justification * demdef) + attention,
                   data = demojudges,
                   weights = weight)

# H5
sm.att.tw <- lm(dv_eval ~ justification + action + demdef + 
                    (justification * demdef) + (action * demdef) + (justification * action) +
                    (justification * action * demdef) + attention,
                  data = demojudges,
                  weights = weight)

att.models <- list(sm.att, sm.att.ad, sm.att.jd, sm.att.tw)

texreg(att.models,
       caption = "Does democratic defence matter if we control for attention?",
       caption.above = TRUE,
       label = "tab:att")

##### Alternative dependent variable: dv_agree ---------------------------------
# H1a, H1b, H2
sm.agree <- lm(post_agree ~ justification + action + demdef + post_libdem_frelect,
               data = demojudges,
               weights = weight) 

# H3
im.agree.ad <- lm(post_agree ~ justification + action + demdef + (action * demdef) + post_libdem_frelect,
                  data = demojudges,
                  weights = weight)

# H4
im.agree.jd  <- lm(post_agree ~ justification + action + demdef + (justification * demdef) + post_libdem_frelect,
                   data = demojudges,
                   weights = weight)

# H5
im.agree.tw <- lm(post_agree ~ justification + action + demdef + 
                    (justification * demdef) + (action * demdef) + (justification * action) +
                    (justification * action * demdef) + post_libdem_frelect,
                  data = demojudges,
                  weights = weight)

models_agree <- list(sm.agree, im.agree.ad, im.agree.jd, im.agree.tw)

texreg(models_agree,
       caption = "Does democratic defence matter if we ask about agreement?",
       caption.above = TRUE,
       label = "tab:agree")

### And what if we control for agreement?
# H1a, H1b, H2
sm.cntrl.agree <- lm(dv_eval ~ justification + action + demdef + post_libdem_frelect + post_agree,
               data = demojudges,
               weights = weight) 

# H3
im.cntrl.agree.ad <- lm(dv_eval ~ justification + action + demdef + (action * demdef) + post_libdem_frelect + post_agree,
                  data = demojudges,
                  weights = weight)

# H4
im.cntrl.agree.jd  <- lm(dv_eval ~ justification + action + demdef + (justification * demdef) + post_libdem_frelect + post_agree,
                   data = demojudges,
                   weights = weight)

# H5
im.cntrl.agree.tw <- lm(dv_eval ~ justification + action + demdef + 
                    (justification * demdef) + (action * demdef) + (justification * action) +
                    (justification * action * demdef) + post_libdem_frelect + post_agree,
                  data = demojudges,
                  weights = weight)

models_cntrl_agree <- list(sm.cntrl.agree, im.cntrl.agree.ad, im.cntrl.agree.jd, im.cntrl.agree.tw)

texreg(models_cntrl_agree,
       caption = "Does democratic defence matter if we control for agreement?",
       caption.above = TRUE,
       label = "tab:agree.cntrl")

# mediation effects

##### Country Effects ----------------------------------------------------------

### Overall ----
# H1a, H1b, H2
sm.eval.cntry <- lm(dv_eval ~ justification + action + demdef +
                 country + post_libdem_frelect,
               data = demojudges,
               weights = weight) 

# H3
im.eval.ad.cntry <- lm(dv_eval ~ justification + action + demdef + (action * demdef) +
                    country + post_libdem_frelect,
                  data = demojudges,
                  weights = weight)

# H4
im.eval.jd.cntry  <- lm(dv_eval ~ justification + action + demdef + (justification * demdef) +
                     country + post_libdem_frelect,
                   data = demojudges,
                   weights = weight)

# H5
im.eval.tw.cntry <- lm(dv_eval ~ justification + action + demdef + 
                    (justification * demdef) + (action * demdef) + (justification * action) +
                    (justification * action * demdef) +
                    country + post_libdem_frelect,
                  data = demojudges,
                  weights = weight)

models_eval_country <- list(sm.eval.cntry, im.eval.ad.cntry, im.eval.jd.cntry, im.eval.tw.cntry)

texreg(models_eval_country,
       caption = "Does democratic defence matter (with country effects)?",
       caption.above = TRUE,
       label = "tab:cntry")

### Netherlands
netherlands <- demojudges |> 
  filter(country == "NL")

france <- demojudges |> 
  filter(country == "FR")

germany <- demojudges |> 
  filter(country == "DE")

# H1a, H1b, H2
sm.eval.nl <- lm(dv_eval ~ justification + action + demdef,
                    data = netherlands,
                    weights = weight) 

sm.eval.fr <- lm(dv_eval ~ justification + action + demdef,
                 data = france,
                 weights = weight) 

sm.eval.de <- lm(dv_eval ~ justification + action + demdef,
                 data = germany,
                 weights = weight) 


models_eval_splitcntry <- list(sm.eval.nl, sm.eval.fr, sm.eval.de)

texreg(models_eval_splitcntry,
       caption = "Does democratic defence matter in different countries?",
       caption.above = TRUE,
       label = "tab:splitcntry",
       custom.model.names = c("Netherlands", "France", "Germany"))


##### Incumbent Effects --------------------------------------------------------
incumbency <- demojudges |> 
  mutate(
    incumbency = case_when(
      vote == "VVD" ~ 1,
      vote == "Macron" ~ 1,
      vote == "SPD" ~ 1,
      TRUE ~ 0),
    coalition = case_when(
      vote == "VVD" | vote == "CDA" | vote == "D66" | vote == "CU" ~ 1,
      vote == "Macron" ~ 1, #do we have the coalition-vote information from the presidential candidate vote?
      vote == "SPD"| vote == "FDP" | vote == "Bündnis 90 / Die Grünen" ~ 1,
      TRUE ~ 0))

# H1a, H1b, H2
sm.eval.inc <- lm(dv_eval ~ justification + action + demdef +
                    incumbency + post_libdem_frelect,
                    data = incumbency,
                    weights = weight) 

sm.eval.coa <- lm(dv_eval ~ justification + action + demdef +
                    coalition + post_libdem_frelect,
                  data = incumbency |> filter(country != "FR"),
                  weights = weight) 

sm.eval.coa.fr <- lm(dv_eval ~ justification + action + demdef +
                    coalition + post_libdem_frelect,
                  data = incumbency,
                  weights = weight) 


models_eval_inc <- list(sm.eval.inc, sm.eval.coa, sm.eval.coa.fr)

texreg(models_eval_inc,
       caption = "Does democratic defence matter (with incumbency effects)?",
       caption.above = TRUE,
       label = "tab:inc")

##### Democracy Attitudes ------------------------------------------------------
# H1a, H1b, H2
sm.eval.dem <- lm(dv_eval ~ justification + action + demdef +
                      post_libdem_frexp + post_libdem_frassc + post_libdem_unisuff + post_libdem_frelect + post_libdem_judcnstr + post_libdem_eqlaw +
                    post_dem_satis + post_dem_sup,
                    data = demojudges,
                    weights = weight) 

# H3
im.eval.ad.dem <- lm(dv_eval ~ justification + action + demdef + (action * demdef) +
                       post_libdem_frexp + post_libdem_frassc + post_libdem_unisuff + post_libdem_frelect + post_libdem_judcnstr + post_libdem_eqlaw +
                       post_dem_satis + post_dem_sup,
                       data = demojudges,
                       weights = weight)

# H4
im.eval.jd.dem  <- lm(dv_eval ~ justification + action + demdef + (justification * demdef) +
                        post_libdem_frexp + post_libdem_frassc + post_libdem_unisuff + post_libdem_frelect + post_libdem_judcnstr + post_libdem_eqlaw +
                        post_dem_satis + post_dem_sup,
                        data = demojudges,
                        weights = weight)

# H5
im.eval.tw.dem <- lm(dv_eval ~ justification + action + demdef + 
                         (justification * demdef) + (action * demdef) + (justification * action) +
                         (justification * action * demdef) +
                       post_libdem_frexp + post_libdem_frassc + post_libdem_unisuff + post_libdem_frelect + post_libdem_judcnstr + post_libdem_eqlaw +
                       post_dem_satis + post_dem_sup,
                       data = demojudges,
                       weights = weight)

models_eval_dem <- list(sm.eval.dem, im.eval.ad.dem, im.eval.jd.dem, im.eval.tw.dem)

texreg(models_eval_dem,
       caption = "Does democratic defence matter (if we control for commitment to democracy)?",
       caption.above = TRUE,
       label = "tab:dem",
       longtable = TRUE)

##### Political Trust ----------------------------------------------------------
trust <- demojudges |> 
  mutate(trust = (pol_trust_crt + pol_trust_gov + pol_trust_med + pol_trust_pol + pol_trust_par) / 5)

# Seperate items
# H1a, H1b, H2
sm.eval.trust.items <- lm(dv_eval ~ justification + action + demdef +
                            pol_trust_crt + pol_trust_gov + pol_trust_med + pol_trust_pol + pol_trust_par,
                   data = demojudges,
                   weights = weight) 

texreg(sm.eval.trust.items,
       caption = "Does democratic defence matter (with all trust-items)?",
       caption.above = TRUE,
       label = "tab:trust-items")

# On the aggregate
# H1a, H1b, H2
sm.eval.trust <- lm(dv_eval ~ justification + action + demdef +
                     trust,
                   data = trust,
                   weights = weight) 

# H3
im.eval.ad.trust <- lm(dv_eval ~ justification + action + demdef + (action * demdef) +
                         trust,
                      data = trust,
                      weights = weight)

# H4
im.eval.jd.trust  <- lm(dv_eval ~ justification + action + demdef + (justification * demdef) +
                          trust,
                       data = trust,
                       weights = weight)

# H5
im.eval.tw.trust <- lm(dv_eval ~ justification + action + demdef + 
                        (justification * demdef) + (action * demdef) + (justification * action) +
                        (justification * action * demdef) +
                         trust,
                      data = trust,
                      weights = weight)

models_eval_trust <- list(sm.eval.trust, im.eval.ad.trust, im.eval.jd.trust, im.eval.tw.trust)

texreg(models_eval_trust,
       caption = "Does democratic defence matter (with trust-index)?",
       caption.above = TRUE,
       label = "tab:trust")

##### Political Interest and RiLe ----------------------------------------------
# H1a, H1b, H2
sm.eval.rile <- lm(dv_eval ~ justification + action + demdef +
                     rile + pol_interest,
                    data = demojudges,
                    weights = weight) 

# H3
im.eval.ad.rile <- lm(dv_eval ~ justification + action + demdef + (action * demdef) +
                        rile + pol_interest,
                       data = demojudges,
                       weights = weight)

# H4
im.eval.jd.rile  <- lm(dv_eval ~ justification + action + demdef + (justification * demdef) +
                         rile + pol_interest,
                        data = demojudges,
                        weights = weight)

# H5
im.eval.tw.rile <- lm(dv_eval ~ justification + action + demdef + 
                         (justification * demdef) + (action * demdef) + (justification * action) +
                         (justification * action * demdef) +
                        rile + pol_interest,
                       data = demojudges,
                       weights = weight)

models_eval_rile <- list(sm.eval.rile, im.eval.ad.rile, im.eval.jd.rile, im.eval.tw.rile)

texreg(models_eval_rile,
       caption = "Does democratic defence matter (with interest and RiLe)?",
       caption.above = TRUE,
       label = "tab:resp")

##### Unweighted ---------------------------------------------------------------

sm.eval.unw <- lm(data = demojudges,
              
              dv_eval ~ 
                # treatments
                justification + action + demdef)
              
im.si.eval.unw <- lm(data = demojudges,
                 
                 dv_eval ~ 
                   #treatments
                   justification + action + demdef + (action * demdef))

im.jd.eval.unw <- lm(data = demojudges,
                 
                 dv_eval ~ 
                   #treatments
                   justification + action + demdef + (justification * demdef))

im.tw.eval.unw <- lm(data = demojudges,
                 
                 dv_eval ~ 
                   
                   #treatments
                   justification + action + demdef +
                   (justification * demdef) + (justification * action) + (demdef * action) +
                   (justification * demdef * action))

unw_models <- list(sm.eval.unw, im.si.eval.unw, im.jd.eval.unw, im.tw.eval.unw)

texreg(unw_models,
       caption = "Does Democratic Defence Matter (Unweighted Data)?",
       caption.above = TRUE,
       label = "tab:unwmodels")

# Mediation ----
### Ambiguity ----
tbl_ambi.unw <- demojudges |> 
  filter(dv_ambi != "NA") |> 
  
  # reverse coding to match intuition: higher scores mean more ambiguity
  mutate(dv_ambi = case_when(
    dv_ambi == 1 ~ 6,
    dv_ambi == 2 ~ 5,
    dv_ambi == 3 ~ 4,
    dv_ambi == 4 ~ 3,
    dv_ambi == 5 ~ 2,
    dv_ambi == 6 ~ 1,
  ))

cm.ambi.xy.unw <- lm(dv_eval ~ justification + action + demdef,
                 data = tbl_ambi.unw)

cm.ambi.xm.unw <- lm(dv_ambi ~ justification + action + demdef,
                 data = tbl_ambi.unw)

cm.ambi.xmy.unw <- lm(dv_eval ~ justification + dv_ambi + action + demdef,
                  data = tbl_ambi.unw)

texreg(list(cm.ambi.xy.unw, cm.ambi.xm.unw, cm.ambi.xmy.unw),
       custom.header = list("Dependent Variable:" = 1:3),
       custom.model.names = c("Democracy Evaluation", "Ambiguity", "Democracy Evaluation"),
       label = "tab:ambi-unweighted",
       caption = "Ambiguity Mediation Models (Unweighted Data)",
       caption.above = TRUE)

cm.ambi.cor.unw <- mediation::mediate(cm.ambi.xm.unw, cm.ambi.xmy.unw,
                                  treat = "justification",
                                  treat.value = "corruption",
                                  control.value = "none",
                                  mediator = "dv_ambi")

summary(cm.ambi.cor.unw)

cm.ambi.sel.unw <- mediation::mediate(cm.ambi.xm.unw, cm.ambi.xmy.unw,
                                  treat = "justification",
                                  treat.value = "self-serving",
                                  control.value = "none",
                                  mediator = "dv_ambi")

summary(cm.ambi.sel.unw) 


### Credibility ----
# these models are run without demdef as dv_cred was only shown when demdef == 1

tbl_cred.unw <- demojudges |> 
  filter(dv_cred != "NA") |> 
  
  # reverse coding to match intuition: higher scores mean more credibility
  mutate(dv_cred = case_when(
    dv_cred == 1 ~ 6,
    dv_cred == 2 ~ 5,
    dv_cred == 3 ~ 4,
    dv_cred == 4 ~ 3,
    dv_cred == 5 ~ 2,
    dv_cred == 6 ~ 1,
  ))

cm.cred.xy.unw <- lm(dv_eval ~ justification + action,
                 data = tbl_cred.unw)

cm.cred.xm.unw <- lm(dv_cred ~ justification + action,
                 data = tbl_cred.unw)

cm.cred.xmy.unw <- lm(dv_eval ~ justification + dv_cred + action,
                  data = tbl_cred.unw)

texreg(list(cm.cred.xy.unw, cm.cred.xm.unw, cm.cred.xmy.unw),
       custom.header = list("Dependent Variable:" = 1:3),
       custom.model.names = c("Democracy Evaluation", "Credibility", "Democracy Evaluation"),
       label = "tab:cred_unweighted",
       caption = "Credibility Mediation Models (Unweighted Data)",
       caption.above = TRUE)

cm.cred.unw <- mediation::mediate(cm.cred.xm.unw, cm.cred.xmy.unw,
                              treat = "action",
                              treat.value = "judiciary",
                              control.value = "media",
                              mediator = "dv_cred")

summary(cm.cred.unw)

# protest ----
# define new function to run multiple lm() for all protest items and the sum-index
run_multiple_lm_unw <- function(dv){
  lm_formula <- as.formula(paste(dv, "~ action + demdef + justification"))
  model <- lm(lm_formula, data = demojudges)
  result <- tidy(model, conf.int = TRUE)
  result$dv <- dv
  return(result)
}

protest.dvs.unw <- c("dv_protest",
                 "dv_protest_vote", "dv_protest_poster", "dv_protest_pers",
                 "dv_protest_peti", "dv_protest_lawpr", "dv_protest_cont", "dv_protest_unlaw")

### simple model
sm.protest.unw <- map_df(protest.dvs.unw, run_multiple_lm_unw) |> 
  mutate(model = "simple") |> 
  mutate(dv = factor(dv, levels = c("dv_protest", "dv_protest_vote", "dv_protest_poster", "dv_protest_pers",
                                    "dv_protest_peti", "dv_protest_lawpr", "dv_protest_cont", "dv_protest_unlaw")))

#### Table for Protest-dv ----
protest.table.unw <- sm.protest.unw |> 
  mutate(sig = case_when(p.value < 0.05 ~ "*",
                         p.value < 0.01 ~ "**",
                         p.value < 0.001 ~ "***",
                         TRUE ~ ""),
         stat = str_c(round(estimate, 2), " (", round(std.error,2 ), ")", sig)) |> 
  filter(term != "post_libdem_frelect") |> 
  dplyr::select(term, dv, stat) |> 
  pivot_wider(names_from = dv, values_from = stat) |> 
  t()


# Table 
kable(protest.table.unw, 
      booktabs = TRUE, 
      format = "latex",
      caption = "Does Democratic Defence Cue Political Participation? (Unweighted Data)",
      label = "protest_unw",
      escape = TRUE)

# /./ End of Code /./
