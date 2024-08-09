#!/bin/bash

# Function to execute a command in directories containing a Pipfile
execute_in_dirs() {
    local command=$1
    # Find Pipfiles in the current and immediate child directories, excluding hidden directories
    find . -maxdepth 2 -type f -name 'Pipfile' ! -path '*/\.*/*' | while read pipfile; do
        dir=$(dirname "$pipfile")
        echo "Executing in $dir"
        (cd "$dir" && eval "$command")
    done
}

# Setup
setup_local() {
    pip install --user pipenv
    pipenv install
    pipenv install --dev
    pre-commit install
}

# Static Analysis
static_analysis() {
    pipenv run mypy src
}

# Function to run pytest and generate junit_xml reports against directories containing a Pipfile
test_and_report_from_dirs() {
    # Find Pipfiles in the current and immediate child directories, excluding hidden directories
    find . -maxdepth 2 -type f -name 'Pipfile' ! -path '*/\.*/*' | while read pipfile; do
        dir=$(dirname "$pipfile")
        echo "Executing in $dir"
        (cd "$dir" && eval "pipenv run python -m pytest --junitxml=../reports/$dir/unit_tests.xml")
    done
}

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [lock|sync|test|requirements|test_and_report]"
    echo "  lock: Update pipenv lockfile"
    echo "  sync: Refresh the pipenv environment"
    echo "  test: Run tests"
    echo "  requirements: Exports a requirements.txt and runtime-requirements.txt"
    echo "  test_and_report: Runs tests and generates reports in junit format locally."
    exit 1
fi

# Process the argument
case $1 in
    setup)
        setup_local
        ;;
    static_analysis)
        static_analysis
        ;;
    lock)
        execute_in_dirs "pipenv lock"
        ;;
    sync)
        execute_in_dirs "pipenv sync --categories=\"packages,runtime-packages,test-packages\""
        ;;
    test)
        execute_in_dirs "pipenv run python -m pytest"
        ;;
    requirements)
        execute_in_dirs "pipenv requirements --categories=\"packages\" > src/requirements.txt"
        execute_in_dirs "pipenv requirements --categories=\"runtime-packages\" > src/runtime-requirements.txt"
        ;;
    test_and_report)
        test_and_report_from_dirs
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: $0 [lock|sync|test|requirements|test_and_report]"
        exit 1
        ;;
esac
