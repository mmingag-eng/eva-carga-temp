%% ========================================================================
%  ELECTRICIDAD AUTOMOTRIZ (MA.03.02) · ISTS · PAO Oct 2026 – Feb 2027
%  UNIDAD 4 · Circuitos eléctricos auxiliares
%  ------------------------------------------------------------------------
%   4.1 Dimensionado de un circuito de alumbrado: corriente, sección y fusible
%   4.2 Tensión en la lámpara y flujo luminoso (por qué importa la caída de tensión)
%   4.3 Relé de intermitencia: destellos, lámpara fundida y lámparas LED
%   4.4 Regulación de faros: altura de la línea de corte según la inclinación
%   4.5 Iluminancia del haz (ley inversa del cuadrado)
%   4.6 Reloj de bobinas cruzadas: ángulo de la aguja según el aforador
%   4.7 Indicador de temperatura con NTC y termocontacto
%   4.8 Motor del limpiaparabrisas: velocidad lenta y rápida (tercera escobilla)
%   4.9 Luneta térmica: corriente y efecto de un hilo cortado
%   4.10 Consumo en reposo y días hasta que la batería no arranca
%  Compatible con MATLAB R2016b+ y GNU Octave. Valores orientativos.
%% ========================================================================
clear; close all; clc;
guardarFiguras = false; guardar = @(n) [];
if guardarFiguras, guardar = @(n) print(gcf,'-dpng','-r150',[n '.png']); end

%% 4.1 Dimensionado de un circuito de alumbrado
% DATOS
P = 55; nL = 2; U = 12; L = 3; dU = 0.03; rho = 0.0178;
S_norm = [0.5 0.75 1 1.5 2.5 4 6 10]; I_adm = [8 10 13 16 23 30 38 53];
F_norm = [3 5 7.5 10 15 20 25 30 40];
I = P*nL/U; Smin = rho*L*I/(dU*U);
S = S_norm(find(S_norm >= Smin, 1)); Ia = I_adm(S_norm == S);
F = F_norm(find(F_norm >= 1.25*I, 1));
dUr = rho*L*I/S;
msg41 = {'AUMENTE LA SECCIÓN.', 'El fusible protege el cable.'};
fprintf('\n=== 4.1 Circuito %d × %g W ===\nI = %.2f A; S mín = %.2f mm² -> %.2f mm² (admite %d A)\n', nL, P, I, Smin, S, Ia);
fprintf('Fusible ≥ 1,25·I = %.1f A -> %g A; caída real %.3f V (%.1f %%). %s\n', 1.25*I, F, dUr, dUr/U*100, ...
        msg41{(F <= Ia)+1});
Lv = 0:0.1:8; figure('Name','4.1 Dimensionado','Color','w'); hold on;
for s = S_norm(3:6), plot(Lv, rho*Lv*I/s, 'LineWidth', 2, 'DisplayName', sprintf('%.1f mm²', s)); end
plot(Lv, dU*U*ones(size(Lv)), 'k--', 'DisplayName', 'Caída admisible'); grid on; legend('Location','northwest');
xlabel('Longitud (m)'); ylabel('Caída de tensión (V)'); title(sprintf('Circuito de %.1f A', I));
guardar('U4_1_dimensionado');

%% 4.2 Tensión en la lámpara y flujo luminoso
% El flujo de una lámpara halógena varía aproximadamente con U^3,4; su vida, con U^−13.
Unom = 13.2; phi_nom = 1500;  % H7: 1500 lm a 13,2 V
Ul = 10.5:0.05:14.5; phi = phi_nom*(Ul/Unom).^3.4; vida = (Ul/Unom).^(-13);
figure('Name','4.2 Flujo luminoso','Color','w');
[ax,h1,h2] = plotyy(Ul, phi, Ul, vida*100); set([h1;h2],'LineWidth',2);
ylabel(ax(1),'Flujo luminoso (lm)'); ylabel(ax(2),'Vida relativa (%)'); xlabel('Tensión en la lámpara (V)'); grid on;
title('Una caída de 1 V en el cable quita alrededor de un 25 % de luz');
fprintf('\n=== 4.2 Con 12,0 V en la lámpara: %.0f lm (%.0f %% del nominal) ===\n', phi_nom*(12/Unom)^3.4, (12/Unom)^3.4*100);
guardar('U4_2_flujo');

