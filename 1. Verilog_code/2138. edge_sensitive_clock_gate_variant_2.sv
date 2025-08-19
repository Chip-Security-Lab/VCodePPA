//SystemVerilog
module edge_sensitive_clock_gate (
    input  wire clk_in,     // Input clock signal
    input  wire data_valid, // Data valid control signal
    input  wire rst_n,      // Active-low reset signal
    output wire clk_out     // Gated output clock
);
    // === Control Signal Pipeline Registers ===
    reg data_valid_reg1;
    reg data_valid_reg2;
    
    // === Edge Detection Signals ===
    reg rising_edge_detected_reg;
    
    // First pipeline stage - capture data_valid
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            data_valid_reg1 <= 1'b0;
        else
            data_valid_reg1 <= data_valid;
    end
    
    // Second pipeline stage - delay for edge detection
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            data_valid_reg2 <= 1'b0;
        else
            data_valid_reg2 <= data_valid_reg1;
    end
    
    // Detect rising edge and register it directly
    // This moves the register backward through the combinational logic
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            rising_edge_detected_reg <= 1'b0;
        else
            rising_edge_detected_reg <= data_valid_reg1 & ~data_valid_reg2;
    end
    
    // Final clock gating logic with glitch-free implementation
    // The enable_clock register has been moved backward through the logic
    assign clk_out = clk_in & rising_edge_detected_reg;
    
endmodule