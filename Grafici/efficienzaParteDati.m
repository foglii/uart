close all
clear

p_bit = 0.005;                   %Bit error rate

efficenza = 0;
valoreAtteso =  0;

for n = 1:1:200                  %Byte della sequenza dati

    p_frame = (1-p_bit).^(n*8 + 40);  %Probabilita' di ottenere un pacchetto corretto
    valoreAtteso = 1/p_frame;    %Numero di ritrasmissioni prima di ottenere un pacchetto corretto
    efficenza(n) = n / ((n + 5) * valoreAtteso); 

end

figure
plot(efficenza);
xlabel("Numero di byte della sequenza dati")
ylabel("Efficienza")
grid on