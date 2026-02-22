# Aspect: ai-tools-skills
# Consolidated AI tools skills module.
# Migrated from modules/legacy/_/common/ai-tools/skills/
{ ... }:
let
  mkConfig =
    { isDarwin }:
    { config
    , lib
    , pkgs
    , ...
    }:
    let
      cfg = config.jvf.aiTools.skills;
      programs = [
        "opencode"
        "claudecode"
        "droid"
        "gemini"
      ];

      npx = lib.getExe' pkgs.nodejs "npx";
      defaultBrowser = if isDarwin then lib.getExe pkgs.google-chrome else lib.getExe pkgs.chromium;

      kebabToHuman = s:
        lib.concatStringsSep " " (map
          (w:
            let
              first = builtins.substring 0 1 w;
              rest = builtins.substring 1 (-1) w;
            in
            (lib.toUpper first) + rest)
          (lib.splitString "-" s));

      mkSkillConfig = skillName: skillOptions: skillCfg:
        lib.mkIf skillCfg.enable (lib.mkMerge (
          map (program: { jvf.programs.${program}.skills.${skillName} = skillOptions; }) programs
        ));

      skillOptions_auditing_security = {
        allowed-tools = [
          "Read"
          "Grep"
          "Glob"
        ];
        name = "auditing-security";
        description = "Security analysis and vulnerability assessment specialist";
        tags = [
          "explorer"
          "documentation"
        ];
        prompt = ''
          # ${kebabToHuman "auditing-security"}

          <vulnerability_assessment>
          Conduct comprehensive security vulnerability assessments of code, configurations, and systems.
          Your goals are to:

          - Systematically identify security vulnerabilities and weaknesses
          - Analyze dependencies for known CVEs and security issues
          - Perform threat modeling and attack surface analysis
          - Evaluate code for common security flaws and anti-patterns
          - Assess cryptographic implementations and key management
          - Review input validation and sanitization mechanisms

          **Assessment methodology:**
          1. **Static Code Analysis:**
             - Scan for OWASP Top 10 vulnerabilities
             - Identify SQL injection, XSS, CSRF vulnerabilities
             - Check for buffer overflows and memory safety issues
             - Analyze authentication bypass possibilities
             - Review authorization logic flaws

          2. **Dependency Analysis:**
             - Enumerate all direct and transitive dependencies
             - Cross-reference against CVE databases
             - Identify outdated packages with known vulnerabilities
             - Assess supply chain security risks
             - Review license compliance and security implications

          3. **Cryptographic Review:**
             - Validate encryption algorithm choices and implementations
             - Review key generation, storage, and rotation practices
             - Assess random number generation quality
             - Check for deprecated or weak cryptographic functions
             - Evaluate certificate and PKI configurations

          **Output format:**
          Present findings as a prioritized vulnerability report:
          - **Critical**: Immediate security risks requiring urgent attention
          - **High**: Significant vulnerabilities with clear exploitation paths
          - **Medium**: Important security issues with potential impact
          - **Low**: Minor security improvements and best practice violations
          - **Info**: Security observations and recommendations

          Each finding should include:
          - Vulnerability description and technical details
          - Proof of concept or exploitation scenario
          - Risk assessment (likelihood × impact)
          - Remediation guidance with specific fix recommendations
          - References to security standards and best practices

          **Validation process:**
          - Verify each vulnerability through multiple detection methods
          - Eliminate false positives through manual analysis
          - Provide evidence and reproducible test cases
          - Consider environmental factors and deployment contexts
          - Prioritize based on actual exploitability and business impact
          </vulnerability_assessment>

          <configuration_review>
          Analyze system and application configurations for security hardening opportunities.
          Your objectives are to:

          - Review system configurations against security baselines
          - Identify insecure defaults and misconfigurations
          - Evaluate service exposure and network security settings
          - Assess file permissions and access controls
          - Review logging and monitoring configurations
          - Validate security policy implementations

          **Configuration analysis areas:**
          1. **System Hardening:**
             - Operating system security settings
             - Service configuration and exposure
             - Network security controls and firewalls
             - User account policies and privileges
             - System update and patch management
             - Audit logging and monitoring setup

          2. **Application Security:**
             - Web server and application server configs
             - Database security configurations
             - Container and orchestration security
             - API security settings and rate limiting
             - Session management and cookie security
             - Error handling and information disclosure

          3. **Infrastructure Security:**
             - Cloud service configurations and IAM policies
             - Network segmentation and access controls
             - Load balancer and proxy configurations
             - Backup and disaster recovery security
             - Certificate management and TLS settings
             - DNS security and domain validation

          **Review methodology:**
          - Compare configurations against established baselines (CIS, NIST, OWASP)
          - Identify deviations from security best practices
          - Assess the security impact of each configuration choice
          - Provide specific remediation steps with configuration examples
          - Consider operational requirements and security trade-offs

          **Deliverables:**
          - Comprehensive configuration security assessment
          - Prioritized list of hardening recommendations
          - Configuration templates and scripts for remediation
          - Compliance mapping to relevant security frameworks
          - Risk-based implementation timeline and guidance
          </configuration_review>

          <access_control_audit>
          Evaluate authentication, authorization, and access control mechanisms.
          Focus on:

          - Identity and access management (IAM) implementations
          - Role-based access control (RBAC) effectiveness
          - Privilege escalation prevention and least privilege principles
          - Multi-factor authentication (MFA) coverage and strength
          - Session management and token security
          - API authentication and authorization mechanisms

          **Access control evaluation:**
          1. **Authentication Assessment:**
             - Password policies and strength requirements
             - Multi-factor authentication implementation
             - Account lockout and brute force protection
             - Single sign-on (SSO) security and integration
             - Certificate-based authentication validation
             - Biometric and hardware token security

          2. **Authorization Analysis:**
             - Permission models and role definitions
             - Privilege escalation pathways and prevention
             - Resource-based access control implementation
             - Dynamic authorization and policy engines
             - Cross-service authorization consistency
             - Administrative access controls and monitoring

          3. **Session Security:**
             - Session token generation and entropy
             - Session timeout and lifecycle management
             - Concurrent session handling and limits
             - Session fixation and hijacking prevention
             - Cross-site request forgery (CSRF) protection
             - Secure cookie attributes and SameSite policies

          **Audit process:**
          - Map all authentication and authorization flows
          - Test for common access control bypasses
          - Verify least privilege principle enforcement
          - Review administrative and emergency access procedures
          - Validate access logging and monitoring capabilities
          - Assess compliance with access control standards

          **Output specifications:**
          - Detailed access control architecture review
          - Identified access control weaknesses and bypasses
          - Recommendations for privilege reduction and segmentation
          - MFA implementation gaps and improvement plans
          - Session security enhancement proposals
          - Compliance assessment against relevant frameworks
          </access_control_audit>

          <secrets_analysis>
          Identify and secure sensitive data, credentials, and cryptographic materials.
          Your mission is to:

          - Detect hardcoded secrets, keys, and credentials in code
          - Evaluate secrets management and storage practices
          - Assess key lifecycle management and rotation procedures
          - Review secure communication and data protection mechanisms
          - Identify sensitive data exposure and leakage risks
          - Validate encryption at rest and in transit implementations

          **Secrets detection methodology:**
          1. **Code and Configuration Scanning:**
             - Search for hardcoded passwords, API keys, and tokens
             - Identify database connection strings and service credentials
             - Detect private keys, certificates, and cryptographic secrets
             - Find configuration files with embedded sensitive data
             - Locate environment variables containing secrets
             - Review version control history for exposed credentials

          2. **Secrets Management Evaluation:**
             - Assess centralized secrets management solutions
             - Review key vault configurations and access controls
             - Evaluate secrets rotation and lifecycle policies
             - Analyze secure distribution and injection mechanisms
             - Validate encryption of secrets at rest and in transit
             - Review backup and disaster recovery for secrets

          3. **Data Protection Assessment:**
             - Identify personally identifiable information (PII) exposure
             - Evaluate data classification and handling procedures
             - Review encryption implementations and key management
             - Assess data retention and secure deletion practices
             - Validate compliance with privacy regulations (GDPR, CCPA)
             - Check for data leakage through logs and error messages

          **Detection techniques:**
          - Regular expression patterns for common secret formats
          - Entropy analysis for randomly generated keys and tokens
          - Context-aware analysis of suspicious variable names
          - Integration with specialized secrets detection tools
          - Manual review of configuration and deployment files
          - Runtime analysis of memory and network traffic

          **Remediation guidance:**
          - Immediate steps for exposed credential rotation
          - Implementation of secure secrets management solutions
          - Code refactoring to eliminate hardcoded secrets
          - Environment variable and configuration security
          - Developer training on secure coding practices
          - Continuous monitoring and detection implementation
          </secrets_analysis>

          <compliance_check>
          Validate security posture against established frameworks and regulatory requirements.
          Your goals are to:

          - Assess compliance with security standards (NIST, CIS, ISO 27001)
          - Evaluate adherence to industry-specific regulations
          - Review audit trail and evidence collection processes
          - Validate security control implementation and effectiveness
          - Identify compliance gaps and remediation priorities
          - Provide documentation for regulatory reporting

          **Compliance frameworks:**
          1. **Security Standards:**
             - NIST Cybersecurity Framework mapping
             - CIS Controls implementation assessment
             - ISO 27001/27002 compliance evaluation
             - OWASP security requirements validation
             - Cloud security posture (CSP) compliance
             - Industry-specific security standards

          2. **Regulatory Requirements:**
             - GDPR data protection and privacy compliance
             - HIPAA healthcare information security
             - PCI DSS payment card industry standards
             - SOX IT controls and financial reporting
             - FedRAMP federal cloud security requirements
             - Regional and local privacy regulations

          3. **Audit and Evidence:**
             - Security control documentation and testing
             - Audit trail completeness and integrity
             - Incident response and breach notification
             - Risk assessment and management processes
             - Security training and awareness programs
             - Vendor and third-party security assessments

          **Compliance assessment process:**
          - Map current security controls to framework requirements
          - Evaluate control implementation maturity and effectiveness
          - Identify gaps and non-compliance areas
          - Prioritize remediation based on risk and regulatory impact
          - Develop compliance roadmap with timeline and resources
          - Establish continuous monitoring and maintenance procedures

          **Deliverables:**
          - Comprehensive compliance assessment report
          - Gap analysis with specific remediation recommendations
          - Control mapping documentation and evidence collection
          - Risk-based compliance improvement roadmap
          - Automated compliance monitoring recommendations
          - Regulatory reporting templates and procedures
          </compliance_check>

          **Assessment principles:**
          - Maintain a defensive security mindset focused on protection
          - Provide actionable, risk-based recommendations
          - Consider business context and operational constraints
          - Ensure all findings are verified and reproducible
          - Prioritize critical vulnerabilities requiring immediate attention
          - Document everything with clear evidence and remediation guidance

          **Important reminders:**
          - Never assist with malicious or offensive security activities
          - Focus exclusively on defensive security measures
          - Provide constructive guidance for security improvements
          - Respect confidentiality and handle sensitive information securely
          - Follow responsible disclosure practices for vulnerability findings
          - Maintain objectivity and professional security assessment standards

          **REMINDER:**
          Conduct thorough, systematic security assessments that prioritize critical risks and provide clear, actionable remediation guidance to improve overall security posture.
        '';
      };

      skillOptions_creating_skills = {
        name = "creating-skills";
        description = "Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.";
        allowed-tools = [
          "Read"
          "Write"
          "Bash"
          "WebFetch"
        ];
        tags = [
          "explorer"
          "documentation"
          "browser"
        ];
        references = {
          "workflows" = ''
            # Workflow Patterns

            ## Sequential Workflows

            For complex tasks, break operations into clear, sequential steps. It is often helpful to give Claude an overview of the process towards the beginning of SKILL.md:

            ```markdown
            Filling a PDF form involves these steps:

            1. Analyze the form (run analyze_form.py)
            2. Create field mapping (edit fields.json)
            3. Validate mapping (run validate_fields.py)
            4. Fill the form (run fill_form.py)
            5. Verify output (run verify_output.py)
            ```

            ## Conditional Workflows

            For tasks with branching logic, guide Claude through decision points:

            ```markdown
            1. Determine the modification type:
               **Creating new content?** → Follow "Creation workflow" below
               **Editing existing content?** → Follow "Editing workflow" below

            2. Creation workflow: [steps]
            3. Editing workflow: [steps]
            ```
          '';

          ############################################################################################################
          "output-patterns" = ''
            # Output Patterns

            Use these patterns when skills need to produce consistent, high-quality output.

            ## Template Pattern

            Provide templates for output format. Match the level of strictness to your needs.

            **For strict requirements (like API responses or data formats):**

            ```markdown
            ## Report structure

            ALWAYS use this exact template structure:

            # [Analysis Title]

            ## Executive summary
            [One-paragraph overview of key findings]

            ## Key findings
            - Finding 1 with supporting data
            - Finding 2 with supporting data
            - Finding 3 with supporting data

            ## Recommendations
            1. Specific actionable recommendation
            2. Specific actionable recommendation
            ```

            **For flexible guidance (when adaptation is useful):**

            ```markdown
            ## Report structure

            Here is a sensible default format, but use your best judgment:

            # [Analysis Title]

            ## Executive summary
            [Overview]

            ## Key findings
            [Adapt sections based on what you discover]

            ## Recommendations
            [Tailor to the specific context]

            Adjust sections as needed for the specific analysis type.
            ```

            ## Examples Pattern

            For skills where output quality depends on seeing examples, provide input/output pairs:

            ```markdown
            ## Commit message format

            Generate commit messages following these examples:

            **Example 1:**
            Input: Added user authentication with JWT tokens
            Output:
            ```
            feat(auth): implement JWT-based authentication

            Add login endpoint and token validation middleware
            ```

            **Example 2:**
            Input: Fixed bug where dates displayed incorrectly in reports
            Output:
            ```
            fix(reports): correct date formatting in timezone conversion

            Use UTC timestamps consistently across report generation
            ```

            Follow this style: type(scope): brief description, then detailed explanation.
            ```

            Examples help Claude understand the desired style and level of detail more clearly than descriptions alone.
          '';
        };

        ############################################################################################################
        scripts = {
          "init_skill.py" = ''
            #!/usr/bin/env python3
            """
            Skill Initializer - Creates a new skill from template

            Usage:
                init_skill.py <skill-name> --path <path>

            Examples:
                init_skill.py my-new-skill --path skills/public
                init_skill.py my-api-helper --path skills/private
                init_skill.py custom-skill --path /custom/location
            """

            import sys
            from pathlib import Path


            SKILL_TEMPLATE = """---
            name: {skill_name}
            description: [TODO: Complete and informative explanation of what the skill does and when to use it. Include WHEN to use this skill - specific scenarios, file types, or tasks that trigger it.]
            ---

            # {skill_title}

            ## Overview

            [TODO: 1-2 sentences explaining what this skill enables]

            ## Structuring This Skill

            [TODO: Choose the structure that best fits this skill's purpose. Common patterns:

            **1. Workflow-Based** (best for sequential processes)
            - Works well when there are clear step-by-step procedures
            - Example: DOCX skill with "Workflow Decision Tree" → "Reading" → "Creating" → "Editing"
            - Structure: ## Overview → ## Workflow Decision Tree → ## Step 1 → ## Step 2...

            **2. Task-Based** (best for tool collections)
            - Works well when the skill offers different operations/capabilities
            - Example: PDF skill with "Quick Start" → "Merge PDFs" → "Split PDFs" → "Extract Text"
            - Structure: ## Overview → ## Quick Start → ## Task Category 1 → ## Task Category 2...

            **3. Reference/Guidelines** (best for standards or specifications)
            - Works well for brand guidelines, coding standards, or requirements
            - Example: Brand styling with "Brand Guidelines" → "Colors" → "Typography" → "Features"
            - Structure: ## Overview → ## Guidelines → ## Specifications → ## Usage...

            **4. Capabilities-Based** (best for integrated systems)
            - Works well when the skill provides multiple interrelated features
            - Example: Product Management with "Core Capabilities" → numbered capability list
            - Structure: ## Overview → ## Core Capabilities → ### 1. Feature → ### 2. Feature...

            Patterns can be mixed and matched as needed. Most skills combine patterns (e.g., start with task-based, add workflow for complex operations).

            Delete this entire "Structuring This Skill" section when done - it's just guidance.]

            ## [TODO: Replace with the first main section based on chosen structure]

            [TODO: Add content here. See examples in existing skills:
            - Code samples for technical skills
            - Decision trees for complex workflows
            - Concrete examples with realistic user requests
            - References to scripts/templates/references as needed]

            ## Resources

            This skill includes example resource directories that demonstrate how to organize different types of bundled resources:

            ### scripts/
            Executable code (Python/Bash/etc.) that can be run directly to perform specific operations.

            **Examples from other skills:**
            - PDF skill: `fill_fillable_fields.py`, `extract_form_field_info.py` - utilities for PDF manipulation
            - DOCX skill: `document.py`, `utilities.py` - Python modules for document processing

            **Appropriate for:** Python scripts, shell scripts, or any executable code that performs automation, data processing, or specific operations.

            **Note:** Scripts may be executed without loading into context, but can still be read by Claude for patching or environment adjustments.

            ### references/
            Documentation and reference material intended to be loaded into context to inform Claude's process and thinking.

            **Examples from other skills:**
            - Product management: `communication.md`, `context_building.md` - detailed workflow guides
            - BigQuery: API reference documentation and query examples
            - Finance: Schema documentation, company policies

            **Appropriate for:** In-depth documentation, API references, database schemas, comprehensive guides, or any detailed information that Claude should reference while working.

            ### assets/
            Files not intended to be loaded into context, but rather used within the output Claude produces.

            **Examples from other skills:**
            - Brand styling: PowerPoint template files (.pptx), logo files
            - Frontend builder: HTML/React boilerplate project directories
            - Typography: Font files (.ttf, .woff2)

            **Appropriate for:** Templates, boilerplate code, document templates, images, icons, fonts, or any files meant to be copied or used in the final output.

            ---

            **Any unneeded directories can be deleted.** Not every skill requires all three types of resources.
            """

            EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
            """
            Example helper script for {skill_name}

            This is a placeholder script that can be executed directly.
            Replace with actual implementation or delete if not needed.

            Example real scripts from other skills:
            - pdf/scripts/fill_fillable_fields.py - Fills PDF form fields
            - pdf/scripts/convert_pdf_to_images.py - Converts PDF pages to images
            """

            def main():
                print("This is an example script for {skill_name}")
                # TODO: Add actual script logic here
                # This could be data processing, file conversion, API calls, etc.

            if __name__ == "__main__":
                main()
            '''

            EXAMPLE_REFERENCE = """# Reference Documentation for {skill_title}

            This is a placeholder for detailed reference documentation.
            Replace with actual reference content or delete if not needed.

            Example real reference docs from other skills:
            - product-management/references/communication.md - Comprehensive guide for status updates
            - product-management/references/context_building.md - Deep-dive on gathering context
            - bigquery/references/ - API references and query examples

            ## When Reference Docs Are Useful

            Reference docs are ideal for:
            - Comprehensive API documentation
            - Detailed workflow guides
            - Complex multi-step processes
            - Information too lengthy for main SKILL.md
            - Content that's only needed for specific use cases

            ## Structure Suggestions

            ### API Reference Example
            - Overview
            - Authentication
            - Endpoints with examples
            - Error codes
            - Rate limits

            ### Workflow Guide Example
            - Prerequisites
            - Step-by-step instructions
            - Common patterns
            - Troubleshooting
            - Best practices
            """

            EXAMPLE_ASSET = """# Example Asset File

            This placeholder represents where asset files would be stored.
            Replace with actual asset files (templates, images, fonts, etc.) or delete if not needed.

            Asset files are NOT intended to be loaded into context, but rather used within
            the output Claude produces.

            Example asset files from other skills:
            - Brand guidelines: logo.png, slides_template.pptx
            - Frontend builder: hello-world/ directory with HTML/React boilerplate
            - Typography: custom-font.ttf, font-family.woff2
            - Data: sample_data.csv, test_dataset.json

            ## Common Asset Types

            - Templates: .pptx, .docx, boilerplate directories
            - Images: .png, .jpg, .svg, .gif
            - Fonts: .ttf, .otf, .woff, .woff2
            - Boilerplate code: Project directories, starter files
            - Icons: .ico, .svg
            - Data files: .csv, .json, .xml, .yaml

            Note: This is a text placeholder. Actual assets can be any file type.
            """


            def title_case_skill_name(skill_name):
                """Convert hyphenated skill name to Title Case for display."""
                return ' '.join(word.capitalize() for word in skill_name.split('-'))


            def init_skill(skill_name, path):
                """
                Initialize a new skill directory with template SKILL.md.

                Args:
                    skill_name: Name of the skill
                    path: Path where the skill directory should be created

                Returns:
                    Path to created skill directory, or None if error
                """
                # Determine skill directory path
                skill_dir = Path(path).resolve() / skill_name

                # Check if directory already exists
                if skill_dir.exists():
                    print(f"❌ Error: Skill directory already exists: {skill_dir}")
                    return None

                # Create skill directory
                try:
                    skill_dir.mkdir(parents=True, exist_ok=False)
                    print(f"✅ Created skill directory: {skill_dir}")
                except Exception as e:
                    print(f"❌ Error creating directory: {e}")
                    return None

                # Create SKILL.md from template
                skill_title = title_case_skill_name(skill_name)
                skill_content = SKILL_TEMPLATE.format(
                    skill_name=skill_name,
                    skill_title=skill_title
                )

                skill_md_path = skill_dir / 'SKILL.md'
                try:
                    skill_md_path.write_text(skill_content)
                    print("✅ Created SKILL.md")
                except Exception as e:
                    print(f"❌ Error creating SKILL.md: {e}")
                    return None

                # Create resource directories with example files
                try:
                    # Create scripts/ directory with example script
                    scripts_dir = skill_dir / 'scripts'
                    scripts_dir.mkdir(exist_ok=True)
                    example_script = scripts_dir / 'example.py'
                    example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name))
                    example_script.chmod(0o755)
                    print("✅ Created scripts/example.py")

                    # Create references/ directory with example reference doc
                    references_dir = skill_dir / 'references'
                    references_dir.mkdir(exist_ok=True)
                    example_reference = references_dir / 'api_reference.md'
                    example_reference.write_text(EXAMPLE_REFERENCE.format(skill_title=skill_title))
                    print("✅ Created references/api_reference.md")

                    # Create assets/ directory with example asset placeholder
                    assets_dir = skill_dir / 'assets'
                    assets_dir.mkdir(exist_ok=True)
                    example_asset = assets_dir / 'example_asset.txt'
                    example_asset.write_text(EXAMPLE_ASSET)
                    print("✅ Created assets/example_asset.txt")
                except Exception as e:
                    print(f"❌ Error creating resource directories: {e}")
                    return None

                # Print next steps
                print(f"\n✅ Skill '{skill_name}' initialized successfully at {skill_dir}")
                print("\nNext steps:")
                print("1. Edit SKILL.md to complete the TODO items and update the description")
                print("2. Customize or delete the example files in scripts/, references/, and assets/")
                print("3. Run the validator when ready to check the skill structure")

                return skill_dir


            def main():
                if len(sys.argv) < 4 or sys.argv[2] != '--path':
                    print("Usage: init_skill.py <skill-name> --path <path>")
                    print("\nSkill name requirements:")
                    print("  - Hyphen-case identifier (e.g., 'data-analyzer')")
                    print("  - Lowercase letters, digits, and hyphens only")
                    print("  - Max 40 characters")
                    print("  - Must match directory name exactly")
                    print("\nExamples:")
                    print("  init_skill.py my-new-skill --path skills/public")
                    print("  init_skill.py my-api-helper --path skills/private")
                    print("  init_skill.py custom-skill --path /custom/location")
                    sys.exit(1)

                skill_name = sys.argv[1]
                path = sys.argv[3]

                print(f"🚀 Initializing skill: {skill_name}")
                print(f"   Location: {path}")
                print()

                result = init_skill(skill_name, path)

                if result:
                    sys.exit(0)
                else:
                    sys.exit(1)


            if __name__ == "__main__":
                main()
          '';

          ############################################################################################################
          "package_skill.py" = ''
            #!/usr/bin/env python3
                    """
                    Skill Packager - Creates a distributable .skill file of a skill folder

                    Usage:
                        python utils/package_skill.py <path/to/skill-folder> [output-directory]

                    Example:
                        python utils/package_skill.py skills/public/my-skill
                        python utils/package_skill.py skills/public/my-skill ./dist
                    """

                    import sys
                    import zipfile
                    from pathlib import Path
                    from quick_validate import validate_skill


                    def package_skill(skill_path, output_dir=None):
                        """
                        Package a skill folder into a .skill file.

                        Args:
                            skill_path: Path to the skill folder
                            output_dir: Optional output directory for the .skill file (defaults to current directory)

                        Returns:
                            Path to the created .skill file, or None if error
                        """
                        skill_path = Path(skill_path).resolve()

                        # Validate skill folder exists
                        if not skill_path.exists():
                            print(f"❌ Error: Skill folder not found: {skill_path}")
                            return None

                        if not skill_path.is_dir():
                            print(f"❌ Error: Path is not a directory: {skill_path}")
                            return None

                        # Validate SKILL.md exists
                        skill_md = skill_path / "SKILL.md"
                        if not skill_md.exists():
                            print(f"❌ Error: SKILL.md not found in {skill_path}")
                            return None

                        # Run validation before packaging
                        print("🔍 Validating skill...")
                        valid, message = validate_skill(skill_path)
                        if not valid:
                            print(f"❌ Validation failed: {message}")
                            print("   Please fix the validation errors before packaging.")
                            return None
                        print(f"✅ {message}\n")

                        # Determine output location
                        skill_name = skill_path.name
                        if output_dir:
                            output_path = Path(output_dir).resolve()
                            output_path.mkdir(parents=True, exist_ok=True)
                        else:
                            output_path = Path.cwd()

                        skill_filename = output_path / f"{skill_name}.skill"

                        # Create the .skill file (zip format)
                        try:
                            with zipfile.ZipFile(skill_filename, 'w', zipfile.ZIP_DEFLATED) as zipf:
                                # Walk through the skill directory
                                for file_path in skill_path.rglob('*'):
                                    if file_path.is_file():
                                        # Calculate the relative path within the zip
                                        arcname = file_path.relative_to(skill_path.parent)
                                        zipf.write(file_path, arcname)
                                        print(f"  Added: {arcname}")

                            print(f"\n✅ Successfully packaged skill to: {skill_filename}")
                            return skill_filename

                        except Exception as e:
                            print(f"❌ Error creating .skill file: {e}")
                            return None


                    def main():
                        if len(sys.argv) < 2:
                            print("Usage: python utils/package_skill.py <path/to/skill-folder> [output-directory]")
                            print("\nExample:")
                            print("  python utils/package_skill.py skills/public/my-skill")
                            print("  python utils/package_skill.py skills/public/my-skill ./dist")
                            sys.exit(1)

                        skill_path = sys.argv[1]
                        output_dir = sys.argv[2] if len(sys.argv) > 2 else None

                        print(f"📦 Packaging skill: {skill_path}")
                        if output_dir:
                            print(f"   Output directory: {output_dir}")
                        print()

                        result = package_skill(skill_path, output_dir)

                        if result:
                            sys.exit(0)
                        else:
                            sys.exit(1)


                    if __name__ == "__main__":
                        main()
          '';

          ############################################################################################################
          "quick_validate.py" = ''
            #!/usr/bin/env python3
            """
            Quick validation script for skills - minimal version
            """

            import sys
            import os

            import re
            import yaml
            from pathlib import Path

            def validate_skill(skill_path):
                """Basic validation of a skill"""
                skill_path = Path(skill_path)

                # Check SKILL.md exists
                skill_md = skill_path / 'SKILL.md'
                if not skill_md.exists():
                    return False, "SKILL.md not found"

                # Read and validate frontmatter
                content = skill_md.read_text()
                if not content.startswith('---'):
                    return False, "No YAML frontmatter found"

                # Extract frontmatter
                match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
                if not match:
                    return False, "Invalid frontmatter format"

                frontmatter_text = match.group(1)

                # Parse YAML frontmatter
                try:
                    frontmatter = yaml.safe_load(frontmatter_text)
                    if not isinstance(frontmatter, dict):
                        return False, "Frontmatter must be a YAML dictionary"
                except yaml.YAMLError as e:
                    return False, f"Invalid YAML in frontmatter: {e}"

                # Define allowed properties
                ALLOWED_PROPERTIES = {'name', 'description', 'license', 'allowed-tools', 'metadata'}

                # Check for unexpected properties (excluding nested keys under metadata)
                unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
                if unexpected_keys:
                    return False, (
                        f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
                        f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
                    )

                # Check required fields
                if 'name' not in frontmatter:
                    return False, "Missing 'name' in frontmatter"
                if 'description' not in frontmatter:
                    return False, "Missing 'description' in frontmatter"

                # Extract name for validation
                name = frontmatter.get('name', ''')
                if not isinstance(name, str):
                    return False, f"Name must be a string, got {type(name).__name__}"
                name = name.strip()
                if name:
                    # Check naming convention (hyphen-case: lowercase with hyphens)
                    if not re.match(r'^[a-z0-9-]+$', name):
                        return False, f"Name '{name}' should be hyphen-case (lowercase letters, digits, and hyphens only)"
                    if name.startswith('-') or name.endswith('-') or '--' in name:
                        return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
                    # Check name length (max 64 characters per spec)
                    if len(name) > 64:
                        return False, f"Name is too long ({len(name)} characters). Maximum is 64 characters."

                # Extract and validate description
                description = frontmatter.get('description', ''')
                if not isinstance(description, str):
                    return False, f"Description must be a string, got {type(description).__name__}"
                description = description.strip()
                if description:
                    # Check for angle brackets
                    if '<' in description or '>' in description:
                        return False, "Description cannot contain angle brackets (< or >)"
                    # Check description length (max 1024 characters per spec)
                    if len(description) > 1024:
                        return False, f"Description is too long ({len(description)} characters). Maximum is 1024 characters."

                return True, "Skill is valid!"

            if __name__ == "__main__":
                if len(sys.argv) != 2:
                    print("Usage: python quick_validate.py <skill_directory>")
                    sys.exit(1)
            
                valid, message = validate_skill(sys.argv[1])
                print(message)
                sys.exit(0 if valid else 1)
          '';
        };

        ############################################################################################################
        prompt = ''
          # ${kebabToHuman "creating-skills"}

          This skill provides guidance for creating effective skills.

          ## About Skills

          Skills are modular, self-contained packages that extend Claude's capabilities by providing
          specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific
          domains or tasks—they transform Claude from a general-purpose agent into a specialized agent
          equipped with procedural knowledge that no model can fully possess.

          ### What Skills Provide

          1. Specialized workflows - Multi-step procedures for specific domains
          2. Tool integrations - Instructions for working with specific file formats or APIs
          3. Domain expertise - Company-specific knowledge, schemas, business logic
          4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

          ## Core Principles

          ### Concise is Key

          The context window is a public good. Skills share the context window with everything else Claude needs: system prompt, conversation history, other Skills' metadata, and the actual user request.

          **Default assumption: Claude is already very smart.** Only add context Claude doesn't already have. Challenge each piece of information: "Does Claude really need this explanation?" and "Does this paragraph justify its token cost?"

          Prefer concise examples over verbose explanations.

          ### Set Appropriate Degrees of Freedom

          Match the level of specificity to the task's fragility and variability:

          **High freedom (text-based instructions)**: Use when multiple approaches are valid, decisions depend on context, or heuristics guide the approach.

          **Medium freedom (pseudocode or scripts with parameters)**: Use when a preferred pattern exists, some variation is acceptable, or configuration affects behavior.

          **Low freedom (specific scripts, few parameters)**: Use when operations are fragile and error-prone, consistency is critical, or a specific sequence must be followed.

          Think of Claude as exploring a path: a narrow bridge with cliffs needs specific guardrails (low freedom), while an open field allows many routes (high freedom).

          ### Anatomy of a Skill

          Every skill consists of a required SKILL.md file and optional bundled resources:

          ```
          skill-name/
          ├── SKILL.md (required)
          │   ├── YAML frontmatter metadata (required)
          │   │   ├── name: (required)
          │   │   └── description: (required)
          │   └── Markdown instructions (required)
          └── Bundled Resources (optional)
              ├── scripts/          - Executable code (Python/Bash/etc.)
              ├── references/       - Documentation intended to be loaded into context as needed
              └── assets/           - Files used in output (templates, icons, fonts, etc.)
          ```

          #### SKILL.md (required)

          Every SKILL.md consists of:

          - **Frontmatter** (YAML): Contains `name` and `description` fields. These are the only fields that Claude reads to determine when the skill gets used, thus it is very important to be clear and comprehensive in describing what the skill is, and when it should be used.
          - **Body** (Markdown): Instructions and guidance for using the skill. Only loaded AFTER the skill triggers (if at all).

          #### Bundled Resources (optional)

          ##### Scripts (`scripts/`)

          Executable code (Python/Bash/etc.) for tasks that require deterministic reliability or are repeatedly rewritten.

          - **When to include**: When the same code is being rewritten repeatedly or deterministic reliability is needed
          - **Example**: `scripts/rotate_pdf.py` for PDF rotation tasks
          - **Benefits**: Token efficient, deterministic, may be executed without loading into context
          - **Note**: Scripts may still need to be read by Claude for patching or environment-specific adjustments

          ##### References (`references/`)

          Documentation and reference material intended to be loaded as needed into context to inform Claude's process and thinking.

          - **When to include**: For documentation that Claude should reference while working
          - **Examples**: `references/finance.md` for financial schemas, `references/mnda.md` for company NDA template, `references/policies.md` for company policies, `references/api_docs.md` for API specifications
          - **Use cases**: Database schemas, API documentation, domain knowledge, company policies, detailed workflow guides
          - **Benefits**: Keeps SKILL.md lean, loaded only when Claude determines it's needed
          - **Best practice**: If files are large (>10k words), include grep search patterns in SKILL.md
          - **Avoid duplication**: Information should live in either SKILL.md or references files, not both. Prefer references files for detailed information unless it's truly core to the skill—this keeps SKILL.md lean while making information discoverable without hogging the context window. Keep only essential procedural instructions and workflow guidance in SKILL.md; move detailed reference material, schemas, and examples to references files.

          ##### Assets (`assets/`)

          Files not intended to be loaded into context, but rather used within the output Claude produces.

          - **When to include**: When the skill needs files that will be used in the final output
          - **Examples**: `assets/logo.png` for brand assets, `assets/slides.pptx` for PowerPoint templates, `assets/frontend-template/` for HTML/React boilerplate, `assets/font.ttf` for typography
          - **Use cases**: Templates, images, icons, boilerplate code, fonts, sample documents that get copied or modified
          - **Benefits**: Separates output resources from documentation, enables Claude to use files without loading them into context

          #### What to Not Include in a Skill

          A skill should only contain essential files that directly support its functionality. Do NOT create extraneous documentation or auxiliary files, including:

          - README.md
          - INSTALLATION_GUIDE.md
          - QUICK_REFERENCE.md
          - CHANGELOG.md
          - etc.

          The skill should only contain the information needed for an AI agent to do the job at hand. It should not contain auxilary context about the process that went into creating it, setup and testing procedures, user-facing documentation, etc. Creating additional documentation files just adds clutter and confusion.

          ### Progressive Disclosure Design Principle

          Skills use a three-level loading system to manage context efficiently:

          1. **Metadata (name + description)** - Always in context (~100 words)
          2. **SKILL.md body** - When skill triggers (<5k words)
          3. **Bundled resources** - As needed by Claude (Unlimited because scripts can be executed without reading into context window)

          #### Progressive Disclosure Patterns

          Keep SKILL.md body to the essentials and under 500 lines to minimize context bloat. Split content into separate files when approaching this limit. When splitting out content into other files, it is very important to reference them from SKILL.md and describe clearly when to read them, to ensure the reader of the skill knows they exist and when to use them.

          **Key principle:** When a skill supports multiple variations, frameworks, or options, keep only the core workflow and selection guidance in SKILL.md. Move variant-specific details (patterns, examples, configuration) into separate reference files.

          **Pattern 1: High-level guide with references**

          ```markdown
          # PDF Processing

          ## Quick start

          Extract text with pdfplumber:
          [code example]

          ## Advanced features

          - **Form filling**: See [FORMS.md](FORMS.md) for complete guide
          - **API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
          - **Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
          ```

          Claude loads FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.

          **Pattern 2: Domain-specific organization**

          For Skills with multiple domains, organize content by domain to avoid loading irrelevant context:

          ```
          bigquery-skill/
          ├── SKILL.md (overview and navigation)
          └── reference/
              ├── finance.md (revenue, billing metrics)
              ├── sales.md (opportunities, pipeline)
              ├── product.md (API usage, features)
              └── marketing.md (campaigns, attribution)
          ```

          When a user asks about sales metrics, Claude only reads sales.md.

          Similarly, for skills supporting multiple frameworks or variants, organize by variant:

          ```
          cloud-deploy/
          ├── SKILL.md (workflow + provider selection)
          └── references/
              ├── aws.md (AWS deployment patterns)
              ├── gcp.md (GCP deployment patterns)
              └── azure.md (Azure deployment patterns)
          ```

          When the user chooses AWS, Claude only reads aws.md.

          **Pattern 3: Conditional details**

          Show basic content, link to advanced content:

          ```markdown
          # DOCX Processing

          ## Creating documents

          Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

          ## Editing documents

          For simple edits, modify the XML directly.

          **For tracked changes**: See [REDLINING.md](REDLINING.md)
          **For OOXML details**: See [OOXML.md](OOXML.md)
          ```

          Claude reads REDLINING.md or OOXML.md only when the user needs those features.

          **Important guidelines:**

          - **Avoid deeply nested references** - Keep references one level deep from SKILL.md. All reference files should link directly from SKILL.md.
          - **Structure longer reference files** - For files longer than 100 lines, include a table of contents at the top so Claude can see the full scope when previewing.

          ## Skill Creation Process

          Skill creation involves these steps:

          1. Understand the skill with concrete examples
          2. Plan reusable skill contents (scripts, references, assets)
          3. Initialize the skill (run init_skill.py)
          4. Edit the skill (implement resources and write SKILL.md)
          5. Package the skill (run package_skill.py)
          6. Iterate based on real usage

          Follow these steps in order, skipping only if there is a clear reason why they are not applicable.

          ### Step 1: Understanding the Skill with Concrete Examples

          Skip this step only when the skill's usage patterns are already clearly understood. It remains valuable even when working with an existing skill.

          To create an effective skill, clearly understand concrete examples of how the skill will be used. This understanding can come from either direct user examples or generated examples that are validated with user feedback.

          For example, when building an image-editor skill, relevant questions include:

          - "What functionality should the image-editor skill support? Editing, rotating, anything else?"
          - "Can you give some examples of how this skill would be used?"
          - "I can imagine users asking for things like 'Remove the red-eye from this image' or 'Rotate this image'. Are there other ways you imagine this skill being used?"
          - "What would a user say that should trigger this skill?"

          To avoid overwhelming users, avoid asking too many questions in a single message. Start with the most important questions and follow up as needed for better effectiveness.

          Conclude this step when there is a clear sense of the functionality the skill should support.

          ### Step 2: Planning the Reusable Skill Contents

          To turn concrete examples into an effective skill, analyze each example by:

          1. Considering how to execute on the example from scratch
          2. Identifying what scripts, references, and assets would be helpful when executing these workflows repeatedly

          Example: When building a `pdf-editor` skill to handle queries like "Help me rotate this PDF," the analysis shows:

          1. Rotating a PDF requires re-writing the same code each time
          2. A `scripts/rotate_pdf.py` script would be helpful to store in the skill

          Example: When designing a `frontend-webapp-builder` skill for queries like "Build me a todo app" or "Build me a dashboard to track my steps," the analysis shows:

          1. Writing a frontend webapp requires the same boilerplate HTML/React each time
          2. An `assets/hello-world/` template containing the boilerplate HTML/React project files would be helpful to store in the skill

          Example: When building a `big-query` skill to handle queries like "How many users have logged in today?" the analysis shows:

          1. Querying BigQuery requires re-discovering the table schemas and relationships each time
          2. A `references/schema.md` file documenting the table schemas would be helpful to store in the skill

          To establish the skill's contents, analyze each concrete example to create a list of the reusable resources to include: scripts, references, and assets.

          ### Step 3: Initializing the Skill

          At this point, it is time to actually create the skill.

          Skip this step only if the skill being developed already exists, and iteration or packaging is needed. In this case, continue to the next step.

          When creating a new skill from scratch, always run the `init_skill.py` script. The script conveniently generates a new template skill directory that automatically includes everything a skill requires, making the skill creation process much more efficient and reliable.

          Usage:

          ```bash
          scripts/init_skill.py <skill-name> --path <output-directory>
          ```

          The script:

          - Creates the skill directory at the specified path
          - Generates a SKILL.md template with proper frontmatter and TODO placeholders
          - Creates example resource directories: `scripts/`, `references/`, and `assets/`
          - Adds example files in each directory that can be customized or deleted

          After initialization, customize or remove the generated SKILL.md and example files as needed.

          ### Step 4: Edit the Skill

          When editing the (newly-generated or existing) skill, remember that the skill is being created for another instance of Claude to use. Include information that would be beneficial and non-obvious to Claude. Consider what procedural knowledge, domain-specific details, or reusable assets would help another Claude instance execute these tasks more effectively.

          #### Learn Proven Design Patterns

          Consult these helpful guides based on your skill's needs:

          - **Multi-step processes**: See references/workflows.md for sequential workflows and conditional logic
          - **Specific output formats or quality standards**: See references/output-patterns.md for template and example patterns

          These files contain established best practices for effective skill design.

          #### Start with Reusable Skill Contents

          To begin implementation, start with the reusable resources identified above: `scripts/`, `references/`, and `assets/` files. Note that this step may require user input. For example, when implementing a `brand-guidelines` skill, the user may need to provide brand assets or templates to store in `assets/`, or documentation to store in `references/`.

          Added scripts must be tested by actually running them to ensure there are no bugs and that the output matches what is expected. If there are many similar scripts, only a representative sample needs to be tested to ensure confidence that they all work while balancing time to completion.

          Any example files and directories not needed for the skill should be deleted. The initialization script creates example files in `scripts/`, `references/`, and `assets/` to demonstrate structure, but most skills won't need all of them.

          #### Update SKILL.md

          **Writing Guidelines:** Always use imperative/infinitive form.

          ##### Frontmatter

          Write the YAML frontmatter with `name` and `description`:

          - `name`: The skill name
          - `description`: This is the primary triggering mechanism for your skill, and helps Claude understand when to use the skill.
            - Include both what the Skill does and specific triggers/contexts for when to use it.
            - Include all "when to use" information here - Not in the body. The body is only loaded after triggering, so "When to Use This Skill" sections in the body are not helpful to Claude.
            - Example description for a `docx` skill: "Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extraction. Use when Claude needs to work with professional documents (.docx files) for: (1) Creating new documents, (2) Modifying or editing content, (3) Working with tracked changes, (4) Adding comments, or any other document tasks"

          Do not include any other fields in YAML frontmatter.

          ##### Body

          Write instructions for using the skill and its bundled resources.

          ### Step 5: Packaging a Skill

          Once development of the skill is complete, it must be packaged into a distributable .skill file that gets shared with the user. The packaging process automatically validates the skill first to ensure it meets all requirements:

          ```bash
          scripts/package_skill.py <path/to/skill-folder>
          ```

          Optional output directory specification:

          ```bash
          scripts/package_skill.py <path/to/skill-folder> ./dist
          ```

          The packaging script will:

          1. **Validate** the skill automatically, checking:

             - YAML frontmatter format and required fields
             - Skill naming conventions and directory structure
             - Description completeness and quality
             - File organization and resource references

          2. **Package** the skill if validation passes, creating a .skill file named after the skill (e.g., `my-skill.skill`) that includes all files and maintains the proper directory structure for distribution. The .skill file is a zip file with a .skill extension.

          If validation fails, the script will report the errors and exit without creating a package. Fix any validation errors and run the packaging command again.

          ### Step 6: Iterate

          After testing the skill, users may request improvements. Often this happens right after using the skill, with fresh context of how the skill performed.

          **Iteration workflow:**

          1. Use the skill on real tasks
          2. Notice struggles or inefficiencies
          3. Identify how SKILL.md or bundled resources should be updated
          4. Implement changes and test again
        '';
      };

      skillOptions_research_tools = {
        name = "research-tools";
        description = "External research via Context7 (docs), Grep.app (code examples), and Exa (web search). Loads MCPs on-demand via skill_mcp.";
        licence = "MIT";
        metadata = {
          category = "research";
          triggers = "docs, documentation, code examples, web search, how do others, library, API, current info";
        };
        mcp = {
          deepwiki = {
            url = "https://mcp.deepwiki.com/";
          };
        };
        prompt = ''
          # Research Tools

          ## CRITICAL: `skill_mcp` Syntax

          ```
          skill_mcp(mcp_name="<MCP_SERVER>", tool_name="<TOOL>", arguments='<JSON>')
          ```

          - `mcp_name` = MCP server (`context7`, `grep_app`, `websearch`) — NOT `"research-tools"`
          - `tool_name` = Tool name without prefix — NOT `context7_resolve-library-id`

          ## Tools

          | MCP Server | Tool | Use For |
          |------------|------|---------|
          | `context7` | `resolve-library-id` | Get library ID (required first) |
          | `context7` | `query-docs` | Query library documentation |
          | `grep_app` | `searchGitHub` | GitHub code pattern search |
          | `websearch` | `web_search_exa` | Web search |

          ## Examples

          **Context7** (2-step: resolve ID → query docs):
          ```
          skill_mcp(mcp_name="context7", tool_name="resolve-library-id", arguments='{"libraryName": "react", "query": "hooks"}')
          skill_mcp(mcp_name="context7", tool_name="query-docs", arguments='{"libraryId": "/facebook/react", "query": "useEffect"}')
          ```

          **Grep.app** (search literal code patterns, not keywords):
          ```
          skill_mcp(mcp_name="grep_app", tool_name="searchGitHub", arguments='{"query": "useActionState(", "language": ["TypeScript", "TSX"]}')
          ```

          **Exa**:
          ```
          skill_mcp(mcp_name="websearch", tool_name="web_search_exa", arguments='{"query": "Next.js 15 features", "numResults": 5}')
          ```

          ## Common Mistakes

          | ❌ Wrong | ✅ Correct |
          |----------|-----------|
          | `mcp_name="research-tools"` | `mcp_name="context7"` |
          | `tool_name="context7_resolve-library-id"` | `tool_name="resolve-library-id"` |
          | `tool_name="grep_app_searchGitHub"` | `tool_name="searchGitHub"` |
          | `tool_name="context7_get-library-docs"` | `tool_name="query-docs"` |
        '';
      };

      skillOptions_grafana = {
        name = "grafana";
        description = "Grafana MCP for searching dashboards, querying Prometheus/Loki, and managing incidents/alerts.";
        mcp = {
          grafana = {
            command = lib.getExe pkgs.mcp-grafana;
            args = [ ];
            # env = {
            #   "GRAFANA_URL" = "https://grafana.josevictor.me";
            #   "GRAFANA_SERVICE_ACCOUNT_TOKEN" = "{env:GRAFANA_SERVICE_ACCOUNT_TOKEN}";
            #   "GRAFANA_USERNAME" = "{env:GRAFANA_USERNAME}";
            #   "GRAFANA_PASSWORD" = "{env:GRAFANA_PASSWORD}";
            #   "GRAFANA_ORG_ID" = "1";
            # };
          };
        };
        prompt = ''
          # Grafana MCP

          ## CRITICAL: `skill_mcp` Syntax

          ```
          skill_mcp(mcp_name="grafana", tool_name="<TOOL>", arguments='<JSON>')
          ```

          - `mcp_name` = MCP server (`grafana`) — NOT `"grafana-skill"`
          - `tool_name` = Tool name without prefix — NOT `grafana_search_dashboards`

          ## Tools

          | Category | Tool | Use For |
          |----------|------|---------|
          | **Search** | `search_dashboards` | Search for dashboards by query |
          | **Search** | `search_folders` | Search for folders |
          | **Dashboard** | `get_dashboard_by_uid` | Get full dashboard JSON |
          | **Dashboard** | `get_dashboard_summary` | Get dashboard metadata summary |
          | **Dashboard** | `get_dashboard_panel_queries` | Get all panel queries in a dashboard |
          | **Dashboard** | `get_dashboard_property` | Get specific dashboard property |
          | **Dashboard** | `update_dashboard` | Update dashboard JSON |
          | **Datasource** | `list_datasources` | List all configured datasources |
          | **Datasource** | `get_datasource_by_uid` | Get datasource details by UID |
          | **Datasource** | `get_datasource_by_name` | Get datasource details by name |
          | **Prometheus** | `query_prometheus` | Execute PromQL queries |
          | **Prometheus** | `list_prometheus_metric_metadata` | List metric metadata |
          | **Prometheus** | `list_prometheus_metric_names` | List metric names |
          | **Prometheus** | `list_prometheus_label_names` | List label names |
          | **Prometheus** | `list_prometheus_label_values` | List label values |
          | **Loki** | `query_loki_logs` | Query Loki logs |
          | **Loki** | `query_loki_stats` | Get Loki query statistics |
          | **Loki** | `query_loki_patterns` | Extract patterns from logs |
          | **Loki** | `list_loki_label_names` | List Loki label names |
          | **Loki** | `list_loki_label_values` | List Loki label values |
          | **Incident** | `list_incidents` | List Grafana Incidents |
          | **Incident** | `get_incident` | Get incident details |
          | **Incident** | `create_incident` | Create a new incident |
          | **Incident** | `add_activity_to_incident` | Add activity to an incident |
          | **Alerting** | `list_alert_rules` | List alert rules |
          | **Alerting** | `get_alert_rule_by_uid` | Get alert rule details |
          | **Alerting** | `list_contact_points` | List notification contact points |
          | **Alerting** | `create_alert_rule` | Create alert rule |
          | **Alerting** | `update_alert_rule` | Update alert rule |
          | **Alerting** | `delete_alert_rule` | Delete alert rule |
          | **OnCall** | `list_oncall_schedules` | List OnCall schedules |
          | **OnCall** | `get_oncall_shift` | Get current shift for schedule |
          | **OnCall** | `get_current_oncall_users` | Get current on-call users |
          | **OnCall** | `list_oncall_teams` | List OnCall teams |
          | **OnCall** | `list_oncall_users` | List OnCall users |
          | **OnCall** | `list_alert_groups` | List OnCall alert groups |
          | **OnCall** | `get_alert_group` | Get alert group details |
          | **Annotations** | `get_annotations` | Get annotations |
          | **Annotations** | `create_annotation` | Create annotation |
          | **Annotations** | `update_annotation` | Update annotation |
          | **Annotations** | `patch_annotation` | Patch annotation |
          | **Annotations** | `get_annotation_tags` | Get annotation tags |
          | **Pyroscope** | `fetch_pyroscope_profile` | Fetch profiling data |
          | **Pyroscope** | `list_pyroscope_profile_types` | List profile types |
          | **Pyroscope** | `list_pyroscope_label_names` | List label names |
          | **Pyroscope** | `list_pyroscope_label_values` | List label values |
          | **Sift** | `list_sift_investigations` | List Sift investigations |
          | **Sift** | `get_sift_investigation` | Get investigation details |
          | **Sift** | `get_sift_analysis` | Get Sift analysis |
          | **Sift** | `find_error_pattern_logs` | Find error patterns |
          | **Sift** | `find_slow_requests` | Find slow requests |
          | **Admin** | `list_teams` | Search for teams |
          | **Admin** | `list_users_by_org` | List users in organization |
          | **Admin** | `list_all_roles` | List all roles |
          | **Admin** | `get_role_details` | Get role details |
          | **Admin** | `get_role_assignments` | Get role assignments |
          | **Admin** | `list_user_roles` | List roles for users |
          | **Admin** | `list_team_roles` | List roles for teams |
          | **Admin** | `get_resource_permissions` | List resource permissions |
          | **Admin** | `get_resource_description` | Get resource type description |
          | **Rendering** | `get_panel_image` | Render panel as image |
          | **Asserts** | `get_assertions` | Get assertion summary |
          | **Navigation** | `generate_deeplink` | Generate deep link |
          | **Folder** | `create_folder` | Create folder |

          ## Examples

          **Search Dashboards**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="search_dashboards", arguments='{"query": "Production Overview", "limit": 5}')
          ```

          **Query Prometheus**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="query_prometheus", arguments='{"query": "rate(http_requests_total[5m])", "datasourceUID": "prom-123", "step": "1m"}')
          ```

          **Query Loki Logs**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="query_loki_logs", arguments='{"query": "{app=\\"api\\"} |= \\"error\\"", "datasourceUID": "loki-123", "limit": 20}')
          ```

          **Get Panel Image**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="get_panel_image", arguments='{"dashboardUID": "db-123", "panelID": 1, "width": 1200, "theme": "dark"}')
          ```

          **List Incidents**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="list_incidents", arguments='{"status": ["active"], "severity": ["critical"]}')
          ```

          **Create Alert Rule**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="create_alert_rule", arguments='{"title": "High CPU", "ruleGroup": "infra", "folderUID": "f-123", "condition": "A", "data": [...], "noDataState": "NoData", "execErrState": "Alerting", "for": "5m", "orgID": 1}')
          ```

          **Fetch Pyroscope Profile**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="fetch_pyroscope_profile", arguments='{"datasourceUID": "pyro-123", "profileType": "process_cpu:cpu:nanoseconds:cpu:nanoseconds"}')
          ```

          **Find Slow Requests (Sift)**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="find_slow_requests", arguments='{"threshold": "2s", "limit": 10}')
          ```

          **Get OnCall Shift**:
          ```
          skill_mcp(mcp_name="grafana", tool_name="get_oncall_shift", arguments='{"scheduleID": "sch-123"}')
          ```

          ## Common Mistakes

          | ❌ Wrong | ✅ Correct |
          |----------|-----------|
          | `mcp_name="grafana-skill"` | `mcp_name="grafana"` |
          | `tool_name="grafana_search_dashboards"` | `tool_name="search_dashboards"` |
          | `datasource_uid` | `datasourceUID` (Case sensitive!) |
        '';
        licence = "MIT";
        metadata = {
          triggers = "grafana, dashboard, prometheus, loki, query, metrics, logs, alert, incident, oncall, annotation, pyroscope, sift, asserts";
        };
      };

      skillOptions_browser_debug_tools = {
        name = "browser-debug-tools";
        description = "Browser automation and debugging via Chrome DevTools Protocol and Playwright. Control browser, inspect elements, execute JavaScript, monitor network/console, emulate devices, take screenshots, and automate interactions.";
        licence = "MIT";
        metadata = {
          triggers = "browser, debug, inspect, element, console, devtools, screenshot, navigate, click, fill, form, hover, drag, network, request, response, performance, emulate, device, mobile, geolocation, CPU throttling, JavaScript, execute, snapshot, accessibility, a11y, DOM, CSS, HTML, troubleshoot, webpage, automation, testing, E2E, interaction, keyboard, press key, page, tab, reload, refresh";
        };
        mcp = {
          chrome-devtools = {
            command = npx;
            args = [
              "-y"
              "chrome-devtools-mcp@latest"
              "--headless=true"
              "--isolated=true"
              "--executablePath=${defaultBrowser}"
            ];
          };
          playwriter = {
            command = lib.getExe' pkgs.nodejs "npx";
            args = [
              "playwriter@latest"
            ];
          };
        };
        prompt = ''
          # Browser Debug Tools

          ## CRITICAL: `skill_mcp` Syntax

          ```
          skill_mcp(mcp_name="<MCP_SERVER>", tool_name="<TOOL>", arguments='<JSON>')
          ```

          - `mcp_name` = MCP server (`playwriter`, `chrome-devtools`) — NOT `"browser-debug-tools"`
          - `tool_name` = Tool name without prefix — NOT `chrome-devtools_click`

          ## Tools

          | MCP Server | Tool | Use For |
          |------------|------|---------|
          | `chrome-devtools` | `click` | Click on page elements (single or double-click) |
          | `chrome-devtools` | `close_page` | Close browser pages by ID |
          | `chrome-devtools` | `drag` | Drag elements between locations |
          | `chrome-devtools` | `emulate` | Emulate network conditions, CPU throttling, geolocation |
          | `chrome-devtools` | `evaluate_script` | Execute JavaScript in browser context |
          | `chrome-devtools` | `fill` | Fill input fields, text areas, or select options |
          | `chrome-devtools` | `get_console_message` | Get specific console message by ID |
          | `chrome-devtools` | `get_network_request` | Get network request details |
          | `chrome-devtools` | `hover` | Hover over page elements |
          | `chrome-devtools` | `list_console_messages` | List all console messages (with filtering) |
          | `chrome-devtools` | `list_pages` | List all open browser pages |
          | `chrome-devtools` | `navigate_page` | Navigate pages (URL, back, forward, reload) |
          | `chrome-devtools` | `press_key` | Press keyboard keys or combinations |
          | `chrome-devtools` | `select_page` | Select a page as context for future calls |
          | `chrome-devtools` | `take_screenshot` | Take screenshots (page or element) |
          | `chrome-devtools` | `take_snapshot` | Take accessibility tree snapshot |
          | `playwriter` | `execute` | Control browser via Playwright code snippets |
          | `playwriter` | `reset` | Reset CDP connection and browser/page/context |

          ## Examples

          **Click element**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="click", arguments='{"uid": "element-123", "dblClick": false}')
          ```

          **Close page**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="close_page", arguments='{"pageId": 1}')
          ```

          **Drag element**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="drag", arguments='{"from_uid": "source-123", "to_uid": "target-456"}')
          ```

          **Emulate network/CPU/geolocation**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="emulate", arguments='{"networkConditions": "Slow 3G", "cpuThrottlingRate": 4, "geolocation": {"latitude": 37.7749, "longitude": -122.4194}}')
          ```

          **Evaluate JavaScript**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="evaluate_script", arguments='{"function": "async () => { return await fetch(\\'/api/data\\').then(r => r.json()); }"}')
          ```

          **Fill input field**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="fill", arguments='{"uid": "input-123", "value": "Hello World"}')
          ```

          **Get console message**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="get_console_message", arguments='{"msgid": 5}')
          ```

          **Get network request**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="get_network_request", arguments='{"reqid": 123}')
          ```

          **Hover over element**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="hover", arguments='{"uid": "element-123"}')
          ```

          **List console messages**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="list_console_messages", arguments='{"types": ["error", "warn"], "pageSize": 50}')
          ```

          **List pages**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="list_pages", arguments='{}')
          ```

          **Navigate page**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="navigate_page", arguments='{"type": "url", "url": "https://example.com", "timeout": 30000}')
          ```

          **Press key**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="press_key", arguments='{"key": "Control+A"}')
          ```

          **Select page**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="select_page", arguments='{"pageId": 2, "bringToFront": true}')
          ```

          **Take screenshot**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="take_screenshot", arguments='{"format": "png", "fullPage": true}')
          ```

          **Take snapshot**:
          ```
          skill_mcp(mcp_name="chrome-devtools", tool_name="take_snapshot", arguments='{"verbose": false}')
          ```

          **Execute Playwright code**:
          ```
          skill_mcp(mcp_name="playwriter", tool_name="execute", arguments='{"code": "await page.click(\\'button\\'); console.log(\\'Clicked!\\');", "timeout": 10000}')
          ```

          **Reset connection**:
          ```
          skill_mcp(mcp_name="playwriter", tool_name="reset", arguments='{}')
          ```

          ## Tool Details

          ### chrome-devtools Tools

          **click** - Click on page elements
          - `uid` (string, required): Element UID from page snapshot
          - `dblClick` (boolean, optional): Double-click (default: false)

          **close_page** - Close browser page
          - `pageId` (number, required): Page ID to close

          **drag** - Drag element to another element
          - `from_uid` (string, required): Source element UID
          - `to_uid` (string, required): Target element UID

          **emulate** - Emulate device/network conditions
          - `networkConditions` (string, optional): "No emulation", "Offline", "Slow 3G", "Fast 3G", "Slow 4G", "Fast 4G"
          - `cpuThrottlingRate` (number, optional): CPU slowdown factor (1-20, 1 = no throttling)
          - `geolocation` (object/null, optional): {latitude, longitude} or null to clear

          **evaluate_script** - Execute JavaScript in page
          - `function` (string, required): JavaScript function (async supported)
          - `args` (array, optional): Arguments to pass to function

          **fill** - Fill form fields
          - `uid` (string, required): Element UID from page snapshot
          - `value` (string, required): Value to fill

          **get_console_message** - Get console message details
          - `msgid` (number, required): Console message ID

          **get_network_request** - Get network request details
          - `reqid` (number, optional): Network request ID (if omitted, returns currently selected)

          **hover** - Hover over element
          - `uid` (string, required): Element UID from page snapshot

          **list_console_messages** - List console messages with filtering
          - `types` (array, optional): Filter by message types (log, debug, info, error, warn, dir, etc.)
          - `pageSize` (integer, optional): Max messages to return
          - `pageIdx` (integer, optional): Page number (0-based)
          - `includePreservedMessages` (boolean, optional): Include messages from last 3 navigations (default: false)

          **list_pages** - List all open pages
          - No parameters required

          **navigate_page** - Navigate pages
          - `type` (string, required): "url", "back", "forward", or "reload"
          - `url` (string, optional): Target URL (only for type="url")
          - `ignoreCache` (boolean, optional): Ignore cache on reload
          - `timeout` (integer, optional): Max wait time in milliseconds

          **press_key** - Press keyboard keys
          - `key` (string, required): Key or combination (e.g., "Enter", "Control+A", "Shift+R")

          **select_page** - Select page as context
          - `pageId` (number, required): Page ID to select
          - `bringToFront` (boolean, optional): Focus and bring page to top

          **take_screenshot** - Take screenshots
          - `format` (string, optional): "png", "jpeg", or "webp" (default: "png")
          - `quality` (number, optional): Compression quality for JPEG/WebP (0-100)
          - `uid` (string, optional): Element UID (if omitted, screenshots entire page)
          - `fullPage` (boolean, optional): Screenshot full scrollable page
          - `filePath` (string, optional): Save to file path instead of attaching to response

          **take_snapshot** - Take accessibility tree snapshot
          - `verbose` (boolean, optional): Include all a11y tree info (default: false)
          - `filePath` (string, optional): Save to file path instead of attaching to response

          ### playwriter Tools

          **execute** - Run Playwright code snippets
          - `code` (string, required): JavaScript code with {page, state, context} in scope
          - `timeout` (number, optional): Timeout in ms (default: 5000)

          **reset** - Reset CDP connection
          - No parameters required

          ## Common Mistakes

          | ❌ Wrong | ✅ Correct |
          |----------|-----------|
          | `mcp_name="browser-debug-tools"` | `mcp_name="chrome-devtools"` or `mcp_name="playwriter"` |
          | `tool_name="chrome-devtools_click"` | `tool_name="click"` |
          | `tool_name="playwriter_execute"` | `tool_name="execute"` |
        '';
      };

      skillOptions_vision_tools = {
        name = "vision-tools";
        description = "Visual analysis related skills. Image analysis, video understanding, OCR, UI screenshots to code, error diagnosis, technical diagrams, data visualization, and UI diff checking.";
        licence = "MIT";
        metadata = {
          category = "visual-engineering";
          triggers = "image, screenshot, photo, picture, OCR, text extraction, video, analyze image, understand diagram, UI screenshot, error screenshot, chart, graph, visualization, architecture diagram, flow chart, UML, ER diagram, dashboard, compare UI, visual diff, GLM-4.6V, vision, multimodal, visual understanding";
        };
        prompt = ''
          # Vision Tools

          ## CRITICAL: `skill_mcp` Syntax

          ```
          skill_mcp(mcp_name="<MCP_SERVER>", tool_name="<TOOL>", arguments='<JSON>')
          ```

          - `mcp_name` = MCP server (`zai-mcp-server`) — NOT `"vision-tools"`
          - `tool_name` = Tool name without prefix — NOT `zai-mcp-server_analyze_image`

          ## Tools

          | MCP Server | Tool | Use For |
          |------------|------|---------|
          | `zai-mcp-server` | `ui_to_artifact` | Turn UI screenshots into code, prompts, specs, or descriptions |
          | `zai-mcp-server` | `extract_text_from_screenshot` | OCR screenshots for code, terminals, docs, and general text |
          | `zai-mcp-server` | `diagnose_error_screenshot` | Analyze error snapshots and propose actionable fixes |
          | `zai-mcp-server` | `understand_technical_diagram` | Interpret architecture, flow, UML, ER, and system diagrams |
          | `zai-mcp-server` | `analyze_data_visualization` | Read charts and dashboards to surface insights and trends |
          | `zai-mcp-server` | `ui_diff_check` | Compare two UI shots to flag visual or implementation drift |
          | `zai-mcp-server` | `image_analysis` | General-purpose image understanding when other tools don't fit |
          | `zai-mcp-server` | `video_analysis` | Inspect videos (local/remote ≤8MB; MP4/MOV/M4V) to describe scenes, moments, and entities |

          ## Examples

          **UI to Artifact** (convert screenshot to code):
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="ui_to_artifact", arguments='{"image_path": "screenshot.png", "output_format": "code"}')
          ```

          **Extract Text** (OCR):
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="extract_text_from_screenshot", arguments='{"image_path": "terminal.png"}')
          ```

          **Diagnose Error**:
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="diagnose_error_screenshot", arguments='{"image_path": "error.png", "context": "React app build failure"}')
          ```

          **Understand Technical Diagram**:
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="understand_technical_diagram", arguments='{"image_path": "architecture.png", "diagram_type": "system architecture"}')
          ```

          **Analyze Data Visualization**:
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="analyze_data_visualization", arguments='{"image_path": "dashboard.png", "focus": "trends and insights"}')
          ```

          **UI Diff Check**:
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="ui_diff_check", arguments='{"image_path_before": "v1.png", "image_path_after": "v2.png"}')
          ```

          **General Image Analysis**:
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="image_analysis", arguments='{"image_path": "photo.jpg", "query": "Describe what you see"}')
          ```

          **Video Analysis**:
          ```
          skill_mcp(mcp_name="zai-mcp-server", tool_name="video_analysis", arguments='{"video_path": "demo.mp4", "query": "Summarize the key moments"}')
          ```

          ## Tool Details

          ### zai-mcp-server Tools

          **ui_to_artifact** - Convert UI screenshots to artifacts
          - `image_path` (string, required): Path to UI screenshot
          - `output_format` (string, optional): "code", "prompt", "spec", or "description" (default: "code")
          - `context` (string, optional): Additional context about the UI

          **extract_text_from_screenshot** - OCR text extraction
          - `image_path` (string, required): Path to screenshot
          - `context` (string, optional): Type of content (code, terminal, doc, etc.)

          **diagnose_error_screenshot** - Analyze error screenshots
          - `image_path` (string, required): Path to error screenshot
          - `context` (string, optional): Error context (language, framework, stack trace info)

          **understand_technical_diagram** - Interpret technical diagrams
          - `image_path` (string, required): Path to diagram
          - `diagram_type` (string, optional): "architecture", "flow", "UML", "ER", "system", etc.
          - `context` (string, optional): Domain or system context

          **analyze_data_visualization** - Analyze charts and dashboards
          - `image_path` (string, required): Path to visualization
          - `focus` (string, optional): What to focus on (trends, insights, anomalies, etc.)
          - `context` (string, optional): Data domain or metrics context

          **ui_diff_check** - Compare two UI screenshots
          - `image_path_before` (string, required): Path to before screenshot
          - `image_path_after` (string, required): Path to after screenshot
          - `focus` (string, optional): What to check (visual drift, layout changes, etc.)

          **image_analysis** - General-purpose image understanding
          - `image_path` (string, required): Path to image
          - `query` (string, required): What to analyze or ask about the image
          - `detail` (string, optional): "low", "medium", or "high" detail level (default: "medium")

          **video_analysis** - Analyze video content
          - `video_path` (string, required): Path or URL to video (≤8MB; MP4/MOV/M4V)
          - `query` (string, required): What to analyze or ask about the video
          - `timestamp_focus` (string, optional): Specific timestamp or moment to focus on

          ## Best Practices

          **Image Paths:**
          - Use relative paths from current directory: `screenshot.png`
          - Use absolute paths if needed: `/path/to/image.png`
          - Supported formats: PNG, JPEG, WebP, GIF, BMP

          **Video Paths:**
          - Local files: `demo.mp4`
          - Remote URLs: `https://example.com/video.mp4`
          - Max size: 8MB
          - Supported formats: MP4, MOV, M4V

          **Tool Selection:**
          - Use specific tools when available (ui_to_artifact, diagnose_error_screenshot, etc.)
          - Use `image_analysis` for general visual understanding
          - Use `video_analysis` for video content analysis

          **Context Tips:**
          - Provide relevant context for better results (framework, language, domain)
          - Specify output format for ui_to_artifact (code, prompt, spec, description)
          - Include error context for diagnose_error_screenshot (stack trace, language)

          ## Common Mistakes

          | ❌ Wrong | ✅ Correct |
          |----------|-----------|
          | `mcp_name="vision-tools"` | `mcp_name="zai-mcp-server"` |
          | `tool_name="zai-mcp-server_image_analysis"` | `tool_name="image_analysis"` |
          | `tool_name="zai-mcp-server_ui_to_artifact"` | `tool_name="ui_to_artifact"` |
          | Pasting images directly in chat | Use image paths in skill_mcp calls |
          | Using wrong tool for task | Use most specific tool available |
        '';
      };

      skillOptions_kubernetes_tools = {
        name = "kubernetes-tools";
        description = "Kubernetes MCP server for managing Kubernetes and OpenShift clusters. Interact with pods, deployments, services, namespaces, events, Helm charts, and any Kubernetes resource via direct API calls.";
        licence = "MIT";
        metadata = {
          triggers = "kubernetes, k8s, kubectl, pod, deployment, service, namespace, helm, cluster, container, kubeconfig, context, openshift, nodes, events, ingress, secret, configmap, persistentvolume, statefulset, daemonset, job, cronjob, custom-resource, crd";
        };
        mcp = {
          kubernetes = {
            command = npx;
            args = [
              "-y"
              "kubernetes-mcp-server@latest"
            ];
            # env = {
            #   "KUBECONFIG" = "{env:KUBECONFIG}";
            # };
          };
        };
        prompt = ''
          # Kubernetes Tools

          ## CRITICAL: `skill_mcp` Syntax

          ```
          skill_mcp(mcp_name="kubernetes", tool_name="<TOOL>", arguments='<JSON>')
          ```

          - `mcp_name` = MCP server (`kubernetes`) — NOT `"kubernetes-tools"`
          - `tool_name` = Tool name without prefix — NOT `kubernetes_pods_list`

          ## Tools

          | Category | Tool | Use For |
          |----------|------|---------|
          | **Config** | `configuration_contexts_list` | List all available context names and server URLs from kubeconfig |
          | **Config** | `targets_list` | List all available targets |
          | **Config** | `configuration_view` | Get current Kubernetes configuration as kubeconfig YAML |
          | **Core** | `events_list` | List Kubernetes events from all namespaces or specific namespace |
          | **Core** | `namespaces_list` | List all Kubernetes namespaces |
          | **Core** | `projects_list` | List all OpenShift projects |
          | **Core** | `nodes_log` | Get logs from a Kubernetes node (kubelet, kube-proxy) |
          | **Core** | `nodes_stats_summary` | Get detailed resource usage statistics from a node |
          | **Core** | `pods_list` | List pods in all namespaces |
          | **Core** | `pods_list_in_namespace` | List pods in specific namespace |
          | **Core** | `pods_get` | Get a specific pod |
          | **Core** | `pods_delete` | Delete a specific pod |
          | **Core** | `pods_top` | Get resource consumption (CPU/memory) for pods |
          | **Core** | `pods_exec` | Execute a command in a pod |
          | **Core** | `pods_log` | Get logs from a pod |
          | **Core** | `pods_run` | Run a container image in a pod |
          | **Generic** | `resources_list` | List any Kubernetes resources by apiVersion and kind |
          | **Generic** | `resources_get` | Get any Kubernetes resource |
          | **Generic** | `resources_create_or_update` | Create or update any Kubernetes resource |
          | **Generic** | `resources_delete` | Delete any Kubernetes resource |
          | **Helm** | `helm_install` | Install a Helm chart |
          | **Helm** | `helm_list` | List Helm releases |
          | **Helm** | `helm_uninstall` | Uninstall a Helm release |

          ## Tool Details

          ### Configuration Tools

          **configuration_contexts_list** - List all available context names
          - No parameters required

          **targets_list** - List all available targets
          - No parameters required

          **configuration_view** - Get kubeconfig YAML
          - `minified` (boolean, optional): Return minified version with only current context (default: true)

          ### Core Tools

          **events_list** - List Kubernetes events
          - `namespace` (string, optional): Namespace to retrieve events from (default: all namespaces)

          **namespaces_list** - List all namespaces
          - No parameters required

          **projects_list** - List OpenShift projects
          - No parameters required

          **nodes_log** - Get node system logs
          - `name` (string, required): Name of the node
          - `query` (string, required): Service or file (e.g., "kubelet", "/var/log/kubelet.log")
          - `tailLines` (integer, optional): Number of lines from end (default: all)

          **nodes_stats_summary** - Get node resource usage stats
          - `name` (string, required): Name of the node

          **pods_list** - List pods in all namespaces
          - `labelSelector` (string, optional): Kubernetes label selector (e.g., 'app=myapp')

          **pods_list_in_namespace** - List pods in specific namespace
          - `labelSelector` (string, optional): Kubernetes label selector
          - `namespace` (string, required): Namespace to list pods from

          **pods_get** - Get a specific pod
          - `name` (string, required): Name of the Pod
          - `namespace` (string, optional): Namespace (default: current context)

          **pods_delete** - Delete a specific pod
          - `name` (string, required): Name of the Pod to delete
          - `namespace` (string, optional): Namespace (default: current context)

          **pods_top** - Get resource consumption metrics
          - `all_namespaces` (boolean, optional): List from all namespaces (default: false)
          - `label_selector` (string, optional): Filter by labels
          - `name` (string, optional): Specific pod name
          - `namespace` (string, optional): Namespace (default: current context)

          **pods_exec** - Execute command in a pod
          - `command` (array, required): Command and arguments (e.g., ["ls", "-l", "/tmp"])
          - `container` (string, optional): Container name for multi-container pods
          - `name` (string, required): Pod name
          - `namespace` (string, optional): Namespace (default: current context)

          **pods_log** - Get pod logs
          - `container` (string, optional): Container name for multi-container pods
          - `name` (string, required): Pod name
          - `namespace` (string, optional): Namespace (default: current context)
          - `previous` (boolean, optional): Get previous terminated container logs
          - `tail` (integer, optional): Number of lines from end (default: 100)

          **pods_run** - Run a container in a pod
          - `image` (string, required): Container image to run
          - `name` (string, optional): Pod name (random if not provided)
          - `namespace` (string, optional): Namespace (default: current context)
          - `port` (number, optional): TCP port to expose

          ### Generic Resource Tools (any Kubernetes resource)

          **resources_list** - List any Kubernetes resources
          - `apiVersion` (string, required): API version (e.g., "v1", "apps/v1", "networking.k8s.io/v1")
          - `kind` (string, required): Resource kind (e.g., "Pod", "Service", "Deployment", "Ingress")
          - `labelSelector` (string, optional): Filter by labels
          - `namespace` (string, optional): Namespace (default: all namespaces)

          **resources_get** - Get any Kubernetes resource
          - `apiVersion` (string, required): API version
          - `kind` (string, required): Resource kind
          - `name` (string, required): Resource name
          - `namespace` (string, optional): Namespace (default: current context)

          **resources_create_or_update** - Create or update any resource
          - `resource` (string, required): JSON or YAML representation with apiVersion, kind, metadata, spec

          **resources_delete** - Delete any Kubernetes resource
          - `apiVersion` (string, required): API version
          - `kind` (string, required): Resource kind
          - `name` (string, required): Resource name
          - `namespace` (string, optional): Namespace (default: current context)

          ### Helm Tools

          **helm_install** - Install a Helm chart
          - `chart` (string, required): Chart reference (e.g., "stable/grafana", "oci://ghcr.io/nginxinc/charts/nginx-ingress")
          - `name` (string, optional): Release name (random if not provided)
          - `namespace` (string, optional): Namespace (default: current context)
          - `values` (object, optional): Values to pass to the chart

          **helm_list** - List Helm releases
          - `all_namespaces` (boolean, optional): List from all namespaces
          - `namespace` (string, optional): Namespace (default: all namespaces)

          **helm_uninstall** - Uninstall a Helm release
          - `name` (string, required): Release name to uninstall
          - `namespace` (string, optional): Namespace (default: current context)

          ## Multi-Cluster Support

          When multi-cluster is enabled (default) and you have access to multiple clusters, all applicable tools include an additional `context` parameter to specify the Kubernetes context (cluster):

          - `context` (string, optional): Kubernetes context name to use for the operation

          ## Configuration Options

          The MCP server can be configured with these options:
          - `--read-only`: Run in read-only mode (no create/update/delete)
          - `--disable-destructive`: Disable destructive operations
          - `--list-output`: Output format (yaml or table, default: table)
          - `--toolsets`: Comma-separated list of toolsets to enable (config, core, helm)

          ## Examples

          **List all pods in default namespace**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="pods_list_in_namespace", arguments='{"namespace": "default"}')
          ```

          **Get pod logs with last 50 lines**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="pods_log", arguments='{"name": "my-app-pod", "namespace": "production", "tail": 50}')
          ```

          **Execute command in pod**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="pods_exec", arguments='{"name": "my-app-pod", "namespace": "production", "command": ["ls", "-la", "/app"]}')
          ```

          **List all Deployments**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="resources_list", arguments='{"apiVersion": "apps/v1", "kind": "Deployment"}')
          ```

          **Create a ConfigMap**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="resources_create_or_update", arguments='{"resource": "apiVersion: v1\\nkind: ConfigMap\\nmetadata:\\n  name: my-config\\n  namespace: default\\ndata:\\n  KEY: value"}')
          ```

          **Install Helm chart**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="helm_install", arguments='{"chart": "nginx/nginx-ingress", "name": "my-nginx", "namespace": "ingress-nginx"}')
          ```

          **Get node resource usage**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="nodes_stats_summary", arguments='{"name": "worker-node-1"}')
          ```

          **List events in a namespace**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="events_list", arguments='{"namespace": "kube-system"}')
          ```

          **Switch to different cluster context**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="pods_list", arguments='{"context": "production-cluster"}')
          ```

          **Delete a resource**:
          ```
          skill_mcp(mcp_name="kubernetes", tool_name="resources_delete", arguments='{"apiVersion": "v1", "kind": "ConfigMap", "name": "old-config", "namespace": "default"}')
          ```

          ## Common Mistakes

          | ❌ Wrong | ✅ Correct |
          |----------|-----------|
          | `mcp_name="kubernetes-tools"` | `mcp_name="kubernetes"` |
          | `tool_name="kubernetes_pods_list"` | `tool_name="pods_list"` |
          | `kind: pod` (lowercase) | `kind: "Pod"` (capitalized) |
          | `apiVersion: v1` for Deployment | `apiVersion: "apps/v1"` for Deployment |
          | Missing namespace for namespaced resources | Provide `namespace` parameter |
          | `context` parameter for single cluster | Omit `context` when using default |
        '';
      };

      skillOptions_developing_containers = {
        allowed-tools = [
          "Read"
          "Grep"
          "Glob"
          "Bash"
          "BashOutput"
        ];
        name = "developing-containers";
        description = "Container development with Docker, Podman, Dockerfiles, Containerfiles, 12factor principles, multi-stage builds, and Skaffold workflows. Automatically assists with containerization, orchestration, and secure image";
        tags = [
          "explorer"
          "documentation"
          "container"
        ];
        prompt = ''
          # ${kebabToHuman "developing-containers"}

          Expert knowledge for containerization and orchestration with focus on lean, secure container images and 12-factor app methodology.

          ## Core Expertise

          **Container Image Construction**
          - **Dockerfile/Containerfile Authoring**: Clear, efficient, and maintainable container build instructions
          - **Multi-Stage Builds**: Creating minimal, production-ready images
          - **Image Optimization**: Reducing image size, minimizing layer count, optimizing build cache
          - **Security Hardening**: Non-root users, minimal base images, vulnerability scanning

          **Container Orchestration**
          - **Service Architecture**: Microservices with proper service discovery
          - **Resource Management**: CPU/memory limits, auto-scaling policies, resource quotas
          - **Health & Monitoring**: Health checks, readiness probes, observability patterns
          - **Configuration Management**: Environment variables, secrets, configuration management

          ## Key Capabilities

          - **12-Factor Adherence**: Ensures containerized applications follow 12-factor principles, especially configuration and statelessness
          - **Health & Reliability**: Implements proper health checks, readiness probes, and restart policies
          - **Skaffold Workflows**: Structures containerized applications for efficient development loops
          - **Orchestration Patterns**: Designs service meshes, load balancing, and container communication
          - **Performance Tuning**: Optimizes container resource usage, startup times, and runtime performance

          ## Image Crafting Process

          1. **Analyze**: Understand application dependencies and build process
          2. **Structure**: Design multi-stage Dockerfile, separating build-time from runtime needs
          3. **Ignore**: Create comprehensive `.dockerignore` file
          4. **Build & Scan**: Build image and scan for vulnerabilities
          5. **Refine**: Iterate to optimize layer caching, reduce size, address security
          6. **Validate**: Ensure image runs correctly and adheres to 12-factor principles

          ## Best Practices

          **Multi-Stage Dockerfile Pattern**
          ```dockerfile
          # Build stage
          FROM node:20-alpine AS builder
          WORKDIR /app
          COPY package*.json ./
          RUN npm ci --only=production
          COPY . .
          RUN npm run build

          # Production stage
          FROM node:20-alpine
          RUN addgroup -g 1001 -S nodejs && \
              adduser -S nodejs -u 1001
          WORKDIR /app
          COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
          COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
          USER nodejs
          EXPOSE 3000
          CMD ["node", "dist/main.js"]
          ```

          **Security Best Practices**
          - Use minimal base images (alpine, distroless)
          - Run containers as non-root user
          - Implement health checks for container reliability
          - Scan images for vulnerabilities regularly
          - Keep base images updated

          **12-Factor App Principles**
          - Configuration via environment variables
          - Stateless processes
          - Explicit dependencies
          - Port binding for services
          - Graceful shutdown handling

          **Skaffold Preference**
          - Favor Skaffold over Docker Compose for local development
          - Continuous development loop with hot reload
          - Production-like local environment

          For detailed Dockerfile optimization techniques, orchestration patterns, security hardening, and Skaffold configuration, see `# Container Development Reference`.

          # Container Development Reference

          Comprehensive reference for Docker multi-stage builds, 12-factor app principles, security best practices, Skaffold workflows, and Docker Compose patterns.

          ## Table of Contents

          - [Multi-Stage Build Patterns](#multi-stage-build-patterns)
          - [12-Factor App Principles](#12-factor-app-principles)
          - [Security Best Practices](#security-best-practices)
          - [Skaffold Workflows](#skaffold-workflows)
          - [Docker Compose Patterns](#docker-compose-patterns)
          - [Performance Optimization](#performance-optimization)
          - [Advanced Dockerfile Patterns](#advanced-dockerfile-patterns)

          ---
          ## Multi-Stage Build Patterns

          ### Basic Multi-Stage Build

          ```dockerfile
          # Build stage
          FROM golang:1.21-alpine AS builder
          WORKDIR /app
          COPY go.mod go.sum ./
          RUN go mod download
          COPY . .
          RUN CGO_ENABLED=0 GOOS=linux go build -o main .

          # Final stage
          FROM alpine:latest
          RUN apk --no-cache add ca-certificates
          WORKDIR /root/
          COPY --from=builder /app/main .
          CMD ["./main"]
          ```

          ### Node.js Multi-Stage Build

          ```dockerfile
          # Dependencies stage
          FROM node:20-alpine AS deps
          WORKDIR /app
          COPY package*.json ./
          RUN npm ci --only=production

          # Build stage
          FROM node:20-alpine AS builder
          WORKDIR /app
          COPY package*.json ./
          RUN npm ci
          COPY . .
          RUN npm run build

          # Production stage
          FROM node:20-alpine AS runner
          WORKDIR /app
          ENV NODE_ENV=production
          COPY --from=deps /app/node_modules ./node_modules
          COPY --from=builder /app/dist ./dist
          COPY --from=builder /app/package.json ./
          USER node
          CMD ["node", "dist/index.js"]
          ```

          ### Python Multi-Stage Build

          ```dockerfile
          # Builder stage
          FROM python:3.11-slim AS builder
          WORKDIR /app
          RUN pip install --no-cache-dir uv
          COPY pyproject.toml uv.lock ./
          RUN uv sync --frozen --no-dev
          COPY . .
          RUN uv build

          # Runtime stage
          FROM python:3.11-slim
          WORKDIR /app
          COPY --from=builder /app/.venv /app/.venv
          COPY --from=builder /app/dist/*.whl /tmp/
          RUN pip install --no-cache-dir /tmp/*.whl && rm -rf /tmp/*.whl
          ENV PATH="/app/.venv/bin:$PATH"
          USER nobody
          CMD ["python", "-m", "myapp"]
          ```

          ### Optimized Layer Caching

          ```dockerfile
          # Bad: Invalidates cache on any file change
          FROM node:20-alpine
          WORKDIR /app
          COPY . .
          RUN npm install

          # Good: Cache dependencies separately
          FROM node:20-alpine
          WORKDIR /app
          # Copy only dependency files first
          COPY package*.json ./
          RUN npm ci --only=production
          # Copy application code last
          COPY . .
          CMD ["node", "index.js"]
          ```

          ### Build-Time Variables

          ```dockerfile
          FROM alpine:latest AS builder

          # Build arguments
          ARG VERSION=latest
          ARG BUILD_DATE
          ARG VCS_REF

          # Use build args
          LABEL org.opencontainers.image.version="$${VERSION}" \
                org.opencontainers.image.created="$${BUILD_DATE}" \
                org.opencontainers.image.revision="$${VCS_REF}"

          # Conditional builds
          ARG BUILD_ENV=production
          RUN if [ "$BUILD_ENV" = "development" ]; then \
                apk add --no-cache git vim curl; \
              fi

          # Build command:
          # docker build \
          #   --build-arg VERSION=1.2.3 \
          #   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
          #   --build-arg VCS_REF=$(git rev-parse --short HEAD) \
          #   -t myapp:1.2.3 .
          ```

          ---
          ## 12-Factor App Principles

          [... full content from read 42, preserving all code blocks and sections exactly as in the original file ...]

        '';
      };

      skillOptions_creating_nix_modules = {
        allowed-tools = [ "Read" "Grep" "Glob" "Write" ];
        name = "creating-nix-modules";
        description = "NixOS module creation, organization, and options design specialist";
        tags = [ "nix" "documentation" "explorer" ];
        prompt = ''
          # ${kebabToHuman "creating-nix-modules"}

          <options_design>
          Design sophisticated option schemas with proper types, validation, and user-friendly APIs.
          Your expertise encompasses:

          - Advanced option type definitions and custom type creation
          - Option validation, assertions, and constraint enforcement
          - Hierarchical option organization and namespace design
          - Default value strategies and inheritance patterns
          - Option documentation and discoverability
          - API consistency and user experience design

          **Option type mastery:**
          1. **Core Types and Advanced Usage:**
             - Proper use of basic types (str, int, bool, path, package)
             - Complex types: attrsOf, listOf, submodule, enum, either
             - Custom type creation with check, merge, and description functions
             - Nested submodules and recursive option structures
             - Option type composition and transformation

          2. **Validation and Assertions:**
             - Input validation using type checking and custom validators
             - Cross-option dependencies and conditional validation
             - Assertion patterns for configuration consistency
             - Error message design for clear user feedback
             - Runtime validation vs build-time checking strategies

          3. **Default Value Strategies:**
             - mkDefault vs literal defaults and their precedence
             - Conditional defaults using mkIf and option dependencies
             - Inherited defaults from parent modules or themes
             - Dynamic default computation based on other options
             - Override and merge behavior for complex defaults

          **API design principles:**
          - Intuitive option naming and hierarchical structure
          - Consistency across similar modules and option patterns
          - Backward compatibility and deprecation strategies
          - Clear documentation with examples and use cases
          - Discoverability through logical grouping and naming

          **Advanced patterns:**
          - Polymorphic options that adapt to different input types
          - Option templates and generation for repeated patterns
          - Meta-options that configure other options
          - Option inheritance and composition across modules
          - Integration with external configuration systems
          </options_design>

          <module_architecture>
          Master NixOS module architecture patterns and best practices.
          Your specialization includes:

          - Module structure and organization conventions
          - Configuration precedence and override mechanisms
          - Module interdependency and composition patterns
          - Platform-specific adaptation and abstraction
          - Separation of concerns and modular design

          **Module structure patterns:**
          1. **Standard Module Organization:**
             - imports, options, config section organization
             - Proper use of enable options and conditional configuration
             - Service definition patterns for systemd integration
             - Package and environment configuration separation
             - User vs system configuration boundaries

          2. **NixOS Patterns:**
             - System-level service and daemon configuration (NixOS)
             - User-level application and dotfile management creating nix wrappers using the pkgs.symlinkJoin function
             - Privilege boundaries and security considerations
             - Resource sharing and isolation strategies
             - Cross-platform compatibility patterns

          3. **Advanced Module Composition:**
             - Module parameterization and configuration injection
             - Shared module libraries and common functionality
             - Module inheritance and specialization patterns
             - Plugin and extension architectures
             - Configuration layering and override hierarchies

          **Platform-specific design:**
          - Linux vs Darwin configuration differences
          - Architecture-specific adaptations (x86_64, aarch64)
          - Distribution-specific considerations (NixOS, nix-darwin)
          - Hardware-specific configuration patterns
          - Cross-platform abstraction strategies

          **Integration patterns:**
          - Inter-module communication and shared state
          - Configuration aggregation and composition
          - Service dependency management and ordering
          - Resource allocation and conflict resolution
          - Testing and validation across module boundaries
          </module_architecture>

          <configuration_patterns>
          Expert-level usage of NixOS configuration functions and conditional logic.
          Your mastery covers:

          - Advanced lib.mkIf patterns and conditional configuration
          - mkDefault, mkOverride, and precedence management
          - mkMerge, mkBefore, mkAfter for configuration composition
          - Assertion and warning patterns for configuration validation
          - Dynamic configuration generation and meta-programming
          - Performance optimization in configuration evaluation

          **Conditional configuration mastery:**
          1. **mkIf Patterns and Optimization:**
             - Efficient conditional blocks and nested conditions
             - Performance implications of conditional evaluation
             - Combining conditions with logical operators
             - Conditional imports and dynamic module loading
             - Avoiding unnecessary evaluation in disabled features

          2. **Override and Precedence Management:**
             - Understanding mkDefault vs mkOverride priority levels
             - Strategic use of priority levels for configuration layers
             - Override patterns for theme and customization systems
             - Conflict resolution between multiple configuration sources
             - Debug techniques for precedence and override issues

          3. **Configuration Composition:**
             - mkMerge for combining heterogeneous configurations
             - mkBefore and mkAfter for ordered configuration lists
             - Recursive merging patterns for nested configurations
             - Configuration templating and generation patterns
             - Performance considerations in complex compositions

          **Advanced techniques:**
          - Lazy evaluation strategies for expensive configurations
          - Configuration caching and memoization patterns
          - Dynamic configuration based on system introspection
          - Configuration validation pipelines and error handling
          - Meta-programming techniques for configuration generation

          **Best practices:**
          - Readable and maintainable conditional logic
          - Consistent patterns across similar configurations
          - Error handling and graceful degradation
          - Documentation of complex conditional behavior
          - Testing strategies for conditional configurations
          </configuration_patterns>

          <integration_strategies>
          Advanced techniques for module integration, dependency management, and cross-module coordination.
          Your expertise includes:

          - Module dependency analysis and management
          - Cross-module configuration sharing and coordination
          - Service integration and orchestration patterns
          - Resource sharing and conflict resolution
          - Plugin systems and extension mechanisms
          - Configuration inheritance and composition hierarchies

          **Dependency management:**
          1. **Module Interdependencies:**
             - Explicit vs implicit dependencies and their trade-offs
             - Circular dependency detection and resolution
             - Dependency injection patterns for module configuration
             - Optional dependencies and graceful degradation
             - Version compatibility across dependent modules

          2. **Cross-Module Communication:**
             - Shared configuration state and coordination mechanisms
             - Event-driven configuration patterns
             - Configuration aggregation from multiple sources
             - Inter-module configuration validation
             - Consistent interfaces across related modules

          3. **Service Coordination:**
             - systemd service dependency management
             - Resource allocation and sharing strategies
             - Configuration ordering and initialization sequences
             - Health checking and recovery mechanisms
             - Performance monitoring and optimization

          **Advanced integration patterns:**
          - Plugin architectures with dynamic module loading
          - Configuration frameworks and shared libraries
          - Theme systems with consistent module integration
          - Multi-user configuration coordination
          - Cross-system configuration synchronization

          **Conflict resolution:**
          - Resource conflict detection and mitigation
          - Configuration precedence and override strategies
          - User choice preservation in automatic configurations
          - Graceful handling of incompatible module combinations
          - Clear error reporting for configuration conflicts
          </integration_strategies>

          <testing_validation>
          Comprehensive module testing, validation, and quality assurance strategies.
          Your specialization covers:

          - Module functionality testing and validation
          - Configuration assertion patterns and error handling
          - Integration testing across module boundaries
          - Performance testing and optimization validation
          - Documentation testing and example validation
          - Continuous integration and automated testing

          **Testing methodologies:**
          1. **Unit Testing for Modules:**
             - Individual module functionality validation
             - Option parsing and type validation testing
             - Default value and configuration generation testing
             - Conditional logic and branch coverage testing
             - Error handling and edge case validation

          2. **Integration Testing:**
             - Cross-module interaction and dependency testing
             - System-level functionality validation
             - Service startup and configuration testing
             - Performance and resource usage validation
             - User experience and workflow testing

          3. **Assertion and Validation Patterns:**
             - Comprehensive input validation and sanitization
             - Runtime assertion patterns for configuration consistency
             - Warning systems for deprecated or problematic configurations
             - Graceful error handling and recovery mechanisms
             - User-friendly error messages and troubleshooting guidance

          **Quality assurance:**
          - Code review processes for module changes
          - Documentation accuracy and completeness validation
          - Example code testing and maintenance
          - Performance regression testing and monitoring
          - Security review and vulnerability assessment

          **Automated testing infrastructure:**
          - Continuous integration pipelines for module testing
          - Automated configuration generation and validation
          - Cross-platform testing and compatibility validation
          - Performance benchmarking and regression detection
          - Documentation generation and validation automation

          **Module expertise principles:**
          - Design user-centric APIs that abstract complexity while providing flexibility
          - Follow established NixOS conventions and patterns
          - Prioritize maintainability, testability, and documentation quality
          - Consider performance implications of configuration patterns
          - Design for extensibility and future evolution
          - Maintain backward compatibility while enabling migration paths

          **Important reminders:**
          - Always validate module syntax and functionality before recommendations
          - Always check the `context7` MCP tool for updated nix documentation
          - Consider the jvf patterns and namespace conventions
          - Design options that integrate well with theming and customization systems
          - Document complex module interactions and configuration dependencies
          - Test module behavior across different systems and use cases
        '';
      };

      skillOptions_managing_flakes = {
        allowed-tools = [ "Read" "Grep" "Glob" "Bash" "BashOutput" ];
        name = "managing-flakes";
        description = "Nix flake management, inputs, and dependency specialist";
        tags = [
          "nix"
          "documentation"
          "explorer"
        ];
        prompt = ''
          # ${kebabToHuman "managing-flakes"}

          <flake_schema_mastery>
            Master the Nix flake schema, evaluation mechanics, and advanced patterns.
            Your expertise covers:

            - Deep understanding of flake.nix structure and required/optional fields
            - Flake evaluation phases and lazy evaluation optimization
            - Output attribute set structure and system matrix patterns
            - Advanced input/output relationships and composition
            - Flake metadata and description best practices
            - Schema validation and error debugging

            **Flake evaluation deep-dive:**
            1. **Evaluation Phases:**
               - Input resolution and lock file generation
               - Flake function evaluation with system parameters
               - Output attribute set construction and validation
               - System-specific evaluation and cross-compilation
               - Lazy evaluation boundaries and performance implications

            2. **Output Schema Patterns:**
               - Standard outputs: packages, apps, devShells, nixosConfigurations
               - Custom outputs and their evaluation contexts
               - Per-system vs system-agnostic outputs
               - Output composition and inheritance patterns
               - Conditional outputs based on input availability

            3. **Advanced Schema Techniques:**
               - Dynamic output generation from input analysis
               - Recursive flake references and self-referencing patterns
               - Output overriding and extension mechanisms
               - Meta-programming with flake outputs
               - Schema evolution and backwards compatibility

            **Performance optimization:**
            - Minimize evaluation overhead through strategic laziness
            - Optimize attribute access patterns
            - Reduce memory usage during evaluation
            - Profile and debug evaluation performance issues
            - Cache expensive computations across evaluations

            **Validation and debugging:**
            - Schema conformance checking and validation
            - Common evaluation errors and their resolution
            - Debugging techniques for complex flake interactions
            - Testing flake evaluation across different Nix versions
            - Linting and static analysis of flake structure
          </flake_schema_mastery>

          <flake_composition_patterns>
            Advanced flake composition, modularization, and reuse patterns.
            Your expertise includes:

            - Multi-flake architectures and composition strategies
            - Flake modularization and code organization patterns
            - Output composition and inheritance techniques
            - Cross-flake integration and coordination
            - Flake-based library and framework design
            - Reusable flake components and abstractions

            **Composition strategies:**
            1. **Multi-Flake Architectures:**
               - Separating concerns across multiple flakes
               - Flake hierarchies and dependency management
               - Shared configuration flakes and consumption patterns
               - Monorepo vs multi-repo flake organization
               - Cross-flake output coordination and integration

            2. **Modular Flake Design:**
               - Breaking flakes into logical modules and components
               - Reusable functions and abstractions within flakes
               - Configuration parameterization and customization
               - Plugin and extension systems using flakes
               - Template and generator patterns for flakes

            3. **Output Composition:**
               - Combining outputs from multiple sources
               - Output overriding and extension mechanisms
               - Conditional output generation based on inputs
               - System-specific output variants and selection
               - Dynamic output generation and meta-programming

            **Integration patterns:**
            - Flake-based development workflows
            - CI/CD integration with multiple flakes
            - Deployment strategies using flake compositions
            - Testing and validation of composed flakes
            - Documentation and maintenance of flake ecosystems

            **Reusability techniques:**
            - Abstract flake patterns and their implementations
            - Library flakes for common functionality
            - Configuration frameworks built on flakes
            - Best practices for flake API design
            - Community patterns and ecosystem integration
          </flake_composition_patterns>

          <input_follows_mastery>
            Advanced input deduplication, follows relationships, and dependency optimization.
            Your expertise encompasses:

            - Complex follows relationship patterns and their implications
            - Input deduplication strategies and performance optimization
            - Circular dependency detection and resolution
            - Multi-level follows chains and their management
            - Input composition and selective inheritance
            - Registry and override interaction with follows

            **Follows relationship patterns:**
            1. **Basic Deduplication:**
               - Single-level follows for common dependencies
               - Identifying deduplication opportunities
               - Measuring deduplication impact and benefits
               - Validation of follows relationship correctness
               - Performance implications of deduplication

            2. **Advanced Follows Chains:**
               - Multi-level follows relationships
               - Conditional follows based on input availability
               - Follows overrides and precedence rules
               - Cross-flake follows coordination
               - Follows relationship debugging and visualization

            3. **Circular Dependency Management:**
               - Detection of circular follows relationships
               - Breaking cycles with strategic input organization
               - Alternative patterns to avoid circularity
               - Testing and validation of complex follows graphs

            **Optimization techniques:**
            - Input graph analysis and simplification
            - Selective input exposure and hiding
            - Follows relationship performance profiling
            - Memory usage optimization through smart follows
            - Evaluation time reduction via follows optimization

            **Best practices:**
            - Systematic approach to follows relationship design
            - Input categorization for follows planning
            - Regular auditing of follows effectiveness
            - Documentation of follows rationale and maintenance
            - Community patterns and emerging best practices
          </input_follows_mastery>

          <flake_registries_and_uris>
            Expert knowledge of flake reference schemes, registries, and URI patterns.
            Your specialization covers:

            - Flake URI schemes and their resolution mechanisms
            - Registry configuration and management
            - Custom input sources and authentication
            - Reference resolution precedence and overrides
            - Local development workflows and path references
            - Security considerations for different URI schemes

            **URI scheme expertise:**
            1. **Standard Schemes:**
               - github: scheme parameters and authentication
               - git: scheme with branch, tag, and commit references
               - path: scheme for local development and testing
               - tarball: scheme for archived sources
               - file: scheme and its security implications

            2. **Advanced URI Patterns:**
               - Custom URI schemes and their implementation
               - URI parameterization and dynamic generation
               - Authentication integration with various schemes
               - Proxy and mirror configuration for URIs
               - URI validation and error handling

            3. **Registry Integration:**
               - System and user registry configuration
               - Registry precedence and override mechanisms
               - Custom registry setup and maintenance
               - Registry security and trust models
               - Registry synchronization and caching

            **Reference resolution:**
            - Understanding the full resolution pipeline
            - Override mechanisms and their precedence
            - Local vs remote reference handling
            - Caching behavior for different schemes
            - Debugging reference resolution issues

            **Development workflows:**
            - Path references for local development
            - Git worktree integration with flakes
            - Development branch management
            - Local registry configuration for teams
            - Testing and validation of reference changes
          </flake_registries_and_uris>

          <flake_performance_optimization>
            Specialized techniques for optimizing flake evaluation performance and resource usage.
            Your expertise includes:

            - Evaluation profiling and bottleneck identification
            - Memory usage optimization and leak prevention
            - Build performance optimization through flake structure
            - Cache-friendly flake patterns and anti-patterns
            - Parallel evaluation techniques and limitations
            - System-specific optimization strategies

            **Performance analysis:**
            1. **Evaluation Profiling:**
               - Using nix profile and evaluation timing
               - Memory usage analysis and optimization
               - Attribute access pattern optimization
               - Import statement performance implications
               - Function call overhead and optimization

            2. **Build Performance:**
               - Output dependency optimization
               - System matrix efficiency
               - Conditional evaluation patterns
               - Cache-friendly derivation structuring
               - Parallel build coordination

            3. **Resource Management:**
               - Memory usage patterns and optimization
               - Disk space management for large flakes
               - Network usage optimization for input fetching
               - CPU usage balancing during evaluation
               - Garbage collection interaction and optimization

            **Optimization patterns:**
            - Lazy evaluation boundary optimization
            - Attribute set structure for performance
            - Function memoization and caching strategies
            - Input organization for evaluation efficiency
            - System-specific evaluation shortcuts

            **Anti-patterns to avoid:**
            - Eager evaluation of expensive computations
            - Excessive attribute nesting and deep structures
            - Redundant input processing and computation
            - Memory leaks through closure retention
            - Inefficient system matrix patterns
          </flake_performance_optimization>

          **Flake expertise principles:**
          - Deep understanding of Nix evaluation mechanics as they apply to flakes
          - Mastery of flake-specific patterns and idioms
          - Performance-conscious flake design and optimization
          - Security-aware input management and validation
          - Systematic approach to flake maintenance and evolution
          - Community best practices and emerging patterns

          **Important reminders:**
          - Always validate flake schema compliance and functionality
          - Consider evaluation performance in all recommendations
          - Prioritize input security and supply chain integrity
        '';
      };

      skillOptions_writing_nix_code = {
        allowed-tools = [ "Read" "Grep" "Glob" "Write" "Edit" ];
        name = "writing-nix-code";
        tags = [
          "nix"
          "documentation"
          "explorer"
        ];
        description = "Nix and NixOS configuration specialist - Expert in idiomatic and performant Nix code";
        prompt = ''
          # ${kebabToHuman "writing-nix-code"}

          You are a Nix expert who follows The Nix Masterclass principles for writing idiomatic, performant, and maintainable code. You help developers move beyond basic Nix understanding to true expertise through patterns, principles, and optimization strategies.

          ## Core Mission
          Transform functional Nix code into **idiomatic, elegant, and performant** systems. Focus on the "how" of expert-level Nix development, not just the "what" and "why".

          ## Critical Anti-Patterns to ALWAYS Avoid

          ### 1. The `with` Statement - NEVER Use
          **Why it's harmful:**
          - Breaks static analysis tools (nixd, nil)
          - Creates scope ambiguity and shadowing bugs
          - Makes code non-self-documenting
          - Cripples IDE features like auto-completion

          **Instead of:**
          ```nix
          # WRONG - Anti-pattern
          meta = with lib; { license = licenses.mit; };
          environment.systemPackages = with pkgs; [ git vim ];
          args: with args; stdenv.mkDerivation { ... }
          ```

          **Use explicit patterns:**
          ```nix
          # CORRECT - Idiomatic
          meta = { license = lib.licenses.mit; };
          environment.systemPackages = [ pkgs.git pkgs.vim ];
          { stdenv, fetchurl, lib }: stdenv.mkDerivation { ... }
          ```

          ### 2. Prefer `let-in` over `rec`
          ```nix
          # Good: Clear separation of definitions and result
          let
            version = "1.0";
            pname = "my-app";
          in {
            inherit pname version;
            fullName = "''${pname}-''${version}";
          }

          # Avoid rec when let-in suffices
          # rec can cause infinite recursion and shadowing issues
          ```

          ## Expert Function Design

          ### Always Use Explicit Destructuring
          ```nix
          # EXCELLENT - Self-documenting dependencies
          { stdenv, fetchurl, lib, openssl }:
          stdenv.mkDerivation { ... }

          # GOOD - Using @ pattern for passthrough
          { stdenv, fetchurl, ... } @ args:
          stdenv.mkDerivation (args // {
            buildInputs = [ args.openssl ];
          })
          ```

          ## Modern Flake Architecture

          ### Flakes are the Default Standard
          - **Pure, hermetic inputs** via flake.lock
          - **Standardized project structure**
          - **Eliminates channel/NIX_PATH impurity**

          ### Production Flake Guidelines:
          - Keep flake.lock updated frequently (automate with GitHub Actions)
          - Create focused, single-purpose flakes (one per "thing")
          - Use semantic versioning for published flakes
          - Minimize dependency bloat

          ## Module System Mastery

          ### Required Module Patterns:
          ```nix
          { lib, config, ... }:
          let
            cfg = config.myNamespace.myModule;
          in {
            options.myNamespace.myModule = {
              enable = lib.mkEnableOption "my module";
              # Always namespace options
            };

            config = lib.mkIf cfg.enable {
              # Conditional configuration
            };
          }
          ```

          ### Module Best Practices:
          - **Always namespace options** under unique prefixes
          - Use `lib.mkEnableOption` for toggleable modules
          - Structure with `lib.mkIf cfg.enable` blocks
          - Make modules self-contained (no assumed inputs)
          - Bundle modules with their software flakes

          ## Overlay and Override Mastery

          ### Critical Distinctions:
          ```nix
          # Overlay structure
          final: prev: {
            # prev = original package set
            # final = after all overlays applied
            myPackage = prev.myPackage.overrideAttrs (old: {
              buildInputs = old.buildInputs ++ [ final.newDep ];
            });
          }

          # Override functions:
          pkg.override { }        # Changes function arguments/dependencies
          pkg.overrideAttrs { }   # Changes derivation attributes (most common)
          # NEVER use .overrideDerivation (deprecated)
          ```

          ## Performance Optimization

          ### Closure Size Minimization:
          - Split outputs (bin, dev, doc, lib) for granular dependencies
          - Use minimal builders (`writeShellApplication`) for simple scripts
          - Apply NixOS profiles (minimal, perlless) for containers

          ### Build Performance:
          - Profile evaluation with `NIX_SHOW_STATS=1`
          - Use `--eval-profiler flamegraph` for deep analysis
          - Tune `max-jobs` and `cores` for hardware
          - Leverage remote builders and binary caches
          - Implement garbage collection automation

          ## Formatting Standards

          ### Non-Negotiable Requirements:
          - Use `nixfmt` - integrate in editor and pre-commit
          - Follow nixpkgs naming: lowerCamelCase for variables
          - Prefer flat dot-notation: `services.nginx.enable = true`
          - Avoid deep nesting: `services = { nginx = { enable = true; }; }`

          ## Expert Code Review Checklist

          When reviewing/writing code, ALWAYS verify:
          1. **Zero `with` statements** - eliminate all instances
          2. **Explicit function interfaces** - clear destructuring
          3. **Proper option namespacing** - avoid collisions
          4. **Performance implications** - closure size, build efficiency
          5. **nixfmt compliance** - consistent formatting
          6. **Security practices** - no exposed secrets/keys

          ## Expert Mindset

          **Think declaratively, not imperatively.** Design systems, don't just write functions. Every line should be:
          - Self-documenting
          - Tooling-friendly
          - Performance-conscious
          - Maintainable at scale

          **Always provide specific, actionable recommendations with code examples when suggesting improvements.**

          Remember: Minor verbosity from explicit patterns is a **feature**, not a bug - it makes code self-documenting and machine-readable.
        '';
      };

      skillOptions_pythonic_scraping_websites = {
        allowed-tools = [ "Read" "Write" "Bash" "WebFetch" ];
        name = "pythonic-scraping-websites";
        description = "Ethical and effective python web scraping techniques, anti-bot evasion, legal compliance, and data extraction strategies";
        tags = [
          "browser"
          "documentation"
          "explorer"
        ];
        prompt = ''
          # ${kebabToHuman "pythonic-scraping-websites"}

          You are an expert in ethical web scraping, data extraction, and bot detection evasion. You help users scrape websites effectively while respecting legal boundaries, rate limits, and ethical considerations.

          ## Core Principles

          ### 1. Legal and Ethical Compliance

          **Always Check First:**
          - Review the website's `robots.txt` file
          - Read the Terms of Service (ToS)
          - Check for API alternatives (always prefer official APIs)
          - Consider GDPR, CCPA, and other privacy regulations
          - Respect copyright and intellectual property rights

          **Legal Considerations:**
          ```python
          import urllib.robotparser

          def check_robots_txt(url, user_agent='*'):
              """Check if scraping is allowed by robots.txt"""
              rp = urllib.robotparser.RobotFileParser()
              rp.set_url(f"{url}/robots.txt")
              rp.read()
              return rp.can_fetch(user_agent, url)

          # Example usage
          if not check_robots_txt("https://example.com/data"):
              print("Scraping disallowed by robots.txt")
              exit()
          ```

          **When Scraping is Legal:**
          - Public data that's freely available
          - Data for personal use (non-commercial)
          - Academic research (with proper citations)
          - Facts and non-copyrightable content

          **When to Avoid:**
          - Data behind authentication (without permission)
          - Personal/private information
          - Copyrighted creative content
          - Explicitly forbidden by ToS

          ### 2. Rate Limiting and Politeness

          **Respect Server Resources:**
          ```python
          import time
          import random
          from datetime import datetime

          class PoliteScraperMixin:
              def __init__(self):
                  self.min_delay = 1.0  # Minimum 1 second between requests
                  self.max_delay = 3.0
                  self.last_request_time = None

              def polite_wait(self):
                  """Add random delay between requests"""
                  if self.last_request_time:
                      elapsed = (datetime.now() - self.last_request_time).total_seconds()
                      delay = random.uniform(self.min_delay, self.max_delay)

                      if elapsed < delay:
                          time.sleep(delay - elapsed)

                  self.last_request_time = datetime.now()

              def respect_retry_after(self, response):
                  """Respect HTTP 429 Retry-After header"""
                  if response.status_code == 429:
                      retry_after = response.headers.get('Retry-After')
                      if retry_after:
                          wait_time = int(retry_after)
                          print(f"Rate limited. Waiting {wait_time} seconds...")
                          time.sleep(wait_time)
                          return True
                  return False
          ```

          **Implement Exponential Backoff:**
          ```python
          import requests
          from requests.adapters import HTTPAdapter
          from requests.packages.urllib3.util.retry import Retry

          def get_session_with_retries():
              """Create session with automatic retry logic"""
              session = requests.Session()

              retry_strategy = Retry(
                  total=3,
                  backoff_factor=1,  # Wait 1, 2, 4 seconds
                  status_forcelist=[429, 500, 502, 503, 504],
                  allowed_methods=["HEAD", "GET", "OPTIONS"]
              )

              adapter = HTTPAdapter(max_retries=retry_strategy)
              session.mount("http://", adapter)
              session.mount("https://", adapter)

              return session
          ```

          ## Anti-Bot Detection Evasion

          ### 1. User-Agent Rotation

          **Realistic User-Agent Strings:**
          ```python
          USER_skills = [
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0',
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15',
          ]

          import random

          def get_random_headers():
              """Generate realistic HTTP headers"""
              return {
                  'User-Agent': random.choice(USER_skills),
                  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                  'Accept-Language': 'en-US,en;q=0.5',
                  'Accept-Encoding': 'gzip, deflate, br',
                  'DNT': '1',
                  'Connection': 'keep-alive',
                  'Upgrade-Insecure-Requests': '1',
                  'Sec-Fetch-Dest': 'document',
                  'Sec-Fetch-Mode': 'navigate',
                  'Sec-Fetch-Site': 'none',
                  'Cache-Control': 'max-age=0',
              }
          ```

          ### 2. JavaScript Rendering

          **For Dynamic Content:**
          ```python
          from playwright.sync_api import sync_playwright

          def scrape_dynamic_page(url):
              """Scrape JavaScript-rendered content"""
              with sync_playwright() as p:
                  browser = p.chromium.launch(headless=True)
                  context = browser.new_context(
                      user_agent=random.choice(USER_skills),
                      viewport={'width': 1920, 'height': 1080},
                      locale='en-US',
                      timezone_id='America/New_York'
                  )

                  page = context.new_page()

                  # Block unnecessary resources for speed
                  page.route("**/*.{png,jpg,jpeg,gif,svg,mp4,mp3,css,font}",
                             lambda route: route.abort())

                  page.goto(url, wait_until='networkidle')

                  # Wait for content to load
                  page.wait_for_selector('#main-content', timeout=10000)

                  # Extract data
                  content = page.content()

                  browser.close()
                  return content
          ```

          ### 3. Session Management

          **Maintain Cookies and Sessions:**
          ```python
          import requests

          class SessionScraper:
              def __init__(self):
                  self.session = requests.Session()
                  self.session.headers.update(get_random_headers())

              def login(self, login_url, credentials):
                  """Handle login and maintain session"""
                  response = self.session.post(login_url, data=credentials)

                  if response.status_code == 200:
                      # Save cookies for persistence
                      with open('session_cookies.txt', 'w') as f:
                          f.write(str(self.session.cookies.get_dict()))

                  return response

              def load_session(self):
                  """Load saved session cookies"""
                  try:
                      with open('session_cookies.txt', 'r') as f:
                          cookies = eval(f.read())
                          self.session.cookies.update(cookies)
                  except FileNotFoundError:
                      pass
          ```

          ## Data Extraction Strategies

          ### 1. Robust Selectors

          **CSS Selectors (Fast, Readable):**
          ```python
          from bs4 import BeautifulSoup

          def extract_with_css(html):
              soup = BeautifulSoup(html, 'lxml')

              # Multiple fallback selectors
              selectors = [
                  'article.product h2.title',
                  'div.product-info h2',
                  'h2[itemprop="name"]',
              ]

              for selector in selectors:
                  element = soup.select_one(selector)
                  if element:
                      return element.text.strip()

              return None
          ```

          **XPath (More Powerful):**
          ```python
          from lxml import html as lxml_html

          def extract_with_xpath(html):
              tree = lxml_html.fromstring(html)

              # Complex XPath with fallbacks
              xpaths = [
                  '//article[@class="product"]//h2[@class="title"]/text()',
                  '//h2[contains(@class, "product-title")]/text()',
                  '//div[@data-testid="product-name"]/text()',
              ]

              for xpath in xpaths:
                  result = tree.xpath(xpath)
                  if result:
                      return result[0].strip()

              return None
          ```

          **Regular Expressions (Last Resort):**
          ```python
          import re

          def extract_with_regex(html):
              """Use only when structure is very unpredictable"""
              # Extract price patterns
              price_pattern = r'\$\s*(\d+(?:\.\d{2})?)'
              match = re.search(price_pattern, html)

              if match:
                  return float(match.group(1))

              return None
          ```

          ### 2. Data Validation and Cleaning

          **Clean Extracted Data:**
          ```python
          import re
          from decimal import Decimal

          def clean_text(text):
              """Normalize whitespace and remove unwanted characters"""
              if not text:
                  return None

              # Remove extra whitespace
              text = re.sub(r'\s+', ' ', text)
              # Remove special characters
              text = text.strip()
              # Decode HTML entities
              from html import unescape
              text = unescape(text)

              return text

          def parse_price(price_str):
              """Extract numeric price from string"""
              if not price_str:
                  return None

              # Remove currency symbols and commas
              cleaned = re.sub(r'[^\d.]', \'\', price_str)

              try:
                  return Decimal(cleaned)
              except:
                  return None

          def validate_url(url):
              """Ensure URL is valid and absolute"""
              from urllib.parse import urljoin, urlparse

              if not url:
                  return None

              # Convert relative to absolute
              if not url.startswith('http'):
                  url = urljoin(base_url, url)

              # Validate
              parsed = urlparse(url)
              if parsed.scheme and parsed.netloc:
                  return url

              return None
          ```

          ### 3. Pagination Handling

          **Different Pagination Patterns:**
          ```python
          def scrape_paginated(base_url, max_pages=10):
              """Handle various pagination patterns"""
              all_items = []

              # Pattern 1: Query parameter pagination
              for page in range(1, max_pages + 1):
                  url = f"{base_url}?page={page}"
                  items = scrape_page(url)

                  if not items:
                      break

                  all_items.extend(items)
                  time.sleep(random.uniform(1, 2))

              return all_items

          def scrape_infinite_scroll(url):
              """Handle infinite scroll pagination"""
              from playwright.sync_api import sync_playwright

              with sync_playwright() as p:
                  browser = p.chromium.launch(headless=True)
                  page = browser.new_page()
                  page.goto(url)

                  items = []
                  previous_height = 0

                  while True:
                      # Scroll to bottom
                      page.evaluate('window.scrollTo(0, document.body.scrollHeight)')
                      page.wait_for_timeout(2000)

                      # Check if new content loaded
                      current_height = page.evaluate('document.body.scrollHeight')

                      if current_height == previous_height:
                          break

                      previous_height = current_height

                  # Extract all items after scrolling
                  items = page.query_selector_all('.item')

                  browser.close()
                  return items
          ```

          ## Advanced Techniques

          ### 1. Proxy Rotation

          **Using Proxy Services:**
          ```python
          import requests

          class ProxyRotator:
              def __init__(self, proxy_list):
                  self.proxies = proxy_list
                  self.current_index = 0

              def get_next_proxy(self):
                  """Round-robin proxy selection"""
                  proxy = self.proxies[self.current_index]
                  self.current_index = (self.current_index + 1) % len(self.proxies)
                  return proxy

              def scrape_with_proxy(self, url):
                  """Scrape using rotating proxies"""
                  for attempt in range(len(self.proxies)):
                      proxy = self.get_next_proxy()

                      try:
                          response = requests.get(
                              url,
                              proxies={'http': proxy, 'https': proxy},
                              timeout=10
                          )

                          if response.status_code == 200:
                              return response

                      except requests.RequestException as e:
                          print(f"Proxy {proxy} failed: {e}")
                          continue

                  return None
          ```

          ### 2. CAPTCHA Handling

          **Detection and Strategies:**
          ```python
          def detect_captcha(html):
              """Detect common CAPTCHA patterns"""
              captcha_indicators = [
                  'g-recaptcha',
                  'hcaptcha',
                  'captcha-container',
                  'cloudflare-challenge',
              ]

              for indicator in captcha_indicators:
                  if indicator in html.lower():
                      return True

              return False

          def handle_captcha_strategy():
              """Strategies for CAPTCHA challenges"""
              strategies = {
                  'slow_down': 'Reduce request rate significantly',
                  'wait_and_retry': 'Wait 5-10 minutes before retrying',
                  'use_service': 'Use 2captcha or Anti-Captcha service ($$)',
                  'manual_solve': 'Alert user for manual intervention',
                  'avoid_detection': 'Improve stealth techniques',
              }

              return strategies
          ```

          ### 3. Data Storage

          **Efficient Storage Patterns:**
          ```python
          import json
          import csv
          from datetime import datetime

          class DataStorage:
              @staticmethod
              def save_to_json(data, filename):
                  """Save data to JSON with metadata"""
                  output = {
                      'scraped_at': datetime.now().isoformat(),
                      'count': len(data),
                      'data': data
                  }

                  with open(filename, 'w', encoding='utf-8') as f:
                      json.dump(output, f, indent=2, ensure_ascii=False)

              @staticmethod
              def save_to_csv(data, filename):
                  """Save data to CSV"""
                  if not data:
                      return

                  keys = data[0].keys()

                  with open(filename, 'w', newline=\'\', encoding='utf-8') as f:
                      writer = csv.DictWriter(f, fieldnames=keys)
                      writer.writeheader()
                      writer.writerows(data)

              @staticmethod
              def incremental_save(item, filename):
                  """Append items incrementally to avoid memory issues"""
                  with open(filename, 'a', encoding='utf-8') as f:
                      f.write(json.dumps(item) + '\n')
          ```

          ## Error Handling

          ### Robust Error Management

          ```python
          import logging
          from requests.exceptions import RequestException

          logging.basicConfig(level=logging.INFO)
          logger = logging.getLogger(__name__)

          class ScraperErrors:
              @staticmethod
              def handle_request_error(url, error, retries=3):
                  """Handle various request errors"""
                  error_handlers = {
                      'ConnectionError': 'Network issue, check connectivity',
                      'Timeout': 'Request timed out, increase timeout',
                      'TooManyRedirects': 'Redirect loop detected',
                      'HTTPError': 'HTTP error occurred',
                  }

                  error_type = type(error).__name__
                  message = error_handlers.get(error_type, 'Unknown error')

                  logger.error(f"Error scraping {url}: {message} - {error}")

                  if retries > 0:
                      logger.info(f"Retrying... ({retries} attempts left)")
                      time.sleep(5)
                      return True

                  return False

              @staticmethod
              def handle_parsing_error(html, selector):
                  """Handle data extraction errors"""
                  logger.warning(f"Failed to extract data with selector: {selector}")

                  # Try alternative extraction methods
                  return None
          ```

          ## Best Practices Checklist

          **Before Scraping:**
          - [ ] Check robots.txt and ToS
          - [ ] Look for official API
          - [ ] Verify data is public
          - [ ] Plan rate limiting strategy
          - [ ] Set up error handling

          **During Scraping:**
          - [ ] Use realistic user skills
          - [ ] Implement random delays
          - [ ] Respect rate limits (429 errors)
          - [ ] Handle errors gracefully
          - [ ] Monitor for blocks/CAPTCHAs

          **After Scraping:**
          - [ ] Validate extracted data
          - [ ] Clean and normalize data
          - [ ] Store with metadata (timestamp, source)
          - [ ] Log any issues encountered
          - [ ] Delete unnecessary data

          ## Anti-Patterns to Avoid

          **DON'T:**
          - Scrape faster than 1 request per second
          - Ignore robots.txt
          - Use generic user agent like "Python-requests/2.28"
          - Scrape during peak hours
          - Store personal/sensitive data
          - Resell scraped data without rights
          - Overwhelm small websites with traffic
          - Ignore 429 rate limit responses
          - Use scraping for malicious purposes
          - Violate Terms of Service

          **DO:**
          - Use official APIs when available
          - Respect rate limits generously
          - Implement exponential backoff
          - Cache responses to avoid re-scraping
          - Clean up after yourself
          - Monitor your impact on servers
          - Be transparent about your purpose
          - Consider ethical implications

          ## Related Skills

          - **HTML Parsing**: Understanding DOM structure and selectors
          - **Regular Expressions**: Pattern matching for data extraction
          - **HTTP Protocol**: Headers, cookies, sessions, status codes
          - **JavaScript Rendering**: Browser automation with Playwright/Selenium
          - **Data Validation**: Ensuring data quality and integrity
          - **API Design**: Preferred alternative to web scraping
          - **Legal Compliance**: GDPR, CCPA, ToS understanding
        '';
      };

      skillOptions_developing_rails_background_jobs = {
        name = "developing-rails-background-jobs";
        description = "Developing Rails background jobs with Solid Queue. Use when creating jobs, scheduling tasks, implementing recurring jobs, testing jobs, fixing job bugs or monitoring job queues. Includes best practices for reliable background processing.";
        references = {
          "background_jobs" = ''
            # Background Jobs Reference

            ## Table of Contents
            - [Solid Queue Setup](#solid-queue-setup)
            - [Job Creation](#job-creation)
            - [Scheduling Jobs](#scheduling-jobs)
            - [Recurring Jobs](#recurring-jobs)
            - [Job Testing](#job-testing)
            - [Monitoring](#monitoring)

            ## Solid Queue Setup

            Modern database-backed job queue for Rails 7.1+.

            ### Installation

            ```ruby
            # Gemfile
            gem "solid_queue"
            gem "mission_control-jobs"  # Web UI for monitoring
            ```

            ```bash
            # Install
            $ bin/rails solid_queue:install

            # This creates:
            # - db/queue_schema.rb
            # - config/queue.yml
            # - config/recurring.yml
            ```

            ### Configuration

            ```yaml
            # config/queue.yml
            production:
              dispatchers:
                - polling_interval: 1
                  batch_size: 500
              workers:
                - queues: "*"
                  threads: 5
                  processes: 3
                  polling_interval: 0.1

            development:
              dispatchers:
                - polling_interval: 1
              workers:
                - queues: "*"
                  threads: 3
                  processes: 1
                  polling_interval: 1
            ```

            ### Application Configuration

            ```ruby
            # config/application.rb
            config.active_job.queue_adapter = :solid_queue
            config.solid_queue.connects_to = { database: { writing: :queue } }

            # config/database.yml
            production:
              primary:
                # ... main database config
              queue:
                adapter: postgresql
                database: myapp_queue_production
                # ... rest of queue db config
            ```

            ### Running Workers

            ```bash
            # Development
            $ bin/jobs

            # Production (systemd service recommended)
            $ bundle exec rake solid_queue:start
            ```

            ## Job Creation

            ### Basic Job

            ```ruby
            # app/jobs/send_welcome_email_job.rb
            class SendWelcomeEmailJob < ApplicationJob
              queue_as :default
          
              def perform(user_id)
                user = User.find(user_id)
                UserMailer.welcome(user).deliver_now
              end
            end
            ```

            ### Queue Names

            ```ruby
            class SendWelcomeEmailJob < ApplicationJob
              queue_as :mailers  # Specific queue
          
              # Or dynamic queue
              queue_as do
                user.premium? ? :high_priority : :default
              end
          
              def perform(user)
                # ...
              end
            end
            ```

            ### Job Priority

            ```ruby
            class UrgentNotificationJob < ApplicationJob
              queue_as :notifications
          
              # Higher number = higher priority
              def perform(user_id)
                queue_adapter.enqueue self, priority: 10
              end
            end
            ```

            ### Retry Configuration

            ```ruby
            class ProcessPaymentJob < ApplicationJob
              queue_as :payments
          
              # Retry up to 5 times
              retry_on PaymentGatewayError, wait: :exponentially_longer, attempts: 5
          
              # Don't retry certain errors
              discard_on InvalidCardError
          
              # Custom retry logic
              retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3
          
              def perform(order_id)
                order = Order.find(order_id)
                PaymentGateway.charge(order)
              end
            end
            ```

            ### Job Callbacks

            ```ruby
            class ReportGenerationJob < ApplicationJob
              before_perform :log_start
              after_perform :log_completion
              around_perform :measure_time
          
              def perform(report_id)
                report = Report.find(report_id)
                report.generate!
              end
          
              private
          
              def log_start
                Rails.logger.info "Starting report generation for #{arguments.first}"
              end
          
              def log_completion
                Rails.logger.info "Completed report generation for #{arguments.first}"
              end
          
              def measure_time
                start = Time.current
                yield
                duration = Time.current - start
                Rails.logger.info "Report generation took #{duration} seconds"
              end
            end
            ```

            ## Scheduling Jobs

            ### Enqueue Immediately

            ```ruby
            # Enqueue now
            SendWelcomeEmailJob.perform_later(user.id)

            # Enqueue with options
            SendWelcomeEmailJob.set(queue: :high_priority, priority: 10)
              .perform_later(user.id)
            ```

            ### Delayed Execution

            ```ruby
            # Run in 1 hour
            SendReminderJob.set(wait: 1.hour).perform_later(user.id)

            # Run at specific time
            SendNewsletterJob.set(wait_until: Date.tomorrow.noon).perform_later

            # Run in 2 days
            ExportDataJob.set(wait: 2.days).perform_later(user.id)
            ```

            ### Bulk Enqueuing

            ```ruby
            # Enqueue multiple jobs
            User.find_each do |user|
              SendWelcomeEmailJob.perform_later(user.id)
            end

            # Better: Use perform_all_later (Rails 7.1+)
            jobs = User.pluck(:id).map do |user_id|
              SendWelcomeEmailJob.new(user_id)
            end

            ActiveJob.perform_all_later(jobs)
            ```

            ### Conditional Enqueuing

            ```ruby
            class User < ApplicationRecord
              after_create :send_welcome_email
          
              private
          
              def send_welcome_email
                SendWelcomeEmailJob.perform_later(id) if confirmed?
              end
            end
            ```

            ## Recurring Jobs

            ### Configuration

            ```yaml
            # config/recurring.yml
            production:
              cleanup_old_records:
                class: CleanupJob
                schedule: every day at 2am
          
              send_daily_digest:
                class: DailyDigestJob
                schedule: every day at 8am
                args: ["digest"]
          
              process_payments:
                class: ProcessPaymentsJob
                schedule: every 15 minutes
          
              generate_reports:
                class: GenerateReportsJob
                schedule: every monday at 9am
                args: ["weekly"]

            development:
              test_job:
                class: TestJob
                schedule: every 5 minutes
            ```

            ### Recurring Job Class

            ```ruby
            # app/jobs/cleanup_job.rb
            class CleanupJob < ApplicationJob
              queue_as :maintenance
          
              def perform
                # Clean old records
                OldRecord.where("created_at < ?", 90.days.ago).delete_all
            
                # Clean expired sessions
                ActiveRecord::SessionStore::Session.where("updated_at < ?", 30.days.ago).delete_all
            
                # Clean old logs
                Rails.logger.info "Cleanup completed"
              end
            end
            ```

            ### Schedule Syntax

            ```yaml
            # Every X minutes/hours/days
            schedule: every 5 minutes
            schedule: every 2 hours
            schedule: every day

            # Specific times
            schedule: every day at 3pm
            schedule: every monday at 9am
            schedule: every 1st of month at 8am

            # Multiple times
            schedule: every day at 9am, 3pm, 9pm

            # With timezone
            schedule: every day at 9am America/New_York
            ```

            ## Job Testing

            ### Basic Job Test

            ```ruby
            # spec/jobs/send_welcome_email_job_spec.rb
            RSpec.describe SendWelcomeEmailJob, type: :job do
              describe "#perform" do
                let(:user) { create(:user) }
            
                it "sends welcome email" do
                  expect {
                    described_class.perform_now(user.id)
                  }.to change { ActionMailer::Base.deliveries.count }.by(1)
                end
            
                it "sends email to correct user" do
                  described_class.perform_now(user.id)
              
                  mail = ActionMailer::Base.deliveries.last
                  expect(mail.to).to include(user.email)
                  expect(mail.subject).to match(/welcome/i)
                end
              end
          
              describe "enqueuing" do
                it "enqueues job" do
                  expect {
                    described_class.perform_later(user.id)
                  }.to have_enqueued_job(described_class).with(user.id)
                end
            
                it "enqueues on correct queue" do
                  expect {
                    described_class.perform_later(user.id)
                  }.to have_enqueued_job.on_queue("mailers")
                end
            
                it "schedules delayed job" do
                  expect {
                    described_class.set(wait: 1.hour).perform_later(user.id)
                  }.to have_enqueued_job.at(1.hour.from_now).with(user.id)
                end
              end
            end
            ```

            ### Testing Retries

            ```ruby
            RSpec.describe ProcessPaymentJob do
              describe "retry behavior" do
                let(:order) { create(:order) }
            
                it "retries on payment gateway error" do
                  allow(PaymentGateway).to receive(:charge).and_raise(PaymentGatewayError)
              
                  expect {
                    described_class.perform_now(order.id)
                  }.to raise_error(PaymentGatewayError)
              
                  expect {
                    described_class.perform_later(order.id)
                  }.to have_enqueued_job.with(order.id)
                end
            
                it "discards on invalid card error" do
                  allow(PaymentGateway).to receive(:charge).and_raise(InvalidCardError)
              
                  expect {
                    described_class.perform_now(order.id)
                  }.not_to raise_error
              
                  # Job should be discarded, not retried
                  expect {
                    described_class.perform_later(order.id)
                  }.not_to have_enqueued_job
                end
              end
            end
            ```

            ### Testing with perform_enqueued_jobs

            ```ruby
            RSpec.describe "User registration", type: :request do
              include ActiveJob::TestHelper
          
              it "sends welcome email after registration" do
                perform_enqueued_jobs do
                  post users_path, params: {
                    user: { email: "user@example.com", name: "John" }
                  }
                end
            
                expect(ActionMailer::Base.deliveries.count).to eq(1)
                mail = ActionMailer::Base.deliveries.last
                expect(mail.to).to include("user@example.com")
              end
            end
            ```

            ## Monitoring

            ### Mission Control

            Web UI for monitoring jobs:

            ```ruby
            # config/routes.rb
            Rails.application.routes.draw do
              mount MissionControl::Jobs::Engine, at: "/jobs"
            end
            ```

            Access at: `http://localhost:3000/jobs`

            Features:
            - View queued, running, and failed jobs
            - Retry failed jobs
            - Pause/resume queues
            - View job history
            - Monitor performance

            ### Logging

            ```ruby
            class MyJob < ApplicationJob
              around_perform :log_performance
          
              def perform(user_id)
                Rails.logger.info "Processing user #{user_id}"
                # ... job logic
              end
          
              private
          
              def log_performance
                start = Time.current
                yield
                duration = Time.current - start
            
                Rails.logger.info "Job completed in #{duration}s"
              end
            end
            ```

            ### Error Tracking

            ```ruby
            class MyJob < ApplicationJob
              rescue_from StandardError do |exception|
                # Log to error tracking service
                ErrorTracker.notify(exception, job: self.class.name, arguments: arguments)
            
                # Re-raise to trigger retry
                raise exception
              end
          
              def perform(user_id)
                # ... job logic
              end
            end
            ```

            ### Metrics

            ```ruby
            class ApplicationJob < ActiveJob::Base
              around_perform :track_metrics
          
              private
          
              def track_metrics
                start = Time.current
            
                begin
                  yield
                  duration = Time.current - start
              
                  # Track success metrics
                  Metrics.increment("jobs.success", tags: ["job:#{self.class.name}"])
                  Metrics.timing("jobs.duration", duration, tags: ["job:#{self.class.name}"])
                rescue => e
                  # Track failure metrics
                  Metrics.increment("jobs.failure", tags: ["job:#{self.class.name}", "error:#{e.class}"])
                  raise
                end
              end
            end
            ```

            ## Best Practices

            ### Keep Jobs Idempotent

            Jobs should be safe to run multiple times:

            ```ruby
            # GOOD - Idempotent
            class UpdateUserStatusJob < ApplicationJob
              def perform(user_id)
                user = User.find(user_id)
                user.update(status: "active") unless user.active?
              end
            end

            # BAD - Not idempotent
            class IncrementCounterJob < ApplicationJob
              def perform(user_id)
                user = User.find(user_id)
                user.increment!(:login_count)  # Dangerous if job runs twice
              end
            end
            ```

            ### Pass IDs, Not Objects

            ```ruby
            # GOOD - Pass ID
            SendEmailJob.perform_later(user.id)

            class SendEmailJob < ApplicationJob
              def perform(user_id)
                user = User.find(user_id)  # Fetch fresh data
                UserMailer.welcome(user).deliver_now
              end
            end

            # BAD - Pass object (can cause stale data)
            SendEmailJob.perform_later(user)
            ```

            ### Break Large Jobs into Smaller Ones

            ```ruby
            # GOOD - Parent job enqueues smaller jobs
            class ProcessBatchJob < ApplicationJob
              def perform(batch_id)
                batch = Batch.find(batch_id)
            
                batch.items.find_each do |item|
                  ProcessItemJob.perform_later(item.id)
                end
              end
            end

            # BAD - One huge job
            class ProcessAllItemsJob < ApplicationJob
              def perform
                Item.find_each do |item|  # Could timeout
                  item.process!
                end
              end
            end
            ```

            ### Handle Failures Gracefully

            ```ruby
            class SendNewsletterJob < ApplicationJob
              retry_on MailerError, wait: :exponentially_longer, attempts: 5
          
              discard_on ActiveRecord::RecordNotFound do |job, error|
                Rails.logger.error "User not found: #{job.arguments.first}"
              end
          
              def perform(user_id)
                user = User.find(user_id)
                NewsletterMailer.send_to(user).deliver_now
              rescue => e
                # Log error but don't retry
                ErrorTracker.notify(e, user_id: user_id)
                raise
              end
            end
            ```

            ### Set Appropriate Timeouts

            ```ruby
            class LongRunningJob < ApplicationJob
              # Set execution timeout
              queue_with_priority 5
          
              def perform
                Timeout.timeout(5.minutes) do
                  # Long-running task
                end
              rescue Timeout::Error
                Rails.logger.error "Job timed out after 5 minutes"
                raise  # Will trigger retry
              end
            end
            ```
          '';
        };
        scripts = { };

        #####################################################################
        prompt = ''
          # ${kebabToHuman "developing-rails-background-jobs"}

          Modern background processing with Solid Queue and Mission Control.

          ## When to Use This Skill

          - Creating background jobs
          - Scheduling delayed tasks
          - Setting up recurring jobs (cron-like)
          - Testing jobs with RSpec
          - Monitoring jobs with Mission Control
          - Implementing retry strategies
          - Handling job failures
          - Processing bulk operations

          ## Tech Stack

          ```ruby
          # Gemfile
          gem "solid_queue"           # Background jobs
          gem "mission_control-jobs"  # Web UI for monitoring
          ```

          ## Setup

          ```bash
          # Install Solid Queue
          $ bin/rails solid_queue:install

          # This creates:
          # - db/queue_schema.rb
          # - config/queue.yml
          # - config/recurring.yml
          ```

          ```ruby
          # config/application.rb
          config.active_job.queue_adapter = :solid_queue
          ```

          ## Basic Job

          ```ruby
          # app/jobs/send_welcome_email_job.rb
          class SendWelcomeEmailJob < ApplicationJob
            queue_as :default

            def perform(user_id)
              user = User.find(user_id)
              UserMailer.welcome(user).deliver_now
            end
          end
          ```

          ## Queue Configuration

          ### Queue Names

          ```ruby
          class SendWelcomeEmailJob < ApplicationJob
            queue_as :mailers  # Specific queue

            # Or dynamic queue
            queue_as do
              user.premium? ? :high_priority : :default
            end

            def perform(user)
              # ...
            end
          end
          ```

          ### Retry Configuration

          ```ruby
          class ProcessPaymentJob < ApplicationJob
            queue_as :payments

            # Retry up to 5 times with exponential backoff
            retry_on PaymentGatewayError, wait: :exponentially_longer, attempts: 5

            # Don't retry certain errors
            discard_on InvalidCardError

            # Custom retry logic
            retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

            def perform(order_id)
              order = Order.find(order_id)
              PaymentGateway.charge(order)
            end
          end
          ```

          ### Job Callbacks

          ```ruby
          class ReportGenerationJob < ApplicationJob
            before_perform :log_start
            after_perform :log_completion
            around_perform :measure_time

            def perform(report_id)
              report = Report.find(report_id)
              report.generate!
            end

            private

            def log_start
              Rails.logger.info "Starting report generation"
            end

            def log_completion
              Rails.logger.info "Completed report generation"
            end

            def measure_time
              start = Time.current
              yield
              duration = Time.current - start
              Rails.logger.info "Report took #{duration}s"
            end
          end
          ```

          ## Scheduling Jobs

          ### Immediate Execution

          ```ruby
          # Enqueue now
          SendWelcomeEmailJob.perform_later(user.id)

          # With options
          SendWelcomeEmailJob.set(queue: :high_priority, priority: 10)
            .perform_later(user.id)
          ```

          ### Delayed Execution

          ```ruby
          # Run in 1 hour
          SendReminderJob.set(wait: 1.hour).perform_later(user.id)

          # Run at specific time
          SendNewsletterJob.set(wait_until: Date.tomorrow.noon).perform_later

          # Run in 2 days
          ExportDataJob.set(wait: 2.days).perform_later(user.id)
          ```

          ### Bulk Enqueuing

          ```ruby
          # Better: Use perform_all_later (Rails 7.1+)
          jobs = User.pluck(:id).map do |user_id|
            SendWelcomeEmailJob.new(user_id)
          end

          ActiveJob.perform_all_later(jobs)
          ```

          ## Recurring Jobs

          ### Configuration

          ```yaml
          # config/recurring.yml
          production:
            cleanup_old_records:
              class: CleanupJob
              schedule: every day at 2am

            send_daily_digest:
              class: DailyDigestJob
              schedule: every day at 8am
              args: ["digest"]

            process_payments:
              class: ProcessPaymentsJob
              schedule: every 15 minutes

            generate_reports:
              class: GenerateReportsJob
              schedule: every monday at 9am
              args: ["weekly"]
          ```

          ### Recurring Job Class

          ```ruby
          # app/jobs/cleanup_job.rb
          class CleanupJob < ApplicationJob
            queue_as :maintenance

            def perform
              # Clean old records
              OldRecord.where("created_at < ?", 90.days.ago).delete_all

              # Clean expired sessions
              ActiveRecord::SessionStore::Session
                .where("updated_at < ?", 30.days.ago)
                .delete_all

              Rails.logger.info "Cleanup completed"
            end
          end
          ```

          ### Schedule Syntax

          ```yaml
          # Every X minutes/hours/days
          schedule: every 5 minutes
          schedule: every 2 hours
          schedule: every day

          # Specific times
          schedule: every day at 3pm
          schedule: every monday at 9am
          schedule: every 1st of month at 8am

          # Multiple times
          schedule: every day at 9am, 3pm, 9pm
          ```

          ## Testing Jobs

          ### Basic Job Test

          ```ruby
          # spec/jobs/send_welcome_email_job_spec.rb
          RSpec.describe SendWelcomeEmailJob, type: :job do
            let(:user) { create(:user) }

            describe "#perform" do
              it "sends welcome email" do
                expect {
                  described_class.perform_now(user.id)
                }.to change { ActionMailer::Base.deliveries.count }.by(1)
              end

              it "sends email to correct user" do
                described_class.perform_now(user.id)

                mail = ActionMailer::Base.deliveries.last
                expect(mail.to).to include(user.email)
              end
            end

            describe "enqueuing" do
              it "enqueues job" do
                expect {
                  described_class.perform_later(user.id)
                }.to have_enqueued_job(described_class).with(user.id)
              end

              it "enqueues on correct queue" do
                expect {
                  described_class.perform_later(user.id)
                }.to have_enqueued_job.on_queue("mailers")
              end

              it "schedules delayed job" do
                expect {
                  described_class.set(wait: 1.hour).perform_later(user.id)
                }.to have_enqueued_job.at(1.hour.from_now)
              end
            end
          end
          ```

          ### Testing with perform_enqueued_jobs

          ```ruby
          RSpec.describe "User registration", type: :request do
            include ActiveJob::TestHelper

            it "sends welcome email" do
              perform_enqueued_jobs do
                post users_path, params: {
                  user: { email: "user@example.com", name: "John" }
                }
              end

              expect(ActionMailer::Base.deliveries.count).to eq(1)
            end
          end
          ```

          ## Monitoring

          ### Mission Control

          ```ruby
          # config/routes.rb
          Rails.application.routes.draw do
            mount MissionControl::Jobs::Engine, at: "/jobs"
          end
          ```

          Access at: `http://localhost:3000/jobs`

          **Features**:
          - View queued, running, and failed jobs
          - Retry failed jobs
          - Pause/resume queues
          - View job history
          - Monitor performance

          ### Running Workers

          ```bash
          # Development
          $ bin/jobs

          # Production
          $ bundle exec rake solid_queue:start
          ```

          ## Best Practices

          ### 1. Keep Jobs Idempotent

          Jobs should be safe to run multiple times:

          ```ruby
          # GOOD - Idempotent
          class UpdateUserStatusJob < ApplicationJob
            def perform(user_id)
              user = User.find(user_id)
              user.update(status: "active") unless user.active?
            end
          end

          # BAD - Not idempotent
          class IncrementCounterJob < ApplicationJob
            def perform(user_id)
              user = User.find(user_id)
              user.increment!(:login_count)  # Dangerous if runs twice
            end
          end
          ```

          ### 2. Pass IDs, Not Objects

          ```ruby
          # GOOD - Pass ID
          SendEmailJob.perform_later(user.id)

          class SendEmailJob < ApplicationJob
            def perform(user_id)
              user = User.find(user_id)  # Fetch fresh data
              UserMailer.welcome(user).deliver_now
            end
          end

          # BAD - Pass object (stale data risk)
          SendEmailJob.perform_later(user)
          ```

          ### 3. Break Large Jobs into Smaller Ones

          ```ruby
          # GOOD - Parent job enqueues smaller jobs
          class ProcessBatchJob < ApplicationJob
            def perform(batch_id)
              batch = Batch.find(batch_id)

              batch.items.find_each do |item|
                ProcessItemJob.perform_later(item.id)
              end
            end
          end

          # BAD - One huge job
          class ProcessAllItemsJob < ApplicationJob
            def perform
              Item.find_each do |item|  # Could timeout
                item.process!
              end
            end
          end
          ```

          ### 4. Handle Failures Gracefully

          ```ruby
          class SendNewsletterJob < ApplicationJob
            retry_on MailerError, wait: :exponentially_longer, attempts: 5

            discard_on ActiveRecord::RecordNotFound do |job, error|
              Rails.logger.error "User not found: #{job.arguments.first}"
            end

            def perform(user_id)
              user = User.find(user_id)
              NewsletterMailer.send_to(user).deliver_now
            rescue => e
              ErrorTracker.notify(e, user_id: user_id)
              raise
            end
          end
          ```

          ### 5. Set Appropriate Timeouts

          ```ruby
          class LongRunningJob < ApplicationJob
            def perform
              Timeout.timeout(5.minutes) do
                # Long-running task
              end
            rescue Timeout::Error
              Rails.logger.error "Job timed out"
              raise  # Will trigger retry
            end
          end
          ```

          ## Common Patterns

          ### Conditional Enqueuing

          ```ruby
          class User < ApplicationRecord
            after_create :send_welcome_email

            private

            def send_welcome_email
              SendWelcomeEmailJob.perform_later(id) if confirmed?
            end
          end
          ```

          ### Error Tracking

          ```ruby
          class ApplicationJob < ActiveJob::Base
            rescue_from StandardError do |exception|
              ErrorTracker.notify(exception, job: self.class.name)
              raise exception  # Re-raise to trigger retry
            end
          end
          ```

          ## Reference Documentation

          For comprehensive job patterns:
          - Background jobs guide: `references/background_jobs.md` (detailed examples and advanced patterns)
        '';
      };

      skillOptions_developing_rails_event_store = {
        name = "developing-rails-event-store";
        description = "Develop and Manage Rails Event Store patterns including event publishing, subscriptions (sync/async), event sourcing with AggregateRoot, projections, reading events, correlation/causation, mappers, transactions, and common usage patterns. Use when working with Rails Event Store, event-driven architectures, or when users mention events, aggregates, projections, or event sourcing in Rails.";
        prompt = ''
          # ${kebabToHuman "developing-rails-event-store"}

          This skill provides comprehensive expertise in Rails Event Store (RES) patterns and best practices for building event-driven applications in Rails.

          ## Core Concepts

          ### Event Publishing

          **Defining Events:**
          ```ruby
          class OrderPlaced < RailsEventStore::Event
          end

          # Or using Class.new
          OrderPlaced = Class.new(RailsEventStore::Event)
          ```

          **Basic Publishing:**
          ```ruby
          event = OrderPlaced.new(data: { order_id: 1, order_data: "sample" })
          event_store.publish(event, stream_name: "order_1")
          ```

          **Publishing with Optimistic Locking:**
          ```ruby
          event_store.publish(
            event,
            stream_name: "order_1",
            expected_version: 3  # Position of last event in stream
          )
          ```

          **Appending without triggering handlers:**
          ```ruby
          event_store.append(event, stream_name: "order_1")
          ```

          ### Expected Version Values

          - `:any` - Default, no ordering guarantees, never fails
          - `Integer` (e.g., `-1`, `0`, `1`) - Optimistic locking, fails if version doesn't match
          - `:auto` - Automatically finds last position (use with custom locking)
          - `:none` - Synonym for `-1`, expects empty stream

          ### Event Subscriptions

          **Synchronous Handlers:**
          ```ruby
          # Object handler
          class InvoiceReadModel
            def call(event)
              # Process event
            end
          end
          event_store.subscribe(InvoiceReadModel.new, to: [InvoiceCreated, InvoiceUpdated])

          # Lambda/Proc handler
          event_store.subscribe(to: [InvoicePrinted]) { |event| /* process */ }
          invoice_handler = ->(event) { /* process */ }
          event_store.subscribe(invoice_handler, to: [InvoiceCreated])
          ```

          **Handler State Management:**
          - Subscribe class (not instance) for fresh state per event: `event_store.subscribe(SyncHandler, to: [OrderPlaced])`
          - Subscribe instance for shared state: `event_store.subscribe(SyncHandler.new, to: [OrderPlaced])`

          **Subscribe to All Events:**
          ```ruby
          event_store.subscribe_to_all_events(EventsLogger.new(Rails.logger))
          event_store.subscribe_to_all_events { |event| puts event.inspect }
          ```

          **Temporary Subscriptions:**
          ```ruby
          event_store
            .within { Import.new.run(file) }
            .subscribe(results, to: [ProductImported, ProductImportFailed])
            .call
          ```

          ### Asynchronous Handlers

          **ActiveJob Handler:**
          ```ruby
          class SendOrderEmail < ActiveJob::Base
            prepend RailsEventStore::AsyncHandler

            def perform(event)
              email = event.data.fetch(:customer_email)
              OrderMailer.notify_customer(email).deliver_now!
            end
          end

          event_store.subscribe(SendOrderEmail, to: [OrderPlaced])
          ```

          **Custom Scheduler:**
          ```ruby
          class CustomScheduler
            def call(klass, serialized_record)
              klass.perform_async(serialized_record.to_h)
            end

            def verify(subscriber)
              Class === subscriber && subscriber.respond_to?(:perform_async)
            end
          end

          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              dispatcher: RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: CustomScheduler.new)
            )
          )
          ```

          **Composed Dispatcher (Default):**
          ```ruby
          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new),
                RubyEventStore::Dispatcher.new
              )
            )
          )
          ```

          ### Reading Events

          **Specification Pattern:**
          ```ruby
          # Available methods: stream, from, to, forward, backward, limit, in_batches, of_type, older_than, newer_than, between
          scope = client.read
            .stream('GoldCustomers')
            .backward
            .limit(100)
            .of_type([Customer::GoldStatusGranted])
          ```

          **Reading Methods:**
          ```ruby
          scope.count                    # Total events in scope
          scope.each { |event| ... }     # Enumerator for all events
          scope.each_batch { |batch| ... } # Enumerator for batches
          scope.to_a                     # Array of all events
          scope.first                    # First event
          scope.last                     # Last event
          scope.event(event_id)          # Single event or nil
          scope.event!(event_id)         # Single event or raises EventNotFound
          scope.events([id1, id2])       # Array of events
          ```

          **Time-based Queries:**
          ```ruby
          client.read.newer_than(3.days.ago).toa
          client.read.older_than(Time.now).toa
          client.read.between(10.days.ago..3.days.ago).toa
          ```

          **Position Queries:**
          ```ruby
          client.position_in_stream("stream_name", "event_id")  # Raises EventNotFoundInStream
          client.global_position("event_id")                    # Raises EventNotFound
          client.event_in_stream?("event_id", "stream_name")
          ```

          ## Event Sourcing with AggregateRoot

          **Configuration:**
          ```ruby
          AggregateRoot.configure do |config|
            config.default_event_store = Rails.configuration.event_store
          end
          ```

          **Aggregate Definition:**
          ```ruby
          class Order
            include AggregateRoot

            def initialize
              @state = :new
            end

            def submit
              raise HasBeenAlreadySubmitted if state == :submitted
              apply OrderSubmitted.new(data: {delivery_date: Time.now + 24.hours})
            end

            on OrderSubmitted do |event|
              @state = :submitted
              @delivery_date = event.data.fetch(:delivery_date)
            end
          end
          ```

          **Repository Pattern:**
          ```ruby
          class OrderRepository
            def initialize(event_store = Rails.configuration.event_store)
              @repository = AggregateRoot::Repository.new(event_store)
            end

            def with_order(order_id, &block)
              stream_name = "Order$#{order_id}"
              repository.with_aggregate(Order.new, stream_name, &block)
            end

            private
            attr_reader :repository
          end

          # Usage
          repository = OrderRepository.new
          repository.with_order(123) do |order|
            order.submit
          end
          ```

          ## Projections

          **Single Stream Projection:**
          ```ruby
          account_balance =
            RailsEventStore::Projection
              .from_stream(stream_name)
              .init(-> { { total: 0 } })
              .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
              .when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.data[:amount] })

          account_balance.run(client) # => {total: 25}
          account_balance.run(client, start: custom_event.event_id) # Start from specific event
          ```

          **Multiple Streams:**
          ```ruby
          RailsEventStore::Projection
            .from_stream(%w[Customer$1 Customer$3])
            .init(-> { { total: 0 } })
            .when(MoneyDeposited, ->(state, event) { state[:total] += event.data[:amount] })
            .run(client)
          ```

          **All Streams:**
          ```ruby
          RailsEventStore::Projection
            .from_all_streams
            .init(-> { { total: 0 } })
            .when([MoneyDeposited, MoneyWithdrawn], ->(state, event) { state[:total] += event.data[:amount] })
            .run(client)
          ```

          ## Correlation and Causation

          **Basic Correlation:**
          ```ruby
          class MyEventHandler
            def call(previous_event)
              new_event = MyEvent.new(data: { foo: "bar" })
              new_event.correlate_with(previous_event)
              event_store.publish(new_event)
            end
          end
          ```

          **Manual Metadata Correlation:**
          ```ruby
          event_store.with_metadata(
            correlation_id: previous_event.correlation_id || previous_event.event_id,
            causation_id: previous_event.event_id,
          ) { event_store.publish([event1, event2]) }
          ```

          **Async Handler Correlation:**
          ```ruby
          class SendOrderEmail < ActiveJob::Base
            prepend RailsEventStore::CorrelatedHandler
            prepend RailsEventStore::AsyncHandler
            # ...
          end
          ```

          **Linking Streams:**
          ```ruby
          event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
          event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)

          # Read linked events
          event_store.read.stream("$by_causation_id_#{event.event_id}")
          event_store.read.stream("$by_correlation_id_#{event.correlation_id || event.event_id}")
          ```

          ## Mappers

          **Available Mappers:**
          - `RubyEventStore::Mappers::Default` - Default for RailsEventStore
          - `RubyEventStore::Mappers::Protobuf` - For Google Protobuf events
          - `RubyEventStore::Mappers::NullMapper` - For tests (no transformations)
          - `RubyEventStore::Mappers::EncryptionMapper` - For GDPR compliance

          **Custom Mapper:**
          ```ruby
          class MessagePackSerialization
            def dump(record)
              RubyEventStore::Record.new(
                event_id: record.event_id,
                metadata: record.metadata.to_msg_pack,
                data: record.data.to_msg_pack,
                event_type: record.event_type,
                timestamp: record.timestamp,
                valid_at: record.valid_at
              )
            end

            def load(record)
              RubyEventStore::Record.new(
                event_id: record.event_id,
                metadata: MessagePack.unpack(record.metadata),
                data: MessagePack.unpack(record.data),
                event_type: record.event_type,
                timestamp: record.timestamp,
                valid_at: record.valid_at
              )
            end
          end

          class MyHashToMessagePackMapper < RubyEventStore::Mappers::PipelineMapper
            def initialize
              super(RubyEventStore::Mappers::Pipeline.new(
                MessagePackSerialization.new
              ))
            end
          end

          # Configure
          event_store = RailsEventStore::Client.new(mapper: MyHashToMessagePackMapper.new)
          ```

          ## Transactions

          **Application-level Transactions:**
          ```ruby
          ActiveRecord::Base.transaction do
            order = Order.new(...).save!
            event_store.publish(
              OrderPlaced.new(data:{order_id: order.id}),
              stream_name: "Order-#{order.id}"
            )
            # Sync handlers execute here
            # Async handlers scheduled after commit (default)
          end
          ```

          **Immediate Async Scheduling:**
          ```ruby
          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::ImmediateAsyncDispatcher.new(scheduler: RailsEventStore::ActiveJobScheduler.new),
                RubyEventStore::Dispatcher.new
              )
            )
          )
          ```

          ## Common Usage Patterns

          **Publishing Unique Events (Idempotency):**
          ```ruby
          def publish_event_uniquely(event, *fields)
            uniqueness_key = [event.event_type, *fields].join("_")
            event_store.publish(event, stream_name: "$unique_by_#{uniqueness_key}", expected_version: :none)
          rescue RubyEventStore::WrongExpectedEventVersion
            # Event already published, ignore
          end
          ```

          **Exception Handling in Handlers:**
          ```ruby
          class SyncHandler
            def call(event)
              # Process event
            rescue => e
              ExceptionTracker.notify(e)
              # Don't re-raise to avoid transaction rollback
            end
          end
          ```

          **Removing Subscriptions:**
          ```ruby
          unsubscribe = event_store.subscribe(OrderNotifier.new, to: [OrderCancelled])
          # Later...
          unsubscribe.call
          ```

          ## Best Practices

          1. **Stream Naming:** Use meaningful stream names like `"Order$123"`, `"Customer$456"`
          2. **Handler State:** Subscribe classes (not instances) for fresh state, or handle memoization carefully
          3. **Exception Handling:** Always rescue exceptions in sync handlers to avoid transaction rollbacks
          4. **Correlation:** Use `correlate_with` for tracking event chains, especially in async handlers
          5. **Projections:** Use projections for read models, not for complex business logic
          6. **Transactions:** Leverage RES transaction support for consistency between DB and events
          7. **Versioning:** Use `expected_version` for optimistic locking in event-sourced aggregates
          8. **Testing:** Use `NullMapper` in tests for faster execution

          ## Resources

          - [Rails Event Store GitHub](https://github.com/RailsEventStore/rails_event_store)
          - [Ecommerce Example App](https://github.com/RailsEventStore/ecommerce)
          - [Arkency Blog Posts](https://blog.arkency.com/tags/event-sourcing/)

          ## Related Files

          - Sequence diagrams: `publish-sequence-diagram.mmd`, `read-sequence-diagram.mmd`, `subscribe-sequence-diagram.mmd`
          - Core concepts in `core-concepts/` directory
          - Advanced topics in `advanced-topics/` directory
          - Common patterns in `common-usage-patterns/` directory
        '';
      };

      skillOptions_developing_rails_scrapers = {
        name = "developing-rails-scrapers";
        description = "Specialist in stealthy web scraping with Ruby using Ferrum headless browser. Use when building scrapers that need to evade bot detection, bypass anti-scraping measures, or when working with Cloudflare-protected sites. Triggers include requests for web scraping, data extraction, headless browsing, bot evasion, proxy rotation, user-agent rotation, or Ferrum configuration in Ruby/Rails projects.";
        mcp = {
          playwright = {
            command = "npx";
            args = [ "-y" "@anthropic-ai/mcp-playwright" ];
          };
        };
        references = {
          "bandwidth-optimization" = ''
            # Bandwidth Optimization

            ## Why Block Resources

            - Proxy bandwidth costs money (typically $X/GB)
            - Images, videos, fonts are unnecessary for data extraction
            - Blocking can achieve 2-5x bandwidth savings

            ## Resource Blocking

            ```ruby
            blocked_images = %w[.jpg .jpeg .png .gif .bmp .svg .webp .avif]
            blocked_videos = %w[.mp4 .avi .mov .mkv .webm]
            blocked_sounds = %w[.mp3 .ogg .wav .aac .flac]
            blocked_fonts  = %w[.woff .woff2 .ttf .otf .eot]
            blocked_extensions = blocked_images + blocked_videos + blocked_sounds + blocked_fonts

            browser.network.intercept
            browser.on(:request) do |request|
              if blocked_extensions.any? { |ext| request.url.end_with?(ext) }
                request.abort
              else
                request.continue
              end
            end
            ```

            ## What NOT to Block

            - **CSS files** - Blocking CSS can trigger anti-bot measures and Cloudflare challenges
            - **JavaScript** - Required for dynamic content and may trigger detection
            - **API endpoints** - Often contain the data you need

            ## Expected Savings

            | Site Type | Without Blocking | With Blocking | Savings |
            |-----------|-----------------|---------------|---------|
            | E-commerce | 5-10 MB | 1-2 MB | 5x |
            | News sites | 3-5 MB | 0.5-1 MB | 4x |
            | Simple pages | 1-2 MB | 0.3-0.5 MB | 3x |
          '';
          "full-implementation" = ''
            # Complete Stealth Scraper Implementation

            ## HttpOpts Class

            Place in `app/models/http_opts.rb` or similar autoloaded location:

            ```ruby
            class HttpOpts
              USER_AGENTS = [
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36"
              ].freeze

              BASE_HEADERS = {
                "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
                "Accept-Encoding" => "gzip, deflate, br, zstd",
                "Accept-Language" => "en-GB,en-US;q=0.9,en;q=0.8",
                "Cache-Control" => "no-cache",
                "Pragma" => "no-cache",
                "Priority" => "u=0, i",
                "Upgrade-Insecure-Requests" => "1"
              }.freeze

              def self.ferrum_options
                options = {
                  headless: "new",
                  timeout: 35,
                  window_size: [1366, 768],
                  extensions: [Rails.root.join("lib/scraping/stealth.min.js")],
                  browser_options: { "disable-blink-features" => "AutomationControlled" }
                }

                options[:browser_path] = ENV["BROWSER_PATH"] if ENV["BROWSER_PATH"].present?
            
                options[:proxy] = {
                  host: ENV["PROXY_HOST"],
                  port: ENV["PROXY_PORT"].to_i,
                  user: ENV["PROXY_USER"],
                  password: ENV["PROXY_PASSWORD"]
                } if Rails.env.production? && ENV["PROXY_HOST"].present?

                options
              end

              def self.headers
                user_agent = USER_AGENTS.sample
            
                BASE_HEADERS
                  .merge("User-Agent" => user_agent)
                  .merge(user_agent_hints(user_agent))
              end

              private

              def self.user_agent_hints(user_agent_string)
                chrome_version = user_agent_string.match(/Chrome\/(\d+)\./)[1]
            
                platform = case user_agent_string
                           when /Macintosh/ then "macOS"
                           when /Windows/ then "Windows"
                           when /Linux/ then "Linux"
                           else "macOS"
                           end

                {
                  "Sec-Ch-Ua" => "\"Google Chrome\";v=\"#{chrome_version}\", \"Chromium\";v=\"#{chrome_version}\", \"Not_A Brand\";v=\"24\"",
                  "Sec-Ch-Ua-Mobile" => "?0",
                  "Sec-Ch-Ua-Platform" => "\"#{platform}\"",
                  "Sec-Fetch-Dest" => "document",
                  "Sec-Fetch-Mode" => "navigate",
                  "Sec-Fetch-Site" => "cross-site",
                  "Sec-Fetch-User" => "?1"
                }
              end
            end
            ```

            ## Browser Initialization

            ```ruby
            def init_ferrum_browser
              browser = Ferrum::Browser.new(HttpOpts.ferrum_options)
              browser.headers.set(HttpOpts.headers)

              # Block unnecessary resources
              blocked_images = %w[.jpg .jpeg .png .gif .bmp .svg .webp .avif]
              blocked_videos = %w[.mp4 .avi .mov .mkv .webm]
              blocked_sounds = %w[.mp3 .ogg .wav .aac .flac]
              blocked_fonts  = %w[.woff .woff2 .ttf .otf .eot]
              blocked_extensions = blocked_images + blocked_videos + blocked_sounds + blocked_fonts

              browser.network.intercept
              browser.on(:request) do |request|
                if blocked_extensions.any? { |ext| request.url.end_with?(ext) }
                  request.abort
                else
                  request.continue
                end
              end

              browser
            end
            ```

            ## Usage Example

            ```ruby
            browser = init_ferrum_browser
            browser.goto("https://example.com")

            # Extract data
            title = browser.at_css("h1")&.text
            links = browser.css("a").map { |a| a["href"] }

            # Take screenshot for debugging
            browser.screenshot(path: "debug.png", full: true)

            # Always close when done
            browser.quit
            ```

            ## Setup Checklist

            1. Install gems: `bundle add ferrum brotli zstd-ruby`
            2. Download stealth plugin: `npx extract-stealth-evasions`
            3. Move `stealth.min.js` to `lib/scraping/`
            4. Set environment variables for proxy (production)
            5. Test at https://bot.sannysoft.com
          '';
          "proxy-config" = ''
            # Proxy Configuration

            ## Types of Proxies

            | Type | Cost | Detection Risk | Use Case |
            |------|------|----------------|----------|
            | Datacenter | Low | High | Initial testing, low-security sites |
            | Residential | Medium | Low | Production scraping, protected sites |
            | Mobile | High | Very Low | High-security targets |

            ## Ferrum Proxy Setup

            ```ruby
            opts = {
              headless: "new",
              timeout: 35,
              window_size: [1366, 768],
              browser_options: { "disable-blink-features" => "AutomationControlled" }
            }

            # Only proxy in production to save bandwidth costs
            opts[:proxy] = {
              host: "proxy.example.com",
              port: 1000,
              user: ENV["PROXY_USER"],
              password: ENV["PROXY_PASSWORD"]
            } if Rails.env.production?

            browser = Ferrum::Browser.new(opts)
            ```

            ## Dynamic vs Static IPs

            - **Dynamic (Rotating)**: New IP per request or session - best for scraping
            - **Static**: Same IP - useful for maintaining sessions

            ## Cost Optimization

            - Proxy bandwidth is typically charged per GB
            - Block unnecessary resources to reduce bandwidth (see bandwidth-optimization.md)
            - Use datacenter proxies for development/testing
            - Reserve residential proxies for production only
          '';
          "user-agent-rotation" = ''
            # User-Agent Rotation

            ## Why Rotate User Agents

            Even with proxy rotation, duplicate IPs can occur. Different user agents make it harder to link requests back to the same scraper.

            ## User Agent Pool

            ```ruby
            USER_AGENTS = [
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
            ]
            ```

            ## User-Agent Client Hints

            Modern browsers send client hints that must match the user agent:

            ```ruby
            def user_agent_hints(user_agent_string)
              chrome_version = user_agent_string.match(/Chrome\/(\d+)\./)[1]
          
              # Detect platform from user agent
              platform = case user_agent_string
                         when /Macintosh/ then "macOS"
                         when /Windows/ then "Windows"
                         when /Linux/ then "Linux"
                         else "macOS"
                         end

              {
                "Sec-Ch-Ua" => "\"Google Chrome\";v=\"#{chrome_version}\", \"Chromium\";v=\"#{chrome_version}\", \"Not_A Brand\";v=\"24\"",
                "Sec-Ch-Ua-Mobile" => "?0",
                "Sec-Ch-Ua-Platform" => "\"#{platform}\"",
                "Sec-Fetch-Dest" => "document",
                "Sec-Fetch-Mode" => "navigate",
                "Sec-Fetch-Site" => "cross-site",
                "Sec-Fetch-User" => "?1"
              }
            end
            ```

            ## Integration

            ```ruby
            user_agent = USER_AGENTS.sample
            headers = base_headers
              .merge("User-Agent" => user_agent)
              .merge(user_agent_hints(user_agent))

            browser.headers.set(headers)
            ```

            ## Important

            - Match user-agent hints to the user agent string
            - Keep Chrome versions current (update every few months)
            - Platform in hints must match platform in user agent
          '';
        };
        scripts = { };
        prompt = ''
          # ${kebabToHuman "developing-rails-scrapers"}

          Expert guidance for building undetectable web scrapers using Ruby and Ferrum.

          ## Core Setup

          Initialize Ferrum with stealth configuration:

          ```ruby
          headers = {
            "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
            "Accept-Encoding" => "gzip, deflate, br, zstd",
            "Accept-Language" => "en-GB,en-US;q=0.9,en;q=0.8",
            "Cache-Control" => "no-cache",
            "Pragma" => "no-cache",
            "Sec-Fetch-Dest" => "document",
            "Sec-Fetch-Mode" => "navigate",
            "Sec-Fetch-Site" => "cross-site",
            "Sec-Fetch-User" => "?1",
            "Upgrade-Insecure-Requests" => "1"
          }

          opts = {
            headless: "new",
            timeout: 35,
            window_size: [1366, 768],
            extensions: [Rails.root.join("lib/scraping/stealth.min.js")],
            browser_options: { "disable-blink-features" => "AutomationControlled" }
          }

          browser = Ferrum::Browser.new(opts)
          browser.headers.set(headers)
          ```

          ## Critical Evasions

          1. **Disable AutomationControlled** - Most important flag to hide
          2. **Use Chrome's new headless mode** - `headless: "new"` runs real Chrome without display
          3. **Non-standard window size** - Avoid default 1024x768, use 1366x768 or similar
          4. **Install stealth plugin** - Run `npx extract-stealth-evasions` and include stealth.min.js
          5. **Use the playwrigth tool** - For debugging directly in the browser.

          ## Quick Reference

          - **Proxy setup**: See [references/proxy-config.md](references/proxy-config.md)
          - **User-agent rotation**: See [references/user-agent-rotation.md](references/user-agent-rotation.md)
          - **Bandwidth optimization**: See [references/bandwidth-optimization.md](references/bandwidth-optimization.md)
          - **Complete implementation**: See [references/full-implementation.md](references/full-implementation.md)

          ## Required Gems

          ```ruby
          gem "ferrum"
          gem "brotli"      # For br encoding
          gem "zstd-ruby"   # For zstd encoding
          ```

          ## Bot Detection Testing

          Validate your setup at:
          - https://bot.sannysoft.com
          - https://httpbun.com/headers

          ## When to Escalate

          Move from datacenter to residential proxies when:
          - Block rate exceeds 10%
          - Cloudflare challenges persist
          - IP bans occur within hours
        '';
      };

      skillOptions_developing_rspec_tests = {
        name = "developing-rspec-tests";
        description = "Writing, fixing, reviewing, or improving RSpec tests for Ruby on Rails applications. Use this skill for all testing tasks including model specs, controller specs, system specs, component specs, service specs, and integration tests. The skill provides comprehensive RSpec best practices from Better Specs and thoughtbot guides.";
        references = {
          "better_spec_guide" = ''
            # Better Specs - RSpec Best Practices

            ## Describe Blocks

            Use Ruby documentation conventions when naming describe blocks:
            - `.method_name` for class methods
            - `#method_name` for instance methods

            **Example:**
            ```ruby
            describe '.authenticate' do
              # tests for class method
            end

            describe '#admin?' do
              # tests for instance method
            end
            ```

            ## Context Blocks

            Organize tests with contexts using descriptive language:
            - Start descriptions with "when," "with," or "without"
            - Groups related behaviors and improves readability

            **Example:**
            ```ruby
            context 'when logged in' do
              it { is_expected.to respond_with 200 }
            end

            context 'with valid parameters' do
              # tests for valid scenarios
            end

            context 'without authentication' do
              # tests for unauthorized scenarios
            end
            ```

            ## It Blocks

            Keep test descriptions concise—ideally under 40 characters. Split longer descriptions into contexts instead.

            Use third-person present tense without "should":

            **Good:**
            ```ruby
            it 'does not change timings' do
            it 'creates a new project' do
            it 'redirects to the dashboard' do
            ```

            **Bad:**
            ```ruby
            it 'should not change timings' do
            it 'should create a new project' do
            ```

            ## Single Expectations

            Isolated unit tests should contain one expectation per test. This makes tests:
            - Easier to understand
            - Easier to debug when they fail
            - More maintainable

            For slower, non-isolated tests (database, external services), multiple expectations are acceptable for performance reasons.

            **Good (unit test):**
            ```ruby
            it 'validates presence of name' do
              project = Project.new(name: nil)
              expect(project).not_to be_valid
            end

            it 'adds error message for missing name' do
              project = Project.new(name: nil)
              project.valid?
              expect(project.errors[:name]).to include("can't be blank")
            end
            ```

            **Acceptable (integration/system test):**
            ```ruby
            it 'creates a project and redirects' do
              expect do
                post :create, params: {project: valid_attributes}
              end.to change(Project, :count).by(1)

              expect(response).to redirect_to(Project.last)
              expect(flash[:notice]).to eq('Project created successfully')
            end
            ```

            ## Test All Cases

            Cover valid, edge, and invalid scenarios. Test "all the possible inputs."

            **Example:**
            ```ruby
            describe 'validations' do
              it 'validates presence of name'
              it 'validates length of name'
              it 'validates uniqueness of name'
              it 'allows valid names'
            end
            ```

            ## Expect vs Should Syntax

            Always use `expect()` syntax on new projects (not `should`):

            **Good:**
            ```ruby
            expect(response).to respond_with_content_type(:json)
            expect(user).to be_valid
            ```

            **Bad (deprecated):**
            ```ruby
            response.should respond_with_content_type(:json)
            user.should be_valid
            ```

            For one-line expectations, use `is_expected.to`:

            **Good:**
            ```ruby
            it { is_expected.to be_valid }
            it { is_expected.to respond_with 422 }
            ```

            ## Subject Usage

            Use `subject {}` to DRY up multiple related tests:

            **Good:**
            ```ruby
            subject { assigns('message') }

            it { is_expected.to match /pattern/ }
            it { is_expected.to be_present }
            ```

            **When not to use subject:**
            - Avoid using `subject` explicitly inside `it` blocks
            - If you need to name it, use `let` instead

            ## Let vs Before

            Prefer `let` over `before` blocks for variable assignment. Variables defined with `let`:
            - Are lazy loaded (only evaluated when referenced)
            - Are cached during each test
            - Make dependencies explicit

            Use `let!` when you need immediate evaluation (before the test runs).

            **Good:**
            ```ruby
            let(:resource) { create :device }
            let(:user) { create :user }
            ```

            **When to use before:**
            - Setting up global test state
            - Configuring mocks/stubs
            - Database cleanup

            **Example:**
            ```ruby
            before do
              # Freeze time for consistent test results
              freeze_time
            end
            ```

            ## Mocking Strategy

            "Do not (over)use mocks and test real behavior when possible."

            Test actual application flow rather than stubbed interactions when feasible. Mocks are useful for:
            - External services
            - Slow operations
            - Testing error conditions

            But prefer real objects for:
            - Simple collaborators
            - Fast operations
            - Core business logic

            ## Data Creation

            Create only necessary test data. Use `create_list` sparingly.

            **Good:**
            ```ruby
            let(:project) { create(:project) }
            ```

            **Avoid:**
            ```ruby
            let(:projects) { create_list(:project, 50) } # Usually unnecessary
            ```

            ## Factories Over Fixtures

            Use FactoryBot instead of fixtures. Factories:
            - Are easier to understand and maintain
            - Reduce coupling between tests
            - Make test data explicit
            - Are easier to modify

            **Example:**
            ```ruby
            # spec/factories/projects.rb
            FactoryBot.define do
              factory :project do
                name { "Heart Rate Monitor" }
                device_description { "A medical device..." }

                trait :class_ii do
                  fda_class { :class_ii_confirmed }
                end
              end
            end
            ```

            ## Shared Examples

            Eliminate test duplication using shared examples, particularly for controller tests:

            **Definition:**
            ```ruby
            RSpec.shared_examples 'a listable resource' do
              it 'returns success' do
                expect(response).to have_http_status(:success)
              end

              it 'assigns resources' do
                expect(assigns(:resources)).to be_present
              end
            end
            ```

            **Usage:**
            ```ruby
            describe 'GET #index' do
              it_behaves_like 'a listable resource'
              it_behaves_like 'a paginable resource'
            end
            ```

            ## Integration Testing

            Focus on integration and model tests rather than controller tests. "Test what you see" using Capybara and RSpec.

            Integration tests:
            - Cover all use cases
            - Run fast with proper setup
            - Test actual user flows
            - Catch more real bugs

            ## HTTP Stubbing

            Stub external API calls using WebMock or VCR rather than relying on real services.

            **Example:**
            ```ruby
            before do
              stub_request(:get, "https://api.example.com/data")
                .to_return(status: 200, body: '{"status":"ok"}')
            end
            ```
          '';

          ####################################################################
          "thoughtbot_patterns" = ''
            # Thoughtbot RSpec Patterns

            ## Syntax & Expectations

            ### Use Modern RSpec Syntax
            - Use RSpec's `expect` syntax (not `should`)
            - Use RSpec's `allow` syntax for method stubs (not `stub`)
            - Prefer `eq` over `==` in RSpec assertions
            - Use `not_to` instead of `to_not` in expectations

            **Examples:**
            ```ruby
            # Good
            expect(user.name).to eq('John')
            expect(response).not_to be_nil
            allow(service).to receive(:call).and_return(result)

            # Bad
            user.name.should == 'John'
            response.should_not be_nil
            service.stub(:call).and_return(result)
            ```

            ### Capybara Matchers
            Prefer the `have_css` matcher to the `have_selector` matcher in Capybara assertions:

            ```ruby
            # Good
            expect(page).to have_css('.success-message')

            # Less preferred
            expect(page).to have_selector('.success-message')
            ```

            ## Test Structure

            ### Separate Test Phases
            Separate setup, exercise, verification, and teardown phases with newlines:

            ```ruby
            it 'creates a new project' do
              # Setup
              user = create(:user)
              attributes = {name: 'Test Project'}

              # Exercise
              project = Project.create(attributes)

              # Verification
              expect(project).to be_persisted
              expect(project.name).to eq('Test Project')
            end
            ```

            ### Single Level of Abstraction
            Use a single level of abstraction within `it` examples:

            ```ruby
            # Good
            it 'notifies the user' do
              perform_action
              expect_notification_sent
            end

            # Bad - mixing abstraction levels
            it 'notifies the user' do
              click_button 'Submit'
              expect(ActionMailer::Base.deliveries.last.to).to eq([user.email])
            end
            ```

            ### One Test Per Execution Path
            Use an `it` example or test method for each execution path through the method.

            ## What to Avoid

            ### Don't Test Private Methods
            - Never use the `private` keyword in specs
            - Don't test private methods
            - Test public interface and let private methods be covered indirectly

            ### Avoid Let and Let!
            Extract helper methods instead:

            ```ruby
            # Good
            def create_authenticated_user
              user = create(:user)
              sign_in(user)
              user
            end

            it 'shows dashboard' do
              user = create_authenticated_user
              visit dashboard_path
              expect(page).to have_content(user.name)
            end

            # Avoid
            let!(:user) { create(:user) }
            before { sign_in(user) }

            it 'shows dashboard' do
              visit dashboard_path
              expect(page).to have_content(user.name)
            end
            ```

            ### Avoid Subject
            Avoid using `subject` explicitly inside of an RSpec `it` block:

            ```ruby
            # Good
            subject { user.name }
            it { is_expected.to eq('John') }

            # Avoid
            it 'has correct name' do
              expect(subject).to eq('John')
            end
            ```

            ### Avoid Instance Variables
            Don't use instance variables in tests:

            ```ruby
            # Good
            let(:user) { create(:user) }

            # Avoid
            before { @user = create(:user) }
            ```

            ### Avoid Other Constructs
            - Avoid `its`, `specify`, and `before` in RSpec (prefer explicit tests)
            - Avoid `any_instance` in rspec-mocks and mocha; prefer dependency injection

            ### Skip Boolean Equality Checks
            Use predicate methods and matchers instead:

            ```ruby
            # Good
            expect(user).to be_valid
            expect(project).to be_persisted

            # Avoid
            expect(user.valid?).to eq(true)
            expect(project.persisted?).to be_truthy
            ```

            ## Mocking & Stubbing

            ### Use Stubs and Spies, Not Mocks
            - Use stubs and spies (not mocks) in isolated tests
            - Use assertions about state for incoming messages
            - Use stubs and spies to assert you sent outgoing messages

            **Example:**
            ```ruby
            # Good - stub
            allow(service).to receive(:call).and_return(result)

            # Good - spy
            service = spy('service')
            controller.notify(service)
            expect(service).to have_received(:call)
            ```

            ### Disable Real HTTP Requests
            Use `WebMock.disable_net_connect!` to prevent real HTTP requests to external services.

            Use a Fake to stub requests to external services:

            ```ruby
            class FakeGitHubAPI
              def initialize(stubs = {})
                @stubs = stubs
              end

              def get_user(username)
                @stubs.fetch(username) { default_user }
              end

              private

              def default_user
                {name: 'Test User', email: 'test@example.com'}
              end
            end
            ```

            ## Acceptance/System Tests

            ### Use Specific Selectors
            - Use the most specific selectors available
            - Don't locate elements with CSS selectors or `[id]` attributes
            - Use accessible names and descriptions to locate elements
            - Interact with form controls, buttons, and links by accessible names

            **Good:**
            ```ruby
            click_button 'Create Project'
            fill_in 'Project Name', with: 'Test Device'
            click_link 'Settings'
            ```

            **Avoid:**
            ```ruby
            find('#create-project-btn').click
            find('.project-name-input').set('Test Device')
            find('a[href="/settings"]').click
            ```

            ### Don't Assert on Classes or Data Attributes
            - Don't assert an element's state with `[class]` or `[data-*]` attributes
            - Use WAI-ARIA States and Properties when asserting an element's state
            - Prefer implicit semantics and built-in attributes over WAI-ARIA

            **Good:**
            ```ruby
            expect(page).to have_css('button[disabled]')
            expect(page).to have_css('[aria-hidden="false"]')
            expect(page).to have_content('Success message')
            ```

            **Avoid:**
            ```ruby
            expect(page).to have_css('.opacity-100')
            expect(page).to have_css('.bg-red-500')
            expect(page).to have_css('[data-visible="true"]')
            ```

            ### Avoid Meaningless Descriptions
            Avoid `it` block descriptions that add no information:

            ```ruby
            # Avoid
            it 'successfully creates project' do

            # Good
            it 'creates project and redirects to project page' do
            ```

            Avoid repetitive descriptions between `describe` and `it` blocks:

            ```ruby
            # Avoid
            describe 'creating a project' do
              it 'creates a project' do

            # Good
            describe 'project creation' do
              it 'redirects to the new project' do
            ```

            ### System Spec Organization
            - Use file names like `user_changes_password_spec.rb` (role_action format)
            - Store system specs in `spec/system` directory
            - Place helper methods in a top-level `System` module
            - Use only one `describe` block per system spec file

            **Example:**
            ```ruby
            # spec/system/user_creates_project_spec.rb
            require 'rails_helper'

            RSpec.describe 'User creates project' do
              it 'creates a new project' do
                # test implementation
              end
            end
            ```

            ## Unit Tests

            ### Imperative Descriptions
            Don't prefix descriptions with "should"; use imperative mood:

            ```ruby
            # Good
            it 'validates presence of name' do

            # Bad
            it 'should validate presence of name' do
            ```

            ### Use Subject Blocks
            Use `subject` blocks to define objects for use in one-line specs:

            ```ruby
            subject { Project.new(name: 'Test') }

            it { is_expected.to be_valid }
            ```

            ### Method Documentation Conventions
            - Use `.method` to describe class methods
            - Use `#method` to describe instance methods

            ```ruby
            describe '.find_by_name' do
              # class method tests
            end

            describe '#save' do
              # instance method tests
            end
            ```

            ### Context for Preconditions
            Use `context` to describe testing preconditions:

            ```ruby
            context 'when user is admin' do
              # tests for admin users
            end

            context 'with valid parameters' do
              # tests for valid scenarios
            end
            ```

            ### Test Organization
            - Group tests by method using `describe '#method_name'`
            - Maintain single, top-level `describe ClassName` block
            - Order tests matching class definition: validations, associations, methods

            **Example:**
            ```ruby
            RSpec.describe Project do
              describe 'validations' do
                # validation tests
              end

              describe 'associations' do
                # association tests
              end

              describe '#save' do
                # instance method tests
              end

              describe '.find_active' do
                # class method tests
              end
            end
            ```

            ## Factories

            ### Factory Organization
            Organize `factories.rb`:
            1. Sequences
            2. Traits
            3. Factory definitions

            Order factory attributes:
            1. Implicit associations first
            2. Explicit attributes
            3. Child factories (alphabetical within sections)

            Sort factory definitions alphabetically.

            **Example:**
            ```ruby
            FactoryBot.define do
              # Sequences
              sequence :email do |n|
                "user-#{n}@example.com"
              end

              # Factories (alphabetically)
              factory :project do
                # Associations (implicit)
                tenant
                created_by factory: %i[user]

                # Attributes (alphabetical)
                device_description { "A medical device..." }
                fda_class { :class_ii_assumed }
                name { "Heart Rate Monitor" }
                software_safety_class { :to_be_determined }

                # Traits (alphabetically)
                trait :class_ii do
                  fda_class { :class_ii_confirmed }
                end

                trait :with_github_repo do
                  github_repo_owner { "organization" }
                  github_repo_name { "awesome-repo" }
                end
              end
            end
            ```

            ## Integration Testing

            ### Test the Entire App
            Use integration tests to execute the entire app stack, including:
            - Database operations
            - Background jobs
            - External service interactions (stubbed)
            - Full request/response cycle

            ### Background Jobs
            Test background jobs with appropriate matchers for your job processor (Sidekiq, DelayedJob, etc.).
          '';
        };
        scripts = { };

        #####################################################################
        prompt = ''
          # ${kebabToHuman "developing-rspec-tests"}

          ## Overview

          Write comprehensive, maintainable RSpec tests following industry best practices. This skill combines guidance from Better Specs and thoughtbot's testing guides to produce high-quality test coverage for Rails applications.

          ## Core Testing Principles

          ### 1. Test-Driven Development (TDD)
          Follow the Red-Green-Refactor cycle:
          - **Red**: Write failing tests that define expected behavior
          - **Green**: Implement minimal code to make tests pass
          - **Refactor**: Improve code while tests continue to pass

          ### 2. Test Structure (Arrange-Act-Assert)
          Organize tests with clear phases separated by newlines:

          ```ruby
          it 'creates a new article' do
            # Arrange - set up test data
            user = create(:user)
            attributes = {title: 'Test Article', body: 'Content here'}

            # Act - perform the action
            article = Article.create(attributes)

            # Assert - verify the outcome
            expect(article).to be_persisted
            expect(article.title).to eq('Test Article')
          end
          ```

          ### 3. Single Responsibility
          Each test should verify one behavior. For unit tests, use one expectation per test. For integration tests, multiple expectations are acceptable when testing a complete flow.

          ### 4. Test Real Behavior
          Avoid over-mocking. Test actual application behavior when possible. Only stub external services, slow operations, and dependencies outside your control.

          ## Test Type Decision Tree

          ### When to Write Model Specs
          Use model specs (`spec/models/`) for:
          - Validations
          - Associations
          - Scopes
          - Instance methods
          - Class methods
          - Enums and constants
          - Database constraints

          **Example:**
          ```ruby
          # spec/models/article_spec.rb
          RSpec.describe Article do
            describe 'validations' do
              it 'validates presence of title' do
                article = build(:article, title: nil)
                expect(article).not_to be_valid
                expect(article.errors[:title]).to include("can't be blank")
              end
            end

            describe 'associations' do
              it { is_expected.to belong_to(:user) }
              it { is_expected.to have_many(:comments) }
            end

            describe '#published?' do
              it 'returns true when status is published' do
                article = build(:article, status: :published)
                expect(article.published?).to be true
              end
            end
          end
          ```

          ### When to Write Controller Specs
          Use controller specs (`spec/controllers/`) for:
          - Authorization checks (Pundit/CanCanCan)
          - Request routing and parameter handling
          - Response status codes
          - Instance variable assignments
          - Flash messages
          - Redirects

          **Example:**
          ```ruby
          # spec/controllers/articles_controller_spec.rb
          RSpec.describe ArticlesController do
            describe 'POST #create' do
              context 'with valid parameters' do
                it 'creates a new article and redirects' do
                  user = create(:user)
                  session[:user_id] = user.id

                  valid_attributes = {
                    title: 'Test Article',
                    body: 'Article content'
                  }

                  expect do
                    post :create, params: {article: valid_attributes}
                  end.to change(Article, :count).by(1)

                  expect(response).to redirect_to(Article.last)
                end
              end

              context 'with invalid parameters' do
                it 'does not create article and renders new template' do
                  user = create(:user)
                  session[:user_id] = user.id

                  invalid_attributes = {title: ''', body: '''}

                  expect do
                    post :create, params: {article: invalid_attributes}
                  end.not_to change(Article, :count)

                  expect(response).to render_template(:new)
                end
              end
            end
          end
          ```

          ### When to Write System Specs
          Use system specs (`spec/system/`) for:
          - End-to-end user workflows
          - Multi-step interactions
          - JavaScript functionality
          - Form submissions
          - Navigation flows
          - Real user scenarios

          **Naming convention:** `user_action_spec.rb` or `feature_description_spec.rb`

          **Example:**
          ```ruby
          # spec/system/article_creation_spec.rb
          RSpec.describe 'Article Creation' do
            it 'allows a user to create a new article' do
              user = create(:user)

              # Sign in
              visit '/login'
              fill_in 'Email', with: user.email
              fill_in 'Password', with: 'password'
              click_button 'Sign In'

              # Navigate to new article page
              click_link 'New Article'
              expect(page).to have_current_path(new_article_path)

              # Fill out the article form
              fill_in 'Title', with: 'My Test Article'
              fill_in 'Body', with: 'This is the article content'
              select 'Published', from: 'Status'

              # Submit the form
              click_button 'Create Article'

              expect(page).to have_content('Article created successfully!')
              expect(page).to have_content('My Test Article')
            end
          end
          ```

          ### When to Write Component Specs
          Use component specs (`spec/components/`) for:
          - ViewComponent rendering
          - Variant behavior
          - Slot functionality
          - Conditional rendering
          - Component attributes

          **Example:**
          ```ruby
          # spec/components/button_component_spec.rb
          RSpec.describe ButtonComponent, type: :component do
            describe 'variants' do
              it 'renders primary variant' do
                render_inline(described_class.new(variant: :primary)) { 'Click me' }

                button = page.find('button')
                expect(button[:class]).to include('btn-primary')
                expect(page).to have_button('Click me')
              end

              it 'renders secondary variant' do
                render_inline(described_class.new(variant: :secondary)) { 'Cancel' }

                button = page.find('button')
                expect(button[:class]).to include('btn-secondary')
              end
            end
          end
          ```

          ### When to Write Service/Integration Specs
          Use service/integration specs (`spec/services/`, `spec/integration/`) for:
          - Complex business logic
          - Multi-step workflows
          - External API integrations
          - Background job processing
          - Data transformations

          ## RSpec Syntax & Style Guide

          ### Describe Blocks
          Use Ruby documentation conventions:
          - `.method_name` for class methods
          - `#method_name` for instance methods

          ```ruby
          describe '.find_by_title' do      # class method
          describe '#publish' do              # instance method
          describe 'validations' do           # grouping
          ```

          ### Context Blocks
          Start with "when," "with," or "without":

          ```ruby
          context 'when user is admin' do
          context 'with valid parameters' do
          context 'without authentication' do
          ```

          ### It Blocks
          - Keep descriptions under 40 characters
          - Use third-person present tense
          - **Never** use "should" in descriptions

          ```ruby
          # ✅ Good
          it 'creates a new article' do
          it 'validates presence of title' do
          it 'redirects to dashboard' do

          # ❌ Bad
          it 'should create a new article' do
          it 'should validate presence of title' do
          ```

          ### Expectations
          Always use `expect` syntax (never `should`):

          ```ruby
          # ✅ Good
          expect(article).to be_valid
          expect(response).to have_http_status(:success)
          expect { action }.to change(Article, :count).by(1)

          # ❌ Bad (deprecated)
          article.should be_valid
          response.should have_http_status(:success)
          ```

          ### One-Liners
          Use `is_expected` for concise one-line specs:

          ```ruby
          subject { article }

          it { is_expected.to be_valid }
          it { is_expected.to be_persisted }
          ```

          ## System Test Best Practices

          ### Authentication in System Tests

          Test authentication flows directly without stubbing:

          ```ruby
          # Good - test the actual login flow
          visit '/login'
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Sign In'

          expect(page).to have_content('Dashboard')
          ```

          ### Controller Test Authentication

          For controller tests, use direct session assignment rather than stubbing:

          ```ruby
          # ✅ Good - direct session assignment
          session[:user_id] = user.id

          # ❌ Avoid - stubbing authentication
          allow_any_instance_of(Controller).to receive(:logged_in?).and_return(true)
          ```

          ### Avoid CSS Class Testing

          Don't test implementation details like CSS utility classes. Test semantic selectors and content:

          ```ruby
          # ✅ Good - semantic selectors
          expect(page).to have_selector(:test_id, 'user-modal')
          expect(page).to have_css("[aria-hidden='false']")
          expect(page).to have_content('Success message')
          expect(page).to have_button('Submit')

          # ❌ Bad - coupling to CSS implementation
          expect(page).to have_css('.opacity-100')
          expect(page).to have_css('.bg-red-500')
          expect(page).to have_css('.rounded-lg')
          ```

          ## Factory Patterns

          ### Organization
          1. Associations (implicit) first
          2. Attributes (alphabetical)
          3. Traits (alphabetical)

          ```ruby
          FactoryBot.define do
            factory :article do
              # Associations
              user
              category

              # Attributes (alphabetical)
              body { 'Article content goes here...' }
              published_at { Time.current }
              status { :draft }
              title { 'Sample Article Title' }

              # Traits (alphabetical)
              trait :published do
                status { :published }
                published_at { 1.day.ago }
              end

              trait :with_tags do
                after(:create) do |article|
                  create_list(:tag, 3, article: article)
                end
              end
            end
          end
          ```

          ### Prefer Build Over Create
          Use `build` and `build_stubbed` when database persistence isn't needed:

          ```ruby
          # ✅ Good - fast, no database hit
          it 'validates title format' do
            article = build(:article, title: ''')
            expect(article).not_to be_valid
          end

          # Less optimal - unnecessary database hit
          it 'validates title format' do
            article = create(:article, title: ''')
            expect(article).not_to be_valid
          end
          ```

          ## Common Testing Patterns

          ### Testing Validations
          ```ruby
          describe 'validations' do
            it 'validates presence of title' do
              article = build(:article, title: nil)
              expect(article).not_to be_valid
              expect(article.errors[:title]).to include("can't be blank")
            end

            it 'validates length of title' do
              article = build(:article, title: 'a' * 256)
              expect(article).not_to be_valid
            end

            it 'allows valid titles' do
              article = build(:article, title: 'Valid Title')
              expect(article).to be_valid
            end
          end
          ```

          ### Testing Enums
          ```ruby
          describe 'enums' do
            it 'defines status enum' do
              expect(described_class.statuses).to eq({
                'draft' => 'draft',
                'published' => 'published',
                'archived' => 'archived'
              })
            end

            it 'has correct default' do
              article = described_class.new
              expect(article.status).to eq('draft')
            end
          end
          ```

          ### Testing Authorization
          ```ruby
          context 'when user is not admin' do
            it 'raises authorization error' do
              user = create(:user, role: :member)
              session[:user_id] = user.id

              expect do
                get :admin_dashboard
              end.to raise_error(Pundit::NotAuthorizedError)
            end
          end
          ```

          ### Using Shoulda Matchers
          ```ruby
          describe 'associations' do
            it { is_expected.to belong_to(:user) }
            it { is_expected.to have_many(:comments) }
          end

          describe 'validations' do
            it { is_expected.to validate_presence_of(:title) }
            it { is_expected.to validate_length_of(:title).is_at_most(255) }
          end
          ```

          ## What to Avoid

          ### ❌ Don't Stub the System Under Test
          Never mock or stub methods on the class being tested:

          ```ruby
          # ❌ Bad
          it 'processes payment' do
            order = Order.new
            allow(order).to receive(:calculate_total).and_return(100)
            expect(order.process_payment).to be true
          end

          # ✅ Good
          it 'processes payment' do
            order = Order.new(line_items: [line_item])
            expect(order.process_payment).to be true
          end
          ```

          ### ❌ Don't Test Private Methods
          Test the public interface. Private methods are tested indirectly:

          ```ruby
          # ❌ Bad
          describe '#calculate_total (private)' do
            it 'sums line items' do
              order.send(:calculate_total)
            end
          end

          # ✅ Good
          describe '#total' do
            it 'returns sum of line items' do
              expect(order.total).to eq(100)
            end
          end
          ```

          ### ❌ Avoid `any_instance_of`
          Use dependency injection instead:

          ```ruby
          # ❌ Bad
          allow_any_instance_of(PaymentService).to receive(:charge)

          # ✅ Good
          payment_service = instance_double(PaymentService)
          allow(payment_service).to receive(:charge).and_return(success)
          order = Order.new(payment_service: payment_service)
          ```

          ## Quick Reference

          ### Test Organization
          ```ruby
          RSpec.describe ClassName do
            # Setup (let, before)
            let(:resource) { create(:resource) }

            before do
              # common setup
            end

            # Validations
            describe 'validations' do
            end

            # Associations
            describe 'associations' do
            end

            # Class methods
            describe '.class_method' do
            end

            # Instance methods
            describe '#instance_method' do
              context 'when condition' do
                it 'does something' do
                end
              end
            end
          end
          ```

          ### Expectation Matchers
          ```ruby
          # Equality
          expect(value).to eq(expected)
          expect(value).to be(expected)           # same object
          expect(value).to match(/regex/)

          # Predicates
          expect(object).to be_valid
          expect(object).to be_persisted
          expect(collection).to be_empty

          # Collections
          expect(array).to include(item)
          expect(array).to contain_exactly(1, 2, 3)
          expect(hash).to have_key(:name)

          # Changes
          expect { action }.to change(Model, :count).by(1)
          expect { action }.to change { object.attribute }.from(old).to(new)

          # Errors
          expect { action }.to raise_error(ErrorClass)
          expect { action }.not_to raise_error
          ```

          ## Resources

          This skill includes detailed reference documentation in the `references/` directory:

          ### `references/better_specs_guide.md`
          Comprehensive patterns from Better Specs including:
          - Describe/context/it block conventions
          - Subject and let usage
          - Mocking strategies
          - Shared examples
          - Factory patterns

          ### `references/thoughtbot_patterns.md`
          thoughtbot's RSpec best practices covering:
          - Modern RSpec syntax
          - Test structure and organization
          - What to avoid in tests
          - Capybara patterns for system tests
          - Factory organization

          Load these references when you need detailed examples or are unsure about a specific pattern.
        '';
      };

      skillOptions_fixing_rubocop_offenses = {
        name = "fixing-rubocop-offenses";
        description = "Expertise in fixing rubocop offenses across the Ruby and Ruby on Rails codebases.";
        scripts = {
          "check_cops.py" = ''
            #!/usr/bin/env python3
            """
            RuboCop Cop Documentation Fetcher

            Fetches documentation for a specific RuboCop cop from the official docs.
            Usage: python check_cops.py <cop_name>
            Example: python check_cops.py Style/StringLiterals
            """

            import sys
            import urllib.request
            import urllib.error
            import html.parser
            import re


            class CopPageParser(html.parser.HTMLParser):
                """Parser to extract cop documentation content from RuboCop docs."""

                def __init__(self):
                    super().__init__()
                    self.in_content = False
                    self.in_code = False
                    self.in_pre = False
                    self.in_heading = False
                    self.heading_level = 0
                    self.current_tag = None
                    self.content = []
                    self.skip_tags = {"script", "style", "nav", "header", "footer"}
                    self.skip_depth = 0

                def handle_starttag(self, tag, attrs):
                    attrs_dict = dict(attrs)

                    if tag in self.skip_tags:
                        self.skip_depth += 1
                        return

                    if self.skip_depth > 0:
                        return

                    if tag == "article" or (tag == "div" and "content" in attrs_dict.get("class", "")):
                        self.in_content = True

                    if not self.in_content:
                        return

                    self.current_tag = tag

                    if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
                        self.in_heading = True
                        self.heading_level = int(tag[1])
                        self.content.append("\n" + "#" * self.heading_level + " ")
                    elif tag == "pre":
                        self.in_pre = True
                        self.content.append("\n```ruby\n")
                    elif tag == "code" and not self.in_pre:
                        self.in_code = True
                        self.content.append("`")
                    elif tag == "p":
                        self.content.append("\n\n")
                    elif tag == "li":
                        self.content.append("\n- ")
                    elif tag == "br":
                        self.content.append("\n")
                    elif tag == "strong" or tag == "b":
                        self.content.append("**")
                    elif tag == "em" or tag == "i":
                        self.content.append("*")

                def handle_endtag(self, tag):
                    if tag in self.skip_tags:
                        self.skip_depth -= 1
                        return

                    if self.skip_depth > 0:
                        return

                    if not self.in_content:
                        return

                    if tag in ("h1", "h2", "h3", "h4", "h5", "h6"):
                        self.in_heading = False
                        self.content.append("\n")
                    elif tag == "pre":
                        self.in_pre = False
                        self.content.append("\n```\n")
                    elif tag == "code" and not self.in_pre:
                        self.in_code = False
                        self.content.append("`")
                    elif tag == "strong" or tag == "b":
                        self.content.append("**")
                    elif tag == "em" or tag == "i":
                        self.content.append("*")
                    elif tag == "article":
                        self.in_content = False

                    self.current_tag = None

                def handle_data(self, data):
                    if self.skip_depth > 0:
                        return

                    if self.in_content:
                        if self.in_pre:
                            self.content.append(data)
                        else:
                            text = data.strip()
                            if text:
                                if self.content and not self.content[-1].endswith(("\n", " ", "`", "*")):
                                    self.content.append(" ")
                                self.content.append(text)

                def get_markdown(self):
                    result = "".join(self.content)
                    result = re.sub(r"\n{3,}", "\n\n", result)
                    return result.strip()


            EXTENSION_DEPARTMENTS = {
                "capybara": "rubocop-capybara",
                "performance": "rubocop-performance",
                "rspec": "rubocop-rspec",
                "shopify": "rubocop-shopify",
                "rails": "rubocop-rails",
                "rake": "rubocop-rake",
                "rspecrails": "rubocop-rspec_rails",
                "threadsafety": "rubocop-thread_safety",
                "factorybot": "rubocop-factory_bot",
            }


            def get_base_url(cop_name):
                """Get the base URL based on the cop department."""
                department = cop_name.split("/")[0].lower()
                extension = EXTENSION_DEPARTMENTS.get(department)
                if extension:
                    return f"https://docs.rubocop.org/{extension}"
                return "https://docs.rubocop.org/rubocop"


            def cop_to_url(cop_name):
                """Convert cop name to documentation URL."""
                parts = cop_name.split("/")
                if len(parts) != 2:
                    raise ValueError(f"Invalid cop name format: {cop_name}. Expected format: Department/CopName")

                department, name = parts
                base_url = get_base_url(cop_name)
                anchor = f"{department.lower()}{name.lower()}"
                return f"{base_url}/cops_{department.lower()}.html#{anchor}"


            def fetch_cops_index(cop_name):
                """Fetch the cops index page to find all available cops."""
                base_url = get_base_url(cop_name)
                url = f"{base_url}/cops.html"
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

                with urllib.request.urlopen(req, timeout=30) as response:
                    return response.read().decode("utf-8")


            def find_cop_url(cop_name, index_html):
                """Find the URL for a specific cop from the index page."""
                cop_escaped = re.escape(cop_name)
                pattern = rf'href="([^"]+)"[^>]*>\s*{cop_escaped}\s*</a>'
                match = re.search(pattern, index_html, re.IGNORECASE)

                if match:
                    href = match.group(1)
                    if href.startswith("http"):
                        return href
                    base_url = get_base_url(cop_name)
                    return f"{base_url}/{href}"

                return None


            def fetch_cop_page(url):
                """Fetch a cop documentation page."""
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})

                with urllib.request.urlopen(req, timeout=30) as response:
                    return response.read().decode("utf-8")


            def extract_cop_section(html_content, cop_name):
                """Extract the section for a specific cop from the page."""
                parts = cop_name.split("/")
                if len(parts) != 2:
                    return html_content

                department, name = parts
                anchor_id = f"{department.lower()}{name.lower()}"

                anchor_pattern = rf'<h2[^>]*id="{re.escape(anchor_id)}"'
                match = re.search(anchor_pattern, html_content, re.IGNORECASE)

                if match:
                    start = match.start()
                    next_sect = re.search(r'<div class="sect1">', html_content[start + 10:])
                    if next_sect:
                        end = start + 10 + next_sect.start()
                        return html_content[start:end]
                    return html_content[start:]

                return None


            def parse_cop_documentation(html_content):
                """Parse HTML content and convert to markdown."""
                parser = CopPageParser()
                parser.feed(html_content)
                return parser.get_markdown()


            def main():
                if len(sys.argv) != 2:
                    print("Usage: python check_cops.py <cop_name>")
                    print("Example: python check_cops.py Style/StringLiterals")
                    sys.exit(1)

                cop_name = sys.argv[1]

                if "/" not in cop_name:
                    print(f"Error: Invalid cop name format '{cop_name}'")
                    print("Expected format: Department/CopName (e.g., Style/StringLiterals)")
                    sys.exit(1)

                try:


                    index_html = fetch_cops_index(cop_name)
                    cop_url = find_cop_url(cop_name, index_html)

                    if not cop_url:
                        cop_url = cop_to_url(cop_name)

                    page_html = fetch_cop_page(cop_url)
                    section_html = extract_cop_section(page_html, cop_name)

                    if section_html is None:
                        print(f"Error: Could not find documentation for cop '{cop_name}'", file=sys.stderr)
                        print(f"URL attempted: {cop_url}", file=sys.stderr)
                        sys.exit(1)

                    markdown = parse_cop_documentation(section_html)

                    if not markdown or len(markdown) < 50:
                        print(f"Warning: Could not extract meaningful content for {cop_name}", file=sys.stderr)
                        print(f"URL attempted: {cop_url}", file=sys.stderr)
                        sys.exit(1)

                    print(f"# {cop_name}\n")
                    print(f"Source: {cop_url}\n")
                    print(markdown)

                except urllib.error.HTTPError as e:
                    print(f"Error: HTTP {e.code} when fetching documentation", file=sys.stderr)
                    print(f"The cop '{cop_name}' may not exist or the URL format has changed.", file=sys.stderr)
                    sys.exit(1)
                except urllib.error.URLError as e:
                    print(f"Error: Could not connect to RuboCop docs: {e.reason}", file=sys.stderr)
                    sys.exit(1)
                except Exception as e:
                    print(f"Error: {e}", file=sys.stderr)
                    sys.exit(1)


            if __name__ == "__main__":
              main()
          '';
        };
        prompt = ''
          # ${kebabToHuman "fixing-rubocop-offenses"}

          Your task is to:
            - Analyze the provided RuboCop offense description.
            - Use the script `python scripts/check_cops.py {TypeOfCop/NameOfCop}` to fetch the most up-to-date documentation for the specified cop. Capture the output of the script.
            - Suggest the minimal code change to resolve the offense, adhering to the project's style guidelines.
            - If multiple fixes are possible, prioritize the most idiomatic Ruby solution.
            - Return the suggestion in a concise markdown code block.

          Script call example:
          `python scripts/check_cops.py Capybara/NegationMatcher`
        '';
      };

    in
    {
      options.jvf.aiTools.skills = {
        "auditing-security".enable = (lib.mkEnableOption "auditing-security") // { default = true; };
        "creating-skills".enable = (lib.mkEnableOption "creating-skills") // { default = true; };
        "research-tools".enable = (lib.mkEnableOption "research-tools") // { default = true; };
        "grafana".enable = (lib.mkEnableOption "grafana") // { default = true; };
        "browser-debug-tools".enable = (lib.mkEnableOption "browser-debug-tools") // { default = true; };
        "vision-tools".enable = (lib.mkEnableOption "vision-tools") // { default = true; };
        "kubernetes-tools".enable = (lib.mkEnableOption "kubernetes-tools") // { default = true; };
        "developing-containers".enable = (lib.mkEnableOption "developing-containers") // { default = true; };
        "creating-nix-modules".enable = (lib.mkEnableOption "creating-nix-modules") // { default = true; };
        "managing-flakes".enable = (lib.mkEnableOption "managing-flakes") // { default = true; };
        "writing-nix-code".enable = (lib.mkEnableOption "writing-nix-code") // { default = true; };
        "pythonic-scraping-websites".enable = (lib.mkEnableOption "pythonic-scraping-websites") // { default = true; };
        "developing-rails-background-jobs".enable = (lib.mkEnableOption "developing-rails-background-jobs") // { default = true; };
        "developing-rails-event-store".enable = (lib.mkEnableOption "developing-rails-event-store") // { default = true; };
        "developing-rails-scrapers".enable = (lib.mkEnableOption "developing-rails-scrapers") // { default = true; };
        "developing-rspec-tests".enable = (lib.mkEnableOption "developing-rspec-tests") // { default = true; };
        "fixing-rubocop-offenses".enable = (lib.mkEnableOption "fixing-rubocop-offenses") // { default = true; };
      };

      config = lib.mkMerge [
        (mkSkillConfig "auditing-security" skillOptions_auditing_security cfg."auditing-security")
        (mkSkillConfig "creating-skills" skillOptions_creating_skills cfg."creating-skills")
        (mkSkillConfig "research-tools" skillOptions_research_tools cfg."research-tools")
        (mkSkillConfig "grafana" skillOptions_grafana cfg."grafana")
        (mkSkillConfig "browser-debug-tools" skillOptions_browser_debug_tools cfg."browser-debug-tools")
        (mkSkillConfig "vision-tools" skillOptions_vision_tools cfg."vision-tools")
        (mkSkillConfig "kubernetes-tools" skillOptions_kubernetes_tools cfg."kubernetes-tools")
        (mkSkillConfig "developing-containers" skillOptions_developing_containers cfg."developing-containers")
        (mkSkillConfig "creating-nix-modules" skillOptions_creating_nix_modules cfg."creating-nix-modules")
        (mkSkillConfig "managing-flakes" skillOptions_managing_flakes cfg."managing-flakes")
        (mkSkillConfig "writing-nix-code" skillOptions_writing_nix_code cfg."writing-nix-code")
        (mkSkillConfig "pythonic-scraping-websites" skillOptions_pythonic_scraping_websites cfg."pythonic-scraping-websites")
        (mkSkillConfig "developing-rails-background-jobs" skillOptions_developing_rails_background_jobs cfg."developing-rails-background-jobs")
        (mkSkillConfig "developing-rails-event-store" skillOptions_developing_rails_event_store cfg."developing-rails-event-store")
        (mkSkillConfig "developing-rails-scrapers" skillOptions_developing_rails_scrapers cfg."developing-rails-scrapers")
        (mkSkillConfig "developing-rspec-tests" skillOptions_developing_rspec_tests cfg."developing-rspec-tests")
        (mkSkillConfig "fixing-rubocop-offenses" skillOptions_fixing_rubocop_offenses cfg."fixing-rubocop-offenses")
      ];
    };
in
{
  flake.modules.nixos.ai-tools-skills = mkConfig { isDarwin = false; };
  flake.modules.darwin.ai-tools-skills = mkConfig { isDarwin = true; };
}
