//SystemVerilog
module ICMU_ShadowHybrid #(
    parameter DW = 32,
    parameter SHADOW_DEPTH = 4
)(
    input clk,
    input shadow_switch,
    input [DW-1:0] reg_in,
    output [DW-1:0] reg_out
);

    reg [DW-1:0] main_reg;
    reg [DW-1:0] shadow_regs [0:SHADOW_DEPTH-1];
    reg [1:0] shadow_ptr;
    wire [DW-1:0] shadow_reg_out = shadow_regs[shadow_ptr];
    wire [1:0] next_shadow_ptr = (shadow_ptr + 1) & {2{shadow_switch}};

    always @(posedge clk) begin
        main_reg <= reg_in;
        if (shadow_switch) begin
            shadow_regs[shadow_ptr] <= main_reg;
            shadow_ptr <= next_shadow_ptr;
        end
    end

    assign reg_out = shadow_switch ? shadow_reg_out : main_reg;

endmodule