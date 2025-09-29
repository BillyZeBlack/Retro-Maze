# 🧪 Guide de Test - Fonctionnalité Premium "Solution après échec"

## 📋 Prérequis

- Xcode 15+
- iOS Simulator ou appareil iOS 15+
- Projet Retro Maze ouvert dans Xcode

## 🎯 Scénarios de Test

### 1. **Test Utilisateur Standard (Sans Premium)**

#### Étapes :
1. **Lancer l'application** dans le simulateur
2. **Observer l'interface** :
   - Pas d'indicateur premium (couronne) dans l'en-tête
   - Bouton "Pack Premium" visible dans les contrôles
3. **Jouer normalement** jusqu'à échec (laisser le temps s'écouler)
4. **Vérifier le comportement** :
   - ❌ La solution NE s'affiche PAS après l'échec
   - Le jeu se réinitialise normalement après 2 secondes

#### Résultat attendu :
- Comportement normal sans fonctionnalité premium

---

### 2. **Test Utilisateur Premium (Avec Achat)**

#### Méthode 1 : Simulation d'achat (Recommandé pour le test)

**Modifier temporairement StoreManager.swift** pour simuler un achat réussi :

```swift
// Dans StoreManager.swift, modifier la méthode purchasePremiumPack() :
func purchasePremiumPack() async -> Bool {
    // Simulation d'achat réussi
    UserDefaults.standard.set(true, forKey: "hasPremiumPack")
    purchasedProductIDs.insert(premiumProductID)
    return true
    
    /* Code original commenté :
    guard let premiumProduct = products.first(where: { $0.id == premiumProductID }) else {
        return false
    }
    
    do {
        let transaction = try await purchase(premiumProduct)
        return transaction != nil
    } catch {
        print("Purchase failed: \(error)")
        return false
    }
    */
}
```

#### Étapes de test :
1. **Lancer l'application**
2. **Activer le pack premium** :
   - Cliquer sur le bouton "Pack Premium"
   - L'indicateur couronne doit apparaître dans l'en-tête
3. **Jouer jusqu'à échec** (laisser le temps s'écouler)
4. **Observer la fonctionnalité premium** :
   - ✅ La solution s'affiche automatiquement pendant 15 secondes
   - ✅ L'indicateur "Solution: Xs" apparaît avec compte à rebours
   - ✅ Le toggle "Solution" est désactivé pendant l'affichage
   - ✅ Après 15s, tout revient à la normale

#### Résultat attendu :
- Fonctionnalité premium active et fonctionnelle

---

### 3. **Test de Persistance**

#### Étapes :
1. **Activer le pack premium** (via le bouton)
2. **Fermer complètement l'application** (swipe up dans le simulateur)
3. **Relancer l'application**
4. **Vérifier** :
   - ✅ L'indicateur premium (couronne) est toujours présent
   - ✅ La fonctionnalité reste active après redémarrage

---

### 4. **Test Mode Sombre/Clair**

#### Étapes :
1. **Activer le pack premium**
2. **Basculer entre mode sombre et clair** (Settings > Developer > Toggle Appearance)
3. **Vérifier** :
   - ✅ Les couleurs premium s'adaptent correctement
   - ✅ L'interface reste lisible dans les deux modes

---

## 🔧 Tests Techniques Avancés

### Test des États du ViewModel

Dans Xcode, ajouter ces points d'arrêt pour vérifier les états :

```swift
// Dans MazeViewModel.swift
// Point d'arrêt dans handleTimeout()
print("🔔 Timeout - Premium: \(hasPremiumPack)")

// Point d'arrêt dans showSolutionAfterTimeout()
print("🎯 Solution affichée - Timer: \(solutionTimer)")

// Point d'arrêt dans hideSolution()
print("🔚 Solution masquée")
```

### Vérification des Données Utilisateur

Dans la console Xcode, vérifier :
```swift
// Taper dans la console :
po UserDefaults.standard.bool(forKey: "hasPremiumPack")
// Doit retourner true si premium activé
```

---

## 🐛 Dépannage des Problèmes Courants

### Problème : "La solution ne s'affiche pas"
**Solutions :**
1. Vérifier que `hasPremiumPack` est true
2. Vérifier que `showSolutionAfterFailure` est true après timeout
3. Vérifier la console pour les erreurs

### Problème : "Bouton premium ne fonctionne pas"
**Solutions :**
1. Vérifier la connexion StoreManager
2. Vérifier que la méthode `activatePremiumPack()` est appelée
3. Vérifier les logs de console

### Problème : "Compte à rebours ne fonctionne pas"
**Solutions :**
1. Vérifier que `tick()` est appelé régulièrement
2. Vérifier que `solutionTimer` décroît correctement

---

## ✅ Checklist de Validation

- [ ] Utilisateur standard : Pas de solution après échec
- [ ] Utilisateur premium : Solution affichée 15s après échec
- [ ] Indicateur premium visible dans l'en-tête
- [ ] Bouton d'achat fonctionnel
- [ ] Compte à rebours actif et visible
- [ ] Persistance après redémarrage
- [ ] Support mode sombre/clair
- [ ] Pas d'erreurs de compilation
- [ ] Performance fluide

---

## 📝 Notes Importantes

- **Environnement de production** : Retirer la simulation d'achat avant publication
- **StoreKit Configuration** : Configurer les produits dans App Store Connect pour les tests réels
- **Sandbox Tester** : Utiliser un compte sandbox pour tester les achats réels

**La fonctionnalité est maintenant prête pour les tests complets !** 🎉
