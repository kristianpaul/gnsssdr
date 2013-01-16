function b = db(x,p) 

  // Codage du décimal vers le binaire sur p bits.
  // On passera en paramètre le nombre en base 10(x) que l'on veut
  // coder et l'entier(p) désignant le nombre de bits souhaité.

  b = zeros(1,p);
  if x>=2^p then error('Dimension'); end

  for i = 1:p
    d = x-2^(p-i);
    b(i) = (d>=0)*1;
    x = x-2^(p-i)*b(i);
  end

endfunction

//================================================================//

function table = Table(n,m,x)

  // Cette fonction gére la création de la table contenant les bits
  // de sorties possibles .Elle retourne une matrice de dimension
  // (2^(m-1)=le nombre d'état, 2*n=2*nb de sorties du codeur) .Il
  // faut placer en paramètre le nombre de sorties du codeur, le
  // nombre d'étages du registre et les polynomes générateurs en
  // binaire sous forme de matrice : chaque ligne correspondant à un
  // polynome.

  table = zeros(2^(m-1),2*n);
  E = zeros(2^(m-1),m-1);

  for i = 1:size(table,'r')
    E(i,:) = db(i-1,m-1);
  end
  // E contient tous les états possibles

  for i = 1:size(table,'r'), for j = 1:n
    table(i,j) = modulo([0 E(i,:)]*x(j,:)',2);
    table(i,n+j) = modulo([1 E(i,:)]*x(j,:)',2);
  end, end

endfunction

//================================================================//

// Algorithme de décodage (Viterbi)
function mess = convol_decoder_soft(code,n,m,x)

  // Cette fonction permet de décoder un code en suivant
  // l'algorithme de Viterbi.
  // Il faut pour cela passer en paramètre le mot code en binaire,
  // puis le nombre de sorties (n) du codeur convolutionnel,
  // le nombre d'étages du registre (m) du codeur convolutionnel,
  // et enfin la matrice contenant les polynomes générateurs en
  // binaire(chaque ligne correspondant à un polynome)

  // Test de validité des paramètres
  // Nous ne testons pas si le code est binaire !
  init_encoder(0,n,m,x);

  // Déclaration
  compteur = 1;
  // Fenêtre de décodage : 6 fois la longueur de contrainte
  f = 6*m;
  // L est la longueur du message original avant le codeur
  L = floor(length(code)/n);

  d = zeros(2^(m-1),2);
  // 2^(m-1) est le nombre d'etats
  // La matrice d va stocker à chaque fois les 2^m poids possibles 

  Dist = zeros(2^(m-1),f+1);
  Dist(:,1) = [0;10000*ones(2^(m-1)-1,1)];
  // La matrice Dist va stocker dans chaque colonne le poids des
  // différents états ; ces poids sont retenus à chaque tour de boucle
  // par l'évaluation de la matrice d.

  P = zeros(2^(m-1),f);
  // La matrice P va contenir le numéro de l'état précédent qui a mené
  // à l'état actuel dans la matrice (la position dans une des
  // colonnes de P donne l'état actuel), l'état(00) est noté(1) et
  // ainsi de suite.

  M = zeros(2^(m-1),f-1);
  // M est une matrice "intermédiaire" nécessaire à la réévaluation de
  // P : élimination des chemins qui "s'arrêtent"

  mess = zeros(1,L);

  // construction de matrices utiles pour les calculs de l'algorithme

  Jd = [zeros(f+1,1) eye(f+1,f+1)];
  Jd = Jd(:,1:f+1);
  Jp = [zeros(f,1) eye(f,f)];
  Jp = Jp(:,1:f);
  // Jd et Jp sont les matrices identités décalées d'une colonne vers
  // la droite.

  I = 1:2^(m-1);
  I = matrix(I,2,2^(m-2));
  I = [I I];
  // Par exemple pour m=3 on a I=[1 3 1 3;2 4 2 4] 
  // et pour m=4 I=[1 3 5 7 1 3 5 7;2 4 6 8 2 4 6 8].
  // Cette matrice sert pour retrouver l'état précédent et remplir P

  // Création de la table contenant les bits de sorties possibles.
  table_sortie = Table(n,m,x);

  code_etat = [zeros(1,2^(m-2)) ones(1,2^(m-2))]

  code = [code zeros(1,f*L-length(code))];

  t = size(table_sortie,'r');

  for i = 1:f

    // On compare les bits du code avec les bits de la table.
    for j = 1:2, for k = 1:t,
        diffCode = (code((i-1)*n+1:i*n) - ...
                    table_sortie(k,(j-1)*n+1:j*n));
        d(k,j) = sum(diffCode.^2) + Dist(k,i);
      end
    end

    // Pour chaque état on garde le chemin arrivant le plus petit
    dbis = matrix(d,2,t);
    [Min,ind] = min(dbis,'r');
    Dist(:,i+1) = Min';

    // P contient le numéro de l'état précedent qui a permis d'arriver à l'état présent
    for l = 1:size(Dist,'r')
      P(l,i) = I(ind(l),l);
    end,

  end

  // on élimine les chemins qui "s'arrêtent" au fur et à mesure
  for i = 1:f-1
    for j = 1:size(P,'r')
      if P(j,f-i+1) ~= 0 then
        M(P(j,f-i+1),f-i) = 1;
      end
    end
    P(:,f-i) = P(:,f-i).*M(:,f-i);
  end

  z = 1;
  Z = zeros(z,2);
  // On regarde les positions restantes au début de la fenêtre (6 fois
  // la longueur de contrainte).
  for j = 1:size(P,'r')
    if P(j,1) ~= 0 then
      Z(z,:) = [j Dist(j,2)];
      z = z+1;
    end
  end

  // On garde celui de poids le plus faible.
  [Min,ind] = min(Z(:,2));
  p = ind;

  // Suivant sa position on en déduit le bit du message qui avait été
  // codé.
  mess(compteur) = code_etat(Z(p,1));

  winId  =  waitbar('Décodage séquence');
  ref = round(L/100);

  while compteur<L,

    // On reste dans la boucle tant que le message n'est pas complet

    if modulo(compteur,ref) == 0
      waitbar(round(compteur/L*100)/100,winId);
    end

    M = zeros(2^(m-1),f-1);

    // On décale les matrices Dist et P d'une colonne vers la gauche
    Dist = Dist*Jd';
    P = P*Jp';

    // Puis on calcule les dernieres colonnes de ces 2 matrices

    for j = 1:2,
      for k = 1:t,
        diffCode = (code((f+compteur-1)*n+1:(f+compteur)*n) - ...
                    table_sortie(k,(j-1)*n+1:j*n));
        d(k,j) = sum(diffCode.^2) + Dist(k,f);
      end 
    end

    dbis  = matrix(d,2,t);
    [Min,ind] = min(dbis,'r');
    Dist(:,f+1) = Min';
    
    for l = 1:size(Dist,'r')
      P(l,f) = I(ind(l),l);
    end,

    // On élimine les chemins qui "s'arrêtent"
    for i = 1:f-1
      for j = 1:size(P,'r')
        if P(j,f-i+1) ~= 0 then
          M(P(j,f-i+1),f-i) = 1;
        end
      end
      P(:,f-i) = P(:,f-i).*M(:,f-i);
    end

    // On regarde les positions restantes au début de la fenêtre (6 fois
    // la longueur de contrainte).
    z = 1.
    Z = zeros(z,2);
    for j = 1:size(P,'r')
      if P(j,1) ~= 0 then
        Z(z,:) = [j Dist(j,2)];
        z = z+1;
      end
    end
  
    // On garde celui de poids le plus faible
    [Min,ind] = min(Z(:,2));
    p = ind;

    // Suivant sa position on en déduit le bit du message qui avait été
    // codé.
    mess(compteur+1) = code_etat(Z(p,1));

    // On incrémente le compteur de passage dans la boucle
    compteur = compteur+1;

  end

  winclose(winId);

endfunction

