//SystemVerilog
//IEEE 1364-2005 Verilog standard
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
    output reg locked,
    // Pipeline control signals
    input wire valid_in,
    output reg valid_out,
    input wire ready_in,
    output wire ready_out
);
    // Pipeline stage registers
    reg [WIDTH-1:0] data_stage1, data_stage2;
    reg lock_req_stage1, lock_req_stage2;
    reg unlock_req_stage1, unlock_req_stage2;
    reg capture_stage1, capture_stage2;
    reg valid_stage1, valid_stage2;
    
    // Lock status registers for pipeline stages
    reg locked_stage1, locked_stage2;
    
    // Ready signal propagation - optimized for faster logic path
    assign ready_out = !valid_stage2 || ready_in;
    
    // Stage 1: Data capture and initial processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
            lock_req_stage1 <= 1'b0;
            unlock_req_stage1 <= 1'b0;
            capture_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (ready_out) begin
            data_stage1 <= data_in;
            lock_req_stage1 <= lock_req;
            unlock_req_stage1 <= unlock_req;
            capture_stage1 <= capture;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 1: Lock status pre-processing - optimized priority logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            locked_stage1 <= 1'b0;
        else if (ready_out) begin
            // Priority-encoded lock status update
            case ({lock_req, unlock_req})
                2'b10:   locked_stage1 <= 1'b1;  // Lock request
                2'b01:   locked_stage1 <= 1'b0;  // Unlock request
                default: locked_stage1 <= locked; // No change
            endcase
        end
    end
    
    // Stage 2: Forward data and control signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {WIDTH{1'b0}};
            lock_req_stage2 <= 1'b0;
            unlock_req_stage2 <= 1'b0;
            capture_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            locked_stage2 <= 1'b0;
        end
        else if (ready_in) begin
            data_stage2 <= data_stage1;
            lock_req_stage2 <= lock_req_stage1;
            unlock_req_stage2 <= unlock_req_stage1;
            capture_stage2 <= capture_stage1;
            valid_stage2 <= valid_stage1;
            locked_stage2 <= locked_stage1;
        end
    end
    
    // Final stage: Output processing - optimized with combined logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            locked <= 1'b0;
            valid_out <= 1'b0;
        end
        else if (ready_in) begin
            // Optimized lock handling with priority encoding
            case ({lock_req_stage2, unlock_req_stage2})
                2'b10:   locked <= 1'b1;  // Lock request has priority
                2'b01:   locked <= 1'b0;  // Unlock request
                default: locked <= locked_stage2; // Maintain current state
            endcase
                
            // Data capture logic optimized to single condition
            if (capture_stage2 & ~locked_stage2)
                shadow_data <= data_stage2;
                
            // Propagate valid signal
            valid_out <= valid_stage2;
        end
    end
endmodule