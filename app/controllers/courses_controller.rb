# ABOUTME: Controller for managing courses (admin-only write, all read)
# ABOUTME: Handles CRUD operations with Pundit authorization
class CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_course, only: [:show, :edit, :update, :destroy]

  def index
    @courses = Course.all
    authorize Course
  end

  def show
    authorize @course
  end

  def new
    @course = Course.new
    authorize @course
  end

  def create
    @course = Course.new(course_params)
    authorize @course

    if @course.save
      redirect_to @course, notice: 'Course was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @course
  end

  def update
    authorize @course

    if @course.update(course_params)
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @course
    @course.destroy
    redirect_to courses_path, notice: 'Course was successfully deleted.'
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def course_params
    params.require(:course).permit(:name, :code, :description, :semester, :year)
  end
end
