%% ========================================================================
%  ELECTRICIDAD AUTOMOTRIZ (MA.03.02) · ISTS · PAO Oct 2026 – Feb 2027
%  UNIDAD 3 · Sistemas de encendido
%  ------------------------------------------------------------------------
%   3.1 Carga de la bobina: corriente del primario y energía (circuito RL)
%   3.2 Ruptor frente a encendido electrónico: corriente y energía según rpm
%   3.3 Ángulo de cierre (dwell) y tiempo de cierre según cilindros y rpm
%   3.4 Oscilograma simulado del secundario y del primario (circuito RLC)
%   3.5 Efecto del condensador del ruptor (con y sin condensador)
%   3.6 Señal del generador inductivo y del generador Hall según las rpm
%   3.7 Avance del encendido: centrífugo, por vacío y total
%   3.8 Tensión disponible frente a tensión necesaria (reserva de encendido)
%   3.9 Chispa perdida (DIS): reparto de tensión entre los dos cilindros
%  Compatible con MATLAB R2016b+ y GNU Octave. Valores orientativos.
%% ========================================================================
clear; close all; clc;
guardarFiguras = false; guardar = @(n) [];
if guardarFiguras, guardar = @(n) print(gcf,'-dpng','-r150',[n '.png']); end

%% 3.1 Carga de la bobina
% DATOS (bobina convencional y bobina electrónica de baja resistencia)
U = 13.5;
bob(1).nombre = 'Convencional (3 Ω, 8 mH)';   bob(1).R = 3.0; bob(1).L = 8e-3;
bob(2).nombre = 'Electrónica (0,6 Ω, 4 mH)';  bob(2).R = 0.6; bob(2).L = 4e-3;
t = linspace(0, 15e-3, 500);
figure('Name','3.1 Carga de la bobina','Color','w');
fprintf('\n=== 3.1 Carga de la bobina ===\n');
for k = 1:2
    tau = bob(k).L/bob(k).R; If = U/bob(k).R; i = If*(1-exp(-t/tau)); W = 0.5*bob(k).L*i.^2*1000;
    subplot(1,2,1); hold on; plot(t*1000, i, 'LineWidth', 2);
    subplot(1,2,2); hold on; plot(t*1000, W, 'LineWidth', 2);
    fprintf('%-28s tau = %.2f ms, I final = %.1f A, al 95 %% en %.1f ms, W máx = %.0f mJ\n', bob(k).nombre, tau*1000, If, 3*tau*1000, 0.5*bob(k).L*If^2*1000);
end
subplot(1,2,1); grid on; xlabel('Tiempo de cierre (ms)'); ylabel('Corriente del primario (A)'); legend(bob(1).nombre, bob(2).nombre, 'Location','southeast'); title('i(t) = (U/R)(1 − e^{−t/τ})');
subplot(1,2,2); grid on; xlabel('Tiempo de cierre (ms)'); ylabel('Energía (mJ)'); title('W = ½·L·i²');
guardar('U3_1_carga_bobina');
% Nota: la bobina electrónica alcanzaría 22 A; la etapa de potencia limita la corriente a 6–8 A.

%% 3.2 Ruptor (dwell fijo) frente a electrónico (tiempo de carga regulado)
z = 4; dwell = 0.60;          % 4 cilindros, 60 % de cierre
t_reg = 3.5e-3; Ilim = 7.5;   % electrónico: 3,5 ms de carga y limitación de corriente
rpm = 500:100:7000;
T = 120./(z*rpm);                         % periodo entre chispas (s)
tr = dwell*T;  te = min(t_reg, 0.9*T);
ir = U/bob(1).R*(1-exp(-tr/(bob(1).L/bob(1).R)));
ie = min(Ilim, U/bob(2).R*(1-exp(-te/(bob(2).L/bob(2).R))));
Wr = 0.5*bob(1).L*ir.^2*1000; We = 0.5*bob(2).L*ie.^2*1000;
figure('Name','3.2 Ruptor vs electrónico','Color','w');
subplot(1,2,1); plot(rpm, ir, rpm, ie, 'LineWidth', 2); grid on; xlabel('rpm'); ylabel('Corriente al abrir (A)'); legend('Ruptor','Electrónico'); title('Corriente de corte');
subplot(1,2,2); plot(rpm, Wr, rpm, We, 'LineWidth', 2); grid on; xlabel('rpm'); ylabel('Energía (mJ)'); legend('Ruptor','Electrónico'); title('Energía disponible para la chispa');
fprintf('\n=== 3.2 A 6000 rpm: ruptor %.1f A / %.0f mJ; electrónico %.1f A / %.0f mJ ===\n', interp1(rpm,ir,6000), interp1(rpm,Wr,6000), interp1(rpm,ie,6000), interp1(rpm,We,6000));
guardar('U3_2_ruptor_vs_electronico');

