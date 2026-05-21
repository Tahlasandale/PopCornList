# 🍿 PopCornList — Charte Graphique & Colorimétrie

L’identité visuelle de PopCornList repose sur un concept simple : **recréer l'expérience de la salle obscure au creux de la main**. L'ambiance générale est sombre (*Dark Mode* par défaut) pour faire ressortir les affiches de films, teintée de touches chaleureuses et gourmandes qui rappellent le pop-corn et les néons des cinémas.

---

## 🎨 La Palette de Couleurs (Design Tokens)

Pour assurer une cohérence absolue dans toute l'application, nous utilisons une palette restreinte de 5 couleurs principales.

| Rôle | Couleur | Code Hex | Utilisation |
| --- | --- | --- | --- |
| **Fond Principal** | Onyx Cinéma | #121214 | Fond de l'application, confort visuel en basse lumière. |
| **Surface** | Gris Projecteur | #1A1A1E | Cartes des films, barres de recherche, menus. |
| **Accent Principal** | Jaune PopCorn | #FFC107 | Boutons d'action, étoiles de notation, éléments actifs. |
| **Accent Secondaire** | Rouge Siège | #E53935 | Boutons de suppression, alertes, badge "Vu". |
| **Texte Principal** | Blanc Écran | #F5F5F7 | Titres, textes importants, contrastes élevés. |
| **Texte Secondaire** | Gris Ticket | #9E9E9E | Synopsis, métadonnées (durée, acteurs), dates. |

---

## 📱 Application de la DA dans l'Interface

Pour que l'application soit harmonieuse, chaque couleur a un rôle strict. **Seigneur Bison**, voici comment ces teintes vont s'articuler sur les écrans de vos utilisateurs :

### 1. Les Écrans de Listes & Navigation

* **Le Fond (#121214) :** Un noir légèrement bleuté/grisé, beaucoup plus doux pour les yeux qu'un noir pur (#000000).
* **Les Cartes de Films (#1A1A1E) :** Elles se détachent subtilement du fond grâce à ce gris très foncé. On y ajoute une légère ombre portée pour donner un effet de profondeur (comme un écran de cinéma qui avance vers le spectateur).

### 2. Le Système de Notation & Filtres

* **Les Étoiles de Note :** Elles utilisent exclusivement le **Jaune PopCorn (#FFC107)**. C'est la couleur de la réussite et du croustillant.
* **Les Badges de Listes :**
* Un film dans la liste *« À regarder »* aura une petite touche de **Jaune PopCorn**.
* Un film basculé dans la liste *« Vu »* arborera un badge **Rouge Siège (#E53935)**, évoquant le velours des fauteuils de cinéma où l'on s'est installé pour le visionner.



### 3. La Recherche et les Zones de Saisie

* **La Barre de Recherche :** Fond en #1A1A1E avec un texte d'explication (ex: *"Rechercher un film, un acteur..."*) en #9E9E9E.
* **Le Texte Saisi :** S'affiche en **Blanc Écran (#F5F5F7)** pour une lisibilité maximale pendant la frappe.

---

## 🌟 Les Règles d'Or du Contraste (Accessibilité)

En tant que développeur de **PopCornList**, il y a deux règles d'or à respecter dans votre code Flutter pour que l'application reste lisible en toutes circonstances :

> **Règle n°1 : Jamais de texte sombre sur fond sombre.**
> Sur le fond Onyx ou les surfaces Gris Projecteur, le texte doit *toujours* être en Blanc Écran (#F5F5F7) pour les titres ou en Gris Ticket (#9E9E9E) pour les détails.

> **Règle n°2 : L'effet "Néon".**
> Le **Jaune PopCorn** et le **Rouge Siège** sont des couleurs très saturées. Utilisez-les avec parcimonie (uniquement sur les boutons, les icônes cliquables ou les éléments sélectionnés). Si l'écran contient trop de jaune ou de rouge, l'utilisateur va fatiguer visuellement.

---

## 🛠️ Traduction en Code (Pour votre projet Flutter)

Lorsque vous créerez votre application, vous pourrez intégrer cette DA directement dans le fichier theme.dart de votre projet sous cette forme :

```dart
final ThemeData popCornListTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121214),
  cardColor: const Color(0xFF1A1A1E),
  primaryColor: const Color(0xFFFFC107),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFFFFC107),     // Jaune PopCorn
    secondary: Color(0xFFE53935),   // Rouge Siège
    surface: Color(0xFF1A1A1E),     // Gris Projecteur
  ),
);

```
