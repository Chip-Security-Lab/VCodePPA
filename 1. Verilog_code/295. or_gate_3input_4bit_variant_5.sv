//SystemVerilog
module or_gate_3input_4bit (
    input wire clk,       // Clock input
    input wire reset_n,   // Active low reset
    input wire [3:0] a,   // First input operand
    input wire [3:0] b,   // Second input operand
    input wire [3:0] c,   // Third input operand
    output reg [3:0] y    // Output result
);
    // Clock buffer signals
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Clock buffer instantiation
    clk_buffer clk_buffer_inst1 (.clk_in(clk), .clk_out(clk_buf1));
    clk_buffer clk_buffer_inst2 (.clk_in(clk), .clk_out(clk_buf2));
    clk_buffer clk_buffer_inst3 (.clk_in(clk), .clk_out(clk_buf3));
    
    // Pipeline stage 1: OR operation between a and b
    reg [3:0] ab_or_stage;
    
    // Pipeline stage 2: OR operation with c
    reg [3:0] result_stage;
    
    // First pipeline stage
    always @(posedge clk_buf1 or negedge reset_n) begin
        if (!reset_n) begin
            ab_or_stage <= 4'b0000;
        end else begin
            ab_or_stage <= a | b;
        end
    end
    
    // Second pipeline stage
    always @(posedge clk_buf2 or negedge reset_n) begin
        if (!reset_n) begin
            result_stage <= 4'b0000;
        end else begin
            result_stage <= ab_or_stage | c;
        end
    end
    
    // Output assignment
    always @(posedge clk_buf3 or negedge reset_n) begin
        if (!reset_n) begin
            y <= 4'b0000;
        end else begin
            y <= result_stage;
        end
    end
endmodule

// Clock buffer module for distributing clock load
module clk_buffer (
    input wire clk_in,
    output wire clk_out
);
    // Simple non-inverting buffer
    assign clk_out = clk_in;
    
    // Synthesis attributes to ensure this is implemented as a clock buffer
    // synthesis attribute IOB of clk_out is "TRUE"
    // synthesis attribute BUFFER_TYPE of clk_buffer is "CLOCK"
endmodule