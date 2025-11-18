# ABOUTME: Controller for managing study groups (creator/admin write, all read)
# ABOUTME: Handles CRUD operations with Pundit authorization for study groups
class StudyGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_group, only: [:show, :edit, :update, :destroy, :join]

  def index
    @study_groups = StudyGroup.active.includes(:course, :creator)
    authorize StudyGroup
  end

  def show
    authorize @study_group
  end

  def new
    @study_group = StudyGroup.new
    authorize @study_group
  end

  def create
    @study_group = StudyGroup.new(study_group_params)
    @study_group.creator = current_user
    authorize @study_group

    if @study_group.save
      redirect_to @study_group, notice: 'Study group was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @study_group
  end

  def update
    authorize @study_group

    if @study_group.update(study_group_params)
      redirect_to @study_group, notice: 'Study group was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @study_group
    @study_group.destroy
    redirect_to study_groups_path, notice: 'Study group was successfully deleted.'
  end

  def join
    authorize @study_group, :show?

    # Only check for pending and approved memberships, allow rejoin after rejection
    existing_membership = @study_group.study_group_memberships
                                      .where(user: current_user)
                                      .where.not(status: :rejected)
                                      .first

    if existing_membership&.pending?
      redirect_to @study_group, alert: 'You already have a pending join request for this group.'
      return
    elsif existing_membership&.approved?
      redirect_to @study_group, alert: 'You are already a member of this group.'
      return
    end

    @study_group.study_group_memberships.create!(
      user: current_user,
      status: :pending,
      requested_at: Time.current
    )
    redirect_to @study_group, notice: 'Your join request has been submitted and is pending approval.'
  end

  private

  def set_study_group
    @study_group = StudyGroup.find(params[:id])
  end

  def study_group_params
    params.require(:study_group).permit(:name, :description, :group_type, :course_id)
  end
end
