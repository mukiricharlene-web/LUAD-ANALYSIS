import pandas as pd
import matplotlib.pyplot as plt

# Load dataset
df = pd.read_csv("for chatgpt.csv")

# Calculate median survival per immune phenotype
median_survival = (
    df.groupby("immune_phenotype")["survival_time"]
    .median()
    .sort_values(ascending=False)
)

# Calculate mortality rate per immune phenotype
mortality_rate = (
    df.groupby("immune_phenotype")["survival_status"]
    .mean()
    .sort_values(ascending=False)
)

# Plot median survival
plt.figure(figsize=(8,6))
median_survival.plot(kind='bar')

plt.xlabel("Immune Phenotype")
plt.ylabel("Median Survival Time (Days)")
plt.title("Median Survival Across Tumor Immune Phenotypes")

plt.xticks(rotation=0)
plt.tight_layout()
plt.show()

# Plot mortality rate
plt.figure(figsize=(8,6))
mortality_rate.plot(kind='bar')

plt.xlabel("Immune Phenotype")
plt.ylabel("Mortality Rate")
plt.title("Mortality Rate Across Tumor Immune Phenotypes")

plt.xticks(rotation=0)
plt.tight_layout()
plt.show()