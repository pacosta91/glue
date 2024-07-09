function correctedConcArray = correctedConc(concArray, refzero, refspan, prezero, prespan, postzero, postspan) 

    correctedConcArray = refzero + (refspan - refzero) * (2 .* concArray - (prezero + postzero)) / (prespan + postspan - prezero - postzero);
    
end