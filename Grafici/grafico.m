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
[ber,ser1] = berawgn(EbNo,'pam',4);
[ber,ser2] = berawgn(EbNo,'pam',8);
[ber,ser3] = berawgn(EbNo,'pam',16);
ylabel('Symbol Error Rate');



figure(3);
semilogy(EbNo,ser);
hold on
semilogy(EbNo,ser1);
semilogy(EbNo,ser2);
grid on
semilogy(EbNo,ser3);

errorPAM = []
errorPAM(1) = ser(7);
errorPAM(2) = ser1(7);
errorPAM(3) = ser2(7);
errorPAM(4) = ser3(7);

numberA = [];
numberA(1) = 2;
numberA(2) = 4;
numberA(3) = 8;
numberA(4) = 16;



posErr = 0;
for i = 0 : 1:16
    posErr = posErr + 2.^i;
end

probError = posErr./ 2.^16




med = @(x) (1 - dataError(x,8)) .* (2 .* x + 9) + 2 .* (2*x+9) .* (dataError(x,8)) ./ 8;

bitMediN = @(a,b) ((1-(2.^(1 - a) - 2.^(1 - b))).*(2 .* a + b + 1) + ((2.^(1-a)-2.^(1 - b))).* 2 .*(2.*a + b + 1))./ b;

bitMedi16 = @(a) ((1-(2.^(1 - a)- 2.^(1 - 16))) .* (2 .* a + 17) + ((2.^(1 - a)- 2 .^(1-16))).*2.*(2 .* a + 17))./ 16;

bitMedi8 = @(a) ((1-(2.^(1 - a) - 2.^(1- 8))).*(2 .* a +9) + ((2.^(1-a)-2.^(1 - 8))).* 2 .*(2.*a + 9))./ 8;

error1 = @(M,x) ((errorPAM(M)./log2(numberA(M))).*(2 .* x +9).*2.*bitMedi8(x)) + (1 - ((errorPAM(M)./log2(numberA(M))).*(2 .* x + 9)).*bitMedi8(x));
error2 = @(M,x) (1./((1- (errorPAM(2)./log2(numberA(2)))).^(2 .* x + M + 1))).*bitMediN(x,M);


x = 1:10:10000; 
y = 1:10:10000;
[X, Y] = meshgrid(x, y);

figure(7)
mesh(X,Y,bitMediN(X,Y));
xlabel("numero bit start_seq/end_seq ");
ylabel("numero bit data");

x = 1:1:20; 
y = 1:1:56;

[X, Y] = meshgrid(x, y);
 figure(6);
 mesh(X,Y,error2(X,Y));
ylabel("numero bit start_seq/end_seq ");
xlabel("numero bit data");

% 
% figure(1);
%  mesh(X,Y,error1(X,Y));
%  % set(gca,'ZScale','log')

figure(2);
fplot(bitMedi8,[0 25]);
hold on
fplot(bitMedi16,[0 25]);
hold off
grid on
ylim([0 8]);
xlim([0,22]);




% sigma=sqrt(Es/(2*EsNo));
% 
% theoreticalSER = 0.75*erfc(sqrt(0.2*(EsNo)));
% 
% error(2)


% function c = error(x)
% 
%     c =  (2 .*(x-1) ./ x) .* cdf(1/(2.*10^(-13)))
% 
% end

    


