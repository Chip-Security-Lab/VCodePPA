//SystemVerilog
// IEEE 1364-2005 Verilog Standard
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

    // === Data Path Stage 1: Input Registration ===
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] mask_stage1;
    reg update_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 'b0;
            mask_stage1 <= 'b0;
            update_stage1 <= 1'b0;
        end
        else begin
            data_stage1 <= data_in;
            mask_stage1 <= bit_mask;
            update_stage1 <= update;
        end
    end
    
    // === Data Path Stage 2: Data Processing ===
    reg [WIDTH-1:0] masked_data;
    reg [WIDTH-1:0] masked_shadow;
    reg update_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_data <= 'b0;
            masked_shadow <= 'b0;
            update_stage2 <= 1'b0;
        end
        else begin
            masked_data <= data_stage1 & mask_stage1;
            masked_shadow <= shadow_out & ~mask_stage1;
            update_stage2 <= update_stage1;
        end
    end
    
    // === Data Path Stage 3: Shadow Register Update ===
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out <= 'b0;
        end
        else if (update_stage2) begin
            shadow_out <= masked_data | masked_shadow;
        end
    end

endmodule