if [ x"$(basename `pwd`)" = x"tests" ] ; then
    cd ..
fi

for i in {1..3}; do
    REQUIRE=tests.net_misc ./run.sh &
done

TEST_SERVER=1 REQUIRE=tests.net_misc ./run.sh
