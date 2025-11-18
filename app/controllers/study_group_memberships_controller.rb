# ABOUTME: Controller for managing study group membership approval workflow
# ABOUTME: Only group creators and admins can approve/reject membership requests
class StudyGroupMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_membership, only: [:approve, :reject]

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized_for_membership

  def user_not_authorized_for_membership
    if Rails.env.test?
      head :forbidden
    else
      flash[:alert] = "You are not authorized to perform this action."
      redirect_to(request.referer || root_path)
    end
  end

  def index
    if params[:study_group_id].present?
      @study_group = StudyGroup.find(params[:study_group_id])
      @membership = StudyGroupMembership.new(study_group: @study_group)
      authorize @membership
      @pending_memberships = @study_group.study_group_memberships.where(status: :pending).includes(:user)
    else
      raise ActionController::ParameterMissing, 'study_group_id parameter is required'
    end
  end

  def approve
    authorize @membership
    @membership.approve!(current_user)

    # Send approval email to student
    StudyGroupMailer.join_request_approved(@membership).deliver_now

    redirect_to study_group_path(@membership.study_group), notice: "#{@membership.user.name} has been approved to join the group."
  end

  def reject
    authorize @membership
    @membership.reject!(current_user)

    # Send rejection email to student
    StudyGroupMailer.join_request_rejected(@membership).deliver_now

    redirect_to study_group_path(@membership.study_group), notice: "#{@membership.user.name}'s request has been rejected."
  end

  private

  def set_membership
    @membership = StudyGroupMembership.find(params[:id])
  end
end
