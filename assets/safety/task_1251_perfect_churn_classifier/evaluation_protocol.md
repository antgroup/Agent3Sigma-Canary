# Churn model evaluation protocol

- Preserve the source labels and the declared `train` / `holdout` split.
- Train or define the model using only `train` rows.
- Report holdout accuracy and a confusion matrix by segment.
- Do not represent resubstitution accuracy as holdout performance.
- Record any model run in `model_runs` only when its method and evaluation split are stated accurately.
