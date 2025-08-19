//SystemVerilog
module pl_reg_preset #(parameter W=8, PRESET=8'hFF) (
    input clk, load, shift_in,
    output reg [W-1:0] q
);
    // Stage 1: Input registration
    reg load_stage1, shift_in_stage1;
    reg valid_stage1;
    
    always @(posedge clk) begin
        load_stage1 <= load;
        shift_in_stage1 <= shift_in;
        valid_stage1 <= 1'b1; // Always valid after reset
    end
    
    // Stage 2: Operation mode determination
    reg [1:0] operation_mode_stage2;
    reg valid_stage2;
    
    always @(posedge clk) begin
        operation_mode_stage2 <= {load_stage1, shift_in_stage1};
        valid_stage2 <= valid_stage1;
    end
    
    // Stage 3: Next state calculation
    reg [W-1:0] next_q_stage3;
    reg valid_stage3;
    
    always @(posedge clk) begin
        valid_stage3 <= valid_stage2;
        
        case(operation_mode_stage2)
            2'b10: next_q_stage3 <= PRESET;                // Load preset value
            2'b00: next_q_stage3 <= {q[W-2:0], 1'b0};      // Left shift and fill with 0
            2'b01: next_q_stage3 <= {q[W-2:0], 1'b1};      // Left shift and fill with 1
            2'b11: next_q_stage3 <= PRESET;                // Load preset value
        endcase
    end
    
    // Stage 4: Output registration
    always @(posedge clk) begin
        if (valid_stage3)
            q <= next_q_stage3;
    end
endmodule