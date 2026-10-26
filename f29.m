%% ========================================================================
%  ELECTRICIDAD AUTOMOTRIZ (MA.03.02) · ISTS · PAO Oct 2026 – Feb 2027
%  UNIDAD 1 · Introducción a la electricidad del automóvil y la batería
%  ------------------------------------------------------------------------
%  Simulaciones:
%   1.1 Ley de Ohm y potencia de una lámpara (filamento frío y caliente)
%   1.2 Circuito serie, paralelo y mixto: reparto de tensiones y corrientes
%   1.3 Caída de tensión en un cable según longitud y sección
%   1.4 Divisor de tensión con sensor NTC (cómo lee la ECU la temperatura)
%   1.5 Circuito RL: corriente de un relé o bobina al conectar y desconectar
%   1.6 Batería: descarga con la ley de Peukert
%   1.7 Batería: tensión en bornes durante el arranque y resistencia interna
%   1.8 Batería: carga en dos etapas (corriente constante – tensión constante)
%   1.9 Batería: estado de carga por tensión en reposo y por densidad
%
%  Uso: cambie los datos de la sección «DATOS» de cada bloque y ejecute el
%  bloque con Ctrl+Enter (Ejecutar sección) o todo el archivo con F5.
%  Compatible con MATLAB R2016b o posterior y con GNU Octave (sin toolboxes).
%  Los valores son orientativos y con fines didácticos.
%  Autor: Ing. Miguel Angel Minga González · Material de la asignatura.
%% ========================================================================
clear; close all; clc;
guardarFiguras = false;      % true = guarda cada figura como PNG en la carpeta actual
guardar = @(nombre) [];      %#ok<NASGU>
if guardarFiguras, guardar = @(nombre) print(gcf, '-dpng', '-r150', [nombre '.png']); end

%% 1.1 Ley de Ohm: lámpara de 12 V – 55 W (H7) y el pico de corriente al encender
% DATOS
U       = 12;        % tensión de alimentación (V)
P       = 55;        % potencia nominal de la lámpara (W)
alfa    = 0.0045;    % coeficiente de temperatura del wolframio (1/°C)
T_frio  = 20;        % temperatura del filamento frío (°C)
% CÁLCULOS
I_nom   = P/U;                       % corriente en funcionamiento (A)
R_cal   = U/I_nom;                   % resistencia en caliente (ohm)
T       = linspace(20,2800,200);     % temperatura del filamento (°C)
R_T     = R_cal ./ (1 + alfa*(2800 - T_frio)) .* (1 + alfa*(T - T_frio)); % aproximación lineal
I_T     = U ./ R_T;
fprintf('\n=== 1.1 Lámpara %g W a %g V ===\n', P, U);
fprintf('Corriente nominal: I = P/U = %.2f A\n', I_nom);
fprintf('Resistencia en caliente: R = U/I = %.2f ohm\n', R_cal);
fprintf('Resistencia en frío (aprox.): %.3f ohm -> pico al encender: %.0f A\n', R_T(1), I_T(1));
figure('Name','1.1 Ley de Ohm en una lámpara','Color','w');
[ax,h1,h2] = plotyy(T, R_T, T, I_T); set([h1;h2],'LineWidth',2);
ylabel(ax(1),'Resistencia del filamento (\Omega)'); ylabel(ax(2),'Corriente (A)');
xlabel('Temperatura del filamento (°C)'); grid on;
title('Lámpara H7: la resistencia sube con la temperatura y la corriente baja');
guardar('U1_1_lampara');

