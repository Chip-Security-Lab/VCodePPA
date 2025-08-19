//SystemVerilog
// IEEE 1364-2005
module locking_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire lock_req,
    input wire unlock_req,
    input wire capture,
    output reg [WIDTH-1:0] shadow_data,
    output reg locked
);
    // Pipeline stage 1 - Input registration
    reg [WIDTH-1:0] data_in_stage1;
    reg lock_req_stage1, unlock_req_stage1, capture_stage1;
    
    // Pipeline stage 2 - Processing registers
    reg [WIDTH-1:0] main_reg_stage2;
    reg locked_stage2;
    reg capture_stage2;
    
    // Valid signals for pipeline control
    reg valid_stage1, valid_stage2;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            lock_req_stage1 <= 0;
            unlock_req_stage1 <= 0;
            capture_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            data_in_stage1 <= data_in;
            lock_req_stage1 <= lock_req;
            unlock_req_stage1 <= unlock_req;
            capture_stage1 <= capture;
            valid_stage1 <= 1'b1; // Data is valid after first clock
        end
    end
    
    // Stage 2: Processing logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_stage2 <= 0;
            locked_stage2 <= 0;
            capture_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else if (valid_stage1) begin
            main_reg_stage2 <= data_in_stage1;
            
            // Lock control logic (moved to stage 2)
            if (lock_req_stage1)
                locked_stage2 <= 1'b1;
            else if (unlock_req_stage1)
                locked_stage2 <= 1'b0;
            
            capture_stage2 <= capture_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Output stage - Shadow register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= 0;
            locked <= 0;
        end
        else if (valid_stage2) begin
            // Shadow register update with lock protection
            if (capture_stage2 && !locked_stage2)
                shadow_data <= main_reg_stage2;
                
            // Forward lock status to output
            locked <= locked_stage2;
        end
    end
endmodule