%% 4.3 Relé de intermitencia
% DATOS
f_nom = 90/60;          % 90 destellos por minuto (INEN 1155: 90 ± 30)
P_lamp = [21 21 5];     % delantera, trasera, lateral (W)
I_umbral = 3.0;         % umbral del relé (A): por debajo duplica la frecuencia
casos = {'Normal', P_lamp; 'Trasera fundida', [21 0 5]; 'LED sin relé adaptado', [3 3 1]};
t = linspace(0, 4, 4000);
figure('Name','4.3 Intermitencia','Color','w');
fprintf('\n=== 4.3 Intermitencia ===\n');
for k = 1:size(casos,1)
    Ik = sum(casos{k,2})/12; f = f_nom*(1 + (Ik < I_umbral));
    s = Ik*(mod(t*f,1) < 0.5);
    subplot(3,1,k); plot(t, s, 'LineWidth', 1.5); grid on; ylim([0 4.5]); ylabel('I (A)');
    title(sprintf('%s: I = %.2f A, %.0f destellos/min', casos{k,1}, Ik, f*60));
    fprintf('%-22s I = %.2f A -> %.0f destellos/min\n', casos{k,1}, Ik, f*60);
end
xlabel('Tiempo (s)'); guardar('U4_3_intermitencia');

%% 4.4 Regulación de faros
% DATOS
h_faro = 700;            % altura del centro del faro (mm)
dist   = 10;             % distancia a la pantalla (m)
incl   = 0:0.1:3;        % inclinación hacia abajo (%)
h_corte = h_faro - dist*1000*incl/100;
alcance = h_faro/1000 ./ max(incl/100, 1e-3);      % distancia a la que el haz toca el suelo (m)
figure('Name','4.4 Regulación de faros','Color','w');
subplot(1,2,1); plot(incl, h_corte, 'LineWidth', 2); grid on; xlabel('Inclinación (%)'); ylabel('Altura del corte a 10 m (mm)');
hold on; plot([1 1],[0 h_faro],'k--', [2.5 2.5],[0 h_faro],'r--'); legend('Corte','−1 % (didáctico)','−2,5 % (INEN 1155)'); title('Altura de la línea de corte');
subplot(1,2,2); plot(incl(incl>=0.5), alcance(incl>=0.5), 'LineWidth', 2); grid on; xlabel('Inclinación (%)'); ylabel('Alcance del haz (m)'); title('A menor inclinación, más alcance y más deslumbramiento');
fprintf('\n=== 4.4 Faro a %d mm: −1 %% -> corte a %.0f mm (alcance %.0f m); −2,5 %% -> %.0f mm (%.0f m) ===\n', ...
        h_faro, h_faro-dist*10, h_faro/10, h_faro-dist*25, h_faro/25);
guardar('U4_4_faros');

