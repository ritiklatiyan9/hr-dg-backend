import {
  GraphQLError,
  Kind,
  type SelectionSetNode,
  type ValidationRule,
} from "graphql";

// Charge fragment expansion and aliases, not merely nodes in the source AST.
// Saturate early: hostile repeated spreads cannot themselves consume unbounded CPU.
export const boundedQuery: ValidationRule = (context) => ({
  OperationDefinition(node) {
    let cost = 0;
    const walk = (set: SelectionSetNode, depth: number, seen: Set<string>) => {
      if (cost > 150) return;
      if (depth > 8) {
        cost = 151;
        return;
      }
      for (const part of set.selections) {
        if (++cost > 150) return;
        if (part.kind === Kind.FIELD && part.selectionSet)
          walk(part.selectionSet, depth + 1, seen);
        else if (part.kind === Kind.INLINE_FRAGMENT)
          walk(part.selectionSet, depth, seen);
        else if (part.kind === Kind.FRAGMENT_SPREAD) {
          if (seen.has(part.name.value)) {
            cost = 151;
            return;
          }
          const fragment = context.getFragment(part.name.value);
          if (fragment)
            walk(
              fragment.selectionSet,
              depth,
              new Set([...seen, part.name.value]),
            );
        }
      }
    };
    walk(node.selectionSet, 1, new Set());
    if (cost > 150)
      context.reportError(
        new GraphQLError("Query is too complex", {
          extensions: { code: "QUERY_TOO_COMPLEX" },
        }),
      );
  },
});
