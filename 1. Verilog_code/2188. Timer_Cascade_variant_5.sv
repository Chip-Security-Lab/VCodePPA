//SystemVerilog - IEEE 1364-2005
module Timer_Cascade #(parameter STAGES=2) (
    input clk, rst, en,
    output cascade_done
);
    // Pipeline stage signals
    genvar i;
    wire [STAGES:0] carry_wire;
    reg [STAGES-1:0] carry_reg;
    
    // Pipeline stage counters and valid signals
    reg [STAGES-1:0][3:0] cnt;
    reg [STAGES-1:0] valid_stage;
    
    // Stage input signals
    wire [STAGES-1:0] stage_active;
    
    // Pipeline stage outputs 
    wire [STAGES-1:0][3:0] next_cnt;
    wire [STAGES-1:0] next_carry;
    wire [STAGES-1:0] next_valid;
    
    // Connect first stage input
    assign carry_wire[0] = en;
    
    // Connect output signal
    assign cascade_done = carry_reg[STAGES-1] & valid_stage[STAGES-1];
    
    // Calculate actual processing control signal for each stage
    generate for(i=0; i<STAGES; i=i+1) begin: stage_control
        assign stage_active[i] = carry_wire[i] & valid_stage[i];
    end endgenerate
    
    // Pipeline architecture
    generate for(i=0; i<STAGES; i=i+1) begin: stage_logic
        // First stage has specialized valid logic
        if (i == 0) begin
            assign next_valid[i] = en | valid_stage[i];
        end else begin
            // Valid propagates through pipeline
            assign next_valid[i] = valid_stage[i-1] | valid_stage[i];
        end
        
        // Generate next counter value based on pipeline stage
        assign next_cnt[i] = (stage_active[i]) ? 
                             ((cnt[i] == 15) ? 4'd0 : cnt[i] + 4'd1) : 
                             cnt[i];
        
        // Generate carry signal for this stage
        assign next_carry[i] = (cnt[i] == 15) & stage_active[i];
        
        // Pipeline registers
        always @(posedge clk or posedge rst) begin
            if (rst) begin
                cnt[i] <= 4'd0;
                carry_reg[i] <= 1'b0;
                valid_stage[i] <= 1'b0;
            end
            else begin
                cnt[i] <= next_cnt[i];
                carry_reg[i] <= next_carry[i];
                valid_stage[i] <= next_valid[i];
            end
        end
        
        // Connect carry between stages
        if (i < STAGES-1)
            assign carry_wire[i+1] = carry_reg[i];
    end endgenerate
endmodule