%% 3.3 Ángulo y tiempo de cierre según el número de cilindros
cil = [4 6 8]; rpm = 500:100:7000;
figure('Name','3.3 Tiempo de cierre','Color','w'); hold on;
fprintf('\n=== 3.3 Ángulo de cierre (60 %%) ===\n');
for z = cil
    ang = 360/z; tc = dwell*120./(z*rpm)*1000;
    plot(rpm, tc, 'LineWidth', 2, 'DisplayName', sprintf('%d cilindros (%.0f° de leva, cierre %.0f°)', z, ang, ang*dwell));
    fprintf('%d cilindros: ángulo disponible %.0f°, cierre %.0f°, a 3000 rpm t = %.2f ms\n', z, ang, ang*dwell, dwell*120/(z*3000)*1000);
end
plot(rpm, 3*bob(1).L/bob(1).R*1000*ones(size(rpm)), 'k--', 'DisplayName', 'Tiempo para cargar al 95 % (3τ)');
grid on; xlabel('rpm'); ylabel('Tiempo de cierre (ms)'); legend; title('A más cilindros y más rpm, menos tiempo para cargar la bobina');
guardar('U3_3_tiempo_cierre');

%% 3.4 Oscilograma simulado (secundario y primario)
% Modelo por fases: aguja de encendido, línea de chispa, oscilaciones amortiguadas y cierre
Uenc = 12e3;    % tensión de encendido (V) – depende de la bujía, la separación y la mezcla
Uch  = 1.5e3;   % tensión de la línea de chispa (V)
tch  = 1.5e-3;  % duración de la chispa (s)
f_os = 5e3;     % frecuencia de las oscilaciones amortiguadas (Hz)
N1N2 = 100;     % relación de transformación
t = linspace(-0.5e-3, 6e-3, 4000); us = zeros(size(t)); up = 13.5*ones(size(t));
a = t>=0 & t<0.03e-3;  us(a) = Uenc*(t(a)/0.03e-3);                         % subida a la aguja
b = t>=0.03e-3 & t<tch; us(b) = Uch + 300*sin(2*pi*20e3*t(b)).*exp(-t(b)/2e-4); % línea de chispa
c = t>=tch & t<tch+2e-3; tc_ = t(c)-tch; us(c) = 3e3*exp(-tc_/4e-4).*cos(2*pi*f_os*tc_); % oscilaciones
d = t>=4.5e-3; us(d) = -1.2e3*exp(-(t(d)-4.5e-3)/1e-4).*cos(2*pi*10e3*(t(d)-4.5e-3)); % cierre del primario
up(t<0) = 1.0;                         % primario conduciendo (V CE ≈ 1 V)
up(a|b) = 13.5 + us(a|b)/N1N2;          % reflejo de la tensión secundaria
up(c) = 13.5 + us(c)/N1N2*0.8;          up(d) = 1.0;
figure('Name','3.4 Oscilogramas','Color','w');
subplot(2,1,1); plot(t*1000, us/1000, 'LineWidth', 1.5); grid on; ylabel('Secundario (kV)');
title('Secundario: aguja de encendido, línea de chispa, oscilaciones y cierre');
text(0.1, Uenc/1000*0.95, ' Aguja de encendido'); text(0.5, Uch/1000+1.2, 'Línea de chispa'); text(tch*1000+0.2, 3.5, 'Oscilaciones');
subplot(2,1,2); plot(t*1000, up, 'LineWidth', 1.5); grid on; ylabel('Primario (V)'); xlabel('Tiempo (ms)');
title(sprintf('Primario (≈ secundario / %d): pico de unos %.0f V', N1N2, 13.5+Uenc/N1N2));
guardar('U3_4_oscilogramas');

%% 3.5 Efecto del condensador del ruptor
% Sin condensador, la tensión de autoinducción salta entre los platinos (arco) y corta la corriente lentamente.
Lp = 8e-3; Rp = 3; I0 = 3.5; Cs = 0.2e-6;          % condensador de 0,2 µF
t = linspace(0, 0.4e-3, 2000);
figure('Name','3.5 Condensador','Color','w'); hold on;
C = Cs(1); a = Rp/(2*Lp); w0 = 1/sqrt(Lp*C); wd = sqrt(w0^2-a^2);
v_con = I0/(C*wd)*exp(-a*t).*sin(wd*t);                 % oscilación LC amortiguada
v_sin = 400*(1-exp(-t/5e-6)).*(t < 0.25e-3);            % arco entre platinos (≈ 400 V) hasta extinguirse
plot(t*1e3, v_con, t*1e3, v_sin, 'LineWidth', 2);
legend('Con condensador 0,2 µF: corte rápido y pico alto','Sin condensador: arco ≈ 400 V, platinos quemados','Location','southeast');
grid on; xlabel('Tiempo tras abrir (ms)'); ylabel('Tensión en el primario (V)'); title('El condensador absorbe la autoinducción y protege los platinos');
fprintf('\n=== 3.5 Pico con condensador: %.0f V (f = %.1f kHz) ===\n', I0*sqrt(Lp/0.2e-6), 1/(2*pi*sqrt(Lp*0.2e-6))/1000);
guardar('U3_5_condensador');

