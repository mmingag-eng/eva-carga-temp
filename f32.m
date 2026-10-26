%% ========================================================================
%  ELECTRICIDAD AUTOMOTRIZ (MA.03.02) · ISTS · PAO Oct 2026 – Feb 2027
%  UNIDAD 2 · Sistema de arranque y de carga
%  ------------------------------------------------------------------------
%   2.1 Curvas características del motor de arranque (modelo de CC)
%   2.2 Comparación: motor de imanes permanentes y motor de excitación serie
%   2.3 Efecto de la batería y de las conexiones sobre el arranque
%   2.4 Transitorio de arranque: corriente y régimen del motor térmico
%   2.5 Alternador: f.e.m. trifásica y rectificación con puente de 6 diodos
%   2.6 Alternador: curva característica I = f(n) a partir de la placa
%   2.7 Regulador de tensión: ciclo de trabajo (PWM) de la excitación según la carga
%   2.8 Balance eléctrico del vehículo
%  Compatible con MATLAB R2016b+ y GNU Octave. Valores orientativos.
%% ========================================================================
clear; close all; clc;
guardarFiguras = false; guardar = @(n) [];
if guardarFiguras, guardar = @(n) print(gcf,'-dpng','-r150',[n '.png']); end

%% 2.1 Curvas características del motor de arranque
% DATOS
E0 = 12.6; Ri = 0.010; Rc = 0.003; Rm = 0.020;   % batería, cables, motor (V, ohm)
kn = 400;            % constante de velocidad (rpm/V)
M0 = 0.5;            % par de pérdidas (N·m)
Zc = 119; Zp = 9;    % dientes de corona y piñón
Ib = E0/(Ri+Rc+Rm);  I = linspace(0, Ib, 200);
U  = E0 - I*(Ri+Rc);          % tensión en bornes del motor
Ep = max(0, U - I*Rm);        % fuerza contraelectromotriz
n  = kn*Ep;                   % rpm del inducido
kT = 60/(2*pi*kn);            % constante de par (N·m/A)
M  = max(0, kT*I - M0);       % par útil
Pu = M .* 2*pi.*n/60;  Pa = U.*I;  eta = Pu./max(Pa,eps)*100;
[Pmax, iP] = max(Pu); i_tr = Zc/Zp;
fprintf('\n=== 2.1 Motor de arranque ===\nCorriente de bloqueo: %.0f A\nPotencia útil máxima: %.0f W a %.0f A (n = %.0f rpm, cigüeñal %.0f rpm)\n', ...
        Ib, Pmax, I(iP), n(iP), n(iP)/i_tr);
figure('Name','2.1 Motor de arranque','Color','w');
subplot(2,1,1); [ax,h1,h2] = plotyy(I', [Pu; Pa]', I', n'); set([h1;h2],'LineWidth',2);
ylabel(ax(1),'Potencia (W)'); ylabel(ax(2),'Velocidad del inducido (rpm)'); grid on;
legend([h1;h2],'P útil','P absorbida','n inducido','Location','north'); title('Curvas características del motor de arranque');
subplot(2,1,2); [ax,h1,h2] = plotyy(I', [M; U]', I', eta'); set([h1;h2],'LineWidth',2);
ylabel(ax(1),'Par (N·m) / tensión (V)'); ylabel(ax(2),'Rendimiento (%)'); xlabel('Corriente (A)'); grid on;
legend([h1;h2],'Par útil','U bornes','Rendimiento');
guardar('U2_1_motor_arranque');

