function Sim_Motor4T_Animado(varargin)
% SIM_MOTOR4T_ANIMADO  Motor Otto de cuatro tiempos animado.
%
%   Introducción a Motores (MA.01.04) - ISTS · Unidad 4 (4.1, 4.4, 4.5)
%
%   Muestra el mecanismo biela-manivela, las válvulas de admisión y escape
%   accionadas según las cotas de distribución, y un punto que recorre el
%   diagrama P-V y la curva P-θ del ciclo real. Indica en todo momento el
%   tiempo del ciclo (admisión, compresión, expansión, escape).
%
%   Uso: escriba Sim_Motor4T_Animado en la ventana de comandos.
%        Botón Reproducir/Pausa, deslizador de velocidad y deslizador de
%        ángulo para detener el motor en una posición.
%
%   Convenio: θ = 0° es el PMS al inicio de la admisión; el ciclo dura 720°.
%   La combustión ocurre cerca de θ = 360° (PMS de compresión).
%
%   Compatible con MATLAB (R2014b o superior, sin toolboxes) y GNU Octave.

%% ---------------- DATOS DEL MOTOR (modifique aquí) ----------------
m.D    = 84;     % diámetro del cilindro, mm
m.L    = 81;     % carrera, mm
m.lb   = 135;    % longitud de la biela entre centros, mm
m.Rc   = 9.9;    % relación de compresión
m.n    = 3000;   % régimen, rpm (solo para la velocidad media del pistón)
% Cotas de distribución, en grados de cigüeñal (ver guía, Unidad 4)
m.AAA  = 10;     % avance a la apertura de admisión (antes del PMS)
m.RCA  = 40;     % retraso al cierre de admisión (después del PMI)
m.AAE  = 45;     % avance a la apertura de escape (antes del PMI)
m.RCE  = 10;     % retraso al cierre de escape (después del PMS)
m.alzada = 9;    % alzada máxima de las válvulas, mm
% Ciclo (modelo de Wiebe, ver Sim_CicloReal_Wiebe)
m.Padm = 0.95;   % presión en la admisión, bar
m.Pesc = 1.10;   % presión en el escape, bar
m.avance = 25;   % avance del encendido, ° antes del PMS
m.dur  = 50;     % duración de la combustión, °

%% ---------------- CÁLCULOS PREVIOS ----------------
c = cicloReal(m);                 % presión y volumen cada 1°

%% ---------------- INTERFAZ ----------------
fig = figure('Name','Motor de cuatro tiempos - Introducción a Motores (ISTS)', ...
    'NumberTitle','off','Color','w','Units','normalized','Position',[0.05 0.08 0.9 0.82]);
% motor
axM = axes('Parent',fig,'Position',[0.03 0.12 0.30 0.80]); hold(axM,'on'); axis(axM,'equal'); axis(axM,'off');
% P-V
axPV = axes('Parent',fig,'Position',[0.40 0.57 0.27 0.36]); hold(axPV,'on'); grid(axPV,'on'); box(axPV,'on');
plot(axPV, c.V, c.p, 'Color',[0.89 0.34 0.18],'LineWidth',1.6);
xlabel(axPV,'Volumen del cilindro V (cm^3)'); ylabel(axPV,'Presión p (bar)'); title(axPV,'Diagrama P-V del ciclo real');
hPV = plot(axPV, c.V(1), c.p(1), 'o','MarkerSize',9,'MarkerFaceColor',[0.08 0.14 0.25],'MarkerEdgeColor','w');
% P-theta y alzadas
axPT = axes('Parent',fig,'Position',[0.40 0.12 0.27 0.34]); hold(axPT,'on'); grid(axPT,'on'); box(axPT,'on');
h1 = plot(axPT, c.th, c.p, 'Color',[0.89 0.34 0.18],'LineWidth',1.6);
yyl = max(c.p)*1.05;
la = alzada(c.th, m, 'adm'); le = alzada(c.th, m, 'esc');
h2 = plot(axPT, c.th, la/m.alzada*yyl*0.25, 'Color',[0.05 0.49 0.48],'LineWidth',1.2);
h3 = plot(axPT, c.th, le/m.alzada*yyl*0.25, '--','Color',[0.35 0.40 0.44],'LineWidth',1.2);
xlim(axPT,[0 720]); ylim(axPT,[0 yyl]); set(axPT,'XTick',0:90:720);
xlabel(axPT,'Ángulo del cigüeñal \theta (°)'); ylabel(axPT,'p (bar)');
title(axPT,'Presión y alzada de válvulas (escala relativa)');
hPT = plot(axPT,[0 0],[0 yyl],'-','Color',[0.08 0.14 0.25],'LineWidth',1.2);
legend(axPT,[h1 h2 h3],{'Presión','Válvula de admisión','Válvula de escape'},'Location','northeast');
% panel de información
info = uicontrol(fig,'Style','text','Units','normalized','Position',[0.70 0.30 0.28 0.62], ...
    'BackgroundColor',[0.95 0.97 0.97],'HorizontalAlignment','left','FontSize',10,'FontName','Arial');
