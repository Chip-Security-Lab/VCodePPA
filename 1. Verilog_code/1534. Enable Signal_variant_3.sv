//SystemVerilog
module enabled_shadow_reg #(
    parameter DATA_WIDTH = 12
)(
    input wire clock,
    input wire reset_n,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_input,
    input wire shadow_capture,
    output reg [DATA_WIDTH-1:0] shadow_output
);
    // Registering input signals to improve timing
    reg [DATA_WIDTH-1:0] data_input_reg;
    reg enable_reg, shadow_capture_reg;
    
    // Input signal registration
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            data_input_reg <= {DATA_WIDTH{1'b0}};
            enable_reg <= 1'b0;
            shadow_capture_reg <= 1'b0;
        end else begin
            data_input_reg <= data_input;
            enable_reg <= enable;
            shadow_capture_reg <= shadow_capture;
        end
    end
    
    // Main register and shadow register combined logic
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            shadow_output <= {DATA_WIDTH{1'b0}};
        end else if (shadow_capture_reg && enable_reg) begin
            shadow_output <= data_input_reg;
        end
    end
endmodule