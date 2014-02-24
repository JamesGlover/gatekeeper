##
# Destruction of qcables is actually an action on asset
# Not only is the user physically carrying the action out on a plate
# but the state change action is conducted on a plate, not a qcable
class AssetsController < ApplicationController

  before_filter :find_user
  before_filter :find_asset_from_barcode

  ##
  # This doesn't actually destroy asset, just flags them as such
  def destroy

    state_change = api.state_change.create!(
      :user => @user.uuid,
      :target => params[:id],
      :reason => params[:reason]
    )

    flash[:success] = "#{@asset.barcode.prefix}#{@asset.barcode.number} has been destroyed!" if state_change.target_state == 'destroyed'

    # There is no reason we should ever hit this one, but if we do, someone needs to know about it.
    flash[:danger]  = "#{@asset.barcode.prefix}#{@asset.barcode.number} was NOT destroyed! Please contact support, as something has gone wrong." unless state_change.target_state == 'destroyed'

    redirect_to :root
  end

  private

  def find_asset_from_barcode
    raise UserError::InputError, "No barcode was provided!" if params[:asset_barcode].nil?
    begin
      @asset = api.search.find(Settings.searches['Find assets by barcode']).first(:barcode => params[:asset_barcode])
    rescue StandardError => exception
      raise UserError::InputError, "Could not find an asset with the barcode #{params[:asset_barcode]}." if no_search_result?(exception.message)
      raise exception
    end
  end

end