% controles
uicontrol(fig,'Style','text','Units','normalized','Position',[0.70 0.21 0.12 0.04],'String','Velocidad de animación','BackgroundColor','w','HorizontalAlignment','left');
sVel = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.70 0.18 0.28 0.03],'Min',1,'Max',12,'Value',4);
uicontrol(fig,'Style','text','Units','normalized','Position',[0.70 0.13 0.20 0.04],'String','Ángulo del cigüeñal (con pausa)','BackgroundColor','w','HorizontalAlignment','left');
sAng = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.70 0.10 0.28 0.03],'Min',0,'Max',719,'Value',0,'SliderStep',[1/719 30/719]);
bPlay = uicontrol(fig,'Style','togglebutton','Units','normalized','Position',[0.70 0.03 0.13 0.05],'String','Pausa','Value',1,'FontWeight','bold');
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[0.85 0.03 0.13 0.05],'String','Cerrar','Callback',@(s,e) close(fig));

g = dibujoInicial(axM, m);

%% ---------------- BUCLE DE ANIMACIÓN ----------------
if nargin > 0 && (strcmp(varargin{1},'captura') || strcmp(varargin{1},'cuadros'))   % imágenes de muestra
    set(bPlay,'Value',0);
    angs = [60 250 365 620]; if strcmp(varargin{1},'cuadros'), angs = 0:12:708; end
    for th = angs
        k = round(th)+1; actualizar(g, m, th); set(hPV,'XData',c.V(k),'YData',c.p(k));
        set(hPT,'XData',[th th]); set(info,'String',textoInfo(m, c, th, k)); drawnow;
        print(fig, sprintf('captura_motor_%03d.png', th), '-dpng', '-r60');
    end
    close(fig); return
end
th = 0;
while ishandle(fig)
    if get(bPlay,'Value') == 1
        set(bPlay,'String','Pausa');
        th = mod(th + get(sVel,'Value'), 720);
        set(sAng,'Value',min(th,719));
    else
        set(bPlay,'String','Reproducir');
        th = get(sAng,'Value');
    end
    k = round(th) + 1; if k > 720, k = 720; end
    actualizar(g, m, th);
    set(hPV,'XData',c.V(k),'YData',c.p(k));
    set(hPT,'XData',[th th]);
    set(info,'String',textoInfo(m, c, th, k));
    drawnow;
    pause(0.03);
end
end

%% =====================================================================
function c = cicloReal(m)
% Ciclo real simplificado con ley de Wiebe (resumen del modelo de Sim_CicloReal_Wiebe)
th = (0:719)';
r = m.L/2; lam = r/m.lb;
Sp = pi*(m.D/10)^2/4;                       % cm^2
Vu = Sp*m.L/10;  Vcc = Vu/(m.Rc-1);         % cm^3
x = posicion(th, r, lam);                   % mm
V = Vcc + Sp*x/10;                          % cm^3
p = zeros(size(th)); g = 1.32;
IVC = 180 + m.RCA; EVO = 540 - m.AAE; ts = 360 - m.avance;
% admisión y escape a presión constante
p(th < IVC) = m.Padm; p(th >= EVO) = m.Pesc;
% compresión y combustión-expansión
T1 = 330; R = 287;
mair = m.Padm*1e5*V(IVC+1)*1e-6/(R*T1);     % kg de aire atrapado
Q = mair/14.7*44e6*0.75;                    % J útiles (75 %: combustión incompleta y calor a las paredes)
p(IVC+1) = m.Padm;
for i = IVC+1 : EVO
    t = th(i);
    xb  = wiebe(t, ts, m.dur); xb0 = wiebe(t-1, ts, m.dur);
    dQ = Q*(xb - xb0);                      % J en este grado
    dV = (V(i+1) - V(i))*1e-6; Vi = V(i)*1e-6;
    pi_ = p(i)*1e5;
    pn = pi_ + ((g-1)*dQ - g*pi_*dV)/Vi;    % ecuación de la energía (1 zona)
    p(i+1) = pn/1e5;
end
c.th = th; c.V = V; c.p = p; c.Vu = Vu; c.Vcc = Vcc;
end

function xb = wiebe(t, ts, dur)
a = 5; mm = 2;
z = (t - ts)/dur; z(z < 0) = 0;
xb = 1 - exp(-a*z.^(mm+1));
end

function x = posicion(th, r, lam)
t = th*pi/180;
x = r*((1 - cos(t)) + (1/lam)*(1 - sqrt(1 - lam^2*sin(t).^2)));
end

