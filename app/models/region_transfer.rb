class RegionTransfer < ApplicationRecord
  belongs_to :from_region, class_name: "Region"
  belongs_to :to_region, class_name: "Region"
  belongs_to :edition
  belongs_to :transferred_by, class_name: "User"

  enum :status, { pending: "pending", approved: "approved", cancelled: "cancelled" }

  validates :quantity, numericality: { greater_than: 0 }
  validate :regions_must_be_different
  validate :regions_must_be_in_same_area_group
  validate :regions_must_be_for_same_edition

  scope :for_edition, ->(edition) { where(edition: edition) }
  scope :recent, -> { order(created_at: :desc) }

  def approve!
    update!(status: :approved, transferred_at: Time.current)
  end

  def cancel!
    update!(status: :cancelled)
  end

  private

  def regions_must_be_different
    if from_region_id == to_region_id
      errors.add(:to_region, "nie może być tym samym rejonem co rejon źródłowy")
    end
  end

  def regions_must_be_in_same_area_group
    return if from_region.nil? || to_region.nil?

    if from_region.area_group_id != to_region.area_group_id
      errors.add(:to_region, "musi należeć do tego samego okręgu co rejon źródłowy")
    end
  end

  def regions_must_be_for_same_edition
    return if from_region.nil? || to_region.nil? || edition.nil?

    unless from_region.edition_id == edition.id && to_region.edition_id == edition.id
      errors.add(:base, "oba rejony muszą należeć do tej samej edycji")
    end
  end
end
