function [n,m,X] = init_encoder(mess,nb_sortie,nb_etage,Gen)

  // Cette fonction est une simple fonction de test de validité des
  // paramètres.

  n = nb_sortie;
  m = nb_etage;
  X = Gen;

  if size(X) ~= [n m] 
    error('Erreur de dimension des codes générateurs');
  end

  if (sum(X>1 | X<0)>0) then
    error ('Le code générateur doit être en binaire');
  end

  if (sum(mess>1 | mess<0)>0) then
    error ('Le message doit être en binaire');
  end

endfunction

//================================================================//

function code = convol_encoder(mess,nb_sortie,nb_etage,Gen)

// Cette fonction permet de coder un message en utilisant le codeur
// convolutionnel. Il faut pour cela passer en paramètre le message à
// coder en binaire, puis le nombre de sorties (n) du codeur
// convolutionnel, le nombre d'étages du registre (m) du codeur
// convolutionnel, et enfin la matrice contenant les polynomes
// générateurs en binaire (chaque ligne correspondant à un polynome).

// Schéma d'un codeur
//
//
//
//
//          entrée         _ _ _     _ _         sorties
//				1    ---->|_|_|_|...|_|_|----> n
//				    		  m étages      
// Le codeur possède n sommateurs de type ou exclusif qui donnent les
// n bits de sorties.
//

  // Test de validité des paramètres
  [n,m,X] = init_encoder(mess,nb_sortie,nb_etage,Gen);

  l = length(mess);
  code = zeros(1,(l+m-1)*n);
  W = zeros(n,l+m-1);

  for i = 1:n
    W(i,:) = modulo(round(convol(mess,X(i,:))),2);
  end
  code = W(:)';

endfunction