function h = alzada(th, m, tipo)
% Alzada de válvula con perfil (1 - cos) entre apertura y cierre
if strcmp(tipo,'adm'), ab = -m.AAA; ci = 180 + m.RCA;
else,                   ab = 540 - m.AAE; ci = 720 + m.RCE; end
h = zeros(size(th));
for s = [-720 0 720]
    t = th + s;
    in = t >= ab & t <= ci;
    h(in) = max(h(in), m.alzada/2*(1 - cos(2*pi*(t(in)-ab)/(ci-ab))));
end
end

function g = dibujoInicial(ax, m)
R = m.L/2; Dc = m.D; hp = 0.7*Dc;            % altura del pistón
yPMS = m.lb + R;                              % bulón en el PMS
yTopPMS = yPMS + 0.45*hp;                     % cabeza del pistón en el PMS
yC = yTopPMS + m.L/(m.Rc - 1);                % cara de la culata (altura de la cámara = L/(Rc-1))
% cilindro y culata
plot(ax, [-Dc/2 -Dc/2], [m.lb-R-10, yC], 'k','LineWidth',3);
plot(ax, [ Dc/2  Dc/2], [m.lb-R-10, yC], 'k','LineWidth',3);
fill(ax, [-Dc/2-12 Dc/2+12 Dc/2+12 -Dc/2-12], yC+[0 0 22 22], [0.75 0.78 0.82],'EdgeColor','k');
text(ax, 0, yC+11, 'Culata','HorizontalAlignment','center','FontSize',9);
fill(ax, [-4 4 4 -4], yC+[22 22 37 37], [0.55 0.55 0.6]);   % bujía
g.chispa = plot(ax, 0, yC-4, 'p','MarkerSize',18,'MarkerFaceColor',[1 0.8 0],'MarkerEdgeColor',[0.9 0.3 0],'Visible','off');
g.gas = fill(ax, [-Dc/2 Dc/2 Dc/2 -Dc/2], [0 0 1 1], [0.7 0.85 1],'EdgeColor','none');
g.vA = fill(ax, [0 0 0 0], [0 0 0 0], [0.05 0.49 0.48],'EdgeColor','k');
g.vE = fill(ax, [0 0 0 0], [0 0 0 0], [0.45 0.45 0.48],'EdgeColor','k');
text(ax, -Dc/4-6, yC+52, 'Admisión','HorizontalAlignment','center','FontSize',9,'Color',[0.05 0.49 0.48]);
text(ax,  Dc/4+6, yC+52, 'Escape','HorizontalAlignment','center','FontSize',9,'Color',[0.35 0.35 0.38]);
g.pis = fill(ax, [0 0 0 0], [0 0 0 0], [0.6 0.62 0.66],'EdgeColor','k','LineWidth',1.2);
g.seg = plot(ax, [0 0],[0 0],'k', [0 0],[0 0],'k', [0 0],[0 0],'k');
tt = linspace(0,2*pi,60);
fill(ax, (R+14)*cos(tt), (R+14)*sin(tt), [0.92 0.93 0.95],'EdgeColor',[0.6 0.6 0.6]);
g.man = plot(ax, [0 0],[0 0], 'Color',[0.89 0.34 0.18],'LineWidth',7);
g.bie = plot(ax, [0 0],[0 0], 'Color',[0.05 0.49 0.48],'LineWidth',6);
plot(ax, 0, 0, 'ko','MarkerFaceColor','k','MarkerSize',8);
g.mun = plot(ax, 0, 0, 'ko','MarkerFaceColor','w','MarkerSize',7);
g.bul = plot(ax, 0, 0, 'ko','MarkerFaceColor','w','MarkerSize',7);
plot(ax, [-Dc/2-15 -Dc/2-2], [yTopPMS yTopPMS], 'b--'); text(ax, -Dc/2-17, yTopPMS, 'PMS','HorizontalAlignment','right','Color','b','FontSize',9);
plot(ax, [-Dc/2-15 -Dc/2-2], [yTopPMS-m.L yTopPMS-m.L], 'b--'); text(ax, -Dc/2-17, yTopPMS-m.L, 'PMI','HorizontalAlignment','right','Color','b','FontSize',9);
plot(ax, [Dc/2+4 Dc/2+4], [yTopPMS-m.L yTopPMS], 'b-'); text(ax, Dc/2+7, yTopPMS-m.L/2, sprintf('L = %g mm', m.L),'Color','b','FontSize',9,'Rotation',90,'HorizontalAlignment','center','VerticalAlignment','top');
g.titulo = title(ax, '', 'FontSize',14,'FontWeight','bold');
xlim(ax, [-Dc/2-45, Dc/2+30]); ylim(ax, [-R-20, yC+60]);
g.R = R; g.Dc = Dc; g.hp = hp; g.yPMS = yPMS; g.yC = yC;
end

