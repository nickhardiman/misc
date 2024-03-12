from ansiblelint.rules import AnsibleLintRule
class DeprecatedVariableRule(AnsibleLintRule):
    """Deprecated variable declarations."""
    id = 'EXAMPLE002'
    description = 'Check for lines that have old style ${var} ' + 'declarations'
    tags = { 'deprecations' }
    def match(self, line: str) -> Union[bool, str]:
        return '${' in line

