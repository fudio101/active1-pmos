import importlib
for mod in ("cryptography", "Crypto"):
    try:
        m = importlib.import_module(mod)
        print("OK", mod, getattr(m, "__version__", "?"))
    except Exception as e:
        print("NO", mod, type(e).__name__)
