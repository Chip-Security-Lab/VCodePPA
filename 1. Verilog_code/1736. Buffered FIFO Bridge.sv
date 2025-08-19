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
    wire empty = (wr_ptr == rd_ptr);
    wire full = (wr_ptr[$clog2(DEPTH)-1:0] == rd_ptr[$clog2(DEPTH)-1:0]) && 
                (wr_ptr[$clog2(DEPTH)] != rd_ptr[$clog2(DEPTH)]);
    
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0; rd_ptr <= 0; dst_valid <= 0;
        end else begin
            if (src_valid && !full) begin
                fifo[wr_ptr[$clog2(DEPTH)-1:0]] <= src_data;
                wr_ptr <= wr_ptr + 1;
            end
            if (!empty && (!dst_valid || dst_ready)) begin
                dst_data <= fifo[rd_ptr[$clog2(DEPTH)-1:0]];
                rd_ptr <= rd_ptr + 1;
                dst_valid <= 1;
            end else if (dst_valid && dst_ready) begin
                dst_valid <= 0;
            end
        end
    end
    
    assign src_ready = !full;
endmodule