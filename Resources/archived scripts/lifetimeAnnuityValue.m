function results = lifetimeAnnuityValue(baseLifeTableFolder, rateCurves,country,rateScenarios, startDateRate,entryAge, gender, deferment,maxNumPayments,guaranteedPayment,inflationRate)

 

   [lx,qx]= obtainImprovedSurvivorship(baseLifeTableFolder,entryAge,gender);
   maxNumPayments = size(lx,1)-entryAge;

  % Get current year and year for annuity start
  % currentYear = year(datetime(startDateRate));
   currentYear = year(startDateRate);
   
  firstPaymentYear = currentYear + deferment;
  

  % Calculate remaining life expectancy (adjust based on your needs)
  % lifeExpectancy = interp1(lx(:,1), lx(:,1), find(lx(:,1) >= age, 1, 'first')) - age; %TODO get grouping to wor
  lifeExpectancy = 25;

  % extract the relevant rate curve
    keyScenario = rateScenarios(1);
    keysCurveNames = keys(rateCurves);
    keysCurveNamesCountry = extractBetween(keysCurveNames,1,2);
    keyCurveNameIndices = contains(keysCurveNamesCountry,country) & contains(keysCurveNames,keyScenario); %logical array with 1 for elements that meet teh criteria
    keyRateCurveName = keysCurveNames(keyCurveNameIndices);
    rateCurve = rateCurves(keyRateCurveName); 
    curveName = keyRateCurveName;

  % Initialize variables
  pv1 = zeros(maxNumPayments+1,1);
  pv2 = zeros(maxNumPayments+1,1);
  deathYear = firstPaymentYear + lifeExpectancy;

  % Loop through each payment year to expectancy age
  for ii = 1:lifeExpectancy
    % Get discount factor for the payment year
    paymentDate = startDateRate + years(ii);
   
    % Calculate the index for the discount factor corresponding to the maturity
    index = year(paymentDate) - year(startDateRate); % Assuming 1-based indexing

    % Extract the discount factor
    discountFactor = (1+rateCurve.Rates(index))^-index; 
   
       
    % Calculate present value of annuity payment in that year (adjust for couples)
    % ... (Add logic to handle single or couple based on 'gender' input)
    payment = guaranteedPayment*(1+inflationRate)^(ii);   % Replace with appropriate annuity payment formula (single/couple),inflation etc

    % Update present value considering discount factor
    pv1(ii+1) = pv1(ii) + discountFactor * payment;
  end
     

  %lAge= interp1(baseLifeTable.(gender).Age(:, 1), baseLifeTable.(gender).lx(:, 1), age, 'linear', 0); % baseline population at Age = intial age

  % Loop through each payment to maximum payment year 
  for ii = 1:maxNumPayments
    % Get discount factor for the payment year
     paymentDate = startDateRate + years(ii);
   % Calculate the index for the discount factor corresponding to the maturity
    index = year(paymentDate) - year(startDateRate) ; % Assuming 1-based indexing

    % Extract the discount factor from time 0 to time ii or index
    discountFactor(ii) = (1+rateCurve.Rates(index))^-index; 

    % Calculate survival probability to time ii
    %survivalProbability = interp1(baseLifeTable.(gender).Age(:, 1), baseLifeTable.(gender).lx(:, 1), age+index, 'linear', 0)/lAge; 
    survivalProbability(ii) = lx(entryAge+index)/lx(entryAge);

    % Inflate annuity value to current year
    payment(ii) = guaranteedPayment*(1+inflationRate)^(ii);   % Replace with appropriate annuity payment formula (single/couple),inflation etc
     
    
    % Update present value at time 0 using discount factor and survival probability
    pv2 = pv2 + discountFactor(ii) * payment(ii) * survivalProbability(ii);
  

    %% TODO work out ho wbest to calculate the value of an annuity on this yield curve at different starting times eg if i start in a year i am one year olde rand the ofrward curve is different.
    % can i use previous zum sutract payment fo rprevious year and
    % multiplyby 1 year zero for that part of the curve. would need to
    % calculate the one year zeros at each point on curve.
  end
  disp(pv1)
  disp(pv2)

  results.pv1 = pv1;
  results.pv2 = pv2;
  results.curveName = curveName;
end