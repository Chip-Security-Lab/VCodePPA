module dual_clk_shadow_reg #(
    parameter WIDTH = 8
)(
    // Primary domain
    input wire clk_pri,
    input wire rst_n_pri,
    input wire [WIDTH-1:0] data_pri,
    input wire capture,
    
    // Shadow domain
    input wire clk_shd,
    input wire rst_n_shd,
    output reg [WIDTH-1:0] shadow_data
);
    // Primary domain registers
    reg [WIDTH-1:0] pri_reg;
    reg cap_flag, cap_sync;
    
    // Shadow domain registers
    reg cap_meta, cap_detect;
    
    // Primary register update
    always @(posedge clk_pri or negedge rst_n_pri) begin
        if (!rst_n_pri) begin
            pri_reg <= 0;
            cap_flag <= 0;
        end else begin
            pri_reg <= data_pri;
            cap_flag <= capture ? 1'b1 : (cap_sync ? 1'b0 : cap_flag);
        end
    end
    
    // Shadow domain clock crossing
    always @(posedge clk_shd or negedge rst_n_shd) begin
        if (!rst_n_shd) begin
            cap_meta <= 0; cap_detect <= 0; cap_sync <= 0;
            shadow_data <= 0;
        end else begin
            cap_meta <= cap_flag; cap_detect <= cap_meta;
            if (cap_detect && !cap_sync) begin
                shadow_data <= pri_reg; cap_sync <= 1'b1;
            end else if (!cap_detect) cap_sync <= 1'b0;
        end
    end
endmodule