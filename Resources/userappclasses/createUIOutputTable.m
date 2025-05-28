function outputTableData = createUIOutputTable(localinputFolderLifeTables, localrateCurves,localCountries,localRateScenarios, localStartDateRates)
            numCountries = length(localCountries); 
            pv1Values = zeros(numCountries, 1);
            pv2Values = zeros(numCountries, 1); 
            curveNames = cell(numCountries, 1);

            % for i = 1:numCountries
            %     localCountry = localCountries(i);
            %     pensionAmount = 1116.40*26;
            %     % annuityValues = lifetimeAnnuityValue(localinputFolderLifeTables, localrateCurves,localCountry,localRateScenarios, localStartDateRates, 67, 'M', 0,100,pensionAmount,0.03);
            %     % 
            %     % pv1Values(i) = annuityValues.pv1(1);
            %     % pv2Values(i) = annuityValues.pv2(1);
            %     curveNames{i} = annuityValues.curveName;
            % 
            % 
            % end %end country loop
            
            
            outputTableData = table(localCountries',curveNames, pv1Values, pv2Values, 'VariableNames', {'Country','curve','Life expectancy $m', 'Lifetime Value $m'});
end