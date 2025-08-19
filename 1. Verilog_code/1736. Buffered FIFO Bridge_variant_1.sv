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
    reg [$clog2(DEPTH):0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] wr_ptr_buf, rd_ptr_buf;
    reg [$clog2(DEPTH):0] wr_ptr_buf2, rd_ptr_buf2;
    wire empty = (wr_ptr_buf2 == rd_ptr_buf2);
    wire full = (wr_ptr_buf2[$clog2(DEPTH)-1:0] == rd_ptr_buf2[$clog2(DEPTH)-1:0]) && 
                (wr_ptr_buf2[$clog2(DEPTH)] != rd_ptr_buf2[$clog2(DEPTH)]);
    
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0; rd_ptr <= 0;
            wr_ptr_buf <= 0; rd_ptr_buf <= 0;
            wr_ptr_buf2 <= 0; rd_ptr_buf2 <= 0;
            dst_valid <= 0;
        end else begin
            case ({src_valid, !full, !empty, dst_valid, dst_ready})
                5'b11000: begin
                    fifo[wr_ptr[$clog2(DEPTH)-1:0]] <= src_data;
                    wr_ptr <= wr_ptr + 1;
                end
                5'b00110: begin
                    dst_data <= fifo[rd_ptr[$clog2(DEPTH)-1:0]];
                    rd_ptr <= rd_ptr + 1;
                    dst_valid <= 1;
                end
                5'b00011: begin
                    dst_valid <= 0;
                end
                default: begin
                    // No operation
                end
            endcase
            
            wr_ptr_buf <= wr_ptr;
            wr_ptr_buf2 <= wr_ptr_buf;
            rd_ptr_buf <= rd_ptr;
            rd_ptr_buf2 <= rd_ptr_buf;
        end
    end
    
    assign src_ready = !full;
endmodule