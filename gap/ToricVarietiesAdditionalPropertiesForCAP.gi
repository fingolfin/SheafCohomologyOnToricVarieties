################################################################################################
##
##  ToricVarietiesAdditionalPropertiesForCAP.gi        SheafCohomologyOnToricVarieties package
##
##  Copyright 2019                                     Martin Bies,       ULB Brussels
##
#! @Chapter Additional methods/properties for toric varieties
##
################################################################################################


###################################################################################
##
##  Define Global variables
##
###################################################################################

SHEAF_COHOMOLOGY_ON_TORIC_VARIETIES_INTERNAL_LAZY := true;


######################
##
#! @Section Properties
##
######################

InstallMethod( IsValidInputForCohomologyComputations,
               " for a toric variety",
               [ IsToricVariety ],

  function( variety )
    local result;

    # initialise value
    result := true;
    
    # check that the variety matches our general requirements
    if SHEAF_COHOMOLOGY_ON_TORIC_VARIETIES_INTERNAL_LAZY then

      if not ( ( IsSmooth( variety ) and IsComplete( variety ) ) or 
               ( IsSimplicial( FanOfVariety( variety ) ) and IsProjective( variety ) ) ) then

        result := false;

      fi;

    else

      if not ( IsSmooth( variety ) and IsComplete( variety ) ) then
      
        result := false;

      fi;

    fi;

    # and return result
    return result;

end );


######################
##
#! @Section Attributes
##
######################

InstallMethod( IrrelevantLeftIdealForCAP,
               " for toric varieties",
               [ IsFanRep ],
  function( variety )
    local cox_ring, maximal_cones, indeterminates, irrelevant_ideal, i, j;
    
    # extract the necessary information
    cox_ring := CoxRing( variety );
    maximal_cones := RaysInMaximalCones( FanOfVariety( variety ) );
    indeterminates := Indeterminates( cox_ring );
    
    # initialise the list of generators of the irrelvant ideal
    irrelevant_ideal := [ 1 .. Length( maximal_cones ) ];
    
    # and now compute these generators
    for i in [ 1 .. Length( maximal_cones ) ] do
        
        irrelevant_ideal[ i ] := 1;
        
        for j in [ 1 .. Length( maximal_cones[ i ] ) ] do
            
            irrelevant_ideal[ i ] := irrelevant_ideal[ i ] * indeterminates[ j ]^( 1 - maximal_cones[ i ][ j ] );
            
        od;
        
    od;
    
    # irrelevant_ideal is now a list that contains all generators of this ideal
    return GradedLeftSubmoduleForCAP( TransposedMat( [ irrelevant_ideal ] ), cox_ring );
    
end );

InstallMethod( IrrelevantRightIdealForCAP,
               " for toric varieties",
               [ IsFanRep ],
  function( variety )
    local cox_ring, maximal_cones, indeterminates, irrelevant_ideal, i, j;
    
    # extract the necessary information
    cox_ring := CoxRing( variety );
    maximal_cones := RaysInMaximalCones( FanOfVariety( variety ) );
    indeterminates := Indeterminates( cox_ring );
    
    # initialise the list of generators of the irrelvant ideal
    irrelevant_ideal := [ 1 .. Length( maximal_cones ) ];
    
    # and now compute these generators
    for i in [ 1 .. Length( maximal_cones ) ] do

        irrelevant_ideal[ i ] := 1;

        for j in [ 1 .. Length( maximal_cones[ i ] ) ] do

            irrelevant_ideal[ i ] := irrelevant_ideal[ i ] * indeterminates[ j ]^( 1 - maximal_cones[ i ][ j ] );

        od;
        
    od;
    
    # irrelevant_ideal is now a list that contains all generators of this ideal
    return GradedRightSubmoduleForCAP( [ irrelevant_ideal ], cox_ring );
    
end );

