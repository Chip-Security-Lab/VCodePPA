//SystemVerilog
module hybrid_timing_shifter (
    input clk, en,
    input [7:0] din,
    input [2:0] shift,
    output [7:0] dout
);
    wire [7:0] reg_stage;
    wire [7:0] comb_stage;
    
    // 实例化各个子模块
    input_register u_input_register (
        .clk(clk),
        .en(en),
        .din(din),
        .reg_out(reg_stage)
    );
    
    shift_operation u_shift_operation (
        .data_in(reg_stage),
        .shift_amount(shift),
        .shifted_data(comb_stage)
    );
    
    output_mux u_output_mux (
        .en(en),
        .comb_data(comb_stage),
        .reg_data(reg_stage),
        .dout(dout)
    );
endmodule

module input_register (
    input clk, en,
    input [7:0] din,
    output reg [7:0] reg_out
);
    always @(posedge clk) 
        if(en) reg_out <= din;
endmodule

module shift_operation #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input [DATA_WIDTH-1:0] data_in,
    input [SHIFT_WIDTH-1:0] shift_amount,
    output [DATA_WIDTH-1:0] shifted_data
);
    assign shifted_data = data_in << shift_amount;
endmodule

module output_mux #(
    parameter DATA_WIDTH = 8
)(
    input en,
    input [DATA_WIDTH-1:0] comb_data,
    input [DATA_WIDTH-1:0] reg_data,
    output [DATA_WIDTH-1:0] dout
);
    assign dout = en ? comb_data : reg_data;
endmodule