%% 3.6 Señal del generador inductivo y del Hall
z = 4; rpm_list = [300 1000 3000];
figure('Name','3.6 Generadores de impulsos','Color','w');
for k = 1:numel(rpm_list)
    r = rpm_list(k); f = z/2*r/60;               % impulsos por segundo (distribuidor: z/2 por vuelta del cigüeñal)
    t = linspace(0, 2/f, 2000);
    Ui = 0.4*r/1000*30*sin(2*pi*f*t).*abs(sin(pi*f*t)).^4;   % amplitud ∝ velocidad (inducción)
    Uh = 12*(mod(t*f,1) < 0.7);                              % Hall: 70 % pantalla, amplitud constante
    subplot(2,1,1); hold on; plot(t*1000*f/2, Ui, 'LineWidth', 1.5);
    subplot(2,1,2); hold on; plot(t*1000*f/2, Uh + (k-1)*0.15, 'LineWidth', 1.5);
    fprintf('%4d rpm: f = %.1f Hz, inductivo pico ≈ %.1f V, Hall 12 V\n', r, f, max(Ui));
end
subplot(2,1,1); grid on; ylabel('Inductivo (V)'); legend('300 rpm','1000 rpm','3000 rpm'); title('Inductivo: la amplitud y la frecuencia crecen con las rpm (eje de tiempo normalizado)');
subplot(2,1,2); grid on; ylabel('Hall (V)'); xlabel('Fracción del periodo'); title('Hall: señal cuadrada de amplitud constante, incluso a muy bajas rpm'); ylim([-1 13]);
guardar('U3_6_generadores');

%% 3.7 Avance del encendido
rpm = 0:100:6000; vac = 0:10:600;   % depresión del colector (mbar)
av_ini = 8;                          % avance inicial (° de cigüeñal)
av_cent = min(24, max(0, (rpm-1000)*24/2800));  av_cent(rpm>=3800) = 24 + (rpm(rpm>=3800)-3800)*2/2200;
av_vac  = min(10, max(0, (vac-150)*10/250));
figure('Name','3.7 Avance','Color','w');
subplot(1,2,1); plot(rpm, av_ini+av_cent, 'LineWidth', 2); grid on; xlabel('rpm'); ylabel('Avance (° APMS)'); title('Inicial + centrífugo');
subplot(1,2,2); plot(vac, av_vac, 'LineWidth', 2); grid on; xlabel('Depresión (mbar)'); ylabel('Avance por vacío (°)'); title('Por vacío (carga parcial)');
% ¿Por qué hace falta? Ángulo que gira el cigüeñal durante 2 ms de combustión
fprintf('\n=== 3.7 Ángulo recorrido en 2 ms: 1000 rpm %.0f°, 4000 rpm %.0f° ===\n', 6*1000*2e-3, 6*4000*2e-3);
guardar('U3_7_avance');

%% 3.8 Tensión disponible frente a tensión necesaria
rpm = 500:100:7000;
Udisp_r = 9 + 17*(Wr/max(Wr));                 % ruptor: proporcional a la energía (kV)
Udisp_e = 9 + 23*(We/max(We));                 % electrónico
gap = [0.7 1.0 1.3];                           % separación de electrodos (mm)
figure('Name','3.8 Reserva de encendido','Color','w'); hold on;
plot(500:100:7000, Udisp_r, 'LineWidth', 2, 'DisplayName', 'Disponible ruptor');
plot(500:100:7000, Udisp_e, 'LineWidth', 2, 'DisplayName', 'Disponible electrónico');
for g = gap
    Unec = 6 + 8*g + 3*(rpm/7000);              % aumenta con la separación y la presión de compresión
    plot(rpm, Unec, '--', 'LineWidth', 1.5, 'DisplayName', sprintf('Necesaria (%.1f mm)', g));
end
grid on; xlabel('rpm'); ylabel('Tensión (kV)'); legend('Location','southwest'); title('Si la necesaria supera a la disponible, la chispa falla');
guardar('U3_8_reserva');

%% 3.9 Chispa perdida (DIS)
Ut = 15;                      % tensión que genera la bobina doble (kV)
Ucomp = 12; Uesc = 1.5;       % tensión necesaria en compresión y en escape (kV)
figure('Name','3.9 Chispa perdida','Color','w');
bar([Ucomp Uesc; Ut-Ucomp-Uesc 0]', 'stacked'); set(gca,'XTickLabel',{'Cilindro en compresión','Cilindro en escape'});
ylabel('kV'); legend('Tensión consumida','Reserva'); grid on; title(sprintf('Las dos bujías en serie: %.1f + %.1f kV de %.0f kV', Ucomp, Uesc, Ut));
fprintf('\n=== 3.9 DIS: reserva %.1f kV; la chispa de escape consume solo %.0f %% ===\n', Ut-Ucomp-Uesc, Uesc/(Ucomp+Uesc)*100);
guardar('U3_9_DIS');
