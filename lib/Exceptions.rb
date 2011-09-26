module Exceptions
  class ClashCreationError < StandardError; end
  class ClashStartError < StandardError; end
  class PlayerJoinError < StandardError; end
  class PlayerLeaveError < StandardError; end
  
  class NeedJoinForm < StandardError
    attr :form
    def initialize form
      @form = form
    end
  end  
  
  class NeedCreateForm < StandardError
    attr :form
    def initialize form
      @form = form
    end
  end
end