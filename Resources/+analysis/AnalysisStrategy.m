% File: AnalysisStrategy.m
classdef (Abstract) AnalysisStrategy < handle
    %ANALYSISSTRATEGY Abstract base class for different analysis calculation strategies.
    %   Defines the interface for any class that can take a Person object and
    %   a configuration, and return a table of results.

    methods (Abstract)
        % The main analysis method.
        % Inputs:
        %   person: The base Person object to analyze.
        %   config: A struct containing loop parameters (xAxisEnum, lineVarEnum, etc.).
        %   rateCurveProvider: An object that can provide rate curves.
        %
        % Returns:
        %   A table containing the results of the analysis.
        resultsTable = analyze(obj, person, config, rateCurveProvider);
    end
end