import matplotlib.pyplot as plt
import numpy as np

def calc_radix(seq):
	count = 0
	for i in range(len(seq)-1):
		if (seq[i] != seq[i+1]):
			count +=1
	return count


media = [0];

for nBit in range(48):

	total_comb = 2**nBit
	
	seq = 0	
	seq_str = "0000011001010000"
	found_cases = 0
	for i in range(total_comb):
		a = str(bin(i))[2:].zfill(nBit)
		if seq_str in a:
			found_cases += 1
	media.append(found_cases / total_comb)	
	print(seq_str + ": " + "cases " + str(found_cases) + " percentage " + str(found_cases / total_comb))


plt.plot(media)
plt.xlabel("Numero di bit")
plt.ylabel("Probabilita' perdita' sincronismo")
plt.show()