%% 2.2 Imanes permanentes frente a excitación serie
% En el motor serie el flujo crece con la corriente (con saturación): par ~ I² a corriente baja.
Isat = 150;                              % corriente a la que el hierro empieza a saturarse (A)
g    = @(x) x ./ (x + Isat);             % flujo relativo con saturación
phi  = g(I) / g(Ib);                     % normalizado: en bloqueo ambos motores tienen el mismo flujo
Ms   = max(0, kT*I.*phi - M0);           % par del motor serie (crece aprox. con I² a corriente baja)
ns   = min(kn*Ep ./ max(phi, 1e-3), 12000);   % velocidad: inversa al flujo (se embala en vacío)
figure('Name','2.2 Imanes permanentes vs serie','Color','w');
subplot(1,2,1); plot(I, M, I, Ms, 'LineWidth', 2); grid on; xlabel('Corriente (A)'); ylabel('Par (N·m)'); legend('Imanes permanentes','Excitación serie','Location','northwest'); title('Par');
subplot(1,2,2); plot(I, n, I, ns, 'LineWidth', 2); grid on; xlabel('Corriente (A)'); ylabel('rpm del inducido'); legend('Imanes permanentes','Excitación serie'); title('Velocidad (el serie se embala en vacío)');
guardar('U2_2_PM_vs_serie');

%% 2.3 Influencia de la batería y de las conexiones
casos = {'Correcto', 0.010, 0.003; 'Masa oxidada', 0.010, 0.015; 'Batería agotada', 0.035, 0.003};
figure('Name','2.3 Conexiones y batería','Color','w'); hold on;
fprintf('\n=== 2.3 Potencia útil máxima ===\n');
for c = 1:size(casos,1)
    ri = casos{c,2}; rc = casos{c,3}; ib = E0/(ri+rc+Rm); Ii = linspace(0,ib,200);
    Ui = E0 - Ii*(ri+rc); ni = kn*max(0,Ui-Ii*Rm); Mi = max(0,kT*Ii-M0); Pi = Mi.*2*pi.*ni/60;
    plot(Ii, Pi, 'LineWidth', 2, 'DisplayName', casos{c,1});
    fprintf('%-16s Pmax = %4.0f W\n', casos{c,1}, max(Pi));
end
grid on; xlabel('Corriente (A)'); ylabel('Potencia útil (W)'); legend; title('Una mala conexión «roba» potencia al motor de arranque');
guardar('U2_3_conexiones');

%% 2.4 Transitorio de arranque (modelo dinámico simple)
% DATOS
J   = 0.25;        % inercia del motor térmico reflejada al cigüeñal (kg·m²)
Mc  = 45;          % par resistente medio de compresión y rozamiento (N·m)
Mc_amp = 30;       % amplitud de la ondulación por compresiones (N·m)
zc  = 4;           % cilindros
eta_e = 0.9;       % rendimiento del engrane
L   = 0.0001;      % inductancia del circuito (H)
dt = 1e-4; tf = 1.2; N = round(tf/dt);
w = 0; th = 0; ia = 0; tt = (0:N-1)*dt; Ia = zeros(1,N); Nc = zeros(1,N); Ub = zeros(1,N);
for k = 1:N
    nmot = w*60/(2*pi)*i_tr;                % rpm del inducido
    Epk  = nmot/kn;                         % f.c.e.m.
    ia   = ia + dt*(E0 - ia*(Ri+Rc+Rm) - Epk)/L; ia = max(ia,0);
    Mm   = max(0,kT*ia - M0)*i_tr*eta_e;    % par en el cigüeñal
    Mr   = Mc + Mc_amp*sin(zc/2*th);        % par resistente con pulsaciones
    if w <= 0 && Mm < Mr, w = 0; else, w = w + dt*(Mm - Mr)/J; end
    th = th + w*dt;
    Ia(k) = ia; Nc(k) = w*60/(2*pi); Ub(k) = E0 - ia*Ri;
