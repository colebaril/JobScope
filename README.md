# JobScope  <img src='logo.png' align="right" height="210" />

[![](https://img.shields.io/badge/Shiny-shinyapps.io-blue?style=flat&labelColor=white&logo=RStudio&logoColor=blue)](https://colewb.shinyapps.io/JobScope/) 
![](https://img.shields.io/badge/Status-Active-Green) ![](https://img.shields.io/badge/Build-Functional-green) 
![](https://img.shields.io/badge/Version-0.0.1-orange)
![Last Commit](https://img.shields.io/github/last-commit/colebaril/JobScope)

I built a GitHub Actions workflow and [Shiny app](https://colewb.shinyapps.io/JobScope/) that automates daily job scraping at midnight GMT (6PM CST), gathering postings from Glassdoor, LinkedIn, Indeed, ZipRecruiter, and Google Jobs based on predefined keywords. The script compiles these listings into a centralized table, appending new data while preserving historical results. Designed to save time, this solution streamlines the job search process by eliminating the need to manually check multiple job boards, providing an efficient and organized way to track relevant opportunities.

# Job Search Queries

Every midnight GMT (6PM CST), Glassdoor, LinkedIn, Indeed, ZipRecruiter, and Google Jobs are searched for jobs in **Winnipeg, MB**, that were posted with the **last 24 hours**. Currently, the following search terms are used:

1. Laboratory technician
2. Research assistant
3. Quality control analyst
4. Biological technician
5. Microbiology technician
6. Data analyst
7. Program coordinator
8. Project manager
9. R programming language

If you use this app and wish to have additional search terms included, please send me an email [here](mailto:colebarilca@gmail.com). 

# How It Works

At midnight GMT, a GitHub Actions workflow is triggered via a cron job, which runs the `job_scraper.py` script. The script scrapes various job boards and appends results to the `jobs_combined.csv` file. The data is then read on load by the Shiny app which involves some data clean-up and displays all data in a table with various filtering options.



