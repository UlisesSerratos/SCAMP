#!/bin/bash

extra_opts=$1

EXECUTABLE=../SCAMP
ROOT_DIR_INPUT=SampleInput
ROOT_DIR_OUTPUT=SampleOutput
WINDOWSZ=(100)
TILE_SZ=(2000000 1000000 500000 250000 125000 62500 31250 15625 8000)
INPUT_FILES=(randomwalk8K randomwalk16K randomwalk32K randomwalk64K)
AB_INPUT_FILES=(randomwalk16K randomwalk32K)
NUM_TESTS=$((${#INPUT_FILES[@]} - 1))
NUM_TILE_SZ=$((${#TILE_SZ[@]} - 1))
NUM_AB=$((${#AB_INPUT_FILES[@]} - 1))

for k in `seq 0 $NUM_TESTS`;
do
    INPUT_FILE=$ROOT_DIR_INPUT/${INPUT_FILES[$k]}.txt
    
    for j in $WINDOWSZ;
    do    
        COMPARE_MPI=$ROOT_DIR_OUTPUT/mpi_${INPUT_FILES[$k]}_w$j.txt
        COMPARE_MP=$ROOT_DIR_OUTPUT/mp_${INPUT_FILES[$k]}_w$j.txt
        for i in `seq 0 $NUM_TILE_SZ`;
        do
            tile_sz=${TILE_SZ[i]}
            count=`wc -l $INPUT_FILE | awk '{print $1}'`
            if [ $tile_sz -lt $(($count * 2)) ]; then
                cmd="$EXECUTABLE --window=$j --max_tile_size=$tile_sz $extra_opts --input_a_file_name=$INPUT_FILE"
                echo "Running Test: $cmd"
                $cmd > /dev/null
                X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPI mp_columns_out_index | grep '^' | wc -l`
                echo "$X matrix profile index differences"
                if [ $X -gt $(($count / 100)) ] ; then
                    echo "Failure: Errors in MP index exceed 1% for this test."
                    exit 1
                fi
                ./difference.py mp_columns_out $COMPARE_MP out
                result=$?
                if [ $result -ne 0 ] ; then
                    exit $result
                fi
            fi
        done
    done
done

# Test correct exclusion zone using an AB-join
INPUT_FILE=$ROOT_DIR_INPUT/${INPUT_FILES[$k]}.txt
for j in $WINDOWSZ;
do
    COMPARE_MPI=$ROOT_DIR_OUTPUT/mpi_${INPUT_FILES[$k]}_w$j.txt
    COMPARE_MP=$ROOT_DIR_OUTPUT/mp_${INPUT_FILES[$k]}_w$j.txt
    for i in `seq 0 $NUM_TILE_SZ`;
    do
        tile_sz=${TILE_SZ[i]}
        count=`wc -l $INPUT_FILE | awk '{print $1}'`
        if [ $tile_sz -lt $(($count * 2)) ]; then
            cmd="$EXECUTABLE --aligned --window=$j --max_tile_size=$tile_sz $extra_opts --input_a_file_name=$INPUT_FILE --input_b_file_name=$INPUT_FILE"
            echo "Running Test: $cmd"
            $cmd > /dev/null
            X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPI mp_columns_out_index | grep '^' | wc -l`
            echo "$X matrix profile index differences"
            if [ $X -gt $(($count / 100)) ] ; then
                echo "Failure: Errors in MP index exceed 1% for this test."
                exit 1
            fi
            ./difference.py mp_columns_out $COMPARE_MP out
            result=$?
            if [ $result -ne 0 ] ; then
                exit $result
            fi
        fi
    done
done

for i in `seq 0 $NUM_AB`;
do
    for j in `seq $(($i + 1)) $NUM_AB`;
    do
        INPUT_FILE_A=$ROOT_DIR_INPUT/${AB_INPUT_FILES[$i]}.txt
        INPUT_FILE_B=$ROOT_DIR_INPUT/${AB_INPUT_FILES[$j]}.txt
        for k in $WINDOWSZ;
        do
            COMPARE_MP=$ROOT_DIR_OUTPUT/mp_${AB_INPUT_FILES[$i]}_${AB_INPUT_FILES[$j]}_w$k.txt
            COMPARE_MPI=$ROOT_DIR_OUTPUT/mpi_${AB_INPUT_FILES[$i]}_${AB_INPUT_FILES[$j]}_w$k.txt
            for l in `seq 0 $NUM_TILE_SZ`;
            do
                tile_sz=${TILE_SZ[$l]}
                count=`wc -l $INPUT_FILE_A | awk '{print $1}'`
                if [ $tile_sz -lt $(($count * 2)) ]; then
                    cmd="$EXECUTABLE --max_tile_size=$tile_sz --input_b_file_name=$INPUT_FILE_B $extra_opts --window=$k --input_a_file_name=$INPUT_FILE_A"
                    echo "Running Test: $cmd"
                    $cmd > /dev/null
                    X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPI mp_columns_out_index | grep '^' | wc -l`
                    echo "$X matrix profile index differences"
                    if [ $X -gt $(($count / 100)) ] ; then
                        echo "Failure: Errors in MP index exceed 1% for this test."
                        exit 1
                    fi
                    ./difference.py mp_columns_out $COMPARE_MP out
                    result=$?
                    if [ $result -ne 0 ] ; then
                        exit $result
                    fi
                fi
            done
        done
        for k in $WINDOWSZ;
        do
            COMPARE_MP=$ROOT_DIR_OUTPUT/mp_${AB_INPUT_FILES[$j]}_${AB_INPUT_FILES[$i]}_w$k.txt
            COMPARE_MPI=$ROOT_DIR_OUTPUT/mpi_${AB_INPUT_FILES[$j]}_${AB_INPUT_FILES[$i]}_w$k.txt
            for l in `seq 0 $NUM_TILE_SZ`;
            do
                tile_sz=${TILE_SZ[$l]}
                count=`wc -l $INPUT_FILE_A | awk '{print $1}'`
                if [ $tile_sz -lt $(($count * 2)) ]; then
                    cmd="$EXECUTABLE --max_tile_size=$tile_sz --input_b_file_name=$INPUT_FILE_A $extra_opts --window=$k --input_a_file_name=$INPUT_FILE_B"
                    echo "Running Test: $cmd"
                    $cmd > /dev/null
                    X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPI mp_columns_out_index | grep '^' | wc -l`
                    echo "$X matrix profile index differences"
                    if [ $X -gt $(($count / 100)) ] ; then
                        echo "Failure: Errors in MP index exceed 1% for this test."
                        exit 1
                    fi
                    ./difference.py mp_columns_out $COMPARE_MP out
                    result=$?
                    if [ $result -ne 0 ] ; then
                        exit $result
                    fi
                fi
            done
        done
        for k in $WINDOWSZ;
        do
            COMPARE_MP=$ROOT_DIR_OUTPUT/mp_${AB_INPUT_FILES[$j]}_${AB_INPUT_FILES[$i]}_w$k.txt
            COMPARE_MPI=$ROOT_DIR_OUTPUT/mpi_${AB_INPUT_FILES[$j]}_${AB_INPUT_FILES[$i]}_w$k.txt
            COMPARE_MPB=$ROOT_DIR_OUTPUT/mp_${AB_INPUT_FILES[$i]}_${AB_INPUT_FILES[$j]}_w$k.txt
            COMPARE_MPIB=$ROOT_DIR_OUTPUT/mpi_${AB_INPUT_FILES[$i]}_${AB_INPUT_FILES[$j]}_w$k.txt
            for l in `seq 0 $NUM_TILE_SZ`;
            do
                tile_sz=${TILE_SZ[$l]}
                count=`wc -l $INPUT_FILE_A | awk '{print $1}'`
                if [ $tile_sz -lt $(($count * 2)) ]; then
                    cmd="$EXECUTABLE --max_tile_size=$tile_sz --input_b_file_name=$INPUT_FILE_A --keep_rows=true --global_row=9000000000 --global_col=100000 $extra_opts --window=$k --input_a_file_name=$INPUT_FILE_B"
                    echo "Running Test: $cmd"
                    $cmd > /dev/null
                    echo "Checking AB result"
                    X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPI mp_columns_out_index | grep '^' | wc -l`
                    echo "$X matrix profile index differences"
                    if [ $X -gt $(($count / 100)) ] ; then
                        echo "Failure: Errors in MP index exceed 1% for this test."
                        exit 1
                    fi
                    ./difference.py mp_columns_out $COMPARE_MP out
                    result=$?
                    if [ $result -ne 0 ] ; then
                        exit $result
                    fi
                    echo "Checking BA result"
                    X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPIB mp_rows_out_index | grep '^' | wc -l`
                    echo "$X matrix profile index differences"
                    if [ $X -gt $(($count / 100)) ] ; then
                        echo "Failure: Errors in MP index exceed 1% for this test."
                        exit 1
                    fi
                    ./difference.py mp_rows_out $COMPARE_MPB out
                    result=$?
                    if [ $result -ne 0 ] ; then
                        exit $result
                    fi

                    cmd="$EXECUTABLE --max_tile_size=$tile_sz --input_b_file_name=$INPUT_FILE_B --keep_rows=true --global_row=9000000000 --global_col=100000 $extra_opts --window=$k --input_a_file_name=$INPUT_FILE_A"
                    echo "Running Test: $cmd"
                    $cmd > /dev/null
                    echo "Checking AB result"
                    X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPIB mp_columns_out_index | grep '^' | wc -l`
                    echo "$X matrix profile index differences"
                    if [ $X -gt $(($count / 100)) ] ; then
                        echo "Failure: Errors in MP index exceed 1% for this test."
                        exit 1
                    fi
                    ./difference.py mp_columns_out $COMPARE_MPB out
                    result=$?
                    if [ $result -ne 0 ] ; then
                        exit $result
                    fi
                    
                    echo "Checking BA result"
                    X=`diff --suppress-common-lines --speed-large-files -y $COMPARE_MPI mp_rows_out_index | grep '^' | wc -l`
                    echo "$X matrix profile index differences"
                    if [ $X -gt $(($count / 100)) ] ; then
                        echo "Failure: Errors in MP index exceed 1% for this test."
                        exit 1
                    fi
                    ./difference.py mp_rows_out $COMPARE_MP out
                    result=$?
                    if [ $result -ne 0 ] ; then
                        exit $result
                    fi
                fi
            done
        done
    done
done
echo "All Tests Passed!"
rm mp_columns_out mp_columns_out_index mp_rows_out mp_rows_out_index
exit 0
