

with open("..\simulation\modelsim\diff_jumpout.txt", "r") as f:
    line_num_str_full = f.readline()
    line_num_str = list(line_num_str_full)
    line_str = ''
    i=0
    line_jumpout = 0
    while(True):
        line_str += line_num_str[i]
        try:
            line_jumpout = int(line_str)
        except ValueError:
            line_jumpout = int(line_str[0:len(line_str)-1])
            break
        i+=1

    # idx = line_num_str.index('c')
    # line_num = int(line_num_str[0:idx])
    # first = f.readline()
    # f.readline()
    # second = f.readline()

    with open ('..\simulation\modelsim\mp4_jumptime.txt') as a:
        with open ('..\simulation\modelsim\mp4_jumpout.txt') as c:

        # time1 = a.readline()
            for i in range(line_jumpout):
                time1 = a.readline()
                first = c.readline()
        


    with open ('..\..\mp2\simulation\modelsim\mp2_jumptime.txt') as b:
        with open ('..\..\mp2\simulation\modelsim\mp2_jumpout.txt') as d:
        # time2 = b.readline()
            for i in range(line_jumpout):
                time2 = b.readline()
                second = d.readline()
        

with open("..\simulation\modelsim\diff_regout.txt", "r") as f:
    line_num_str_full = f.readline()
    line_num_str = list(line_num_str_full)
    line_str = ''
    i=0
    line_regout = 0
    while(True):
        line_str += line_num_str[i]
        try:
            line_regout = int(line_str)
        except ValueError:
            line_regout = int(line_str[0:len(line_str)-1])
            # print(line_regout)
            break
        i+=1

    # idx = line_num_str.index('c')
    # line_num = int(line_num_str[0:idx])
    # first = f.readline()
    # f.readline()
    # second = f.readline()

    with open ('..\simulation\modelsim\mp4_regtimeout.txt') as a:
        with open ('..\simulation\modelsim\mp4_regoutput.txt') as c:

        # time1 = a.readline()
            for i in range(line_regout):
                time3 = a.readline()
                third = c.readline()
        


    with open ('..\..\mp2\simulation\modelsim\mp2_regtimeout.txt') as b:
        with open ('..\..\mp2\simulation\modelsim\mp2_regoutput.txt') as d:
        # time2 = b.readline()
            for i in range(line_regout):
                time4 = b.readline()
                fourth = d.readline()
    
    print(time1.split()[-1])
    print(time3.split()[-1])
    print("MP4 (Test):")
    if (int(time1.split()[-1]) < int(time3.split()[-1])):
        print(first)
        print(time1)
    else:
        print(third)
        print(time3)
    # print('')
    print("-------------")
    # print('')
    print("MP2 (Gold):")
    if (int(time2.split()[-1]) < int(time4.split()[-1])):
        print(second)
        # print("here")
        print(time2)
    else:
        print(fourth)
        print(time4)
