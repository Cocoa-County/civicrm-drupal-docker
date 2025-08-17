<?php

use Twig\Environment;
use Twig\Error\LoaderError;
use Twig\Error\RuntimeError;
use Twig\Extension\CoreExtension;
use Twig\Extension\SandboxExtension;
use Twig\Markup;
use Twig\Sandbox\SecurityError;
use Twig\Sandbox\SecurityNotAllowedTagError;
use Twig\Sandbox\SecurityNotAllowedFilterError;
use Twig\Sandbox\SecurityNotAllowedFunctionError;
use Twig\Source;
use Twig\Template;
use Twig\TemplateWrapper;

/* core/themes/claro/templates/status-report-general-info.html.twig */
class __TwigTemplate_5b68143b7d8a0b3afed699acd53d1034 extends Template
{
    private Source $source;
    /**
     * @var array<string, Template>
     */
    private array $macros = [];

    public function __construct(Environment $env)
    {
        parent::__construct($env);

        $this->source = $this->getSourceContext();

        $this->parent = false;

        $this->blocks = [
        ];
        $this->sandbox = $this->extensions[SandboxExtension::class];
        $this->checkSecurity();
    }

    protected function doDisplay(array $context, array $blocks = []): iterable
    {
        $macros = $this->macros;
        // line 32
        yield "<div class=\"system-status-general-info\">
  <h2 class=\"system-status-general-info__header\">";
        // line 33
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("General System Information"));
        yield "</h2>
  <div class=\"system-status-general-info__items\">
    <div class=\"system-status-general-info__item card\">
      <span class=\"system-status-general-info__item-icon system-status-general-info__item-icon--drupal\"></span>
      <div class=\"system-status-general-info__item-details\">
        <h3 class=\"system-status-general-info__item-title\">";
        // line 38
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Drupal Version"));
        yield "</h3>
        ";
        // line 39
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["drupal"] ?? null), "value", [], "any", false, false, true, 39), "html", null, true);
        yield "
        ";
        // line 40
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["drupal"] ?? null), "description", [], "any", false, false, true, 40)) {
            // line 41
            yield "          <div class=\"description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["drupal"] ?? null), "description", [], "any", false, false, true, 41), "html", null, true);
            yield "</div>
        ";
        }
        // line 43
        yield "      </div>
    </div>

    <div class=\"system-status-general-info__item card\">
      <span class=\"system-status-general-info__item-icon system-status-general-info__item-icon--server\"></span>
      <div class=\"system-status-general-info__item-details\">
        <h3 class=\"system-status-general-info__item-title\">";
        // line 49
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Web Server"));
        yield "</h3>
        ";
        // line 50
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["webserver"] ?? null), "value", [], "any", false, false, true, 50), "html", null, true);
        yield "
        ";
        // line 51
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["webserver"] ?? null), "description", [], "any", false, false, true, 51)) {
            // line 52
            yield "          <div class=\"description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["webserver"] ?? null), "description", [], "any", false, false, true, 52), "html", null, true);
            yield "</div>
        ";
        }
        // line 54
        yield "      </div>
    </div>
    <div class=\"system-status-general-info__item card\">
      <span class=\"system-status-general-info__item-icon system-status-general-info__item-icon--clock\"></span>
      <div class=\"system-status-general-info__item-details\">
        <h3 class=\"system-status-general-info__item-title\">";
        // line 59
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Last Cron Run"));
        yield "</h3>
        ";
        // line 60
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["cron"] ?? null), "value", [], "any", false, false, true, 60), "html", null, true);
        yield "
        ";
        // line 61
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["cron"] ?? null), "run_cron", [], "any", false, false, true, 61)) {
            // line 62
            yield "          <div class=\"system-status-general-info__run-cron\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["cron"] ?? null), "run_cron", [], "any", false, false, true, 62), "html", null, true);
            yield "</div>
        ";
        }
        // line 64
        yield "        ";
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["cron"] ?? null), "description", [], "any", false, false, true, 64)) {
            // line 65
            yield "          <div class=\"system-status-general-info__description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["cron"] ?? null), "description", [], "any", false, false, true, 65), "html", null, true);
            yield "</div>
        ";
        }
        // line 67
        yield "      </div>
    </div>
    <div class=\"system-status-general-info__item card\">
      <span class=\"system-status-general-info__item-icon system-status-general-info__item-icon--php\"></span>
      <div class=\"system-status-general-info__item-details\">
        <h3 class=\"system-status-general-info__item-title\">";
        // line 72
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("PHP"));
        yield "</h3>
        <h4 class=\"system-status-general-info__sub-item-title\">";
        // line 73
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Version"));
        yield "</h4>";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["php"] ?? null), "value", [], "any", false, false, true, 73), "html", null, true);
        yield "
        ";
        // line 74
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["php"] ?? null), "description", [], "any", false, false, true, 74)) {
            // line 75
            yield "          <div class=\"description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["php"] ?? null), "description", [], "any", false, false, true, 75), "html", null, true);
            yield "</div>
        ";
        }
        // line 77
        yield "
        <h4 class=\"system-status-general-info__sub-item-title\">";
        // line 78
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Memory limit"));
        yield "</h4>";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["php_memory_limit"] ?? null), "value", [], "any", false, false, true, 78), "html", null, true);
        yield "
        ";
        // line 79
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["php_memory_limit"] ?? null), "description", [], "any", false, false, true, 79)) {
            // line 80
            yield "          <div class=\"description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["php_memory_limit"] ?? null), "description", [], "any", false, false, true, 80), "html", null, true);
            yield "</div>
        ";
        }
        // line 82
        yield "      </div>
    </div>
    <div class=\"system-status-general-info__item card\">
      <span class=\"system-status-general-info__item-icon system-status-general-info__item-icon--database\"></span>
      <div class=\"system-status-general-info__item-details\">
        <h3 class=\"system-status-general-info__item-title\">";
        // line 87
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Database"));
        yield "</h3>
        <h4 class=\"system-status-general-info__sub-item-title\">";
        // line 88
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("Version"));
        yield "</h4>";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["database_system_version"] ?? null), "value", [], "any", false, false, true, 88), "html", null, true);
        yield "
        ";
        // line 89
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["database_system_version"] ?? null), "description", [], "any", false, false, true, 89)) {
            // line 90
            yield "          <div class=\"description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["database_system_version"] ?? null), "description", [], "any", false, false, true, 90), "html", null, true);
            yield "</div>
        ";
        }
        // line 92
        yield "
        <h4 class=\"system-status-general-info__sub-item-title\">";
        // line 93
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->renderVar(t("System"));
        yield "</h4>";
        yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["database_system"] ?? null), "value", [], "any", false, false, true, 93), "html", null, true);
        yield "
        ";
        // line 94
        if (CoreExtension::getAttribute($this->env, $this->source, ($context["database_system"] ?? null), "description", [], "any", false, false, true, 94)) {
            // line 95
            yield "          <div class=\"description\">";
            yield $this->extensions['Drupal\Core\Template\TwigExtension']->escapeFilter($this->env, CoreExtension::getAttribute($this->env, $this->source, ($context["database_system"] ?? null), "description", [], "any", false, false, true, 95), "html", null, true);
            yield "</div>
        ";
        }
        // line 97
        yield "      </div>
    </div>
  </div>
