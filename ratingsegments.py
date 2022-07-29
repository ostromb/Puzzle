import pandas as pd
df = pd.read_csv('lichess_db_puzzle.csv',names=[1,2,3,4,5,6,7,8,9,10,11])
df1 = df[df[4]>1000]
rng_18_20 = df1[df1[4]<1200]
rng_18_20.to_csv('1000_1200.csv',index=False, header=False)

df1 = df[df[4]>1200]
rng_18_20 = df1[df1[4]<1400]
rng_18_20.to_csv('1200_1400.csv',index=False, header=False)

df1 = df[df[4]>1400]
rng_18_20 = df1[df1[4]<1600]
rng_18_20.to_csv('1400_1600.csv',index=False, header=False)

df1 = df[df[4]>1600]
rng_18_20 = df1[df1[4]<1800]
rng_18_20.to_csv('1600_1800.csv',index=False, header=False)

df1 = df[df[4]>1800]
rng_18_20 = df1[df1[4]<2000]
rng_18_20.to_csv('1800_2000.csv',index=False, header=False)

df1 = df[df[4]>2000]
rng_18_20 = df1[df1[4]<2200]
rng_18_20.to_csv('2000_2200.csv',index=False, header=False)

