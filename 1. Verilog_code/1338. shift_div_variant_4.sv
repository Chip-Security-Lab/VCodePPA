//SystemVerilog
module shift_div #(parameter PATTERN=8'b1010_1100) (
    input clk, rst,
    output wire clk_out
);
    reg [7:0] shift_reg;
    
    // First level of buffer registers - split into two groups to reduce fanout
    reg [3:0] shift_reg_buf1_low;  // Buffer for lower bits
    reg [3:0] shift_reg_buf1_high; // Buffer for higher bits
    
    // Second level of buffer registers for further fanout reduction
    reg [3:0] shift_reg_buf2_low;
    reg [3:0] shift_reg_buf2_high;
    
    // Output buffer register
    reg clk_out_buf;
    
    // Main shift register logic
    always @(posedge clk) begin
        shift_reg <= rst ? PATTERN : {shift_reg[6:0], shift_reg[7]};
    end
    
    // First stage buffering - split into two parts to reduce loading
    always @(posedge clk) begin
        shift_reg_buf1_low <= shift_reg[3:0];
        shift_reg_buf1_high <= shift_reg[7:4];
    end
    
    // Second stage buffering for balanced distribution
    always @(posedge clk) begin
        shift_reg_buf2_low <= shift_reg_buf1_low;
        shift_reg_buf2_high <= shift_reg_buf1_high;
    end
    
    // Output register buffer to isolate output load
    always @(posedge clk) begin
        clk_out_buf <= shift_reg_buf2_high[3]; // Corresponds to bit 7
    end
    
    // Final output assignment
    assign clk_out = clk_out_buf;
endmodule