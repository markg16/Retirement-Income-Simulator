classdef AnalyticalAnnuityValuations
    methods (Static)
        function pv = calculateAnnuityPV_Gompertz(B, c, age, term, interestRate)
            % Calculates the PV of a n-year temporary life annuity-due analytically.
            % The annuity pays 1 at the start of each year if the life is alive.
            % Inputs:
            %   B, c:         Gompertz parameters
            %   age:          Current age of the annuitant (x)
            %   term:         Term of the annuity in years (n)
            %   interestRate: Annual effective interest rate (i)
            
            pv = 0;
            v = 1 / (1 + interestRate);
            log_c = log(c);

            % The sum is from t=0 to n-1 for an annuity-due
            for t = 0:(term - 1)
                % Probability of life aged x surviving t years:
                % _t_p_x = exp( (B/log(c)) * c^x * (1 - c^t) )
                t_p_x = exp( (B/log_c) * (c^age) * (1 - c^t) );
                
                % PV of payment at time t
                pv_t = (v^t) * t_p_x;
                
                % Add to total PV
                pv = pv + pv_t;
            end
        end
    end
end