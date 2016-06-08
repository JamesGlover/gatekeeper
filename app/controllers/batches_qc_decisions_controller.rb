##
# Make QC Decisions
class BatchesQcDecisionsController < QcDecisionsController

  before_filter :find_user, :except=>[:search,:new]

  ##
  # For rendering a QC Decision
  # On Batch
  def new
    @lot_presenters = find_lots_for_batch.map{|lot| Presenter::Lot.new(lot)}
    render 'batches/qc_decisions/new'
  end

  ##
  # For making a QC Decision
  # On Lot
  def create
    begin
      decisions = params[:decisions].select {|uuid,decision| decision.present? }
      api.qc_decision.create!(
        :user => @user.uuid,
        :lot  => params[:lot_id],
        :decisions => decisions.map do |uuid,decision|
          {'qcable'=>uuid, 'decision' => decision }
        end
      )
      flash[:success] = "Qc decision has been updated."
      return redirect_to lot_path(params[:lot_id])
    rescue Sequencescape::Api::ResourceInvalid => exception
      message = exception.resource.errors.messages.map {|k,v| "#{k.capitalize} #{v.to_sentence.chomp('.')}"}.join('; ')<<'.'
      flash[:danger] = "A decision was not made. #{message}"
      redirect_to new_lot_qc_decision_path(params[:lot_id])
      return
    end
  end

end
