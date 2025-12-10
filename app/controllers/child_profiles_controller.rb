class ChildProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_profile, only: [:show]
  after_action :verify_authorized, except: [:new, :create]

  def new
    @child_profile = ChildProfile.new
  end

  def create
    @child_profile = ChildProfile.new(child_profile_params)
    @child_profile.primary_caregiver = current_user

    if @child_profile.save
      # Create membership for primary caregiver
      ChildMembership.create!(
        user: current_user,
        child_profile: @child_profile,
        role: 'parent',
        is_primary: true
      )

      redirect_to @child_profile, notice: 'Child profile created successfully. You can now start the onboarding process.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @child_profile
    @onboarding_session = @child_profile.onboarding_sessions.completed.recent.first
    @profile_summary = @child_profile.ai_documents.profile_summary.recent.first
    @suggested_goals = @child_profile.child_goals.suggested.ordered_by_priority
  end

  private

  def set_child_profile
    @child_profile = ChildProfile.find(params[:id])
  end

  def child_profile_params
    params.require(:child_profile).permit(:name, :birth_date, :diagnosis_summary)
  end
end
