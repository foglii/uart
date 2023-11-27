SamplingRate=1e6; % Frequenza di campionamento (Hz)
T_symbol = 1/SamplingRate;      % Tempo di simbolo
fc=2.44e9;

idTX='sn:1044735411960009090038004f371e8d27';

Nsimboli=1000
symbols=zeros(Nsimboli,1);
symbols(500)=1;
symbols(497)=1;
symbols(750)=1;
%symbols = randi([0, 1], 1000, 1);
segnale= pammod(symbols, 2);

figure(1)
segnale=complex(segnale);
t1=[0:1:length(segnale)-1];
plot(t1,segnale,'o')
segnale=complex(symbols);
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


%normalizzazione per avere a 1 il massimo del filtro 
b = coeffs(txfilter);
txfilter.Gain = 1/max(b.Numerator);

% disegno filtro
figure(2)
impz(txfilter.coeffs.Numerator)
%il filtro è visto come una funzione e i punti servono per 
% accedere ai vari campi di essa 

%applico filtro
tx_segnale=txfilter(segnale);


t3=[0:1:length(tx_segnale)-1]
figure(3)
plot(t3,tx_segnale)



