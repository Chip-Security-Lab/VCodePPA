//SystemVerilog
module fifo_bridge #(parameter WIDTH=32, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] src_data,
    input src_valid,
    output src_ready,
    output reg [WIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    reg [WIDTH-1:0] fifo [0:DEPTH-1];
    reg [$clog2(DEPTH):0] wr_ptr_buf, wr_ptr; // Buffer for write pointer
    reg [$clog2(DEPTH):0] rd_ptr_buf, rd_ptr; // Buffer for read pointer
    wire empty = (wr_ptr == rd_ptr);
    wire full = (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]) && 
                (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]);
    
    // Buffering for high fanout signals
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr_buf <= 0; 
            rd_ptr_buf <= 0; 
            dst_valid <= 0;
        end else begin
            case ({src_valid, !full, !empty, (!dst_valid || dst_ready), (dst_valid && dst_ready)})
                5'b10000: begin // src_valid && !full
                    fifo[wr_ptr_buf[$clog2(DEPTH)-1:0]] <= src_data;
                    wr_ptr_buf <= wr_ptr_buf + 1;
                end
                5'b00010: begin // !empty && (!dst_valid || dst_ready)
                    dst_data <= fifo[rd_ptr_buf[$clog2(DEPTH)-1:0]];
                    rd_ptr_buf <= rd_ptr_buf + 1;
                    dst_valid <= 1;
                end
                5'b00001: begin // dst_valid && dst_ready
                    dst_valid <= 0;
                end
                default: begin
                    // Do nothing
                end
            endcase
        end
    end

    // Update the actual pointers with buffered values to reduce fanout
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
        end else begin
            wr_ptr <= wr_ptr_buf;
            rd_ptr <= rd_ptr_buf;
        end
    end

    assign src_ready = !full;
endmodule