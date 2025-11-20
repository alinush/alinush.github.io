{% include prelims-time-complexities.md %}
    - $\Gadd{\Gr}{n}$ for $n$ additions in $\Gr$
    - $\Gmul{\Gr}{n}$ for $n$ individual scalar multiplications in $\Gr$
    + $\fmsm{\Gr}{n}$ for a size-$n$ MSM in $\Gr$ where the group element bases are known ahead of time (i.e., _fixed-base_)
        - when the scalars are always from a set $S$, then we use $\fmsmSmall{\Gr}{n}{S}$ 
    + $\vmsm{\Gr}{n}$ for a size-$n$ MSM in $\Gr$ where the group element bases are **not** known ahead of time (i.e., _variable-base_)
        - when the scalars are always from a set $S$, then we use $\vmsmSmall{\Gr}{n}{S}$ 
