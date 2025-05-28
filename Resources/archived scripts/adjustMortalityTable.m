function [revisedlx revisedqx] = adjustMortalityTable(qx,lx, localImprovementFactors, entryAge)

  revisedqx = qx;
  revisedlx = lx;
 


  % Error handling (check for valid age and gender in lifeTable)
  % ... (Implement checks based on your lifeTable structure)
 
  % % Identify entry Age group for the person
  % entryAgeGroup = find(localLifeTable.(gender).Age >= entryAge, 1, 'first');
  % 
    
  % look through the remaining ages in the life table and calculate the
  % improvement factor for each
  maxAge = length(lx);

 for ii = 0:maxAge-entryAge
  %select the mortality rate to be improved
  xplusn = entryAge+ii;
  qxplusn = qx(xplusn);
  lxplusn = lx(xplusn);
  
  %select the improvement factor 
  fxplusn = selectImprovementFactor(entryAge + ii,localImprovementFactors);

  % Apply improvement rates to base lx
   if ii == 0
       revisedlx(xplusn) = lxplusn;
       revisedqx(xplusn) = qxplusn;
   else
       revisedqx(xplusn) = qxplusn* (1 - fxplusn/100)^ii;
       revisedlx(xplusn) = revisedlx(xplusn-1) * (1-revisedqx(xplusn));
   end
 end

end