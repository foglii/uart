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
 plot(abs(rxWave))
 grid on
rolloff_factor = 0.25; % Fattore di roll-off del filtro

% Design del filtro a coseno rialzato
span = 9; % Lunghezza in simboli del filtro
sps = 8;  % Campionamenti per simbolo (oversampling factor)
rcosine_filter = rcosdesign(rolloff_factor, span,sps,'sqrt');
figure(2);
plot(rcosine_filter,'.');
rxWave=double(rxWave)

rcosine_filter = rcosdesign(rolloff_factor, span, sps,'sqrt');
rx_signal = upfirdn(rxWave, rcosine_filter,1,8);

t4=[0:1:1017];
figure(3);
plot(rxWave);

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
