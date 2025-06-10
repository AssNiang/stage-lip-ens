function pl = customLogarithmicPathLoss(sig, rxInfo)
    d = norm(sig.TransmitterPosition - rxInfo.Position); % Distance en mètres
    d_0 = 1; % Distance de référence (1 m)
    PL_0 = 46.677; % Perte de référence à d_0 = 1 m (comme sur ns-3)
    n = 3.0; % Exposant de perte (comme sur ns-3)
    
    % Modèle logarithmique : PL = PL_0 + 10 * n * log10(d/d_0)
    pl = PL_0 + 10 * n * log10(d/d_0);
    disp(['Perte logarithmique appliquée : ', num2str(pl), ' dB']);
end
