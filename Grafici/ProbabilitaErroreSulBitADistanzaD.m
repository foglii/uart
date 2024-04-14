close all 
clear

Ptx = -22.5;       %dB (ricavato dal datasheet)
Pn0 = -92.5;       %dB (ricavato sperimentalmente)
Grx = 2;           %dBi (ricavato dal datasheet) 
Gtx = 2;           %dBi (ricavato dal datasheet)
Margine = -10;     %dB 

Prx = 0;
SNR = 0;
f = 2400000000/8;
lambda = 300000000 / f;

probErrore = 0;

for d = 1:1:200

    Prx(d) = 10.^(Ptx/10) * 10.^(Gtx/10) *10.^(Margine/10)* 10.^(Grx/10) * ...
    ( ( lambda / (4*pi*(d)) ).^2 );
    SNR(d) = (10 .* log10(Prx(d))) - Pn0;
    probErrore(d) = qfunc(sqrt( 10.^(SNR(d)/10)));

end


figure;
plot(probErrore);
xlabel("Distance [m]");
ylabel("Bit Error Probability");
grid on