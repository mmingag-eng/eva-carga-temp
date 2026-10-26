function Sim_Comparador_Ciclos(varargin)
% SIM_COMPARADOR_CICLOS  Ciclos ideales Otto, Diesel y Dual de aire estándar.
%
%   Introducción a Motores (MA.01.04) - ISTS · Unidad 2 (2.4, 2.5, 2.6, 2.7)
%
%   Los tres ciclos reciben el mismo calor q_entrada. El Otto lo recibe a
%   volumen constante, el Diesel a presión constante y el Dual reparte una
%   fracción a volumen constante y el resto a presión constante.
%   Compare los diagramas P-v y T-s, el rendimiento y la PME:
%     - con la misma relación de compresión, el Otto es el más eficiente;
%     - con las relaciones reales (Diesel mucho mayor), el Diesel lo supera.
%
%   Uso: Sim_Comparador_Ciclos   y mueva los deslizadores.
%   Calores específicos constantes (Çengel y Boles, 2012).
%   Compatible con MATLAB (R2014b o superior, sin toolboxes) y GNU Octave.

c.cv = 0.718; c.cp = 1.005; c.R = 0.287; c.k = c.cp/c.cv;
def = {'rO','Relación de compresión del Otto',5,14,9; ...
       'rD','Relación de compresión del Diesel y del Dual',12,24,18; ...
       'q','Calor suministrado q_entrada (kJ/kg)',300,2000,1000; ...
       'P1','Presión inicial P1 (kPa) — Loja ≈ 79',60,120,100; ...
       'f','Dual: fracción del calor a volumen constante',0,1,0.5};

fig = figure('Name','Comparador de ciclos Otto, Diesel y Dual - Introducción a Motores (ISTS)', ...
    'NumberTitle','off','Color','w','Units','normalized','Position',[0.04 0.06 0.92 0.86]);
ax(1) = axes('Parent',fig,'Position',[0.05 0.42 0.42 0.52]);
ax(2) = axes('Parent',fig,'Position',[0.55 0.42 0.42 0.52]);
ax(3) = axes('Parent',fig,'Position',[0.05 0.06 0.25 0.26]);
uicontrol(fig,'Style','checkbox','Units','normalized','Position',[0.33 0.30 0.30 0.03],'BackgroundColor','w', ...
    'String','Usar la misma relación de compresión en los tres ciclos','Value',0,'Tag','misma','Callback',@(s,e) redibujar());
info = uicontrol(fig,'Style','text','Units','normalized','Position',[0.64 0.04 0.34 0.28], ...
    'BackgroundColor',[0.95 0.97 0.97],'HorizontalAlignment','left','FontSize',10,'FontName','Arial');
sl = zeros(1,5); lb = sl;
for i = 1:5
    y = 0.25 - (i-1)*0.045;
    lb(i) = uicontrol(fig,'Style','text','Units','normalized','Position',[0.33 y 0.30 0.025],'BackgroundColor','w','HorizontalAlignment','left','FontSize',9);
    sl(i) = uicontrol(fig,'Style','slider','Units','normalized','Position',[0.33 y-0.018 0.28 0.02], ...
        'Min',def{i,3},'Max',def{i,4},'Value',def{i,5},'Callback',@(s,e) redibujar());
end
redibujar();
if nargin > 0 && strcmp(varargin{1},'captura')
    drawnow; disp(get(info,'String')); print(fig,'captura_comparador.png','-dpng','-r80'); close(fig);
