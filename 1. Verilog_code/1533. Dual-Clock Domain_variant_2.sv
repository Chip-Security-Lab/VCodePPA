//SystemVerilog
// IEEE 1364-2005
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
    reg cap_flag;
    wire cap_sync;
    
    // Shadow domain registers
    reg cap_meta, cap_detect;
    reg cap_sync_reg;
    
    // Complementary signal for detection using two's complement subtraction
    reg [1:0] cap_comp_value;
    wire cap_edge_detected;
    
    assign cap_sync = cap_sync_reg;
    
    // Primary register update
    always @(posedge clk_pri or negedge rst_n_pri) begin
        if (!rst_n_pri) begin
            pri_reg <= {WIDTH{1'b0}};
            cap_flag <= 1'b0;
        end else begin
            pri_reg <= data_pri;
            if (capture)
                cap_flag <= 1'b1;
            else if (cap_sync)
                cap_flag <= 1'b0;
        end
    end
    
    // Two's complement subtraction for edge detection
    // When cap_detect changes from 0→1, cap_comp_value will be 2'b01
    assign cap_edge_detected = (cap_comp_value == 2'b01);
    
    // Shadow domain clock crossing with 2-FF synchronizer
    always @(posedge clk_shd or negedge rst_n_shd) begin
        if (!rst_n_shd) begin
            cap_meta <= 1'b0;
            cap_detect <= 1'b0;
            cap_sync_reg <= 1'b0;
            shadow_data <= {WIDTH{1'b0}};
            cap_comp_value <= 2'b00;
        end else begin
            // Synchronizer FF stages
            cap_meta <= cap_flag;
            cap_detect <= cap_meta;
            
            // Two's complement subtraction for edge detection
            // Current value minus previous value (stored in its complement form)
            cap_comp_value <= {1'b0, cap_detect} + {1'b0, ~cap_sync_reg} + 2'b01;
            
            // Edge detection and data capture using two's complement result
            if (cap_edge_detected) begin
                shadow_data <= pri_reg;
                cap_sync_reg <= 1'b1;
            end else if (!cap_detect) begin
                cap_sync_reg <= 1'b0;
            end
        end
    end
endmodule