%% 1.2 Circuitos serie, paralelo y mixto
% DATOS
U  = 12;            % tensión (V)
R1 = 1; R2 = 6; R3 = 3;   % resistencias (ohm)
% Serie
Rs = R1+R2+R3; Is = U/Rs; Vs = Is*[R1 R2 R3];
% Paralelo
Rp = 1/(1/R1+1/R2+1/R3); Ip = U./[R1 R2 R3];
% Mixto: R1 en serie con (R2 // R3)
R23 = R2*R3/(R2+R3); Rm = R1+R23; Im = U/Rm; V23 = Im*R23; Im2 = V23/R2; Im3 = V23/R3;
fprintf('\n=== 1.2 Circuitos ===\n');
fprintf('SERIE:    Rt = %.2f ohm, I = %.2f A, V1..V3 = %.2f / %.2f / %.2f V (suma %.2f V)\n', Rs, Is, Vs, sum(Vs));
fprintf('PARALELO: Rt = %.3f ohm, I1..I3 = %.2f / %.2f / %.2f A, It = %.2f A\n', Rp, Ip, sum(Ip));
fprintf('MIXTO:    Rt = %.2f ohm, It = %.2f A, V paralelo = %.2f V, I2 = %.2f A, I3 = %.2f A\n', Rm, Im, V23, Im2, Im3);
figure('Name','1.2 Serie, paralelo y mixto','Color','w');
subplot(1,3,1); bar(Vs); set(gca,'XTickLabel',{'R1','R2','R3'}); ylabel('Tensión (V)'); title(sprintf('Serie: I = %.2f A', Is)); grid on;
subplot(1,3,2); bar(Ip); set(gca,'XTickLabel',{'R1','R2','R3'}); ylabel('Corriente (A)'); title(sprintf('Paralelo: V = %g V', U)); grid on;
subplot(1,3,3); bar([Im Im2 Im3]); set(gca,'XTickLabel',{'I total','I(R2)','I(R3)'}); ylabel('Corriente (A)'); title('Mixto'); grid on;
guardar('U1_2_circuitos');

%% 1.3 Caída de tensión en un cable
% DATOS
I     = 10;                 % corriente del consumidor (A)
rho   = 0.0178;             % resistividad del cobre (ohm·mm²/m)
Lmax  = 8;                  % longitud máxima a representar (m)
S     = [0.75 1 1.5 2.5 4]; % secciones normalizadas (mm²)
dUadm = 0.03*12;            % caída admisible: 3 % de 12 V
L = linspace(0, Lmax, 100);
figure('Name','1.3 Caída de tensión en cables','Color','w'); hold on;
for k = 1:numel(S)
    plot(L, rho*L*I/S(k), 'LineWidth', 2, 'DisplayName', sprintf('%.2f mm²', S(k)));
end
plot(L, dUadm*ones(size(L)), 'k--', 'LineWidth', 1.5, 'DisplayName', 'Límite 3 %');
xlabel('Longitud del cable (m)'); ylabel('Caída de tensión (V)'); grid on; legend('Location','northwest');
title(sprintf('Caída de tensión con I = %g A', I));
Smin = rho*Lmax*I/dUadm;
fprintf('\n=== 1.3 Caída de tensión ===\nCon %g m y %g A la sección mínima es %.2f mm²\n', Lmax, I, Smin);
guardar('U1_3_caida_cable');

%% 1.4 Divisor de tensión con NTC (sensor de temperatura del refrigerante)
% DATOS
Vref = 5;          % referencia de la ECU (V)
Rfij = 2200;       % resistencia fija interna de la ECU (ohm)
R25  = 2500;       % resistencia de la NTC a 25 °C (ohm)
B    = 3500;       % constante beta de la NTC (K)
Tc = -20:1:120;  TK = Tc + 273.15;
Rntc = R25 .* exp(B .* (1./TK - 1/298.15));
Vs = Vref .* Rntc ./ (Rntc + Rfij);
figure('Name','1.4 Sensor NTC','Color','w');
subplot(1,2,1); semilogy(Tc, Rntc, 'LineWidth', 2); grid on; xlabel('Temperatura (°C)'); ylabel('R NTC (\Omega)'); title('Resistencia de la NTC');
subplot(1,2,2); plot(Tc, Vs, 'LineWidth', 2); grid on; xlabel('Temperatura (°C)'); ylabel('Tensión de señal (V)'); title('Tensión que lee la ECU');
fprintf('\n=== 1.4 NTC ===\n'); for t = [20 60 90]
    i = find(Tc==t); fprintf('%3d °C: R = %6.0f ohm, señal = %.2f V\n', t, Rntc(i), Vs(i)); end
guardar('U1_4_NTC');

%% 1.5 Circuito RL: corriente en la bobina de un relé (conexión y desconexión)
% DATOS
U = 12; R = 80; L = 0.2;     % relé típico: 80 ohm y 0,2 H
tON = 0.02;                  % tiempo conectado (s)
tau = L/R; t = linspace(0, 3*tON, 600);
i = zeros(size(t)); Ion = U/R*(1-exp(-tON/tau));
i(t<=tON) = U/R*(1-exp(-t(t<=tON)/tau));
i(t>tON)  = Ion*exp(-(t(t>tON)-tON)/(tau/50));    % al abrir, la corriente cae muy rápido (diodo/supresor)
fprintf('\n=== 1.5 Relé ===\nConstante de tiempo tau = L/R = %.2f ms; corriente final %.0f mA\n', tau*1000, U/R*1000);
fprintf('Sin diodo, la f.e.m. de autoinducción al abrir sería U = L·di/dt: varios cientos de voltios.\n');
figure('Name','1.5 Circuito RL','Color','w'); plot(t*1000, i*1000, 'LineWidth', 2); grid on;
xlabel('Tiempo (ms)'); ylabel('Corriente (mA)'); title(sprintf('Bobina de relé: \\tau = %.1f ms', tau*1000));
guardar('U1_5_RL');

%% 1.6 Descarga de la batería: ley de Peukert
% DATOS
C20 = 60;          % capacidad nominal (Ah)
k   = 1.25;        % exponente de Peukert (1,1 – 1,3)
I = logspace(0, log10(300), 60);       % corrientes de 1 a 300 A
t = 20*(C20./(20*I)).^k;               % horas hasta 10,5 V
Cap = I.*t;
figure('Name','1.6 Peukert','Color','w');
subplot(1,2,1); loglog(I, t, 'LineWidth', 2); grid on; xlabel('Corriente (A)'); ylabel('Tiempo hasta 10,5 V (h)'); title('Autonomía');
subplot(1,2,2); semilogx(I, Cap, 'LineWidth', 2); grid on; xlabel('Corriente (A)'); ylabel('Capacidad aprovechable (Ah)'); title(sprintf('C_{20} = %g Ah, k = %.2f', C20, k));
fprintf('\n=== 1.6 Peukert ===\nA 3 A: %.1f h; a 50 A: %.0f min; a 200 A: %.1f min\n', ...
        20*(C20/60)^k, 60*20*(C20/1000)^k, 60*20*(C20/4000)^k);
guardar('U1_6_Peukert');

%% 1.7 Tensión en bornes durante el arranque
% DATOS
E0 = 12.6;                      % tensión en vacío (V)
Ri = [0.005 0.010 0.020 0.040]; % resistencias internas a comparar (ohm): nueva → agotada
I  = 0:5:400;
figure('Name','1.7 Arranque','Color','w'); hold on;
for r = Ri, plot(I, E0 - I*r, 'LineWidth', 2, 'DisplayName', sprintf('Ri = %.0f m\\Omega', r*1000)); end
plot(I, 9.6*ones(size(I)), 'k--', 'LineWidth', 1.5, 'DisplayName', 'Mínimo 9,6 V');
grid on; xlabel('Corriente de arranque (A)'); ylabel('Tensión en bornes (V)'); legend('Location','southwest');
title('U = E_0 − I·R_i: la batería agotada no sostiene la tensión');
guardar('U1_7_arranque');

%% 1.8 Carga en dos etapas: corriente constante y tensión constante (CC–CV)
% DATOS
C   = 60;          % capacidad (Ah)
SOC0 = 0.30;       % estado de carga inicial
Ic  = 0.1*C;       % corriente de carga en la etapa CC (A)
Vcv = 14.4;        % tensión de la etapa CV (V)
Rint = 0.02;       % resistencia interna en carga (ohm)
dt = 1/60;         % paso de 1 minuto (h)
ocv = @(s) 11.9 + 0.8*s + 0.9*max(0,s-0.8).^2*5;     % tensión de reposo aproximada
SOC = SOC0; tt = 0; Ib = []; Vb = []; S = []; T = [];
while SOC < 0.995 && tt < 24
    V_cc = ocv(SOC) + Ic*Rint;
    if V_cc < Vcv, I = Ic; V = V_cc; else, I = max((Vcv - ocv(SOC))/Rint, 0.2); V = Vcv; end
    SOC = min(1, SOC + 0.9*I*dt/C);   % rendimiento de carga 0,9
    Ib(end+1) = I; Vb(end+1) = V; S(end+1) = SOC; T(end+1) = tt; tt = tt + dt; %#ok<SAGROW>
end
figure('Name','1.8 Carga CC-CV','Color','w');
subplot(2,1,1); [ax,h1,h2] = plotyy(T, Ib, T, Vb); set([h1;h2],'LineWidth',2);
ylabel(ax(1),'Corriente (A)'); ylabel(ax(2),'Tensión (V)'); grid on; title('Carga en dos etapas: CC y luego CV');
subplot(2,1,2); plot(T, S*100, 'LineWidth', 2); grid on; xlabel('Tiempo (h)'); ylabel('Estado de carga (%)');
fprintf('\n=== 1.8 Carga CC-CV ===\nDel %.0f %% al 99 %% en %.1f h (I = %.1f A, CV = %.1f V)\n', SOC0*100, tt, Ic, Vcv);
guardar('U1_8_carga');

%% 1.9 Estado de carga por tensión en reposo y por densidad
% DATOS
V_medida = 12.40;     % tensión en reposo medida (V)
d_medida = 1.215;     % densidad leída (g/cm³)
T_electr = 35;        % temperatura del electrolito (°C)
d25  = d_medida + 0.0007*(T_electr - 25);           % corrección a 25 °C
SOCd = (d25 - 1.12)/0.16*100;
SOCv = (V_medida - 11.9)/(12.7-11.9)*100;
fprintf('\n=== 1.9 Estado de carga ===\nPor tensión: %.0f %%; por densidad corregida (%.3f): %.0f %%\n', SOCv, d25, SOCd);
s = 0:100; figure('Name','1.9 Estado de carga','Color','w');
subplot(1,2,1); plot(s, 11.9+0.008*s, 'LineWidth', 2); hold on; plot(SOCv, V_medida, 'ro', 'MarkerSize', 9, 'LineWidth', 2);
grid on; xlabel('Estado de carga (%)'); ylabel('Tensión en reposo (V)'); title('Tensión en reposo');
subplot(1,2,2); plot(s, 1.12+0.0016*s, 'LineWidth', 2); hold on; plot(SOCd, d25, 'ro', 'MarkerSize', 9, 'LineWidth', 2);
grid on; xlabel('Estado de carga (%)'); ylabel('Densidad a 25 °C (g/cm³)'); title('Densidad del electrolito');
guardar('U1_9_SOC');
