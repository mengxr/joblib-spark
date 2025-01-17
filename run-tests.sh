#!/usr/bin/env bash

#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Return on any failure
set -e

# assumes run from python/ directory
if [ -z "$SPARK_HOME" ]; then
    echo 'You need to set $SPARK_HOME to run these tests.' >&2
    exit 1
fi

# Honor the choice of python driver
if [ -z "$PYSPARK_PYTHON" ]; then
    PYSPARK_PYTHON=`which python`
fi
# Override the python driver version as well to make sure we are in sync in the tests.
export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
python_major=$($PYSPARK_PYTHON -c 'import sys; print(".".join(map(str, sys.version_info[:1])))')

LIBS=""
for lib in "$SPARK_HOME/python/lib"/*zip ; do
  LIBS=$LIBS:$lib
done

# The current directory of the script.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


export PYSPARK_SUBMIT_ARGS="--driver-memory 2g --executor-memory 2g pyspark-shell "

export PYTHONPATH=$PYTHONPATH:$SPARK_HOME/python:$LIBS:.

export PYTHONPATH=$PYTHONPATH:joblibspark

echo "PYTHONPATH: ${PYTHONPATH}"

# Run test suites
echo "PYSPARK_PIN_THREAD: ${PYSPARK_PIN_THREAD}"
if [[ "$python_major" == "2" ]]; then
  echo $PYSPARK_DRIVER_PYTHON `which nosetests` -v --all-modules -w $DIR 2>&1 | grep -vE "INFO (ParquetOutputFormat|SparkContext|ContextCleaner|ShuffleBlockFetcherIterator|MapOutputTrackerMaster|TaskSetManager|Executor|MemoryStore|CacheManager|BlockManager|DAGScheduler|PythonRDD|TaskSchedulerImpl|ZippedPartitionsRDD2)";

  # Horrible hack for spark 1.x: we manually remove some log lines to stay below the 4MB log limit on Travis.
  $PYSPARK_DRIVER_PYTHON `which nosetests` -v --all-modules -w $DIR 2>&1 | grep -vE "INFO (ParquetOutputFormat|SparkContext|ContextCleaner|ShuffleBlockFetcherIterator|MapOutputTrackerMaster|TaskSetManager|Executor|MemoryStore|CacheManager|BlockManager|DAGScheduler|PythonRDD|TaskSchedulerImpl|ZippedPartitionsRDD2)";

else
  echo $PYSPARK_DRIVER_PYTHON -m "nose" -v --all-modules -w $DIR 2>&1 | grep -vE "INFO (ParquetOutputFormat|SparkContext|ContextCleaner|ShuffleBlockFetcherIterator|MapOutputTrackerMaster|TaskSetManager|Executor|MemoryStore|CacheManager|BlockManager|DAGScheduler|PythonRDD|TaskSchedulerImpl|ZippedPartitionsRDD2)";

  $PYSPARK_DRIVER_PYTHON -m "nose" -v --all-modules -w $DIR 2>&1 | grep -vE "INFO (ParquetOutputFormat|SparkContext|ContextCleaner|ShuffleBlockFetcherIterator|MapOutputTrackerMaster|TaskSetManager|Executor|MemoryStore|CacheManager|BlockManager|DAGScheduler|PythonRDD|TaskSchedulerImpl|ZippedPartitionsRDD2)";

fi

# Exit immediately if the tests fail.
# Since we pipe to remove the output, we need to use some horrible BASH features:
# http://stackoverflow.com/questions/1221833/bash-pipe-output-and-capture-exit-status
test ${PIPESTATUS[0]} -eq 0 || exit 1;
