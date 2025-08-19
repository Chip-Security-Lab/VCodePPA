//SystemVerilog
// IEEE 1364-2005 Verilog
module ArithShift #(parameter N=8) (
    input clk, rstn, arith_shift, s_in,
    input valid_in,                      // 输入有效信号
    output reg valid_out,                // 输出有效信号
    output reg [N-1:0] q,
    output reg carry_out
);
    // Stage 1: Input and control registers
    reg arith_shift_stage1, s_in_stage1;
    reg [N-1:0] q_stage1;
    reg valid_stage1;
    
    // Stage 2: Computation preparation registers
    reg arith_shift_stage2;
    reg s_in_stage2;
    reg [N-1:0] q_stage2;
    reg valid_stage2;
    
    // Stage 3: Execution registers
    reg [N-1:0] q_stage3;
    reg carry_stage3;
    reg valid_stage3;
    
    // Pipelined implementation
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset all pipeline registers
            // Stage 1 registers
            arith_shift_stage1 <= 0;
            s_in_stage1 <= 0;
            q_stage1 <= 0;
            valid_stage1 <= 0;
            
            // Stage 2 registers
            arith_shift_stage2 <= 0;
            s_in_stage2 <= 0;
            q_stage2 <= 0;
            valid_stage2 <= 0;
            
            // Stage 3 registers
            q_stage3 <= 0;
            carry_stage3 <= 0;
            valid_stage3 <= 0;
            
            // Output registers
            q <= 0;
            carry_out <= 0;
            valid_out <= 0;
        end else begin
            // Stage 1: Input and capture stage
            arith_shift_stage1 <= arith_shift;
            s_in_stage1 <= s_in;
            q_stage1 <= q;              // Feedback from output
            valid_stage1 <= valid_in;
            
            // Stage 2: Preparation stage
            arith_shift_stage2 <= arith_shift_stage1;
            s_in_stage2 <= s_in_stage1;
            q_stage2 <= q_stage1;
            valid_stage2 <= valid_stage1;
            
            // Stage 3: Execute shift operation
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                if (arith_shift_stage2) begin
                    // Arithmetic right shift
                    carry_stage3 <= q_stage2[0];
                    q_stage3 <= {q_stage2[N-1], q_stage2[N-1:1]};
                end else begin
                    // Logical left shift
                    carry_stage3 <= q_stage2[N-1];
                    q_stage3 <= {q_stage2[N-2:0], s_in_stage2};
                end
            end
            
            // Output stage: Transfer results to output
            q <= q_stage3;
            carry_out <= carry_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule