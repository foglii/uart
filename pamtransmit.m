SamplingRate=1e6;
fc=2.44e9;
idTX='sn:1044735411960009090038004f371e8d27';
symbol=randi([0,1])
symbols = randi([0, 1], 1000, 1);

symbolsPluto=symbols+symbols*i
sig= pammod(symbols, 2)*(1+i);

Fs = 100000;           % Frequenza di campionamento (Hz)
T_symbol = 1/Fs;      % Tempo di simbolo
rolloff_factor = 0.25; % Fattore di roll-off del filtro

% Design del filtro a coseno rialzato
span = 6; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)
rcosine_filter = rcosdesign(rolloff_factor, span, sps);

% Generazione di un segnale di esempio
tx_signal = upfirdn(sig, rcosine_filter, sps);


txNorm=sig/max(abs(sig));
txPluto = sdrtx('Pluto',...
       'RadioID',idTX,...
       'CenterFrequency',fc,...
       'Gain',-3, ... %must be between -89 and 0
       'BasebandSampleRate',SamplingRate);

transmitRepeat(txPluto,txNorm);
%100k simb per secondo