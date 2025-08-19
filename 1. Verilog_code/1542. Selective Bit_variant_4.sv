//SystemVerilog
// IEEE 1364-2005 Verilog standard
module selective_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] bit_mask,
    input wire update,
    output reg [WIDTH-1:0] shadow_out
);
    // Pipeline stage 1: Input data capture
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] bit_mask_stage1;
    reg update_stage1;
    
    // Pipeline stage 2: Intermediate registers and partial computation
    reg [WIDTH-1:0] data_stage2;
    reg [WIDTH-1:0] bit_mask_stage2;
    reg update_stage2;
    reg [WIDTH-1:0] inverted_mask_stage2;
    
    // Pipeline stage 3: Computation preparation
    reg [WIDTH-1:0] masked_data_stage3;
    reg [WIDTH-1:0] inverted_mask_stage3;
    reg update_stage3;
    reg [WIDTH-1:0] shadow_stage3; // Added pipeline register for shadow_out
    
    // Pipeline stage 4: Partial computation
    reg [WIDTH-1:0] masked_shadow_stage4;
    reg [WIDTH-1:0] masked_data_stage4;
    reg update_stage4;
    
    // Pipeline stage 5: Final computation
    reg [WIDTH-1:0] combined_data_stage5;
    reg update_stage5;
    
    // Pipeline stage 1: Input data capture with reduced critical path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            bit_mask_stage1 <= 0;
            update_stage1 <= 0;
        end
        else begin
            data_stage1 <= data_in;
            bit_mask_stage1 <= bit_mask;
            update_stage1 <= update;
        end
    end
    
    // Pipeline stage 2: Compute inverted mask early to reduce critical path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            bit_mask_stage2 <= 0;
            update_stage2 <= 0;
            inverted_mask_stage2 <= 0;
        end
        else begin
            data_stage2 <= data_stage1;
            bit_mask_stage2 <= bit_mask_stage1;
            update_stage2 <= update_stage1;
            inverted_mask_stage2 <= ~bit_mask_stage1; // Move inversion operation earlier
        end
    end
    
    // Pipeline stage 3: Compute masked data and capture shadow value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data_stage3 <= 0;
            inverted_mask_stage3 <= 0;
            update_stage3 <= 0;
            shadow_stage3 <= 0;
        end
        else begin
            masked_data_stage3 <= data_stage2 & bit_mask_stage2;
            inverted_mask_stage3 <= inverted_mask_stage2;
            update_stage3 <= update_stage2;
            shadow_stage3 <= shadow_out; // Cache shadow value to reduce fanout
        end
    end
    
    // Pipeline stage 4: Split computation to reduce critical path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_shadow_stage4 <= 0;
            masked_data_stage4 <= 0;
            update_stage4 <= 0;
        end
        else begin
            masked_shadow_stage4 <= shadow_stage3 & inverted_mask_stage3;
            masked_data_stage4 <= masked_data_stage3;
            update_stage4 <= update_stage3;
        end
    end
    
    // Pipeline stage 5: Final data combination
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            combined_data_stage5 <= 0;
            update_stage5 <= 0;
        end
        else begin
            combined_data_stage5 <= masked_data_stage4 | masked_shadow_stage4;
            update_stage5 <= update_stage4;
        end
    end
    
    // Final shadow register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out <= 0;
        end 
        else if (update_stage5) begin
            shadow_out <= combined_data_stage5;
        end
    end
endmodule