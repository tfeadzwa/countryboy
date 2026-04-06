# Folder Structure Setup Script

This script creates the complete folder structure for the Countryboy Conductor mobile app following Clean Architecture principles.

## 🚀 Quick Setup

### Option 1: Manual Creation (Cross-platform)

Create the following folders manually in your IDE or file explorer:

```
mobile/lib/
├── core/
│   ├── config/
│   ├── network/
│   ├── storage/
│   ├── errors/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── trips/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── tickets/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── sync/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   └── dashboard/
│       └── presentation/
│           ├── screens/
│           └── widgets/
└── shared/
    ├── widgets/
    └── extensions/
```

### Option 2: Bash Script (Mac/Linux/Git Bash)

Create a file `setup_folders.sh`:

```bash
#!/bin/bash

# Navigate to mobile/lib
cd "$(dirname "$0")/lib"

# Core folders
mkdir -p core/{config,network,storage,errors,utils}

# Auth feature
mkdir -p features/auth/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

# Trips feature
mkdir -p features/trips/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

# Tickets feature  
mkdir -p features/tickets/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

# Sync feature
mkdir -p features/sync/{data/{models,datasources,repositories},domain/{entities,repositories,usecases},presentation/{providers,screens,widgets}}

# Dashboard feature
mkdir -p features/dashboard/presentation/{screens,widgets}

# Shared
mkdir -p shared/{widgets,extensions}

echo "✅ Folder structure created successfully!"
echo "📂 Check mobile/lib for the new structure"
```

Run it:
```bash
chmod +x setup_folders.sh
./setup_folders.sh
```

### Option 3: PowerShell Script (Windows)

Create a file `setup_folders.ps1`:

```powershell
# Navigate to mobile/lib
Set-Location -Path "$PSScriptRoot\lib"

# Core folders
New-Item -ItemType Directory -Force -Path "core\config"
New-Item -ItemType Directory -Force -Path "core\network"
New-Item -ItemType Directory -Force -Path "core\storage"
New-Item -ItemType Directory -Force -Path "core\errors"
New-Item -ItemType Directory -Force -Path "core\utils"

# Auth feature
$authPaths = @(
    "features\auth\data\models",
    "features\auth\data\datasources",
    "features\auth\data\repositories",
    "features\auth\domain\entities",
    "features\auth\domain\repositories",
    "features\auth\domain\usecases",
    "features\auth\presentation\providers",
    "features\auth\presentation\screens",
    "features\auth\presentation\widgets"
)
$authPaths | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ }

# Trips feature
$tripsPaths = @(
    "features\trips\data\models",
    "features\trips\data\datasources",
    "features\trips\data\repositories",
    "features\trips\domain\entities",
    "features\trips\domain\repositories",
    "features\trips\domain\usecases",
    "features\trips\presentation\providers",
    "features\trips\presentation\screens",
    "features\trips\presentation\widgets"
)
$tripsPaths | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ }

# Tickets feature
$ticketsPaths = @(
    "features\tickets\data\models",
    "features\tickets\data\datasources",
    "features\tickets\data\repositories",
    "features\tickets\domain\entities",
    "features\tickets\domain\repositories",
    "features\tickets\domain\usecases",
    "features\tickets\presentation\providers",
    "features\tickets\presentation\screens",
    "features\tickets\presentation\widgets"
)
$ticketsPaths | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ }

# Sync feature
$syncPaths = @(
    "features\sync\data\models",
    "features\sync\data\datasources",
    "features\sync\data\repositories",
    "features\sync\domain\entities",
    "features\sync\domain\repositories",
    "features\sync\domain\usecases",
    "features\sync\presentation\providers",
    "features\sync\presentation\screens",
    "features\sync\presentation\widgets"
)
$syncPaths | ForEach-Object { New-Item -ItemType Directory -Force -Path $_ }

# Dashboard feature
New-Item -ItemType Directory -Force -Path "features\dashboard\presentation\screens"
New-Item -ItemType Directory -Force -Path "features\dashboard\presentation\widgets"

# Shared
New-Item -ItemType Directory -Force -Path "shared\widgets"
New-Item -ItemType Directory -Force -Path "shared\extensions"

Write-Host "✅ Folder structure created successfully!" -ForegroundColor Green
Write-Host "📂 Check mobile/lib for the new structure" -ForegroundColor Cyan
```

Run it:
```powershell
.\setup_folders.ps1
```

### Option 4: Node.js Script (Cross-platform)

Create a file `setup_folders.js` in the mobile directory:

