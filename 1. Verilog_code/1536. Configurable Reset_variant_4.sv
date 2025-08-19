//SystemVerilog
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
    
    // Pipeline registers for shadow trigger path
    reg shadow_trigger_p1;
    reg [DWIDTH-1:0] work_reg_p1;
    
    // Working register update
    always @(posedge clk) begin
        case (rst)
            1'b1: work_reg <= RESET_VAL;
            1'b0: work_reg <= data;
        endcase
    end
    
    // Pipeline stage 1 - register the trigger and data
    always @(posedge clk) begin
        case (rst)
            1'b1: begin
                shadow_trigger_p1 <= 1'b0;
                work_reg_p1 <= RESET_VAL;
            end
            1'b0: begin
                shadow_trigger_p1 <= shadow_trigger;
                work_reg_p1 <= work_reg;
            end
        endcase
    end
    
    // Shadow register update (now using pipelined signals)
    always @(posedge clk) begin
        case ({rst, shadow_trigger_p1})
            2'b10,
            2'b11: shadow <= RESET_VAL;
            2'b01: shadow <= work_reg_p1;
            2'b00: shadow <= shadow;
        endcase
    end
endmodule