end
figure('Name','2.4 Transitorio de arranque','Color','w');
subplot(3,1,1); plot(tt, Ia, 'LineWidth', 1.5); grid on; ylabel('Corriente (A)'); title('Arranque: pico inicial y ondulación por compresiones');
subplot(3,1,2); plot(tt, Ub, 'LineWidth', 1.5); grid on; ylabel('Tensión batería (V)');
subplot(3,1,3); plot(tt, Nc, 'LineWidth', 1.5); grid on; ylabel('Cigüeñal (rpm)'); xlabel('Tiempo (s)');
fprintf('\n=== 2.4 Transitorio ===\nPico de corriente %.0f A, tensión mínima %.2f V, régimen final %.0f rpm\n', max(Ia), min(Ub), mean(Nc(end-2000:end)));
guardar('U2_4_transitorio');

%% 2.5 Alternador: f.e.m. trifásica y rectificación (puente de 6 diodos)
% DATOS
n_alt = 3000;       % rpm del alternador
p     = 6;          % pares de polos (rotor de 12 garras)
Ef    = 9;          % amplitud de la f.e.m. de fase (V) – el regulador la mantiene
Vd    = 0.8;        % caída en cada diodo (V)
f = p*n_alt/60;     % frecuencia (Hz)
t = linspace(0, 3/f, 1500);
ea = Ef*sin(2*pi*f*t); eb = Ef*sin(2*pi*f*t - 2*pi/3); ec = Ef*sin(2*pi*f*t + 2*pi/3);
uL = max([ea;eb;ec]) - min([ea;eb;ec]) - 2*Vd;      % tensión rectificada (estrella)
fprintf('\n=== 2.5 Rectificación ===\nFrecuencia de fase f = p·n/60 = %.0f Hz; rizado a %.0f Hz\n', f, 6*f);
fprintf('Tensión rectificada media %.2f V, máx %.2f V, mín %.2f V\n', mean(uL), max(uL), min(uL));
figure('Name','2.5 Rectificación trifásica','Color','w');
subplot(2,1,1); plot(t*1000, ea, t*1000, eb, t*1000, ec, 'LineWidth', 1.5); grid on; ylabel('f.e.m. de fase (V)'); title(sprintf('Tres fases desfasadas 120° (f = %.0f Hz)', f)); legend('U','V','W');
subplot(2,1,2); plot(t*1000, uL, 'LineWidth', 2); grid on; xlabel('Tiempo (ms)'); ylabel('Tensión en B+ (V)'); title('Salida del puente de 6 diodos: continua con rizado');
% Simulación de un diodo positivo abierto en la fase U: la fase U ya no puede llevar el positivo
pos = max([eb;ec]); pos2 = max([ea;eb;ec]); %#ok<NASGU>
uDiodo = max(0, max([eb;ec]) - min([ea;eb;ec]) - 2*Vd);   % sin batería conectada
hold on; plot(t*1000, uDiodo, 'r', 'LineWidth', 1); legend('Normal','Diodo positivo de U abierto','Location','south');
fprintf('Con un diodo abierto la media baja a %.2f V y el rizado aumenta (de %.2f a %.2f V)\n', mean(uDiodo), max(uL)-min(uL), max(uDiodo)-min(uDiodo));
guardar('U2_5_rectificacion');

%% 2.6 Curva característica del alternador a partir de la placa (14 V 40/90 A)
% DATOS
U = 14; I1800 = 40; Imax = 90; n0 = 1000; poleas = 2.6; eta = 0.6; ralenti = 800;
tau = (1800-n0)/(-log(1-I1800/Imax));
n = 0:50:15000; Ia = Imax*(1-exp(-max(0,n-n0)/tau));
Pel = U*Ia; Pmec = Pel/eta; Mcig = Pmec ./ max(2*pi*(n/poleas)/60, eps); Mcig(n==0) = 0;
I_ral = Imax*(1-exp(-max(0,ralenti*poleas-n0)/tau));
fprintf('\n=== 2.6 Alternador ===\nAl ralentí (%d rpm motor = %.0f rpm alternador): %.1f A\n', ralenti, ralenti*poleas, I_ral);
figure('Name','2.6 Curva del alternador','Color','w');
subplot(2,1,1); plot(n, Ia, 'LineWidth', 2); hold on; plot(1800, I1800, 'ro', ralenti*poleas, I_ral, 'ks', 'MarkerSize', 8, 'LineWidth', 2);
grid on; ylabel('Corriente (A)'); title('Curva característica'); legend('I = f(n)','Punto de placa (1800 rpm)','Ralentí','Location','southeast');
subplot(2,1,2); [ax,h1,h2] = plotyy(n, Pmec, n, Mcig); set([h1;h2],'LineWidth',2);
ylabel(ax(1),'Potencia mecánica (W)'); ylabel(ax(2),'Par en el cigüeñal (N·m)'); xlabel('rpm del alternador'); grid on;
guardar('U2_6_curva_alternador');

