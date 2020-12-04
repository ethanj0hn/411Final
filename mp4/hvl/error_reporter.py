

with open("..\simulation\modelsim\diff_regout.txt", "r") as f:
    line_num_str = f.readline()
    idx = line_num_str.index('c')
    line_num = int(line_num_str[0:idx])
    first = f.readline()
    f.readline()
    second = f.readline()

    with open ('..\simulation\modelsim\mp4_regtimeout.txt') as a:

        # time1 = a.readline()
        for i in range(line_num):
            time1 = a.readline()
        


    with open ('..\..\mp2\simulation\modelsim\mp2_regtimeout.txt') as b:
        # time2 = b.readline()
        for i in range(line_num):
            time2 = b.readline()
        
    
    print("MP4 (Test):")
    print(first)
    print(time1)
    # print('')
    print("-------------")
    # print('')
    print("MP2 (Gold):")
    print(second)
    print(time2)