</div>
";
        $this->env->getExtension('\Drupal\Core\Template\TwigExtension')
            ->checkDeprecations($context, ["drupal", "webserver", "cron", "php", "php_memory_limit", "database_system_version", "database_system"]);        yield from [];
    }

    /**
     * @codeCoverageIgnore
     */
    public function getTemplateName(): string
    {
        return "core/themes/claro/templates/status-report-general-info.html.twig";
    }

    /**
     * @codeCoverageIgnore
     */
    public function isTraitable(): bool
    {
        return false;
    }

    /**
     * @codeCoverageIgnore
     */
    public function getDebugInfo(): array
    {
        return array (  211 => 97,  205 => 95,  203 => 94,  197 => 93,  194 => 92,  188 => 90,  186 => 89,  180 => 88,  176 => 87,  169 => 82,  163 => 80,  161 => 79,  155 => 78,  152 => 77,  146 => 75,  144 => 74,  138 => 73,  134 => 72,  127 => 67,  121 => 65,  118 => 64,  112 => 62,  110 => 61,  106 => 60,  102 => 59,  95 => 54,  89 => 52,  87 => 51,  83 => 50,  79 => 49,  71 => 43,  65 => 41,  63 => 40,  59 => 39,  55 => 38,  47 => 33,  44 => 32,);
    }

    public function getSourceContext(): Source
    {
        return new Source("", "core/themes/claro/templates/status-report-general-info.html.twig", "/opt/drupal/web/core/themes/claro/templates/status-report-general-info.html.twig");
    }
    
    public function checkSecurity()
    {
        static $tags = ["if" => 40];
        static $filters = ["t" => 33, "escape" => 39];
        static $functions = [];

        try {
            $this->sandbox->checkSecurity(
                ['if'],
                ['t', 'escape'],
                [],
                $this->source
            );
        } catch (SecurityError $e) {
            $e->setSourceContext($this->source);

            if ($e instanceof SecurityNotAllowedTagError && isset($tags[$e->getTagName()])) {
                $e->setTemplateLine($tags[$e->getTagName()]);
            } elseif ($e instanceof SecurityNotAllowedFilterError && isset($filters[$e->getFilterName()])) {
                $e->setTemplateLine($filters[$e->getFilterName()]);
            } elseif ($e instanceof SecurityNotAllowedFunctionError && isset($functions[$e->getFunctionName()])) {
                $e->setTemplateLine($functions[$e->getFunctionName()]);
            }

            throw $e;
        }

    }
}
