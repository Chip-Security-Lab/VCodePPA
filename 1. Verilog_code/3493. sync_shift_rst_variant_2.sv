//SystemVerilog
// SystemVerilog
// 顶层模块
module sync_shift_rst #(
    parameter DEPTH = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire serial_in,
    output wire [DEPTH-1:0] shift_reg
);
    // 内部连接信号
    wire [DEPTH:0] stage_connections;
    
    // 将serial_in连接到第一级的输入
    assign stage_connections[0] = serial_in;
    
    // 生成多个移位单元
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : shift_unit_gen
            shift_unit shift_stage (
                .clk(clk),
                .rst(rst),
                .data_in(stage_connections[i]),
                .data_out(stage_connections[i+1])
            );
            
            // 将中间结果连接到输出
            assign shift_reg[i] = stage_connections[i+1];
        end
    endgenerate
endmodule

// 单位移位单元子模块
module shift_unit (
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    output reg  data_out
);
    // 单位移位寄存器
    always @(posedge clk) begin
        data_out <= rst ? 1'b0 : data_in;
    end
endmodule