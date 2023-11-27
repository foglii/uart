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
toc;

% The samples collected are now available in rxWave
%% Plots
% this will plot the absolute value of the samples
figure (1)
plot(abs(rxWave));
grid on
%rolloff_factor = 0.25; % Fattore di roll-off del filtro
% 
% % Design del filtro a coseno rialzato span = 9; % Lunghezza in simboli
% del filtro sps = 8;  % Campionamenti per simbolo (oversampling factor)
% rcosine_filter = rcosdesign(rolloff_factor, span,sps,'sqrt'); %
% figure(2); % plot(rcosine_filter,'.'); rxWave=double(rxWave);
% 
% rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt'); rx_signal
% = upfirdn(rxWave, rcosine_filter,1,sps);
rxfilter = comm.RaisedCosineReceiveFilter( ...
  'Shape','Square root', ...
  'RolloffFactor',beta, ...
  'FilterSpanInSymbols',span, ...
  'InputSamplesPerSymbol',sps, ...
  'DecimationFactor',sps);

rx_signal=rxfilter(rxWave); %correggere con rxWave 

%correzione delay tx
%rx_signal= rx_signal((span*sps)+1:end);


t4=[0:1:length(rxWave)-1];
figure(3);
plot(rxWave);
title('segnale ricevuto');
figure(4);
plot(t4,rxWave);
title('segnale ricevuto nel tempo');
xlabel('t');
figure;
t5=[0:1:length(rx_signal)-1];
plot(t5,rx_signal);
title('segnale filtrato');
xlabel('t')
% %correzione ritardo di 9 campioni(dimensione filtro)
% for i=1:length(rx_signal)-(2*span)
%     rx_signal_no_offset(i)=rx_signal(i+span);
% end
%demodulazione
sig_demod=pamdemod(rx_signal_no_offset,2);




%Calculate quantization noise power 
%(assuming constant input)
%Pnoise=10*log10(mean((real(rxWave)...
 %   - mean(real(rxWave))).^2));
%disp("Detected Pnoise:")
% disp(Pnoise)

% Theoretical Pnoise N=12bit ADC
% delta^2 / 12
% delta is D/2^N
% D=2
% Pnt=10*log10(((2/2^12)^2)*(1/12));
% disp("Theoretical Pnoise:")
% disp(Pnt)
