//SystemVerilog
module Demux_MultiProto #(parameter DW=8) (
    input wire clk,
    input wire [1:0] proto_sel, // 0:SPI, 1:I2C, 2:UART
    input wire [DW-1:0] data,
    output reg [2:0][DW-1:0] proto_out
);

    // 使用one-hot编码的选择信号，避免解码步骤
    reg [2:0] proto_decode;
    
    // 预解码逻辑优化，减少关键路径延迟
    always @(*) begin
        proto_decode = 3'b000;
        proto_decode[proto_sel] = (proto_sel < 2'b11) ? 1'b1 : 1'b0;
    end
    
    // 使用并行结构更新输出，提高时序性能
    always @(posedge clk) begin
        proto_out[0] <= proto_decode[0] ? data : {DW{1'b0}};
        proto_out[1] <= proto_decode[1] ? data : {DW{1'b0}};
        proto_out[2] <= proto_decode[2] ? data : {DW{1'b0}};
    end

endmodule