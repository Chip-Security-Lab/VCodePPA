//SystemVerilog
// Top level module
module DynamicWidthBridge #(
    parameter IN_W = 32,
    parameter OUT_W = 64
)(
    input clk, rst_n,
    input [IN_W-1:0] data_in,
    input in_valid,
    output [OUT_W-1:0] data_out,
    output out_valid
);
    localparam RATIO = OUT_W / IN_W;
    
    // Internal signals
    wire [OUT_W-1:0] shift_reg_out;
    wire [3:0] count_out;
    wire shift_en;
    
    // Instantiate submodules
    ShiftRegister #(
        .IN_W(IN_W),
        .OUT_W(OUT_W)
    ) shift_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .shift_en(shift_en),
        .shift_reg_out(shift_reg_out)
    );
    
    Counter #(
        .RATIO(RATIO)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .count_out(count_out)
    );
    
    ControlLogic #(
        .RATIO(RATIO)
    ) ctrl_inst (
        .count(count_out),
        .in_valid(in_valid),
        .shift_en(shift_en),
        .out_valid(out_valid)
    );
    
    assign data_out = shift_reg_out;

endmodule

// Shift register submodule
module ShiftRegister #(
    parameter IN_W = 32,
    parameter OUT_W = 64
)(
    input clk, rst_n,
    input [IN_W-1:0] data_in,
    input shift_en,
    output reg [OUT_W-1:0] shift_reg_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg_out <= 0;
        end else if (shift_en) begin
            shift_reg_out <= {shift_reg_out[OUT_W-IN_W-1:0], data_in};
        end
    end
endmodule

// Counter submodule
module Counter #(
    parameter RATIO = 2
)(
    input clk, rst_n,
    input in_valid,
    output reg [3:0] count_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_out <= 0;
        end else if (in_valid) begin
            count_out <= (count_out == RATIO-1) ? 0 : count_out + 1;
        end
    end
endmodule

// Control logic submodule
module ControlLogic #(
    parameter RATIO = 2
)(
    input [3:0] count,
    input in_valid,
    output shift_en,
    output out_valid
);
    assign shift_en = in_valid;
    assign out_valid = (count == RATIO-1) & in_valid;
endmodule