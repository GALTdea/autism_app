module Admin
  class AssessmentsController < Admin::ApplicationController
        before_action :set_assessment, only: [ :show, :edit, :update, :destroy,
                                              :select_domains, :update_domains,
                                              :order_domains, :reorder_domains,
                                              :preview, :clone, :configure_scoring,
                                              :clone_domain_for_assessment ]
    after_action :verify_authorized

    def index
      authorize [ :admin, Assessment ]
      @assessments = policy_scope([ :admin, Assessment ]).includes(:profile_domains, :onboarding_sessions)
                                                        .order(name: :asc, version: :desc)
    end

    def show
      authorize [ :admin, @assessment ]
      @assessment_domains = @assessment.assessment_domains.includes(:profile_domain, :questions).ordered
      @stats = {
        total_questions: @assessment.total_questions_count,
        total_sessions: @assessment.onboarding_sessions.count,
        active_sessions: @assessment.onboarding_sessions.in_progress.count,
        completed_sessions: @assessment.onboarding_sessions.completed.count
      }
    end

    def new
      @assessment = Assessment.new
      authorize [ :admin, @assessment ]
    end

    def create
      @assessment = Assessment.new(assessment_params)
      authorize [ :admin, @assessment ]

      if @assessment.save
        redirect_to select_domains_admin_assessment_path(@assessment),
                    notice: "Assessment created. Now select domains."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize [ :admin, @assessment ]
      # Load domains for display in edit view
      @domains = @assessment.ordered_domains if @assessment.domain_count > 0
    end

    def update
      authorize [ :admin, @assessment ]

      if @assessment.update(assessment_params)
        # If coming from index or dashboard page, redirect back there
        referer = request.referer.to_s
        if referer.include?(admin_assessments_path)
          redirect_to admin_assessments_path,
                      notice: "Assessment updated successfully."
        elsif referer.include?(admin_root_path)
          redirect_to admin_root_path,
                      notice: "Assessment updated successfully."
        else
          redirect_to admin_assessment_path(@assessment),
                      notice: "Assessment updated successfully."
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize [ :admin, @assessment ]

      if @assessment.can_be_deleted?
        @assessment.destroy
        redirect_to admin_assessments_path,
                    notice: "Assessment deleted successfully."
      else
        redirect_to admin_assessments_path,
                    alert: "Cannot delete assessment with existing onboarding sessions."
      end
    end

    # Assessment Builder Wizard Actions

    def select_domains
      authorize [ :admin, @assessment ]
      @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered

      # Load all AssessmentDomains (standalone and from other assessments)
      # Exclude domains that are already in this assessment
      @available_domains = AssessmentDomain
                                           .includes(:profile_domain, :assessment, :questions)
                                           .where.not(id: @assessment.assessment_domains.select(:id))
                                           .ordered
    end

    def update_domains
      authorize [ :admin, @assessment ]

      domain_ids = params[:domain_ids] || []

      # Filter to only include standalone domains (domains in other assessments cannot be added directly)
      standalone_domain_ids = AssessmentDomain.where(id: domain_ids)
                                             .standalone
                                             .pluck(:id)
                                             .map(&:to_s)

      begin
        # Use the new service method for adding standalone AssessmentDomains
        AssessmentDomainService.add_assessment_domains(@assessment, standalone_domain_ids)
        redirect_to admin_assessment_path(@assessment),
                    notice: "Domains added successfully."
      rescue AssessmentDomainService::Error => e
        redirect_to select_domains_admin_assessment_path(@assessment),
                    alert: "Failed to add domains: #{e.message}"
      end
    end

    def order_domains
      authorize [ :admin, @assessment ]
      @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered
      redirect_to select_domains_admin_assessment_path(@assessment),
                  alert: "Please select at least one domain first." if @assessment_domains.empty?
    end

    def reorder_domains
      authorize [ :admin, @assessment ]

      domain_positions = reorder_domains_params

      begin
        # Use assessment_domain_ids (both pages now use assessment_domain.id)
        AssessmentDomainService.reorder_assessment_domains(@assessment, domain_positions)

        # Reload to get updated positions
        @assessment.reload
        @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered

        respond_to do |format|
          format.json { render json: { status: "success", message: "Domain order updated successfully." } }
          format.turbo_stream { render :reorder_domains }
          format.html {
            # Redirect based on referer to maintain context
            if request.referer&.include?("order_domains")
              redirect_to order_domains_admin_assessment_path(@assessment),
                          notice: "Domain order updated successfully."
            else
              redirect_to admin_assessment_path(@assessment),
                          notice: "Domain order updated successfully."
            end
          }
        end
      rescue AssessmentDomainService::Error => e
        respond_to do |format|
          format.json { render json: { status: "error", message: e.message }, status: :unprocessable_entity }
          format.turbo_stream {
            render turbo_stream: turbo_stream.append("flash-container", partial: "shared/flash",
              locals: { flash: { alert: e.message } })
          }
          format.html {
            redirect_to admin_assessment_path(@assessment),
                        alert: "Failed to reorder domains: #{e.message}"
          }
        end
      end
    end

    def preview
      authorize [ :admin, @assessment ]
      @domains = @assessment.ordered_domains
      redirect_to select_domains_admin_assessment_path(@assessment),
                  alert: "Please select at least one domain first." if @domains.empty?
    end

    def clone
      authorize [ :admin, @assessment ]
      begin
        cloned_assessment = @assessment.clone
        redirect_to edit_admin_assessment_path(cloned_assessment),
                    notice: "Assessment cloned successfully. Update version and details."
      rescue AssessmentCloningService::Error => e
        redirect_to admin_assessments_path,
                    alert: "Failed to clone assessment: #{e.message}"
      end
    end

    def configure_scoring
      authorize [ :admin, @assessment ]
      @domains = @assessment.ordered_domains
    end

    def clone_domain_for_assessment
      authorize [ :admin, @assessment ]

      source_domain = AssessmentDomain.find(params[:domain_id])

      begin
        # Clone the domain as standalone (assessment: nil)
        cloned = source_domain.clone(
          new_name: "#{source_domain.display_name} (Copy)",
          new_version: source_domain.version,
          assessment: nil  # Make it standalone
        )

        # Reload available domains list
        @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered
        @available_domains = AssessmentDomain
          .includes(:profile_domain, :assessment, :questions)
          .where.not(id: @assessment.assessment_domains.select(:id))
          .ordered

        respond_to do |format|
          format.html {
            redirect_to select_domains_admin_assessment_path(@assessment),
                        notice: "Domain cloned successfully. You can now select it."
          }
          format.turbo_stream {
            flash.now[:notice] = "Domain cloned successfully. You can now select it."
            render :clone_domain_for_assessment
          }
          format.json {
            render json: {
              status: "success",
              cloned_domain: {
                id: cloned.id,
                name: cloned.display_name,
                standalone: cloned.standalone?
              }
            }
          }
        end
      rescue StandardError => e
        # Reload available domains even on error
        @assessment_domains = @assessment.assessment_domains.includes(:profile_domain).ordered
        @available_domains = AssessmentDomain
          .includes(:profile_domain, :assessment, :questions)
          .where.not(id: @assessment.assessment_domains.select(:id))
          .ordered

        respond_to do |format|
          format.html {
            redirect_to select_domains_admin_assessment_path(@assessment),
                        alert: "Failed to clone domain: #{e.message}"
          }
          format.turbo_stream {
            flash.now[:alert] = "Failed to clone domain: #{e.message}"
            render :clone_domain_for_assessment
          }
          format.json {
            render json: { status: "error", message: e.message }, status: :unprocessable_entity
          }
        end
      end
    end

    private

    def set_assessment
      @assessment = Assessment.find(params[:id])
    end

    def assessment_params
      params.require(:assessment).permit(:name, :version, :description, :active, :is_default)
    end

    def reorder_domains_params
      params.permit(domain_positions: {}).fetch(:domain_positions, {})
    end
  end
end
