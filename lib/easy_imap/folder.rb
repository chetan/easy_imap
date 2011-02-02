module EasyIMAP
  # A Folder on the IMAP server.
  class Folder

    READ_ONLY   = 0
    READ_WRITE  = 1

    # the name of the folder.
    attr_reader :name

    # Creates an instance representing a folder with +name+, on
    # the server connection +conn+, with the folder delimiter +delim+.
    #
    # Normally this class is only instantiated internally.
    def initialize(conn, name, delim)
      @conn = conn
      @full_name = name
      @name = name.split(delim).last
      @delim = delim
    end

    # An array of messages in this folder.
    def messages
      read_only()
      @conn.uid_search(['ALL']).map do |uid|
        Message.new(@conn, uid)
      end
    end

    # An array of folders in this folder.
    def folders
      @conn.list("#{@full_name}#{@delim}", '%').map do |f|
        Folder.new(@conn, f.name, f.delim)
      end
    end

    # Delete the given message or uid
    def delete(msg)
      read_write()
      uid = (msg.kind_of?(EasyIMAP::Message) ? msg.uid : msg)
      @conn.uid_store(uid, '+FLAGS', [:Deleted])
      expunge()
    end

    def expunge
      @conn.expunge()
    end

    def read_only
      return if @mode == READ_ONLY
      @mode = READ_ONLY
      @conn.examine(@full_name)
    end

    def read_write
      return if @mode == READ_WRITE
      @mode = READ_WRITE
      @conn.select(@full_name)
    end
  end
end
