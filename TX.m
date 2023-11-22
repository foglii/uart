SamplingRate=1e6;
fc=2.44e9;
idTX='sn:1044735411960009090038004f371e8d27';
symbols=zeros(1000,1);
symbols(500)=1;
symbols(497)=1;
symbols(750)=1;
%symbols = randi([0, 1], 1000, 1);
sig= pammod(symbols, 2);
figure(1)
t=[0:1:999];
plot(t,sig,'o')
sig=complex(symbols);

% sig= pammod(symbols, 2)*(1+i);

Fs = 100000;           % Frequenza di campionamento (Hz)
T_symbol = 1/Fs;      % Tempo di simbolo
rolloff_factor = 0.25; % Fattore di roll-off del filtro

% Design del filtro a coseno rialzato
span = 9; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)
rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
figure(2)
plot(rcosine_filter,'.')

% Generazione di un segnale di esempio
tx_signal = upfirdn(sig, rcosine_filter, sps);
t3=[0:1:8064]


rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
rx_signal = upfirdn(tx_signal, rcosine_filter,1,8);
t4=[0:1:1017]
figure(3)
plot(t3,tx_signal)
figure(4)
plot(t4,rx_signal)
%ritardo di 9 campioni(dimensione filtro)
txNorm=complex(tx_signal/max(abs(tx_signal)));
txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm);
%100k simb per secondo