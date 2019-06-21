class CellBuffer
    def initialize(rows, columns)
        @rows = rows
        @columns = columns
        @cells = Array.new(rows) { Array.new(cols) }
    end
    def sync
    end
end