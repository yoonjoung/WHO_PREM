# This creates shiny app to display results from PREMs pilot conducted in XXX
# There are four parts in this document:
# 0. Database update 
# 1. USER INTERFACE 
# 2. SERVER
# 3. CREATE APP 

        # call relevant library before start
        library(shiny)
        library(shinythemes)
        
        library(plyr)
        library(dplyr)
        #library(tidyr)
        #library(tidyverse)
        library(plotly)
        library(RColorBrewer)
        #library(lubridate)
        library(stringr)
        #library(stringi)

        date<-as.Date(Sys.time(	), format='%d%b%Y')

##### 0. Database update #####

# Define country information  
    COUNTRY<-"Wakanda"
    NUMDISTRICTS<-"4"
    MONTH<-"June"
    YEAR<-"2023"
    CL<-"Spanish"   
    
    #NUMLISTED_PHONE<-
    #NUMLISTED_FTF<-    

# 0.1 Call PREMs summary estimates data ####
#setwd("~/Dropbox/0iSquared/iSquared_WHO/PREM/DataAnalysis")
#dir()
#dir("./DataProduced")

dta<-read.csv("./DataProduced/summary_PREM_EXAMPLE_R1.csv")
dim(dta)  

dta<-dta%>%
    mutate_if(is.factor, as.character)%>%
    filter(!grepl("Other/NoResponse", grouplabel))%>%
    mutate(
        grouplabel = str_split_i(grouplabel, "_", 3),
        dummy = "" #substitute for grouplabel
    )
    #%>%
    #mutate_at(vars(starts_with(c("y_", "yy_", "yyy_"))), 
    #mutate_at(vars(starts_with(c("y_"))), 
    #          funs(round((.), 1)))

dtapooled<-dta%>%filter(mode=="Both modes" & language=="Both languages")
dtaENPhone<-dta%>%filter(mode=="Phone" & language=="English")
dtaENFTF<-dta%>%filter(mode=="FTF" & language=="English")
dtaCLPhone<-dta%>%filter(mode=="Phone" & language==CL)
dtaCLFTF<-dta%>%filter(mode=="FTF" & language==CL)

# 0.1 Call PREMs client-level data ####
dtamicro<-read.csv("./DataProduced/PREM_EXAMPLE_R1.csv")
dim(dtamicro)  

# 0.2 Prepare user input list ####    
grouplist<-as.vector(unique(dta$group))

grouplist_facility<-c("Facility type",
                      "Facility managing authority")

grouplist_client<-c("Clients' Age",
                    "Clients' Education",
                    "Clients' Gender",
                    "WHO-5 wellbeing score")

# 0.3 Prepare global for figures ####    
### color lists ####
bluecolors <- brewer.pal(9,"Blues")
greencolors <- brewer.pal(9,"Greens")
orangecolors <- brewer.pal(9,"Oranges")
redcolors <- brewer.pal(9,"Reds")
divcolors<-brewer.pal(9,"RdYlBu")

### axis lists ####
ylist<-list(title = " ", 
            autorange = "reversed") #for horizontal bar charts
            
xlist <- list(title = " ", 
              showgrid = FALSE,
              range = list(0, 100))
### legend lists ####
legendlist <- list(orientation="v", font=list(size=12), 
                   #traceorder = "reversed",
                   xanchor = "left", x = 1.0, 
                   yanchor = "center", y = 0.5)

##### 1. USER INTERFACE #####

