classdef AnnuityStrategyFactory
    %UNTITLED6 Summary of this class goes here
    %   Detailed explanation goes here
  

    methods (Static)
        function annuityFactory = createAnnuityStrategyFactory(annuityType)
            %UNTITLED6 Construct an instance of this class
            %   Detailed explanation goes here

            switch annuityType
                case AnnuityType.FixedAnnuity
                    annuityFactory = FixedAnnuityFactory();
                case AnnuityType.SingleLifeTimeAnnuity
                    annuityFactory = SingleLifeTimeAnnuityFactory();
                otherwise

                    error('Unsupported annuity type for annuity strategy factory');
            end


        end
    end
end