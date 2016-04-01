##
# Slightly different behaviour from PlateConversion that does not change the state of the asset
# and does not check that it is in qc state as QA plates could be in any state
module QcAssetCreator::QaPlateConversion

  include QcAssetCreator::PlateConversion

  ##
  # Ensures no update of the state is performed
  def asset_update_state
    # No updates
  end

  ##
  # Raises QcAssetException if the asset is the wrong type
  def validate!
    errors = []
    errors << "The asset used to validate should be '#{Gatekeeper::Application.config.qced_state}'." unless @sibling.qced?
    errors << "#{@sibling.purpose.name} plates can't be used to test #{@asset.purpose.name} plates." unless compatible_siblings?
    raise QcAssetCreator::QcAssetException, errors.join(' ') unless errors.empty?
    true
  end

end