ui<-fluidPage(
    #shinythemes::themeSelector(),
    theme = shinytheme("sandstone"),
    
    # Header panel 
    headerPanel(paste("Patient Reported Experience Measures:", COUNTRY, "pilot")),

    # Title panel 
    #titlePanel("A. By language"),
    h4("This presents results from the Patient Reported Experience Measures (PREMs) pilot, 
       conducted in select", NUMDISTRICTS, "districts in", COUNTRY, ". 
       See the last tab, Methods, for further information about the pilot."),
    
    # Main page for output display 
    mainPanel(
        width = 12,
        
        tabsetPanel(type = "tabs",

            ##### Summary tab #####
            tabPanel("Summary",                                                 
                h4("Average PREMs scores: summary and domain-specific (range: 0-100)"),   

                fluidRow(
                    h4("All languages and modes - pooled data"),
                    column(12,
                           plotlyOutput("plot_pooled",
                                        width = 500, height = 500)
                    )                      
                ),
                
                fluidRow(
                    h4("By language and mode"),
                    column(12,
                           plotlyOutput("plot_by_language_mode",
                                        width = 1000, height = 500)
                    )                      
                )
            ),
            
            ##### English tab #####        
            tabPanel("English",                    
                         
                h4("Average PREMs scores: summary and domain-specific (range: 0-100), 
                   using the",
                   strong("English"), 
                   "questionnarie - in both modes 
                   (n=", dtaENFTF$obs + dtaENPhone$obs, ")"),                
                fluidRow(
                    column(6,
                           h4("Overall"),    
                           plotlyOutput("plot_English_BothM_overall",
                                        width = 500, height = 500)
                    ), 
                    
                    column(6,
                           h4("By district"),    
                           plotlyOutput("plot_English_BothM_district",
                                        width = 600, height = 500)
                    )                      
                ),  
                hr(),    
                fluidRow(
                    column(6,
                           h4("By clients' characteristics"),   
                           selectInput("group_client_English", 
                                       "Select client characteristic",
                                       choices = grouplist_client, 
                                       selected = "Clients' Age"),
                           plotlyOutput("plot_English_BothM_client",
                                        width = 600, height = 500) 
                    ),
                    column(6,
                           h4("By facilities' characteristics"),   
                           selectInput("group_facility_English", 
                                       "Select facility characteristic",
                                       choices = grouplist_facility, 
                                       selected = "Facility type"),   
                           plotlyOutput("plot_English_BothM_facility",
                                        width = 600, height = 500) 
                    )                      
                )
            ),
            
            ##### Country language tab #####        
            tabPanel(CL,                    
                     
                     h4("Average PREMs scores: summary and domain-specific (range: 0-100), 
                        using the",
                        strong(CL), 
                        "questionnarie - in both modes
                        (n=", dtaCLFTF$obs + dtaCLPhone$obs, ")"),                          
                     fluidRow(
                         column(6,
                                h4("Overall"),    
                                plotlyOutput("plot_CL_BothM_overall",
                                             width = 500, height = 500)
                         ),  
                         column(6,
                                h4("By district"),    
                                plotlyOutput("plot_CL_BothM_district",
                                             width = 600, height = 500)
                         )                      
                     ),                
                     fluidRow(
                         column(6,
                                h4("By clients' characteristics"),   
                                selectInput("group_client_CL", 
                                            "Select client characteristic",
                                            choices = grouplist_client, 
                                            selected = "Clients' Age"),
                                plotlyOutput("plot_CL_BothM_client",
                                             width = 600, height = 500) 
                         ),
                         column(6,
                                h4("By facilities' characteristics"),   
                                selectInput("group_facility_CL", 
                                            "Select facility characteristic",
                                            choices = grouplist_facility, 
                                            selected = "Facility type"),   
                                plotlyOutput("plot_CL_BothM_facility",
                                             width = 600, height = 500) 
                         )                      
                     )
            ),
            
            ##### Phone interviews #####
            tabPanel("Phone",                    
                     
                     h4("Average PREMs scores: summary and domain-specific (range: 0-100), 
                        using data collected from",
                        strong("Phone interviews"),
                        " - in both languages
                        (n=", dtaENPhone$obs + dtaCLPhone$obs, ")"),                
                     fluidRow(
                         column(6,
                                h4("Overall"),    
                                plotlyOutput("plot_BothL_Phone_overall",
                                             width = 600, height = 500)
                         ),
                         column(6,
                                h4("By district"),    
                                plotlyOutput("plot_BothL_Phone_district",
                                             width = 600, height = 500)
                         )                      
                     ),                
                     fluidRow(
                         column(6,
                                h4("By clients' characteristics"),   
                                selectInput("group_client_phone", 
                                            "Select client characteristic",
                                            choices = grouplist_client, 
                                            selected = "Clients' Age"),
                                plotlyOutput("plot_BothL_Phone_client",
                                             width = 600, height = 500) 
                         ),
                         column(6,
                                h4("By facilities' characteristics"),   
                                selectInput("group_facility_phone", 
                                            "Select facility characteristic",
                                            choices = grouplist_facility, 
                                            selected = "Facility type"),   
                                plotlyOutput("plot_BothL_Phone_facility",
                                             width = 600, height = 500) 
                         )                      
                     )
            ),
            
            ##### FTF interviews #####
            tabPanel("FTF",                    
                     
                     h4("Average PREMs scores: summary and domain-specific (range: 0-100), 
                        using data collected from",
                        strong("FTF interviews"),
                        " - in both languages
                        (n=", dtaENFTF$obs + dtaCLFTF$obs, ")"),                
                     fluidRow(
                         column(6,
                                h4("Overall"),    
                                plotlyOutput("plot_BothL_FTF_overall",
                                             width = 600, height = 500)
                         ), 
                         column(6,
                                h4("By district"),    
                                plotlyOutput("plot_BothL_FTF_district",
                                             width = 600, height = 500)
                         )                      
                     ),                
                     fluidRow(
                         column(6,
                                h4("By clients' characteristics"),   
                                selectInput("group_client_FTF", 
                                            "Select client characteristic",
                                            choices = grouplist_client, 
                                            selected = "Clients' Age"),
                                plotlyOutput("plot_BothL_FTF_client",
                                             width = 600, height = 500) 
                         ),
                         column(6,
                                h4("By facilities' characteristics"),   
                                selectInput("group_facility_FTF", 
                                            "Select facility characteristic",
                                            choices = grouplist_facility, 
                                            selected = "Facility type"),   
                                plotlyOutput("plot_BothL_FTF_facility",
                                             width = 600, height = 500) 
                         )                      
                     )
            ),
            
            ##### Process #####
            tabPanel("Implementation Processes",                    
                     
                     h4("Process metrics by language and interview mode"),
                     fluidRow(
                         column(6,
                                h4("XXX"),    
                                #plotlyOutput("plot_BothL_FTF_overall",
                                #             width = 600, height = 500)
                         ), 
                         column(6,
                                h4("YYY"),    
                                #plotlyOutput("plot_BothL_FTF_district",
                                #             width = 600, height = 500)
                         )                      
                     )
            ),
            
            ##### Methods tab #####       
            tabPanel("Methods",           
                     p(strong("Objectives")),
                     p("The pilot study has two objectives:"), 
                     p("(1) to evaluate the PREMs tool, by measuring psychometric properties; and"), 
                     p("(2) to explore feasibility of the two data collection methods, 
                       by assesseing process of the implementation and data quality 
                       with both qualitative and quantitative data."),
                     
                     br(),
                     p(strong("Questionnaire")),
                     p(a("The questionnaire", 
                       href="https://www.census.gov/data/developers/data-sets/decennial-census.html"),
                       "was developed to XYZ..."),

                     br(),
                     p(strong("Study Design")),
                     p("A total of", NUMDISTRICTS, "districts were purposively selected for the pilot, 
                       based on commonly spoken languages, mobile phone ownership, and 
                       logistics for data collection. 
                       Each districts was again purposively assigned to one of the four study arms:"),
                     p("(1) English phone interviews (n=", dtaENPhone$obs, ")"), 
                     p("(2) English face-to-face (FTF) interviews (n=", dtaENFTF$obs, ")"),
                     p("(3)", dtaCLPhone$language, "phone interviews (n=", dtaCLPhone$obs, ")"),
                     p("(4)", dtaCLFTF$language, "FTF interviews (n=", dtaCLFTF$obs, ")."), 
                     p("In all districts, study facilites were purposively selected, 
                       comprised of various types of facilities that provide primary health care services. 
                       Then, study participants were systematically sampled from clients 
                       who attended the study facilities on specific study date(s)."),
                     
                     br(),
                     p(strong("Data Collection")),
                     p("Data collection was conducted in", MONTH, ",", YEAR, ".", 
                       "In districts where phone interviews were conducted, 
                       participants were interviwed about X weeks after they attended the facilities. 
                       Participants were called upto three times on different days and times of the day. 
                       In districts where FTF interviews, participants were interviewed at the facility.
                       In total,", dtapooled$obs, "clients completed interviews. 
                       All interviews were conducted as a computer-assisted personal interview (CAPI)."),
                     
                     br(),
                     p(strong("Data Analyasis: PREMs")),
                     p("In each of the eight domains, a", strong("domain-specific PREMs score"), "is calculated by: 
                       averaging all itmes in the domain (range: 1-5) and, then, scaling the average to 0-100. 
                       The number of items varies across the domains, 
                       ranging from 1 in the professional competence and the overall experience domains 
                       to 18 in the person-centered care domain."),
                     p("The", strong("summary PREMs score"), "is a weigted average of eight domain-specific PREM scores.
                       It ranges from 0 to 100 - the higher score the better experience."),
                     
                     br(),
                     p(strong("Data Analyasis: Process and Data Quality")),
                     p("By language and mode, the following measures were calculated:"),  
                     
                     p("-", strong("Enrollment rate:"), "percentage of selected clients 
                       who agreed to participate in the interview.
                       In FTF interviews, the denominator is the number of all identified eligible clients, and 
                       the numerator is the number of clients who started the interview.
                       In phone interviews, the denominator is the number of all identified eligible clients, and 
                       the numerator is the number of clients who provided their phone numbers."),
                     p("- [ONLY FOR PHONE INTERVIEWS]", strong("Valid phone number rate:"), "percentage of sampled clients 
                       whose phone numbers are eitehr invalid or do not exist."),
                     p("- [ONLY FOR PHONE INTERVIEWS]", strong("Contact rate:"), "percentage of sampled clients 
                       who were contacted successfully with up to three calls."),
                     p("-", strong("Completion rate:"), "percentage of sampled clients who completed the interview. 
                       In FTF interviews, the denominator is the number of clients who started the interivew.
                       In phone interviews, the denominator is the number of clients who were selected."),
                     p("-", strong("Response rate:"), "product of contact rate and completion rate for phone interviews. 
                       In FTF interviews, this is identical with the completion rate."),
                     p("-", strong("percent distribution of participants"), 
                       "by client characteristics, facility type, facility managing authority, and district."),
                     
                     hr(), 
                     h5("For typos, errors, and questions:", 
                        a("contact YJ Choi at www.iSquared.global", 
                          href="https://www.isquared.global/YJ"))
                    
            )
        )
    )
)

##### 2. SERVER #####

##### Define panel #####

panel <- . %>% 
    plot_ly(y = ~dummy )%>%
    
    add_bars(x = ~yyy_w, name = "Summary score",
             text=~yyy_w, textposition = 'auto', textangle=0,  
             marker = list(color = greencolors[8]))%>%              
    
    add_bars(x = ~yy_fc, name = "First contact",
             text=~yy_fc, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[2]))%>%
    add_bars(x = ~yy_cont, name = "Continuity",
             text=~yy_cont, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[3]))%>%
    add_bars(x = ~yy_comp, name = "Comprehensiveness",
             text=~yy_comp, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[4]))%>%
    add_bars(x = ~yy_coor, name = "Coordination",
             text=~yy_coor, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[5]))%>%
    add_bars(x = ~yy_pcc, name = "Person-centered care",
             text=~yy_pcc, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[6]))%>% 
    add_bars(x = ~yy_prof, name = "Professional competence",
             text=~yy_prof, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[7]))%>%               
    add_bars(x = ~yy_overall, name = "Overall",
             text=~yy_overall, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[8]))%>%   
    add_bars(x = ~yy_safe, name = "Safety",
             text=~yy_safe, textposition = 'auto', textangle=0,  
             marker = list(color = bluecolors[9]))%>%
    
    add_annotations(
        text = ~unique(category),
        x = 0.5, y = 1.0, xref = "paper", yref = "paper",    
        xanchor = "center", yanchor = "bottom", showarrow = FALSE,
        font = list(size = 12) )%>%
    
    layout(
        showlegend = FALSE,
        legend = legendlist, 
        yaxis = ylist, 
        xaxis = xlist
    )

##### Server #####
server<-function(input, output) {
    
    ##### output: Summary tab #####

    output$plot_pooled <- renderPlotly({    
        
        dtafig<-dta%>%
            filter(mode=="Both modes" & language=="Both languages") %>%
            mutate(category=paste0(language, ", ", mode, " (n=", obs, ")"))
            
        plot<-dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            ) 
        
        dtafig%>%
        plot_ly(y = ~dummy )%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              
            
            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))%>%
            
            add_annotations(
                text = ~unique(category),
                x = 0.5, y = 1.0, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 12) )%>%
            
            layout(
                showlegend = TRUE,
                legend = legendlist, 
                yaxis = ylist, 
                xaxis = xlist
            )
        
        
        })  

    output$plot_by_language_mode <- renderPlotly({    
        
        dtafig<-dta%>%
            filter(grouplabel=="All")%>%
            filter(mode!="Both modes" & language!="Both languages")%>%
            mutate(category=paste0(language, ", ", mode, " (n=", obs, ")"))

        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                ylist = list(title = " ", autorange = "reversed"),
                xaxis = list(title = " ")
            )

    })  
    
    output$plot_by_language <- renderPlotly({    
        
        dtafig<-dta%>%
            filter(grouplabel=="All" & mode=="Both modes" & language!="Both languages")%>%
            mutate(category=paste0(language, ", ", mode, " (n=", obs, ")"))
        
        plot<-dtafig%>%
            plot_ly(y=~category)%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              

            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))
        
        plot%>%
            layout(
                yaxis = ylist, 
                xaxis = xlist, 
                legend = legendlist
            )
    })  
    
    output$plot_by_mode <- renderPlotly({    
        
        dtafig<-dta%>%
            filter(grouplabel=="All" & mode!="Both modes" & language=="Both languages")%>%
            mutate(category=paste0(language, ", ", mode, " (n=", obs, ")"))
        
        plot<-dtafig%>%
            plot_ly(y=~category)%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              
            
            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))
        
        plot%>%
            layout(
                yaxis = ylist, 
                xaxis = xlist, 
                legend = legendlist
            )        
    })  

    
    ##### output: English tab #####
    
    output$plot_English_BothM_overall <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="English" & mode=="Both modes" & group=="All")%>%
            mutate(category=paste0(language, ", ", mode, ", ", grouplabel, " (n=", obs, ")"))

        dtafig%>%
            plot_ly(y = ~dummy )%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              
            
            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))%>%
            
            add_annotations(
                text = ~unique(category),
                x = 0.5, y = 1.0, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 12) )%>%
            
            layout(
                showlegend = TRUE,
                legend = legendlist, 
                yaxis = ylist, 
                xaxis = xlist
            )   
        
    })  
    
    output$plot_English_BothM_district <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="English" & mode=="Both modes" & group=="District")%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )            
    })      

    output$plot_English_BothM_client <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="English" & mode=="Both modes")%>%
            #filter(group=="Clients' Age")%>%
            filter(group==input$group_client_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
            
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )       
    })          
    
    output$plot_English_BothM_facility <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="English" & mode=="Both modes")%>%
            #filter(group=="Clients' Age")
            filter(group==input$group_facility_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )          
        
    })              
    
    ##### output: Country language tab #####
    output$plot_CL_BothM_overall <- renderPlotly({    
        
        dtafig<-dta%>%filter(language==CL & mode=="Both modes" & group=="All")%>%
            mutate(category=paste0(language, ", ", mode, ", ", grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            plot_ly(y = ~dummy )%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              
            
            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))%>%
            
            add_annotations(
                text = ~unique(category),
                x = 0.5, y = 1.0, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 12) )%>%
            
            layout(
                showlegend = TRUE,
                legend = legendlist, 
                yaxis = ylist, 
                xaxis = xlist
            )   
        
    })  
    
    output$plot_CL_BothM_district <- renderPlotly({    
        
        dtafig<-dta%>%filter(language==CL & mode=="Both modes" & group=="District")%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )            
    })      
    
    output$plot_CL_BothM_client <- renderPlotly({    
        
        dtafig<-dta%>%filter(language==CL & mode=="Both modes")%>%
            #filter(group=="Clients' Age")%>%
            filter(group==input$group_client_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )       
    })          
    
    output$plot_CL_BothM_facility <- renderPlotly({    
        
        dtafig<-dta%>%filter(language==CL & mode=="Both modes")%>%
            #filter(group=="Clients' Age")
            filter(group==input$group_facility_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )          
        
    })           
    ##### output: Phone interviews tab #####
    output$plot_BothL_Phone_overall <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="Phone" & group=="All")%>%
            mutate(category=paste0(language, ", ", mode, ", ", grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            plot_ly(y = ~dummy )%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              
            
            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))%>%
            
            add_annotations(
                text = ~unique(category),
                x = 0.5, y = 1.0, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 12) )%>%
            
            layout(
                showlegend = TRUE,
                legend = legendlist, 
                yaxis = ylist, 
                xaxis = xlist
            )   
        
    })  
    
    output$plot_BothL_Phone_district <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="Phone" & group=="District")%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )            
    })      
    
    output$plot_BothL_Phone_client <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="Phone")%>%
            #filter(group=="Clients' Age")%>%
            filter(group==input$group_client_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )       
    })          
    
    output$plot_BothL_Phone_facility <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="Phone")%>%
            #filter(group=="Clients' Age")
            filter(group==input$group_facility_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )          
        
    })              
    ##### output: FTF interviews tab #####
    output$plot_BothL_FTF_overall <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="FTF" & group=="All")%>%
            mutate(category=paste0(language, ", ", mode, ", ", grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            plot_ly(y = ~dummy )%>%
            
            add_bars(x = ~yyy_w, name = "Summary score",
                     text=~yyy_w, textposition = 'auto', textangle=0,  
                     marker = list(color = greencolors[8]))%>%              
            
            add_bars(x = ~yy_fc, name = "First contact",
                     text=~yy_fc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[2]))%>%
            add_bars(x = ~yy_cont, name = "Continuity",
                     text=~yy_cont, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[3]))%>%
            add_bars(x = ~yy_comp, name = "Comprehensiveness",
                     text=~yy_comp, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[4]))%>%
            add_bars(x = ~yy_coor, name = "Coordination",
                     text=~yy_coor, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[5]))%>%
            add_bars(x = ~yy_pcc, name = "Person-centered care",
                     text=~yy_pcc, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[6]))%>% 
            add_bars(x = ~yy_prof, name = "Professional competence",
                     text=~yy_prof, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[7]))%>%               
            add_bars(x = ~yy_overall, name = "Overall",
                     text=~yy_overall, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[8]))%>%   
            add_bars(x = ~yy_safe, name = "Safety",
                     text=~yy_safe, textposition = 'auto', textangle=0,  
                     marker = list(color = bluecolors[9]))%>%
            
            add_annotations(
                text = ~unique(category),
                x = 0.5, y = 1.0, xref = "paper", yref = "paper",    
                xanchor = "center", yanchor = "bottom", showarrow = FALSE,
                font = list(size = 12) )%>%
            
            layout(
                showlegend = TRUE,
                legend = legendlist, 
                yaxis = ylist, 
                xaxis = xlist
            )   
        
    })  
    
    output$plot_BothL_FTF_district <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="FTF" & group=="District")%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )            
    })      
    
    output$plot_BothL_FTF_client <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="FTF")%>%
            #filter(group=="Clients' Age")%>%
            filter(group==input$group_client_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )       
    })          
    
    output$plot_BothL_FTF_facility <- renderPlotly({    
        
        dtafig<-dta%>%filter(language=="Both languages" & mode=="FTF")%>%
            #filter(group=="Clients' Age")
            filter(group==input$group_facility_English)%>%
            mutate(category=paste0(grouplabel, " (n=", obs, ")"))
        
        dtafig%>%
            group_by(category) %>%
            do(p = panel(.)) %>%
            subplot(nrows = 1, shareX = FALSE, shareY = FALSE)%>%
            layout(
                yaxis = list(title = " "),
                xaxis = list(title = " ")
            )          
        
    })          
    
    ##### output: Methods tab #####
    
    
}       

#******************************
# 3. CREATE APP 
#******************************

 shinyApp(ui = ui, server = server)