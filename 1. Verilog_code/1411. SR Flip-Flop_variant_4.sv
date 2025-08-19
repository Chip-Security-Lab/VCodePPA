//SystemVerilog
module sr_flip_flop (
    input wire clk,
    input wire s,
    input wire r,
    output reg q
);
    // Stage 1: Input registration
    reg s_stage1, r_stage1;
    reg valid_stage1;
    
    // Stage 2: Logic computation
    reg s_stage2, r_stage2;
    reg valid_stage2;
    reg q_computed;
    
    // Stage 3: Output registration
    reg valid_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk) begin
        s_stage1 <= s;
        r_stage1 <= r;
        valid_stage1 <= 1'b1; // Always valid after reset
    end
    
    // Stage 2: Compute next state
    always @(posedge clk) begin
        s_stage2 <= s_stage1;
        r_stage2 <= r_stage1;
        valid_stage2 <= valid_stage1;
        
        // Compute the next q value
        case ({s_stage1, r_stage1})
            2'b00: q_computed <= q;      // No change
            2'b01: q_computed <= 1'b0;   // Reset
            2'b10: q_computed <= 1'b1;   // Set
            2'b11: q_computed <= 1'bx;   // Invalid - undefined
        endcase
    end
    
    // Stage 3: Register output
    always @(posedge clk) begin
        valid_stage3 <= valid_stage2;
        if (valid_stage2) begin
            q <= q_computed;
        end
    end
endmodule