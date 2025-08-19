//SystemVerilog
module lfsr_divider (
    input wire i_clk,
    input wire i_rst,
    output wire o_clk_div
);
    reg [4:0] lfsr;
    wire feedback;
    reg [4:0] lfsr_buf1, lfsr_buf2;  // Buffer registers for high fanout signal
    
    // Use non-blocking assignment and optimize feedback logic
    assign feedback = lfsr_buf1[4] ^ lfsr_buf1[2];
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst)
            lfsr <= 5'h1f;
        else
            lfsr <= {lfsr[3:0], feedback};
    end
    
    // Adding buffer registers to reduce fanout
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            lfsr_buf1 <= 5'h1f;
            lfsr_buf2 <= 5'h1f;
        end else begin
            lfsr_buf1 <= lfsr;      // First level buffer
            lfsr_buf2 <= lfsr_buf1; // Second level buffer for further fanout reduction
        end
    end
    
    // Output from buffer register instead of directly from lfsr
    assign o_clk_div = lfsr_buf2[4];
endmodule