%% 4.5 Iluminancia del haz
I_cd = [20000 40000 80000];   % intensidad luminosa (cd): cruce, carretera halógena, carretera LED
d = 5:1:250;
figure('Name','4.5 Iluminancia','Color','w');
loglog(d, (I_cd') ./ (d.^2), 'LineWidth', 2); grid on; hold on; plot(d, ones(size(d)), 'k--');
xlabel('Distancia (m)'); ylabel('Iluminancia (lx)'); legend('20 000 cd','40 000 cd','80 000 cd','1 lx (luz útil)');
title('E = I / d²');
fprintf('\n=== 4.5 Alcance con 1 lx: %s m ===\n', mat2str(round(sqrt(I_cd))));
guardar('U4_5_iluminancia');

%% 4.6 Reloj de bobinas cruzadas (indicador de combustible)
% B1 fija y B2 en serie con el aforador, en ángulo de 90°. La aguja sigue al campo resultante.
U = 12; RB1 = 60; RB2 = 60; Rv = 0:1:240;     % aforador: 240 ohm vacío … 0 ohm lleno (orientativo)
I1 = U/RB1*ones(size(Rv)); I2 = U./(RB2 + Rv);
ang = atan2(I2, I1)*180/pi;                    % 0° = vacío, 45° = mitad, ...
figure('Name','4.6 Reloj de bobinas','Color','w');
subplot(1,2,1); plot(Rv, ang, 'LineWidth', 2); grid on; xlabel('Resistencia del aforador (\Omega)'); ylabel('Ángulo de la aguja (°)'); title('La medida no depende de la tensión de batería');
subplot(1,2,2); hold on; for Ux = [11 12.5 14.5], plot(Rv, atan2(Ux./(RB2+Rv), Ux/RB1*ones(size(Rv)))*180/pi, 'LineWidth', 2); end
grid on; xlabel('Resistencia del aforador (\Omega)'); legend('11 V','12,5 V','14,5 V'); title('Con 11, 12,5 o 14,5 V la aguja marca igual');
guardar('U4_6_reloj_bobinas');

%% 4.7 Indicador de temperatura con NTC y termocontacto
R25 = 2500; B = 3400; Tc = 0:1:120; Rn = R25*exp(B*(1./(Tc+273.15) - 1/298.15));
I2 = 12./(60 + Rn); ang = atan2(I2, 12/60*ones(size(Tc)))*180/pi;
T_termo = 97;      % termocontacto del testigo de sobretemperatura (°C)
figure('Name','4.7 Temperatura','Color','w');
plot(Tc, ang, 'LineWidth', 2); hold on; plot([T_termo T_termo], [0 50], 'r--', 'LineWidth', 1.5); grid on;
xlabel('Temperatura del refrigerante (°C)'); ylabel('Ángulo de la aguja (°)'); legend('Aguja (NTC)','Se enciende el testigo rojo','Location','northwest');
title('Indicador de temperatura: la NTC baja su resistencia al calentarse');
guardar('U4_7_temperatura');

%% 4.8 Motor del limpiaparabrisas: dos velocidades
% Con la tercera escobilla se usan menos espiras activas: menor f.c.e.m. por rpm -> más velocidad.
U = 13.5; Ra = 0.25; k1 = 0.0060; k2 = 0.0042;  % V/rpm (lenta y rápida)
red = 50;                                     % reducción del sinfín
M = 0:0.02:1.5;                               % par en el eje del inducido (N·m)
kT1 = k1*60/(2*pi); kT2 = k2*60/(2*pi);
n1 = (U - M/kT1*Ra)/k1; n2 = (U - M/kT2*Ra)/k2;
figure('Name','4.8 Limpiaparabrisas','Color','w');
plot(M, n1/red, M, n2/red, 'LineWidth', 2); grid on; xlabel('Par resistente en el inducido (N·m)'); ylabel('Ciclos de barrido por minuto');
legend('1.ª velocidad (borne 53)','2.ª velocidad (borne 53b)'); ylim([0 inf]);
title('El cristal seco frena el motor: bajan los ciclos por minuto');
fprintf('\n=== 4.8 Con 0,5 N·m: lenta %.0f ciclos/min, rápida %.0f ciclos/min ===\n', interp1(M,n1,0.5)/red, interp1(M,n2,0.5)/red);
guardar('U4_8_limpia');

%% 4.9 Luneta térmica
P = 150; U = 13.5; nh = 12; Rt = U^2/P; Rh = nh*Rt;
cortados = 0:4; I = U./(Rh./(nh-cortados));
figure('Name','4.9 Luneta térmica','Color','w'); bar(cortados, I); grid on;
xlabel('Hilos cortados'); ylabel('Corriente total (A)'); title(sprintf('Luneta de %d hilos de %.1f \\Omega en paralelo', nh, Rh));
fprintf('\n=== 4.9 Luneta: I = %.1f A; con 1 hilo cortado %.1f A ===\n', I(1), I(2));
guardar('U4_9_luneta');

%% 4.10 Consumo en reposo
C = 60; SOC_min = 0.5;           % capacidad y estado mínimo para arrancar
Irep = [0.02 0.035 0.05 0.1 0.15 0.3];    % corriente en reposo (A)
dias = C*SOC_min./Irep/24;
figure('Name','4.10 Consumo en reposo','Color','w'); bar(Irep*1000, dias); grid on;
xlabel('Consumo en reposo (mA)'); ylabel('Días hasta no poder arrancar'); title('Una alarma o un módulo que no «duerme» descarga la batería');
fprintf('\n=== 4.10 ===\n'); fprintf('%5.0f mA -> %5.1f días\n', [Irep*1000; dias]);
guardar('U4_10_reposo');
