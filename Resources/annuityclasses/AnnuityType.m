classdef AnnuityType
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
       SingleLifeTimeAnnuity
       FixedAnnuity
    end
    methods (Static) % Define a static method for the alias lookup
        function alias = getAlias(annuityType)
            switch annuityType
                case AnnuityType.SingleLifeTimeAnnuity
                    alias = 'SingleLifeTimeAnnuity';
                case AnnuityType.FixedAnnuity
                    alias = 'FixedAnnuity';
                
                otherwise
                    error('Unsupported annuity type');
            end
        end
        function annuityType = fromAlias(alias)
            switch alias
                case 'SingleLifeTimeAnnuity'
                    annuityType = AnnuityType.SingleLifeTimeAnnuity;
                case 'FixedAnnuity'
                    annuityType = FrequencyType.FixedAnnuity;
                
                otherwise
                    error('Unsupported AnnuityType alias');
            end
        end
    end
end