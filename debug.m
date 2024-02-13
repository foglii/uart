[number,ratio,individual] = biterr([frame,ones(1,3)],pamdemod(sig,2).')
M = movmean(individual,20);
figure;
plot(M);
