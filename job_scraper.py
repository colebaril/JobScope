import pandas as pd
from jobspy import scrape_jobs
from datetime import datetime
import requests
from io import StringIO
import os

# Get the directory of the Python script
base_dir = os.path.dirname(os.path.abspath(__file__))
local_csv_file = os.path.join(base_dir, "jobs_combined.csv")

# GitHub raw file URL for the CSV
github_csv_url = "https://github.com/colebaril/JobScope/blob/main/jobs_combined.csv?raw=TRUE"

# List of job search terms
job_search_terms = [
    "laboratory technician",
    "research assistant",
    "quality control analyst",
    "biological technician",
    "microbiology technician",
    "data analyst",
    "program coordinator",
    "project manager"
]

# Initialize an empty list to store results
all_jobs = []

# Get the current date for the date stamp
date_stamp = datetime.now().strftime("%Y-%m-%d")

# Step 1: Read the existing data from GitHub
try:
    print("Fetching existing data from GitHub...")
    response = requests.get(github_csv_url)
    response.raise_for_status()
    existing_jobs = pd.read_csv(StringIO(response.text))
    print(f"Loaded {len(existing_jobs)} rows from the existing dataset.")
except Exception as e:
    print(f"Failed to fetch existing data from GitHub: {e}")
    existing_jobs = pd.DataFrame()  # Create an empty DataFrame if fetch fails

# Step 2: Scrape new jobs
for term in job_search_terms:
    print(f"Scraping jobs for search term: {term}")
    jobs = scrape_jobs(
        site_name=["indeed", "linkedin", "zip_recruiter", "glassdoor", "google"],
        search_term=term,
        google_search_term=f"{term} jobs in Winnipeg, MB since yesterday",
        location="Winnipeg, MB",
        results_wanted=50,
        hours_old=24,
        country_indeed="Canada",
    )
    
    if not jobs.empty:  # Ensure the DataFrame isn't empty
        # Add the search term and date stamp as new columns
        jobs["search_term"] = term
        jobs["date_scraped"] = date_stamp
        
        # Append jobs to the list
        all_jobs.append(jobs)
        print(f"Found {len(jobs)} jobs for search term: {term}")

# Step 3: Combine newly scraped data
if all_jobs:
    new_jobs = pd.concat(all_jobs, ignore_index=True)
    print(f"Scraped a total of {len(new_jobs)} new jobs.")
else:
    new_jobs = pd.DataFrame()
    print("No new jobs scraped.")

# Step 4: Combine existing and new data
if not existing_jobs.empty:
    # Append new jobs to existing dataset
    combined_jobs = pd.concat([existing_jobs, new_jobs], ignore_index=True)
else:
    combined_jobs = new_jobs  # If no existing data, use only the new data

print(f"Final dataset contains {len(combined_jobs)} rows.")

# Step 5: Save the final combined dataset to the same directory as the script
combined_jobs.to_csv(local_csv_file, index=False)
print(f"Data successfully saved to {local_csv_file}.")
