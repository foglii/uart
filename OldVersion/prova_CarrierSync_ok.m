clear all;

fs = 1000;   % Symbol rate (Hz)
sps = 8;      % Samples per symbol
M = 2;       % Modulation order
k = log2(M);  % Bits per symbol
EbNo = 20;    % Eb/No (dB)
span = 20;     % Lunghezza in simboli del filtro
SNR = convertSNR(EbNo,"ebno",BitsPerSymbol=k,SamplesPerSymbol=sps);


%GENERO OFFSET 
phaseFreqOffset = comm.PhaseFrequencyOffset( ...
    'FrequencyOffset',40, ...
    'SampleRate',fs*sps);

%GENERO BLOCCO DI FUNZIONI PER LA SINCRONIZZAZIONE
coarseSync = comm.CoarseFrequencyCompensator( ...
    'Modulation','PAM', ...
    'FrequencyResolution',10, ...
    'SampleRate',fs*sps);

fineSync = comm.CarrierSynchronizer( ...
    'DampingFactor',0.7, ...
    'NormalizedLoopBandwidth',0.005, ...
    'SamplesPerSymbol',sps, ...
    'Modulation','PAM');


%GENERO SEQUENZA DATI E LA MODULO CON M-PAM
data = randi([0 M-1],10000,1);
modSig = pammod(data,M);


% GENERO IL FILTRO DI TRASMISSIONE A COSENO RIALZATO
txfilter=comm.RaisedCosineTransmitFilter(...
  Shape='Square root', ...
  RolloffFactor=0.5, ...
  FilterSpanInSymbols=span, ...
  OutputSamplesPerSymbol=sps)

% NORMALIZZAZIONE PER AVERE L'AMPIEZZA MASSIMA DEL FILTRO AD 1 
b = coeffs(txfilter);
txfilter.Gain = 1/max(b.Numerator);

%APPLICO IL FILTRO DI TRASMISSIONE
txSig=txfilter(modSig);

%PLOT DEL FILTRO
figure(2);
impz(txfilter.coeffs.Numerator);

%APPLICO L'OFFSET AL SEGNALE
freqOffsetSig = phaseFreqOffset(txSig);


%APPLICO DEL RUMORE AWGN AL SEGNALE E OTTENGO IL SEGNALE RICEVUTO
rxSig = awgn(freqOffsetSig,SNR);



%APPLICO LE FUNZIONI DI SINCORNIZZAZIONE
syncCoarse = coarseSync(rxSig);
rxData = fineSync(syncCoarse);


%FILTRO LA SEQUENZA RICEVUTA CON UN FILTRO A COSENO RIALZATO

rxfilter = comm.RaisedCosineReceiveFilter( ...
  'Shape','Square root', ...
  'RolloffFactor',0.5, ...
  'FilterSpanInSymbols',span, ...
  'InputSamplesPerSymbol',sps, ...
  'DecimationFactor',sps);

rxSigFilt=rxfilter(rxData);
rxSigFilt=rxSigFilt./mean(abs(rxSigFilt)); %normalizzazione grezza

constdiagram = comm.ConstellationDiagram( ...
    'ReferenceConstellation',pammod(0:M-1,M), ...
    'SamplesPerSymbol',1, ...
    'SymbolsToDisplaySource','Property', ...
    'SymbolsToDisplay',2000, ...
    'XLimits',[-3 3], ...
    'YLimits',[-3 3]);
constdiagram(rxSigFilt);



figure
plot(real(txSig(1:800)))
hold on
plot(real(rxData(1:800)))



