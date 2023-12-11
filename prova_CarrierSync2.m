clear all;

%DEFINIZIONE VARIABILI
span=20;
M=2;
sps=8;
fs = 1000;
lung_sig = 2000;

load cattura_3.mat;


figure(1)
n1 = (0:length(rxWave)-1)/(lung_sig*sps);
plot(n1,rxWave);
title('Segnale Ricevuto')
grid on;
title('Segnale Ricevuto');
xlabel('Numero Trasmissioni');
ylabel('Valori');
axis("padded");



figure(2);
n1 = (0:length(rxWave)-1)/(lung_sig*sps);
plot(n1,abs(rxWave));
grid on;
title('Modulo del Segnale Ricevuto');
xlabel('Numero di Trasmissioni');
ylabel('Valori');
axis("padded");

scatterplot(rxWave);




constdiagram = comm.ConstellationDiagram( ...
    'ReferenceConstellation',pammod(0:M-1,M), ...
    'SamplesPerSymbol',1, ...
    'SymbolsToDisplaySource','Property', ...
    'SymbolsToDisplay',2000, ...
    'XLimits',[-3 3], ...
    'YLimits',[-3 3]);

%GENERO BLOCCO DI FUNZIONI PER LA SINCRONIZZAZIONE
coarseSync = comm.CoarseFrequencyCompensator( ...
    'Modulation','PAM', ...
    'FrequencyResolution',10, ...
    'SampleRate', 1e6*sps);

fineSync = comm.CarrierSynchronizer( ...
    'DampingFactor',0.7, ...
    'NormalizedLoopBandwidth',0.005, ...
    'SamplesPerSymbol',sps, ...
    'Modulation','PAM');


%APPLICO LE FUNZIONI DI SINCORNIZZAZIONE
syncCoarse = coarseSync(rxWave);
rxData = fineSync(syncCoarse);


%FILTRO LA SEQUENZA RICEVUTA CON UN FILTRO A COSENO RIALZATO
rxfilter = comm.RaisedCosineReceiveFilter( ...
  'Shape','Square root', ...
  'RolloffFactor',0.5, ...
  'FilterSpanInSymbols',span, ...
  'InputSamplesPerSymbol',sps, ...
  'DecimationFactor',sps);

rx_signal=rxfilter(rxData);
rx_signal=rx_signal./mean(abs(rx_signal));


figure (4);
t5=[0:1:length(rx_signal)-1];
plot(t5,rx_signal);
title('Segnale Filtrato');
xlabel('')
rxNorm=abs(rx_signal)/max(abs(rx_signal));

%PLOT
constdiagram(rx_signal);