# 🔄 Guide pour Réinitialiser l'État Premium

## 📋 Méthodes pour Remettre `hasPremiumPack` à false

### Méthode 1 : Via le Code (Recommandé pour le développement)

#### Option A : Bouton de réinitialisation (DÉJÀ IMPLÉMENTÉ)

Le bouton de réinitialisation est **déjà présent** dans l'interface ! 

**Fonctionnement :**
- Le bouton "Réinitialiser Premium" apparaît automatiquement quand `hasPremiumPack` est true
- Il appelle la méthode `resetPremiumStatus()` qui :
  - Met `hasPremiumPack` à false
  - Met UserDefaults à false
  - Appelle `storeManager.resetPremiumForTesting()`
  - Affiche un message de confirmation

**Utilisation :**
1. Activer le pack premium via le bouton "Pack Premium"
2. Le bouton "Réinitialiser Premium" apparaît automatiquement
3. Cliquer dessus pour réinitialiser l'état premium

#### Option B : Méthode temporaire dans StoreManager

Modifiez temporairement `StoreManager.swift` :

```swift
// Dans StoreManager.swift, ajouter cette méthode :
func resetPremiumForTesting() {
    UserDefaults.standard.set(false, forKey: "hasPremiumPack")
    purchasedProductIDs.remove(premiumProductID)
    print("🔄 Premium réinitialisé pour les tests")
}
```

Puis appelez-la depuis la console Xcode :
```swift
// Dans la console Xcode :
po StoreManager().resetPremiumForTesting()
```

---

### Méthode 2 : Via la Console Xcode (Direct)

Dans Xcode, pendant l'exécution de l'application :

1. **Mettre l'application en pause** (bouton pause dans la barre de debug)
2. **Ouvrir la console** (View → Debug Area → Activate Console)
3. **Taper cette commande** :
```swift
UserDefaults.standard.set(false, forKey: "hasPremiumPack")
```
4. **Redémarrer l'application** pour voir les changements

---

### Méthode 3 : Via les Paramètres du Simulateur

1. **Ouvrir l'application Settings** dans le simulateur
2. **Aller dans** Settings → Developer
3. **Scroller vers le bas** et trouver "Reset Content and Settings"
4. **Confirmer la réinitialisation** (⚠️ Cela efface TOUTES les données)

---

### Méthode 4 : Supprimer l'Application

1. **Maintenir appuyé** sur l'icône de l'application dans le simulateur
2. **Sélectionner "Remove App"**
3. **Confirmer "Delete App"**
4. **Relancer depuis Xcode**

---

### Méthode 5 : Code de Réinitialisation Automatique

Pour les tests, vous pouvez ajouter ce code dans `MazeViewModel.swift` dans `init()` :

```swift
init() {
    // Pour les tests - réinitialiser automatiquement
    #if DEBUG
    UserDefaults.standard.set(false, forKey: "hasPremiumPack")
    #endif
    
    checkPremiumStatus()
    resetPlayer()
    // ... reste du code
}
```

---

## 🔧 Vérification de l'État

Pour vérifier que la réinitialisation a fonctionné :

### Dans la console Xcode :
```swift
// Vérifier l'état actuel
po UserDefaults.standard.bool(forKey: "hasPremiumPack")
// Doit retourner false

// Vérifier dans le ViewModel
po vm.hasPremiumPack
// Doit retourner false
```

### Dans l'interface :
- L'indicateur couronne doit avoir disparu
- Le bouton "Pack Premium" doit être visible
- La solution ne doit pas s'afficher après échec

---

## 🎯 Méthode Recommandée pour le Développement

**Option A (Bouton de réinitialisation)** est la meilleure car :
- ✅ Rapide et facile à utiliser
- ✅ Pas besoin de recompiler
- ✅ Visible dans l'interface
- ✅ Sécurisé (uniquement en développement)

---

## ⚠️ Important

- **En production** : Retirer le bouton de réinitialisation
- **Tests StoreKit réels** : Utiliser les comptes sandbox Apple
- **Données utilisateur** : La réinitialisation efface l'état premium mais pas les autres données

**La réinitialisation est maintenant facile à effectuer !** 🔄