%% 2.7 Regulador electrónico: ciclo de trabajo de la excitación según la carga
% Modelo: la corriente que entrega el alternador es proporcional a la excitación (ciclo de trabajo D)
% y a la velocidad; el regulador ajusta D para mantener 14,2 V.
Ureg = 14.2; Iex_max = 4.5; n_alt = [1800 3000 6000]; Icarga = 0:2:90;
figure('Name','2.7 Regulador PWM','Color','w'); hold on;
for nn = n_alt
    Iposible = Imax*(1-exp(-max(0,nn-n0)/tau));
    D = min(1, Icarga/Iposible);
    plot(Icarga, D*100, 'LineWidth', 2, 'DisplayName', sprintf('%d rpm', nn));
end
grid on; xlabel('Corriente consumida (A)'); ylabel('Ciclo de trabajo de la excitación (%)'); legend('Location','southeast');
title('Al 100 % el alternador ya no puede sostener 14,2 V: la batería aporta la diferencia');
% forma de onda PWM en el terminal DF a media carga
f_pwm = 400; D0 = 0.45; tt = linspace(0, 3/f_pwm, 2000); uDF = 14*(mod(tt*f_pwm,1) < D0);
axes('Position',[0.55 0.2 0.32 0.22]); plot(tt*1000, uDF, 'LineWidth', 1.5); ylim([-1 16]); title('Señal DF (D = 45 %)'); xlabel('ms');
guardar('U2_7_regulador');

%% 2.8 Balance eléctrico
consum = {'Encendido e inyección',120,1; 'Bomba de combustible',60,1; 'Posición y matrícula',30,1; 'Cruce',110,1; ...
          'Carretera',120,0; 'Antinieblas',110,0; 'Cuadro',15,1; 'Radio',20,1; 'Limpiaparabrisas',90,1; ...
          'Soplador',200,1; 'Luneta térmica',150,1; 'Electroventilador',240,0};
P = cell2mat(consum(:,2)); on = cell2mat(consum(:,3)); Itot = sum(P.*on)/U;
nmot = 600:50:4000; Idisp = Imax*(1-exp(-max(0,nmot*poleas-n0)/tau));
figure('Name','2.8 Balance eléctrico','Color','w');
subplot(1,2,1); barh(P.*on/U); set(gca,'YTick',1:numel(P),'YTickLabel',consum(:,1)); xlabel('Corriente (A)'); grid on; title(sprintf('Consumo total %.1f A', Itot));
subplot(1,2,2); plot(nmot, Idisp, 'LineWidth', 2); hold on; plot(nmot, Itot*ones(size(nmot)), 'r--', 'LineWidth', 2); grid on;
xlabel('rpm del motor'); ylabel('Corriente (A)'); legend('Alternador','Consumo','Location','southeast');
nEq = nmot(find(Idisp>=Itot,1)); if isempty(nEq), nEq = NaN; end
title(sprintf('Balance positivo a partir de %.0f rpm', nEq));
fprintf('\n=== 2.8 Balance ===\nConsumo %.1f A; el alternador lo cubre desde %.0f rpm del motor\n', Itot, nEq);
guardar('U2_8_balance');
