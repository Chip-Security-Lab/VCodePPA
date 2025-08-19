//SystemVerilog
module pipelined_mult (
    input clk,
    input signed [15:0] a, b,
    output reg signed [31:0] result
);
    // Stage 1 registers
    reg signed [15:0] a_stage1, b_stage1;
    reg signed [15:0] a_abs, b_abs;
    reg a_sign, b_sign;
    
    // Stage 2 registers
    reg signed [31:0] unsigned_prod;
    reg signed [31:0] partial_stage2;
    
    // Buffer registers for high fanout signals
    reg signed [15:0] a_buf1, a_buf2;
    reg signed [15:0] b_buf1, b_buf2;
    reg signed [15:0] a_abs_buf, b_abs_buf;
    reg a_sign_buf, b_sign_buf;
    
    always @(posedge clk) begin
        // Stage 1: Input register and sign processing
        a_buf1 <= a;
        b_buf1 <= b;
        
        a_buf2 <= a_buf1;
        b_buf2 <= b_buf1;
        
        a_stage1 <= a_buf2;
        b_stage1 <= b_buf2;
        
        a_abs_buf <= a_buf2[15] ? -a_buf2 : a_buf2;
        b_abs_buf <= b_buf2[15] ? -b_buf2 : b_buf2;
        
        a_abs <= a_abs_buf;
        b_abs <= b_abs_buf;
        
        a_sign_buf <= a_buf2[15];
        b_sign_buf <= b_buf2[15];
        
        a_sign <= a_sign_buf;
        b_sign <= b_sign_buf;
        
        // Stage 2: Unsigned multiplication and sign calculation
        unsigned_prod <= a_abs * b_abs;
        partial_stage2 <= (a_sign ^ b_sign) ? -unsigned_prod : unsigned_prod;
        
        // Stage 3: Output register
        result <= partial_stage2;
    end
endmodule