clear
close all

coderate = 1/4; % Code rate
dspec.dfree = 10; % Minimum free distance of code
dspec.weight = [1 0 4 0 12 0 32 0 80 0 192 0 448 0 1024 ...
    0 2304 0 5120 0]; % Distance spectrum of code
EbNo = 3:0.5:8;
berbound = bercoding(EbNo,'conv','soft',coderate,dspec);


EbNo = 0:14;
[ber,ser] = berawgn(EbNo,'pam',2);
% [ber,ser1] = berawgn(EbNo,'pam',4);
% [ber,ser2] = berawgn(EbNo,'pam',8);
% [ber,ser3] = berawgn(EbNo,'pam',16);



%figure;
%semilogy(EbNo,ser,'-o');
% hold on
% semilogy(EbNo,ser1,'-o');
% semilogy(EbNo,ser2,'-o');
%grid on
% semilogy(EbNo,ser3,'-o');

errorPAM = ser(8);
% errorPAM(2) = ser1(8);
% errorPAM(3) = ser2(8);
% errorPAM(4) = ser3(8);

combErr = 0;
errorProb = 0;

for j = 4:4:64
combErr = 0;
for i = 1:1:100

    combTot = 2^(i);

    if i >= j
        combErr = 0;
        for z = j:1:i
            combErr = combErr + 2^(z-j); 
        end
    end
    
    errorProb(j,i) = combErr/combTot;
    if i <= 16
        efficienzaSign(i) = 0;
        efficenzasenzaBitStuffing(i) = 0;
    else
        efficienzaSign(i) = (i-16)/(((1-errorProb(i))*(i+16))+(errorProb(i)*2*(i+16)));  
        efficenzasenzaBitStuffing(i) = (i-16)/(i+16);

    end


end
end


% figure
% plot(efficienzaSign)
% hold
% plot(efficenzasenzaBitStuffing)
% xlabel("Number of data send (without preamble)");
% ylabel("Efficency (meaningfull data / total data)");
% 
% legend('Efficency with bit staffing','Efficency without bit staffing')


% figure
% plot(efficienzaSign)
 figure
 semilogy(errorProb(4,1:100))
 grid on
 hold on
 semilogy(errorProb(8,1:100))
 semilogy(errorProb(12,1:100))
 semilogy(errorProb(16,1:100))
 semilogy(errorProb(20,1:100))
 semilogy(errorProb(24,1:100))
 semilogy(errorProb(28,1:100))
 semilogy(errorProb(32,1:100))
 % semilogy(errorProb(36,1:1000))
 % semilogy(errorProb(40,1:1000))
 % semilogy(errorProb(44,1:1000))
 % semilogy(errorProb(48,1:1000))
 % semilogy(errorProb(52,1:1000))
 % semilogy(errorProb(56,1:1000))
 % semilogy(errorProb(60,1:1000))
 % semilogy(errorProb(64,1:1000))

 ylabel("Probability of finding preamble in data sequence");
 xlabel("Number of data send (without preamble)");
 legend('4 bit preamble','8 bit preamble','12 bit preamble','16 bit preamble','20 bit preamble','24 bit preamble','28 bit preamble', '32 bit preamble')

