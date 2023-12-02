SamplingRate=1e6;
fc=2.44e9;
idTX='sn:1044735411960009090038004f371e8d27';
Nsimboli=1000;
symbols=zeros(Nsimboli,1);
symbols(500)=1;
symbols(497)=1;
symbols(750)=1;
%symbols = randi([0, 1], 1000, 1);
sig=pammod(symbols, 2);
sig=(sig+1)/2;
figure(1)
sig=complex(sig);
t=[0:1:length(sig)-1];
plot(t,sig,'o')
title('segnale')
xlabel('t')



% sig= pammod(symbols, 2)*(1+i);
% Design del filtro a coseno rialzato
beta= 0.5; % Fattore di roll-off del filtro
span = 6; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)

txfilter=comm.RaisedCosineTransmitFilter(...
  Shape='Square root', ...
  RolloffFactor=beta, ...
  FilterSpanInSymbols=span, ...
  OutputSamplesPerSymbol=sps)
% gain = 1 è di default


% %normalizzazione per avere a 1 il massimo del filtro 
% b = coeffs(txfilter);
% txfilter.Gain = 1/max(b.Numerator);

% disegno filtro
figure(2);
impz(txfilter.coeffs.Numerator);
%il filtro è visto come una funzione e i punti servono per 
% accedere ai vari campi di essa 

%applico filtro
tx_signal=txfilter([zeros(Nsimboli/2,1);sig;zeros(Nsimboli/2,1)]);
%correzione delay tx
tx_signal= tx_signal((span*sps)+1:end);

t3=[0:1:length(tx_signal)-1];
figure(3)
plot(t3,tx_signal);
axis("normal");


% Fs = 100000;           % Frequenza di campionamento (Hz)
% T_symbol = 1/Fs;      % Tempo di simbolo
% rolloff_factor = 0.25; % Fattore di roll-off del filtro
% 
% % Design del filtro a coseno rialzato
% span = 9; % Lunghezza in simboli del filtro
% sps = 8;  % Campionamenti per simbolo (oversampling factor)
% rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
% figure(2)
% plot(rcosine_filter,'.')
% title('filtro tx')
% 
% % Generazione di un segnale di esempio
% tx_signal = upfirdn(sig, rcosine_filter, sps);
t3=[0:1:length(tx_signal)-1];
figure(3)
plot(t3,tx_signal);
title('segnale tx filtrato');
xlabel('t');


% rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
% rx_signal = upfirdn(tx_signal, rcosine_filter,1,8);
% t4=[0:1:length(rx_signal)-1];
% figure(4)
% plot(t4,rx_signal)
% title('segnale rx filtrato');
% xlabel('t')

txNorm=complex(tx_signal/max(abs(tx_signal)));
txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm);
%100k simb per secondo
