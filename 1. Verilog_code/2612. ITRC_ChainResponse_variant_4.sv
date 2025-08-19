//SystemVerilog
module ITRC_ChainResponse #(
    parameter WIDTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_src,
    input ack,
    output reg [WIDTH-1:0] current_int
);

    // Buffer registers for high fanout signals
    reg [WIDTH-1:0] current_int_buf;
    reg [WIDTH-1:0] masked_src_buf;
    
    // First stage: Calculate masked_src with buffered current_int
    wire [WIDTH-1:0] masked_src = int_src & ~current_int_buf;
    
    // Second stage: Buffer masked_src
    always @(posedge clk) begin
        if (!rst_n) begin
            masked_src_buf <= {WIDTH{1'b0}};
        end else begin
            masked_src_buf <= masked_src;
        end
    end
    
    // Third stage: Calculate remaining logic with buffered signals
    wire [WIDTH-1:0] masked_src_inv = ~masked_src_buf;
    wire [WIDTH-1:0] masked_src_plus_1 = masked_src_buf + 1;
    wire [WIDTH-1:0] masked_src_plus_1_inv = ~masked_src_plus_1;
    
    wire [WIDTH-1:0] mux_sel = {WIDTH{masked_src_buf[0]}};
    wire [WIDTH-1:0] mux_in0 = masked_src_inv;
    wire [WIDTH-1:0] mux_in1 = masked_src_plus_1_inv;
    wire [WIDTH-1:0] cond_inv_sub = (mux_sel & mux_in1) | (~mux_sel & mux_in0);
    
    // Fourth stage: Update current_int with buffered version
    always @(posedge clk) begin
        if (!rst_n) begin
            current_int <= {WIDTH{1'b0}};
            current_int_buf <= {WIDTH{1'b0}};
        end else if (ack) begin
            current_int <= {1'b0, current_int_buf[WIDTH-1:1]};
            current_int_buf <= {1'b0, current_int_buf[WIDTH-1:1]};
        end else if (!current_int_buf[0]) begin
            current_int <= cond_inv_sub;
            current_int_buf <= cond_inv_sub;
        end
    end
endmodule