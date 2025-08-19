//SystemVerilog
module circular_queue #(parameter DW=8, DEPTH=16) (
    input clk,
    input rst_n,
    input en,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out,
    output reg full,
    output reg empty
);
    reg [DW-1:0] mem [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] read_pointer, write_pointer;
    reg [4:0] queue_count;
    wire write_enable, read_enable;
    reg [DW-1:0] data_in_reg;
    reg en_reg;

    // -------------------------------------------------------------------------
    // Input retiming: Register data_in and en for timing and control stability
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= {DW{1'b0}};
            en_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            en_reg <= en;
        end
    end

    assign write_enable = en_reg && !full;
    assign read_enable  = en_reg && !empty;

    // -------------------------------------------------------------------------
    // Memory Write Control: Handles writing data_in_reg to FIFO memory
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_pointer <= {($clog2(DEPTH)){1'b0}};
        end else if (write_enable) begin
            mem[write_pointer] <= data_in_reg;
            write_pointer <= (write_pointer + 1'b1) % DEPTH;
        end
    end

    // -------------------------------------------------------------------------
    // Memory Read Control: Handles reading data from FIFO memory to data_out
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_pointer <= {($clog2(DEPTH)){1'b0}};
            data_out <= {DW{1'b0}};
        end else if (read_enable) begin
            data_out <= mem[read_pointer];
            read_pointer <= (read_pointer + 1'b1) % DEPTH;
        end
    end

    // -------------------------------------------------------------------------
    // Queue Counter Control: Tracks the number of elements in the FIFO
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            queue_count <= 5'd0;
        end else begin
            case ({write_enable, read_enable})
                2'b10: queue_count <= queue_count + 1'b1;
                2'b01: queue_count <= queue_count - 1'b1;
                default: queue_count <= queue_count;
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Full Flag Control: Indicates when the FIFO is full
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            full <= 1'b0;
        end else begin
            full <= (queue_count == DEPTH-1 && write_enable && !read_enable) ||
                    (queue_count == DEPTH && !read_enable);
        end
    end

    // -------------------------------------------------------------------------
    // Empty Flag Control: Indicates when the FIFO is empty
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            empty <= 1'b1;
        end else begin
            empty <= (queue_count == 1 && read_enable && !write_enable) ||
                     (queue_count == 0 && !write_enable);
        end
    end

endmodule