SamplingRate=1e6;
fc=2.44e9;

rxPluto = sdrrx('Pluto','RadioID',...
    "usb:0",'CenterFrequency',fc,...
    'GainSource','Manual',...
       'Gain',30,...
       'OutputDataType','single',...
       'BasebandSampleRate',SamplingRate);
   
tic;   
[rxWave,rx_meta]=capture(rxPluto,1e6);
% toc;
% The samples collected are now available in rxWave
beta= 0.5; % Fattore di roll-off del filtro
span = 6; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)

rxfilter = comm.RaisedCosineReceiveFilter( ...
  'Shape','Square root', ...
  'RolloffFactor',beta, ...
  'FilterSpanInSymbols',span, ...
  'InputSamplesPerSymbol',sps, ...
  'DecimationFactor',sps);

rx_signal=rxfilter(rxWave);

%correzione delay tx
%rx_signal= rx_signal((span*sps)+1:end);
t4=[0:1:length(rxWave)-1];
figure;
plot(rxWave);
title('costellazione');
figure;
plot(t4,rxWave);
title('rxWave');
xlabel('t');
figure;
t5=[0:1:length(rx_signal)-1];
plot(t5,rx_signal);
title('rx_signal');
xlabel('t')
rxNorm=abs(rx_signal)/max(abs(rx_signal));
figure;
t6=[0:1:length(rxNorm)-1];
plot(t6,rxNorm);
title('rxNorm');
xlabel('t')
sig_demod=zeros(2000,1);
%trovo il primo valore della sequenza
i=1;
while rxNorm(i)<0.5
    i=i+1;
end
%demodulazione
c=i-1;
for i=1:1:2000; %sappiamo che il nostro segnale è lungo 2000 campioni dopo lo zero padding
    if abs(rxNorm(i+c))>0.5
       sig_demod(i)=1;
    else sig_demod(i)=0;
    end
plot(sig_demod)
end
