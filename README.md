# iWalk

iWalk è un'applicazione per iPhone che utilizza il machine learning per prevedere il numero di passi da percorrere in base alle calorie bruciate e al tempo di esercizio. L'app raccoglie dati tramite un Apple Watch e fornisce previsioni per supportare l'utente nel monitoraggio dell'attività fisica.

## Caratteristiche principali

- **Previsione dei passi**: Utilizza un modello di regressione lineare per prevedere il numero di passi in base alle calorie che si vogliono bruciare.
- **Raccolta dati da Apple Watch**: Interagisce con HealthKit per raccogliere i dati relativi alle calorie bruciate, ai minuti di esercizio e ai passi.
- **K-fold Validation**: Utilizza la tecnica di k-fold cross-validation per constatare l'affidabilità delle previsioni.
- **Semplicità d'uso**: Interfaccia utente semplice e intuitiva per visualizzare le previsioni e i dati raccolti.

## Tecnologie utilizzate

- **Swift**: Linguaggio di programmazione utilizzato per sviluppare l'applicazione.
- **Core ML**: Framework per l'integrazione del modello di machine learning nell'app.
- **HealthKit**: API di Apple per l'accesso ai dati sanitari e all'attività fisica tramite l'Apple Watch.
- **GPT-3.5 Turbo**: Utilizzato per ottenere le calorie dei cibi mangiati tramite interazioni con il modello linguistico.

## Funzionamento

1. **Raccolta Dati**: L'app raccoglie dati relativi alle calorie bruciate, ai minuti di esercizio e ai passi tramite Apple Watch e HealthKit.
2. **Generazione del Modello**: Il modello di machine learning è addestrato sui dati reali, più opzionalmente dati sintetici
3. **Previsioni**: L'app fornisce previsioni sui passi che l'utente dovrebbe fare in base alle calorie da bruciare, visualizzando un risultato basato sui dati raccolti.
4. **Integrazione con GPT-3.5**: Quando l'utente inserisce un alimento, GPT-3.5 viene utilizzato per ottenere le calorie relative al cibo e aggiornare i dati.
