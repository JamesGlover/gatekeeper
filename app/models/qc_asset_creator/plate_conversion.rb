##
# Converts one plate type (The target) to another
# and transfers the source in
module QcAssetCreator::PlateConversion

  ##
  # Ensures the qcable state changes are recorded
  def asset_update_state
    api.state_change.create!(
      :user => @user.uuid,
      :target => @asset.uuid,
      :reason => 'Used in QC',
      :target_state => Gatekeeper::Application.config.qcing_state
    )
    api.state_change.create!(
      :user => @user.uuid,
      :target => @sibling.uuid,
      :reason => 'Used to QC',
      :target_state => Gatekeeper::Application.config.used_state
    )
  end

  ##
  # Actually converts the target plate to the specified purpose
  def asset_create
    api.plate_conversion.create!(
      :target => target,
      :purpose => @purpose,
      :user => @user.uuid,
    ).target
  end

  ##
  # Transfers the source plate into the target plate
  # The child is ignored (Although it should be the same as the target plate)
  def asset_transfer(_)
    transfer_template.create!(
      :source => source,
      :destination => target,
      :user => @user.uuid
    )
    api.tag_layout_template.find(tag_template).create!(
      :user => @user.uuid,
      :plate => target,
      :substitutions => {}
    )
  end

  ##
  # Raises QcAssetException if the asset is the wrong type, or is in the wrong state
  # We don't bother checking state if the type is wrong
  def validate!
    raise QcAssetCreator::QcAssetException, 'The type of plate or tube requested is not suitable.' unless valid_children.include?(purpose)
    errors = []
    errors << "The asset being QCed should be '#{Gatekeeper::Application.config.qcable_state}'." unless @asset.qcable?
    errors << "The asset used to validate should be '#{Gatekeeper::Application.config.qced_state}'." unless @sibling.qced?
    errors << "#{@sibling.purpose.name} plates can't be used to test #{@asset.purpose.name} plates." unless compatible_siblings?
    raise QcAssetCreator::QcAssetException, errors.join(' ') unless errors.empty?
    true
  end

  protected

  def target
    asset_target ? @asset.uuid : @sibling.uuid
  end

  def source
    !asset_target ? @asset.uuid : @sibling.uuid
  end

  def target_purpose
    asset_target ? @asset.purpose.uuid : @sibling.purpose.uuid
  end

  def asset_target
    Settings.purposes.has_key?(@asset.purpose.uuid) && Settings.purposes[@asset.purpose.uuid].as == 'target'
  end

  def valid_children
    Settings.purposes[target_purpose].children
  end

  def compatible_siblings?
    Settings.purposes[@asset.purpose.uuid].sibling == @sibling.purpose.name
  end

  def target_barcode
    asset_target ? @asset.barcode.ean13 : @sibling.barcode.ean13
  end

  def tag_template
    api.search.find(Settings.searches['Find qcable by barcode']).first(:barcode => target_barcode).lot.template.uuid
  end
end
