//SystemVerilog
module delay_ff #(parameter STAGES=2) (
    input wire clk,
    input wire d,
    output wire q
);
    // Increase pipeline depth by implementing a more fine-grained approach
    // Pipeline registers for each stage calculation
    reg [STAGES-1:0] shift_reg;
    reg [STAGES-1:0] next_shift_stage1;
    reg [STAGES-1:0] next_shift_stage2;
    reg [STAGES:0] carry_stage1;
    reg [STAGES:0] carry_stage2;
    
    // First pipeline stage - Calculate XORs
    always @(posedge clk) begin
        integer i;
        
        carry_stage1[0] <= d;
        for (i = 0; i < STAGES; i = i + 1) begin
            next_shift_stage1[i] <= shift_reg[i] ^ carry_stage1[i];
            carry_stage1[i+1] <= shift_reg[i] & carry_stage1[i];
        end
    end
    
    // Second pipeline stage - Finalize calculations and update shift register
    always @(posedge clk) begin
        integer i;
        
        for (i = 0; i < STAGES; i = i + 1) begin
            next_shift_stage2[i] <= next_shift_stage1[i];
            carry_stage2[i] <= carry_stage1[i];
        end
        carry_stage2[STAGES] <= carry_stage1[STAGES];
        
        shift_reg <= next_shift_stage2;
    end
    
    // Output assignment
    assign q = shift_reg[STAGES-1];
endmodule