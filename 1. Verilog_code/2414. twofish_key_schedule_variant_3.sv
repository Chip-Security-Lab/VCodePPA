//SystemVerilog
module twofish_key_schedule (
    input clk, key_update,
    input [255:0] master_key,
    
    // Valid-Ready interface signals
    output reg [31:0] round_key,
    output reg valid,
    input ready
);
    // Key storage registers
    reg [255:0] me_key, mo_key;
    
    // Pipeline stage registers
    reg [31:0] me_key_part_stage1, mo_key_part_stage1;
    reg [31:0] sum_stage2;
    reg [31:0] shifted_sum_stage3;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [2:0] cnt;
    
    // Handshake control
    reg stall;
    
    // Pipeline implementation
    always @(posedge clk) begin
        // Determine if pipeline should stall (valid but not ready)
        stall = valid && !ready;
        
        // Stage 0: Input and control logic
        if (key_update) begin
            me_key <= master_key[255:128];
            mo_key <= master_key[127:0];
            cnt <= 3'b0;
            valid_stage1 <= 1'b0;
        end else if (!stall) begin
            // Address selection and valid signal generation
            if (cnt < 4) begin
                cnt <= cnt + 1'b1;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
        
        // Stage 1: Key part selection (only update if not stalled)
        if (!stall) begin
            me_key_part_stage1 <= me_key[cnt*32+:32];
            mo_key_part_stage1 <= mo_key[cnt*32+:32];
            valid_stage2 <= valid_stage1;
        end
        
        // Stage 2: Addition (only update if not stalled)
        if (!stall) begin
            sum_stage2 <= me_key_part_stage1 + mo_key_part_stage1;
            valid_stage3 <= valid_stage2;
        end
        
        // Stage 3: Shifting (only update if not stalled)
        if (!stall) begin
            shifted_sum_stage3 <= sum_stage2 <<< 9;
            valid <= valid_stage3;
        end
        
        // Output stage (only update if handshake completes)
        if (!stall && ready) begin
            round_key <= shifted_sum_stage3;
        end
    end
endmodule