InstallMethod( SRLeftIdealForCAP,
               " for toric varieties",
               [ IsToricVariety ],
  function( variety )
    local number, generators_of_the_SR_ideal, rays_in_max_cones, rays_in_max_conesII, i, j, k, l, buffer, tester,
         generator_list, SR_ideal, embedding;
  
    # initialise the variables
    number := Length( RayGenerators( FanOfVariety( variety ) ) );
    generators_of_the_SR_ideal := [];
    rays_in_max_cones := RaysInMaximalCones( FanOfVariety( variety ) );

    # turn the rays_in_max_cones into a list that makes the comparision simpler
    rays_in_max_conesII := List( rays_in_max_cones, x -> Positions( x, 1 ) );

    # iterate over the subsets of [ 1.. number ] that consist of at least 2 elements
    # then keep only those that are not contained in a maximal-cone-set
    for i in [ 2 .. number ] do

      # so get us all subsets that consist of precisely i elements
      buffer := Combinations( [ 1 .. number ], i );
      
      # and iterate over its elements
      for j in [ 1 .. Length( buffer ) ] do

        # now check if these rays form a face of a maximal cone
        tester := true;
        k := 1;
        while tester do
        
          if k > Length( rays_in_max_conesII ) then
          
            tester := false;
        
          elif IsSubsetSet( rays_in_max_conesII[ k ], buffer[ j ] ) then
          
            tester := false;
          
          fi;
          
          k := k + 1;

        od;
        
        # if k = Length( rays_in_max_conesII ) + 2 we add buffer[ j ] to the SR-ideal_generators
        if k = Length( rays_in_max_conesII ) + 2 then
        
          Add( generators_of_the_SR_ideal, buffer[ j ] );
        
        fi;
        
      od;
  
    od;
  
    # now turn all the sets in generators_of_the_SR_ideal into monomials and use them to generate an ideal in the 
    # Cox ring of the variety
    generator_list := List( [ 1 .. Length( generators_of_the_SR_ideal ) ] );
    for i in [ 1 .. Length( generators_of_the_SR_ideal ) ] do
    
      # form a monomial from generators_of_the_SR_ideal[ i ]
      buffer := Indeterminates( CoxRing( variety ) )[ generators_of_the_SR_ideal[ i ][ 1 ] ];
      for j in [ 2 .. Length( generators_of_the_SR_ideal[ i ] ) ] do
      
        buffer := buffer * Indeterminates( CoxRing( variety ) )[ generators_of_the_SR_ideal[ i ][ j ] ];
      
      od;
      
      # then add this monomial to the monomial list
      generator_list[ i ] := buffer;

    od;

    # generator_list contains now all monomials that generate the Stanley-Reißner ideal
    # we have to transpose this list to use it for a graded left-module presentation
    SR_ideal := GradedLeftSubmoduleForCAP( TransposedMat( [ generator_list ] ), CoxRing( variety ) );

    # simplify this presentation
    SR_ideal := GradedStandardModule( LessGradedGenerators( PresentationForCAP( SR_ideal ) ) );

    # and return the ideal
    embedding := EmbeddingInProjectiveObject( SR_ideal );
    return GradedLeftSubmoduleForCAP( UnderlyingMorphism( embedding ) );

end );

InstallMethod( SRRightIdealForCAP,
               " for toric varieties",
               [ IsToricVariety ],
  function( variety )
    local number, generators_of_the_SR_ideal, rays_in_max_cones, rays_in_max_conesII, i, j, k, l, buffer, tester,
         generator_list, SR_ideal, embedding;
  
    # initialise the variables
    number := Length( RayGenerators( FanOfVariety( variety ) ) );
    generators_of_the_SR_ideal := [];
    rays_in_max_cones := RaysInMaximalCones( FanOfVariety( variety ) );
    
    # turn the rays_in_max_cones into a list that makes the comparision simpler
    rays_in_max_conesII := List( rays_in_max_cones, x -> Positions( x, 1 ) );
        
    # iterate over the subsets of [ 1.. number ] that consist of at least 2 elements
    # then keep only those that are not contained in a maximal-cone-set
    for i in [ 2 .. number ] do
    
      # so get us all subsets that consist of precisely i elements
      buffer := Combinations( [ 1 .. number ], i );
      
      # and iterate over its elements
      for j in [ 1 .. Length( buffer ) ] do

        # now check if these rays form a face of a maximal cone
        tester := true;
        k := 1;
        while tester do
        
          if k > Length( rays_in_max_conesII ) then
          
            tester := false;
        
          elif IsSubsetSet( rays_in_max_conesII[ k ], buffer[ j ] ) then
          
            tester := false;
          
          fi;
          
          k := k + 1;

        od;
        
        # if k = Length( rays_in_max_conesII ) + 2 we add buffer[ j ] to the SR-ideal_generators
        if k = Length( rays_in_max_conesII ) + 2 then
        
          Add( generators_of_the_SR_ideal, buffer[ j ] );
        
        fi;
        
      od;
  
    od;
  
    # now turn all the sets in generators_of_the_SR_ideal into monomials and use them to generate an ideal in the 
    # Cox ring of the variety
    generator_list := List( [ 1 .. Length( generators_of_the_SR_ideal ) ] );
    for i in [ 1 .. Length( generators_of_the_SR_ideal ) ] do
    
      # form a monomial from generators_of_the_SR_ideal[ i ]
      buffer := Indeterminates( CoxRing( variety ) )[ generators_of_the_SR_ideal[ i ][ 1 ] ];
      for j in [ 2 .. Length( generators_of_the_SR_ideal[ i ] ) ] do
      
        buffer := buffer * Indeterminates( CoxRing( variety ) )[ generators_of_the_SR_ideal[ i ][ j ] ];
      
      od;
      
      # then add this monomial to the monomial list
      generator_list[ i ] := buffer;

    od;

    # generator_list contains now all monomials that generate the Stanley-Reißner ideal
    # we have to transpose this list to use it for a graded left-module presentation
    SR_ideal := GradedRightSubmoduleForCAP( [ generator_list ], CoxRing( variety ) );

    # simplify this presentation
    SR_ideal := GradedStandardModule( LessGradedGenerators( PresentationForCAP( SR_ideal ) ) );

    # and return the ideal
    embedding := EmbeddingInProjectiveObject( SR_ideal );
    return GradedRightSubmoduleForCAP( UnderlyingMorphism( embedding ) );

end );

# f.p. graded left S-modules category
InstallMethod( SfpgrmodLeft,
               " for toric varieties",
               [ IsToricVariety ],
  function( variety )

    return SfpgrmodLeft( CoxRing( variety ) );

end );

# f.p. graded right S-modules category
InstallMethod( SfpgrmodRight,
               " for toric varieties",
               [ IsToricVariety ],
  function( variety )

    return SfpgrmodRight( CoxRing( variety ) );

end );
