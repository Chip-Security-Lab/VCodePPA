//SystemVerilog
module rom_async #(parameter DATA=16, ADDR=8)(
    input [ADDR-1:0] a,
    output reg [DATA-1:0] dout
);
    // 使用时序逻辑读取以提高时序性能
    always @(a) begin
        case(a)
            8'd0: dout = 16'h1234;
            8'd1: dout = 16'h5678;
            8'd2: dout = 16'h9ABC;
            8'd3: dout = 16'hDEF0;
            default: dout = 16'h0000; // 为未初始化地址提供默认值
        endcase
    end
endmodule