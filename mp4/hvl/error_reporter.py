

with open("diff.txt", "r") as f:
    line_num_str = f.readline()
    idx = line_num_str.index('c')
    line_num = int(line_num_str[0:idx])
    first = f.readline()
    f.readline()
    second = f.readline()

    with open ('mp2_lstimeout.txt') as a:

        time1 = a.readline()
        for i in range(line_num):
            time1 = a.readline()
        


    with open ('mp4_lstimeout.txt') as b:
        time2 = b.readline()
        for i in range(line_num):
            time2 = b.readline()
        
    
    print("MP2 (Gold):")
    print(first)
    print(time1)
    print('')
    print("-------------")
    print('')
    print("MP4 (Test):")
    print(second)
    print(time2)
