import hashlib, hmac, secrets

KEY = secrets.token_bytes(32)  

def mac(tag, *parts):
    m = hashlib.sha256()
    m.update(tag)
    for p in parts:
        m.update(p)
    m.update(KEY)
    return m.digest()

def node(tag, children=()):
    c = b"".join(children)
    m = mac(tag, c)
    label = hashlib.sha256(tag + c + m).digest()
    STORE[label] = (tag, children, m)
    return label

T_S, T_K, T_APP = b"S", b"K", b"A"

STORE = {}

S = node(T_S)
K = node(T_K)

def app(f, x):
    return node(T_APP, (f, x))

def verify(label):
    tag, children, m = STORE[label]
    c = b"".join(children)
    assert hmac.compare_digest(m, mac(tag, c)), "MAC FORGERY!"
    assert hashlib.sha256(tag + c + m).digest() == label, "HASH MISMATCH!"

def reduce(label, arg=None):
    tag, children, _ = STORE[label]
    if tag != T_APP:
        return label

    verify(label)
    f, x = children
    f_tag, f_children, _ = STORE[f]

    if f_tag == T_APP:
        verify(f)
        f_head, f_arg = f_children
        f_head_tag, f_head_children, _ = STORE[f_head]

        if f_head_tag == T_K:
            return f_arg  # (K a) x → a

        if f_head_tag == T_APP:
            verify(f_head)
            s_head, g = f_head_children
            if STORE[s_head][0] == T_S:
                h = f_arg
                fx = app(g, x)
                hx = app(h, x)
                return app(fx, hx)  # ((S g) h) x -> (g x) (h x)

    return label  # no reduction

# evaluate (S K K) x -> x

x = node(b"X", (b"value",))     # arbitrary atom
term = app(app(app(S, K), K), x)

print("Initial label:", term.hex()[:16], "...")

cur = term
for i in range(4):
    nxt = reduce(cur)
    if nxt == cur: break
    print(f"Step {i}: {cur.hex()[:16]} -> {nxt.hex()[:16]}")
    cur = nxt

print("\nFinal result is x:", cur == x)
