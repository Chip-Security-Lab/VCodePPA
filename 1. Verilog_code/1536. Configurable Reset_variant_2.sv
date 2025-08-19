//SystemVerilog
// IEEE 1364-2005 Verilog Standard
module param_shadow_reg #(
    parameter DWIDTH = 32,
    parameter RESET_VAL = 0
)(
    input wire clk,
    input wire rst,
    input wire [DWIDTH-1:0] data,
    input wire shadow_trigger,
    output reg [DWIDTH-1:0] shadow
);
    // Register data directly at input
    reg [DWIDTH-1:0] data_reg;
    // Registered trigger signal
    reg shadow_trigger_reg;
    
    // Register input signals
    always @(posedge clk) begin
        if (rst) begin
            data_reg <= RESET_VAL;
            shadow_trigger_reg <= 1'b0;
        end else begin
            data_reg <= data;
            shadow_trigger_reg <= shadow_trigger;
        end
    end
    
    // Shadow register update logic
    always @(posedge clk) begin
        if (rst) begin
            shadow <= RESET_VAL;
        end else if (shadow_trigger_reg) begin
            shadow <= data_reg;
        end
    end
endmodule