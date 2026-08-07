---
title: Airflow setup
layout: default
nav_order: 1
parent: Automated processing with flocs
---

To set up Airflow:
1. Install airflow: `uv pip install apache-airflow`
2. Set up a folder that wil contain all of Airflow's own stuff and assign it to the `AIRFLOW_HOME` environment variable.
3. Run `airflow config list --defaults > "${AIRFLOW_HOME}/airflow.cfg"`
4. Define `AIRFLOW__CORE__DAGS_FOLDER` as `${AIRFLOW_HOME}/dags` and create the folder. Copy the DAGs inside `flocs_processing/dags` to this folder.
5. Define `AIRFLOW__CORE__LOAD_EXAMPLES` as `False`

Finally, define the following airflow variables:

```
export AIRFLOW_HOME=/path/to/some/folder/for/airflow
export AIRFLOW__CORE__DAGS_FOLDER=$AIRFLOW_HOME/dags
export AIRFLOW__CORE__LOAD_EXAMPLES=False
export AIRFLOW__CORE__PARALLELISM=32
export AIRFLOW__LOGGING__DAG_PROCESSOR_CHILD_PROCESS_LOG_DIRECTORY=$AIRFLOW_HOME/logs/dag_processor
export AIRFLOW__CORE__PLUGINS_FOLDER=$AIRFLOW_HOME/plugins
export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="sqlite:///$AIRFLOW_HOME/airflow.db"
export AIRFLOW__LOGGING__BASE_LOG_FOLDER=$AIRFLOW_HOME/logs
```

For a small test, you can run `airflow standalone` to start the Airflow instance for a small test.  For proper deployment, it is recommended by the Airflow docs to not use `standalone`. First we'll set up a persistent JWT secret for authentication purpose.

```
mkdir -p "$HOME/.config/airflow"
chmod 700 "$HOME/.config/airflow"
openssl rand -hex 32 > "$HOME/.config/airflow/jwt_secret"
chmod 600 "$HOME/.config/airflow/jwt_secret"
export AIRFLOW__API_AUTH__JWT_SECRET="$(cat "$HOME/.config/airflow/jwt_secret")"
```

Next, initialise Airflow's own database with

```
airflow db migrate
```

Finally, to start the necessary Airflow services, execute them like follows:

```
tmux new-session -d -s airflow-api-server "bash -c 'source $HOME/source_airflow.sh && airflow api-server'; bash -i"
tmux new-session -d -s airflow-triggerer "bash -c 'source $HOME/source_airflow.sh && airflow triggerer'; bash -i"
tmux new-session -d -s airflow-dag-processor "bash -c 'source $HOME/source_airflow.sh && airflow dag-processor'; bash -i"
tmux new-session -d -s airflow-scheduler "bash -c 'source $HOME/source_airflow.sh && airflow scheduler'; bash -i"
```

This should start four tmux sessions with these services running in the background. The credentials to log into e.g. the web interface will be stored in `${AIRFLOW_HOME}/simple_auth_manager_passwords.json.generated`. The Airflow instance will start on port 8080. You can access it via `localhost:8080` in your browser. If it is running on a remote cluster, you can set up a tunnel via e.g. `ssh -N -L 8080:localhost:8080 <remote>` to forward it to your local machine.
