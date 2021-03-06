type field  = Rfc5322.trace

type word = Rfc822.word
type local = Rfc822.local
type phrase = Rfc5322.phrase

type literal_domain = Rfc5321.literal_domain =
  | IPv4 of Ipaddr.V4.t
  | IPv6 of Ipaddr.V6.t
  | Ext of string * string

type domain = Rfc5322.domain

type mailbox = Rfc5322.mailbox =
  { name : phrase option
  ; local : local
  ; domain : domain * domain list }

type t =
  { index : Number.t
  ; trace : mailbox option
  ; received : (received list * Date.t option) list
  ; location : Location.t }
and received =
  [ `Addr of mailbox
  | `Domain of domain
  | `Word of word ]

let location { location; _ } = location

let pp_trace ppf (local, (x, r)) = match r with
  | [] ->
    Fmt.pf ppf "{ @[<hov>local = %a;@ domain = %a@] }"
      Mailbox.pp_local local Mailbox.pp_domain x
  | domains ->
    Fmt.pf ppf "{ @[<hov>local = %a;@ domains = %a@] }"
      Mailbox.pp_local local
      Fmt.(hvbox (Dump.list Mailbox.pp_domain)) (x :: domains)

let pp_trace = Fmt.using (fun { local; domain; _} -> local, domain) pp_trace

let pp_received ppf = function
  | `Addr v -> Fmt.pf ppf "(`Addr %a)" (Fmt.hvbox pp_trace) v
  | `Domain v -> Fmt.pf ppf "(`Domain %a)" (Fmt.hvbox Mailbox.pp_domain) v
  | `Word v -> Fmt.pf ppf "(`Word %a)" (Fmt.hvbox Mailbox.pp_word) v

let pp_received ppf = function
  | received, Some date ->
    Fmt.pf ppf "{ @[<hov>received = %a;@ date = %a;@] }"
      Fmt.(Dump.list pp_received) received
      Date.pp date
  | received, None ->
    Fmt.pf ppf "{ @[<hov>received = %a;@] }"
      Fmt.(Dump.list pp_received) received

let pp ppf = function
  | { trace= Some trace; received; _ } ->
    Fmt.pf ppf "{ @[<hov>trace = %a;@ received = %a;@] }"
      pp_trace trace
      Fmt.(vbox (list ~sep:(always "@\n&@ ") pp_received)) received
  | { received; _ } ->
    Fmt.pf ppf "{ @[<hov>received = %a;@] }"
      Fmt.(vbox (list ~sep:(always "@\n&@ ") pp_received)) received

let fold : (Number.t * ([> field ] as 'a) * Location.t) list -> t list -> (t list * (Number.t * 'a * Location.t) list) = fun fields t ->
  List.fold_left
    (fun (t, rest) -> function
       | index, `Trace (trace, received), loc -> { index; trace; received; location= loc; } :: t, rest
       | index, field, loc -> t, (index, field, loc) :: rest)
    (t, []) fields
  |> fun (t, fields) -> t, List.rev fields
