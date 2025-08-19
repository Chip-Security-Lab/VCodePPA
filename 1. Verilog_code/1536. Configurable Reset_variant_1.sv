//SystemVerilog
// IEEE 1364-2005 Verilog
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
    // Registered inputs to reduce input to register delay
    reg [DWIDTH-1:0] data_reg;
    reg shadow_trigger_reg;
    
    // Working register - now positioned after input registers
    reg [DWIDTH-1:0] work_reg;
    
    // Input registration
    always @(posedge clk) begin
        if (rst) begin
            data_reg <= RESET_VAL;
            shadow_trigger_reg <= 1'b0;
        end
        else begin
            data_reg <= data;
            shadow_trigger_reg <= shadow_trigger;
        end
    end
    
    // Working register update - now operates on registered inputs
    always @(posedge clk) begin
        if (rst)
            work_reg <= RESET_VAL;
        else
            work_reg <= data_reg;
    end
    
    // Shadow register update
    always @(posedge clk) begin
        if (rst)
            shadow <= RESET_VAL;
        else if (shadow_trigger_reg)
            shadow <= work_reg;
    end
endmodule