end

    function redibujar()
        for j = 1:5
            v.(def{j,1}) = get(sl(j),'Value');
            set(lb(j),'String',sprintf('%s:  %.2f', def{j,2}, v.(def{j,1})));
        end
        if get(findobj(fig,'Tag','misma'),'Value') == 1, v.rD = v.rO; end
        T1 = 300;
        cyc = {ciclo(c, v.P1, T1, v.rO, v.q, 1), ciclo(c, v.P1, T1, v.rD, v.q, 0), ciclo(c, v.P1, T1, v.rD, v.q, v.f)};
        nom = {'Otto','Diesel','Dual'};
        col = {[0.89 0.34 0.18],[0.05 0.49 0.48],[0.08 0.14 0.25]};
        sty = {'-','-','--'};
        cla(ax(1)); hold(ax(1),'on'); grid(ax(1),'on'); box(ax(1),'on');
        cla(ax(2)); hold(ax(2),'on'); grid(ax(2),'on'); box(ax(2),'on');
        for j = 1:3
            plot(ax(1), cyc{j}.v, cyc{j}.P, sty{j}, 'Color',col{j},'LineWidth',2);
            plot(ax(2), cyc{j}.s, cyc{j}.T, sty{j}, 'Color',col{j},'LineWidth',2);
        end
        xlabel(ax(1),'Volumen específico v (m^3/kg)'); ylabel(ax(1),'Presión P (kPa)'); title(ax(1),'Diagrama P-v');
        xlabel(ax(2),'Entropía s - s_1 (kJ/kg·K)'); ylabel(ax(2),'Temperatura T (K)'); title(ax(2),'Diagrama T-s');
        legend(ax(1), nom, 'Location','northeast'); legend(ax(2), nom, 'Location','northwest');
        cla(ax(3)); hold(ax(3),'on');
        eta = [cyc{1}.eta cyc{2}.eta cyc{3}.eta]*100;
        for j = 1:3, bar(ax(3), j, eta(j), 0.6, 'FaceColor', col{j}); end
        set(ax(3),'XTick',1:3,'XTickLabel',nom); ylabel(ax(3),'\eta (%)'); title(ax(3),'Rendimiento térmico'); ylim(ax(3),[0 80]); grid(ax(3),'on');
        for j = 1:3, text(j, eta(j)+3, sprintf('%.1f %%', eta(j)), 'Parent',ax(3),'HorizontalAlignment','center','FontWeight','bold'); end
        s = {sprintf('%-8s %6s %8s %8s %8s %9s', 'Ciclo','r','η (%)','Pmáx(bar)','Tmáx(K)','PME(kPa)')};
        for j = 1:3
            s{end+1} = sprintf('%-8s %6.1f %8.1f %8.1f %8.0f %9.0f', nom{j}, cyc{j}.r, cyc{j}.eta*100, max(cyc{j}.P)/100, max(cyc{j}.T), cyc{j}.pme); %#ok<AGROW>
        end
        s{end+1} = '';
        s{end+1} = sprintf('Diesel: relación de corte rc = %.2f', cyc{2}.rc);
        s{end+1} = sprintf('Dual: relación de presiones rp = %.2f; rc = %.2f', cyc{3}.rp, cyc{3}.rc);
        s{end+1} = 'Active la casilla para comparar a igual r.';
        set(info,'String',s,'FontName','Courier New');
        drawnow;
    end
end

%% =====================================================================
function y = ciclo(c, P1, T1, r, q, f)
% Ciclo dual general: f = 1 -> Otto; f = 0 -> Diesel
k = c.k; R = c.R; cv = c.cv; cp = c.cp;
v1 = R*T1/P1; v2 = v1/r;
T2 = T1*r^(k-1); P2 = P1*r^k;
Tx = T2 + f*q/cv;   Px = P2*Tx/T2;              % aporte a v = cte
T3 = Tx + (1-f)*q/cp; v3 = v2*T3/Tx; P3 = Px;   % aporte a P = cte
P4 = P3*(v3/v1)^k; T4 = T3*(v3/v1)^(k-1);
qout = cv*(T4 - T1); w = q - qout;
n = 60;
vc = linspace(v1,v2,n)'; Pc = P1*(v1./vc).^k;            % 1-2
Tvx = linspace(T2,Tx,n)'; vvx = v2*ones(n,1); Pvx = R*Tvx./vvx; % 2-x
vpx = linspace(v2,v3,n)'; Ppx = Px*ones(n,1);           % x-3
ve = linspace(v3,v1,n)'; Pe = P3*(v3./ve).^k;            % 3-4
v = [vc; vvx; vpx; ve; v1]; P = [Pc; Pvx; Ppx; Pe; P1];
T = P.*v/R;
% entropía relativa
sx = cv*log(Tx/T2); s3 = sx + cp*log(T3/Tx);
s = [zeros(n,1); cv*log(Tvx/T2); sx + cp*log((Ppx.*vpx/R)/Tx); s3*ones(n,1); 0];
% tramo 4-1 a v = cte para cerrar el T-s
T41 = linspace(T4,T1,n)'; s41 = s3 + cv*log(T41/T4);
v = [v(1:end-1); v1*ones(n,1)]; P = [P(1:end-1); R*T41/v1]; T = [T(1:end-1); T41]; s = [s(1:end-1); s41];
y = struct('v',v,'P',P,'T',T,'s',s,'eta',w/q,'pme',w/(v1-v2),'r',r,'rc',v3/v2,'rp',Px/P2);
end
