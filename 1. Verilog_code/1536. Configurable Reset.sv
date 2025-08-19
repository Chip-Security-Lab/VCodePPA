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
    // Working register
    reg [DWIDTH-1:0] work_reg;
    
    // Working register update
    always @(posedge clk) begin
        if (rst)
            work_reg <= RESET_VAL;
        else
            work_reg <= data;
    end
    
    // Shadow register update
    always @(posedge clk) begin
        if (rst)
            shadow <= RESET_VAL;
        else if (shadow_trigger)
            shadow <= work_reg;
    end
endmodule