function actualizar(g, m, th)
R = g.R; Dc = g.Dc; hp = g.hp;
t = th*pi/180;
xc = R*sin(t); yc = R*cos(t);                       % muñequilla (θ=0 arriba)
yb = yc + sqrt(m.lb^2 - xc^2);                      % bulón
set(g.man,'XData',[0 xc],'YData',[0 yc]); set(g.mun,'XData',xc,'YData',yc);
set(g.bie,'XData',[xc 0],'YData',[yc yb]); set(g.bul,'XData',0,'YData',yb);
yTop = yb + hp*0.45;
set(g.pis,'XData',[-Dc/2+1 Dc/2-1 Dc/2-1 -Dc/2+1],'YData',[yb-hp*0.55 yb-hp*0.55 yTop yTop]);
for i = 1:3, set(g.seg(i),'XData',[-Dc/2+1 Dc/2-1],'YData',[yTop-4*i yTop-4*i]); end
yC = g.yC;                                          % cara de la culata
set(g.gas,'XData',[-Dc/2 Dc/2 Dc/2 -Dc/2],'YData',[yTop yTop yC yC]);
% color del gas según el tiempo
tt = mod(th,720);
if tt < 180,      col = [0.70 0.85 1.00];          % mezcla fresca
elseif tt < 360,  col = [0.55 0.70 1.00];          % compresión
elseif tt < 540,  col = [1.00 0.60 0.35];          % combustión-expansión
else,             col = [0.70 0.70 0.70]; end      % gases quemados
set(g.gas,'FaceColor',col);
% válvulas (alzada dibujada al doble para que se aprecie)
hA = alzada(th, m, 'adm'); hE = alzada(th, m, 'esc');
vx = Dc/4; w = Dc/5;
set(g.vA,'XData',-vx+[-w/2 w/2 2 2 -2 -2],'YData',yC-2*hA+[0 0 4 45 45 4]);
set(g.vE,'XData', vx+[-w/2 w/2 2 2 -2 -2],'YData',yC-2*hE+[0 0 4 45 45 4]);
% chispa
ts = 360 - m.avance;
if tt >= ts && tt <= ts + 8, set(g.chispa,'Visible','on'); else, set(g.chispa,'Visible','off'); end
set(g.titulo,'String',sprintf('%s   θ = %3.0f°', tiempo(tt), tt));
end

function s = tiempo(t)
if t < 180, s = '1. ADMISIÓN';
elseif t < 360, s = '2. COMPRESIÓN';
elseif t < 540, s = '3. EXPANSIÓN';
else, s = '4. ESCAPE'; end
end

function s = textoInfo(m, c, th, k)
t = mod(th,720);
lam = (m.L/2)/m.lb;
x = posicion(t, m.L/2, lam);
vm = m.L/1000*m.n/30;
estA = 'cerrada'; if alzada(t,m,'adm') > 0.05, estA = 'ABIERTA'; end
estE = 'cerrada'; if alzada(t,m,'esc') > 0.05, estE = 'ABIERTA'; end
s = {sprintf('TIEMPO ACTUAL: %s', tiempo(t)), ...
     sprintf('Ángulo del cigüeñal: %5.1f°', t), ...
     sprintf('Vueltas del cigüeñal: %d de 2', floor(t/360)+1), ...
     sprintf('Árbol de levas: %5.1f° (gira a la mitad)', t/2), '', ...
     sprintf('Posición del pistón desde el PMS: %5.1f mm', x), ...
     sprintf('Volumen del cilindro: %6.1f cm³', c.V(k)), ...
     sprintf('Presión en el cilindro: %5.1f bar', c.p(k)), '', ...
     sprintf('Válvula de admisión: %s', estA), ...
     sprintf('Válvula de escape: %s', estE), '', ...
     'DATOS DEL MOTOR', ...
     sprintf('D = %g mm   L = %g mm   l = %g mm', m.D, m.L, m.lb), ...
     sprintf('Vu = %.1f cm³   Vcc = %.1f cm³   Rc = %.1f', c.Vu, c.Vcc, m.Rc), ...
     sprintf('λ = r/l = %.2f   vm = %.1f m/s a %d rpm', lam, vm, m.n), ...
     sprintf('Cotas: AAA %d°  RCA %d°  AAE %d°  RCE %d°', m.AAA, m.RCA, m.AAE, m.RCE), ...
     sprintf('Cruce de válvulas: %d°', m.AAA + m.RCE), ...
     sprintf('Presión máxima: %.1f bar a %.0f°', max(c.p), c.th(find(c.p==max(c.p),1)))};
end
