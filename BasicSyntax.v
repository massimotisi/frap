(** Formal Reasoning About Programs <http://adam.chlipala.net/frap/>
  * Chapter 2: Basic Program Syntax
  * Author: Adam Chlipala
  * License: https://creativecommons.org/licenses/by-nc-nd/4.0/ *)

Require Import Frap.


Module ArithWithConstants.

  Inductive arith : Set :=
  | Const (n : nat)
  | Plus (e1 e2 : arith)
  | Times (e1 e2 : arith).

  Example ex1 := Const 42.
  Example ex2 := Plus (Const 1) (Times (Const 2) (Const 3)).

  Fixpoint size (e : arith) : nat :=
    match e with
    | Const _ => 1
    | Plus e1 e2 => 1 + size e1 + size e2
    | Times e1 e2 => 1 + size e1 + size e2
    end.

  Compute size ex1.
  Compute size ex2.

  Fixpoint depth (e : arith) : nat :=
    match e with
    | Const _ => 1
    | Plus e1 e2 => 1 + max (depth e1) (depth e2)
    | Times e1 e2 => 1 + max (depth e1) (depth e2)
    end.

  Compute depth ex1.
  Compute size ex2.

  Theorem depth_le_size : forall e, depth e <= size e.
  Proof.
    induct e.

    simplify.
    linear_arithmetic.

    simplify.
    linear_arithmetic.

    simplify.
    linear_arithmetic.
  Qed.

  Theorem depth_le_size_snazzy : forall e, depth e <= size e.
  Proof.
    induct e; simplify; linear_arithmetic.
  Qed.

  Fixpoint commuter (e : arith) : arith :=
    match e with
    | Const _ => e
    | Plus e1 e2 => Plus (commuter e2) (commuter e1)
    | Times e1 e2 => Times (commuter e2) (commuter e1)
    end.

  Compute commuter ex1.
  Compute commuter ex2.

  Theorem size_commuter : forall e, size (commuter e) = size e.
  Proof.
    induct e; simplify; linear_arithmetic.
  Qed.

  Theorem depth_commuter : forall e, depth (commuter e) = depth e.
  Proof.
    induct e; simplify; linear_arithmetic.
  Qed.

  Theorem commuter_inverse : forall e, commuter (commuter e) = e.
  Proof.
    induct e; simplify; equality.
  Qed.

End ArithWithConstants.

Module ArithWithVariables.

  Inductive arith : Set :=
  | Const (n : nat)
  | Var (x : var)
  | Plus (e1 e2 : arith)
  | Times (e1 e2 : arith).

  Example ex1 := Const 42.
  Example ex2 := Plus (Const 1) (Times (Var "x") (Const 3)).

  Fixpoint size (e : arith) : nat :=
    match e with
    | Const _ => 1
    | Var _ => 1
    | Plus e1 e2 => 1 + size e1 + size e2
    | Times e1 e2 => 1 + size e1 + size e2
    end.

  Compute size ex1.
  Compute size ex2.

  Fixpoint depth (e : arith) : nat :=
    match e with
    | Const _ => 1
    | Var _ => 1
    | Plus e1 e2 => 1 + max (depth e1) (depth e2)
    | Times e1 e2 => 1 + max (depth e1) (depth e2)
    end.

  Compute depth ex1.
  Compute size ex2.

  Theorem depth_le_size : forall e, depth e <= size e.
  Proof.
    induct e; simplify; linear_arithmetic.
  Qed.

  Fixpoint commuter (e : arith) : arith :=
    match e with
    | Const _ => e
    | Var _ => e
    | Plus e1 e2 => Plus (commuter e2) (commuter e1)
    | Times e1 e2 => Times (commuter e2) (commuter e1)
    end.

  Compute commuter ex1.
  Compute commuter ex2.

  Theorem size_commuter : forall e, size (commuter e) = size e.
  Proof.
    induct e; simplify; linear_arithmetic.
  Qed.

  Theorem depth_commuter : forall e, depth (commuter e) = depth e.
  Proof.
    induct e; simplify; linear_arithmetic.
  Qed.

  Theorem commuter_inverse : forall e, commuter (commuter e) = e.
  Proof.
    induct e; simplify; equality.
  Qed.

  Fixpoint substitute (inThis : arith) (replaceThis : var) (withThis : arith) : arith :=
    match inThis with
    | Const _ => inThis
    | Var x => if x ==v replaceThis then withThis else inThis
    | Plus e1 e2 => Plus (substitute e1 replaceThis withThis) (substitute e2 replaceThis withThis)
    | Times e1 e2 => Times (substitute e1 replaceThis withThis) (substitute e2 replaceThis withThis)
    end.

  Theorem substitute_depth : forall replaceThis withThis inThis,
    depth (substitute inThis replaceThis withThis) <= depth inThis + depth withThis.
  Proof.
    induct inThis.

    simplify.
    linear_arithmetic.

    simplify.
    cases (x ==v replaceThis).
    linear_arithmetic.
    simplify.
    linear_arithmetic.

    simplify.
    linear_arithmetic.

    simplify.
    linear_arithmetic.
  Qed.

  Theorem substitute_depth_snazzy : forall replaceThis withThis inThis,
    depth (substitute inThis replaceThis withThis) <= depth inThis + depth withThis.
  Proof.
    induct inThis; simplify;
    try match goal with
        | [ |- context[if ?a ==v ?b then _ else _] ] => cases (a ==v b); simplify
        end; linear_arithmetic.
  Qed.

  Theorem substitute_self : forall replaceThis inThis,
    substitute inThis replaceThis (Var replaceThis) = inThis.
  Proof.
    induct inThis; simplify;
    try match goal with
        | [ |- context[if ?a ==v ?b then _ else _] ] => cases (a ==v b); simplify
        end; equality.
  Qed.

  Theorem substitute_commuter : forall replaceThis withThis inThis,
    commuter (substitute inThis replaceThis withThis)
    = substitute (commuter inThis) replaceThis (commuter withThis).
  Proof.
    induct inThis; simplify;
    try match goal with
        | [ |- context[if ?a ==v ?b then _ else _] ] => cases (a ==v b); simplify
        end; equality.
  Qed.

  Fixpoint constantFold (e : arith) : arith :=
    match e with
    | Const _ => e
    | Var _ => e
    | Plus e1 e2 =>
      let e1' := constantFold e1 in
      let e2' := constantFold e2 in
      match e1', e2' with
      | Const n1, Const n2 => Const (n1 + n2)
      | Const 0, _ => e2'
      | _, Const 0 => e1'
      | _, _ => Plus e1' e2'
      end
    | Times e1 e2 =>
      let e1' := constantFold e1 in
      let e2' := constantFold e2 in
      match e1', e2' with
      | Const n1, Const n2 => Const (n1 * n2)
      | Const 1, _ => e2'
      | _, Const 1 => e1'
      | Const 0, _ => Const 0
      | _, Const 0 => Const 0
      | _, _ => Times e1' e2'
      end
    end.

  Theorem size_constantFold : forall e, size (constantFold e) <= size e.
  Proof.
    induct e; simplify;
    repeat match goal with
           | [ |- context[match ?E with _ => _ end] ] => cases E; simplify
           end; linear_arithmetic.
  Qed.

  Theorem commuter_constantFold : forall e, commuter (constantFold e) = constantFold (commuter e).
  Proof.
    induct e; simplify;
    repeat match goal with
           | [ |- context[match ?E with _ => _ end] ] => cases E; simplify
           | [ H : ?f _ = ?f _ |- _ ] => invert H
           | [ |- ?f _ = ?f _ ] => f_equal
           end; equality || linear_arithmetic || ring.
  Qed.

  Definition isConst (e : arith) : option nat :=
    match e with
    | Const n => Some n
    | _ => None
    end.

  Fixpoint pushMultiplicationInside' (multiplyBy : nat) (e : arith) : arith :=
    match e with
    | Const n => Const (multiplyBy * n)
    | Var _ => Times (Const multiplyBy) e
    | Plus e1 e2 => Plus (pushMultiplicationInside' multiplyBy e1)
                         (pushMultiplicationInside' multiplyBy e2)
    | Times e1 e2 =>
      match isConst e1 with
      | Some k => pushMultiplicationInside' (k * multiplyBy) e2
      | None => Times (pushMultiplicationInside' multiplyBy e1) e2
      end
    end.

  Definition pushMultiplicationInside (e : arith) : arith :=
    pushMultiplicationInside' 1 e.

  Lemma n_times_0 : forall n, n * 0 = 0.
  Proof.
    linear_arithmetic.
  Qed.

  Lemma depth_pushMultiplicationInside'_irrelevance0 : forall e multiplyBy,
    depth (pushMultiplicationInside' multiplyBy e)
    = depth (pushMultiplicationInside' 0 e).
  Proof.
    induct e; simplify.

    linear_arithmetic.

    linear_arithmetic.

    rewrite IHe1.
    rewrite IHe2.
    linear_arithmetic.

    cases (isConst e1); simplify.

    rewrite IHe2.
    rewrite n_times_0.
    linear_arithmetic.

    rewrite IHe1.
    linear_arithmetic.
  Qed.

  Lemma depth_pushMultiplicationInside'_irrelevance0_snazzy : forall e multiplyBy,
    depth (pushMultiplicationInside' multiplyBy e)
    = depth (pushMultiplicationInside' 0 e).
  Proof.
    induct e; simplify;
    try match goal with
        | [ |- context[match ?E with _ => _ end] ] => cases E; simplify
        end; equality.
  Qed.

  Lemma depth_pushMultiplicationInside'_irrelevance : forall e multiplyBy1 multiplyBy2,
    depth (pushMultiplicationInside' multiplyBy1 e)
    = depth (pushMultiplicationInside' multiplyBy2 e).
  Proof.
    intros.
    transitivity (depth (pushMultiplicationInside' 0 e)).
    apply depth_pushMultiplicationInside'_irrelevance0.
    symmetry.
    apply depth_pushMultiplicationInside'_irrelevance0.
  Qed.

  Lemma depth_pushMultiplicationInside' : forall e,
    depth (pushMultiplicationInside' 0 e) <= S (depth e).
  Proof.
    induct e; simplify.

    linear_arithmetic.

    linear_arithmetic.

    linear_arithmetic.

    cases (isConst e1); simplify.

    rewrite n_times_0.
    linear_arithmetic.

    linear_arithmetic.
  Qed.

  Hint Rewrite n_times_0.

  Lemma depth_pushMultiplicationInside'_snazzy : forall e,
    depth (pushMultiplicationInside' 0 e) <= S (depth e).
  Proof.
    induct e; simplify;
    try match goal with
        | [ |- context[match ?E with _ => _ end] ] => cases E; simplify
        end; linear_arithmetic.
  Qed.

  Theorem depth_pushMultiplicationInside : forall e,
    depth (pushMultiplicationInside e) <= S (depth e).
  Proof.
    simplify.
    unfold pushMultiplicationInside.
    rewrite depth_pushMultiplicationInside'_irrelevance0.
    apply depth_pushMultiplicationInside'.
  Qed.

End ArithWithVariables.
