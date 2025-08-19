//SystemVerilog
module MuxBusHold #(parameter W=4) (
    input [3:0][W-1:0] bus_in,
    input [1:0] sel,
    input hold,
    output reg [W-1:0] bus_out
);
    wire [W-1:0] mux_out;
    wire [W-1:0] sub_result;
    wire [W-1:0] complement_bus_in;
    wire borrow;

    assign mux_out = bus_in[sel];
    
    // 计算补码
    assign complement_bus_in = ~mux_out + 1;

    // 条件反相减法器
    assign {borrow, sub_result} = hold ? {1'b0, bus_out} : {1'b0, mux_out} + 1'b1;

    always @(*) begin
        bus_out = hold ? bus_out : sub_result;
    end
endmodule