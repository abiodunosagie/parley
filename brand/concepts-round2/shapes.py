import math
def bubble(cx, cy, r, tail, spread=30, reach=1.0, at=None):
    """Circle speech bubble. Tail wedge leaves the circle between two angles and points
    down-left or down-right."""
    mid = at if at is not None else (143 if tail == 'left' else 37)
    a1, a2 = math.radians(mid - spread/2), math.radians(mid + spread/2)
    tip_ang = math.radians(mid)
    tip = (cx + r*1.45*reach*math.cos(tip_ang), cy + r*1.45*reach*math.sin(tip_ang))
    p1 = (cx + r*math.cos(a1), cy + r*math.sin(a1)); p2 = (cx + r*math.cos(a2), cy + r*math.sin(a2))
    return (f"M{p2[0]:.2f},{p2[1]:.2f} A{r},{r} 0 1 1 {p1[0]:.2f},{p1[1]:.2f} "
            f"L{tip[0]:.2f},{tip[1]:.2f} Z")