```javascript
const fs = require('fs');
const path = require('path');

const folders = [
  // Core
  'lib/core/config',
  'lib/core/network',
  'lib/core/storage',
  'lib/core/errors',
  'lib/core/utils',
  
  // Auth feature
  'lib/features/auth/data/models',
  'lib/features/auth/data/datasources',
  'lib/features/auth/data/repositories',
  'lib/features/auth/domain/entities',
  'lib/features/auth/domain/repositories',
  'lib/features/auth/domain/usecases',
  'lib/features/auth/presentation/providers',
  'lib/features/auth/presentation/screens',
  'lib/features/auth/presentation/widgets',
  
  // Trips feature
  'lib/features/trips/data/models',
  'lib/features/trips/data/datasources',
  'lib/features/trips/data/repositories',
  'lib/features/trips/domain/entities',
  'lib/features/trips/domain/repositories',
  'lib/features/trips/domain/usecases',
  'lib/features/trips/presentation/providers',
  'lib/features/trips/presentation/screens',
  'lib/features/trips/presentation/widgets',
  
  // Tickets feature
  'lib/features/tickets/data/models',
  'lib/features/tickets/data/datasources',
  'lib/features/tickets/data/repositories',
  'lib/features/tickets/domain/entities',
  'lib/features/tickets/domain/repositories',
  'lib/features/tickets/domain/usecases',
  'lib/features/tickets/presentation/providers',
  'lib/features/tickets/presentation/screens',
  'lib/features/tickets/presentation/widgets',
  
  // Sync feature
  'lib/features/sync/data/models',
  'lib/features/sync/data/datasources',
  'lib/features/sync/data/repositories',
  'lib/features/sync/domain/entities',
  'lib/features/sync/domain/repositories',
  'lib/features/sync/domain/usecases',
  'lib/features/sync/presentation/providers',
  'lib/features/sync/presentation/screens',
  'lib/features/sync/presentation/widgets',
  
  // Dashboard feature
  'lib/features/dashboard/presentation/screens',
  'lib/features/dashboard/presentation/widgets',
  
  // Shared
  'lib/shared/widgets',
  'lib/shared/extensions',
];

folders.forEach(folder => {
  const fullPath = path.join(__dirname, folder);
  fs.mkdirSync(fullPath, { recursive: true });
});

console.log('✅ Folder structure created successfully!');
console.log('📂 Check mobile/lib for the new structure');
```

Run it:
```bash
node setup_folders.js
```

---

## 📋 Verification

After running any of the above scripts, verify the structure:

```bash
# Mac/Linux
tree lib -L 4

# Windows PowerShell
tree /F lib

# Or use VS Code file explorer
```

You should see all the folders listed in Option 1.

---

## 📝 Creating Placeholder Files

To help with navigation, you can create `.gitkeep` files in empty folders:

### Bash/PowerShell
```bash
# Find all empty directories and add .gitkeep
find lib -type d -empty -exec touch {}/.gitkeep \;
```

### Manually
Create a file named `.gitkeep` in each empty folder to ensure they're tracked by Git.

---

## ✅ Next Steps

After creating the folder structure:

1. **Verify creation**: Check that all folders exist
2. **Update pubspec.yaml**: Add required dependencies
3. **Run flutter pub get**: Install dependencies
4. **Start coding**: Begin with Phase 1 (Foundation)

---

## 🎯 Folder Purpose Reference

### Core Layer
- `config/` - Environment variables, theme, constants
- `network/` - API client, interceptors
- `storage/` - Database, secure storage, shared prefs
- `errors/` - Exception classes, failure types
- `utils/` - Helpers, formatters, validators

### Feature Layer (Clean Architecture)
Each feature follows the same structure:

- `data/` - External data handling
  - `models/` - JSON serialization (DTOs)
  - `datasources/` - API calls, local queries
  - `repositories/` - Implementation of domain contracts

- `domain/` - Business logic
  - `entities/` - Core business objects
  - `repositories/` - Abstract contracts
  - `usecases/` - Business use cases

- `presentation/` - UI layer
  - `providers/` - State management (Riverpod)
  - `screens/` - Full-page widgets
  - `widgets/` - Reusable components

### Shared Layer
- `widgets/` - Common UI components (buttons, cards, etc.)
- `extensions/` - Dart extension methods

---

## 📚 Additional Resources

- [Clean Architecture Guide](https://resocoder.com/flutter-clean-architecture-tdd/)
- [Feature-First Structure](https://codewithandrea.com/articles/flutter-project-structure/)
- [Implementation Plan](./IMPLEMENTATION_PLAN.md)

---

**Ready to create your structure?** Choose your preferred option above and run it! 🚀
