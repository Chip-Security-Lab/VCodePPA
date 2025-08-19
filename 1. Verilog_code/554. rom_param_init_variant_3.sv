//SystemVerilog
module rom_param_init #(
    parameter INIT_VAL = 64'h1234_5678_9ABC_DEF0
)(
    input [2:0] adr,
    output reg [15:0] dat
);
    // 内部信号声明 - 分段存储参数值
    wire [15:0] mem_segment_0;
    wire [15:0] mem_segment_1; 
    wire [15:0] mem_segment_2;
    wire [15:0] mem_segment_3;
    
    // 参数值分段提取 - 提高并行性并简化后续逻辑
    assign mem_segment_0 = INIT_VAL[15:0];
    assign mem_segment_1 = INIT_VAL[31:16];
    assign mem_segment_2 = INIT_VAL[47:32];
    assign mem_segment_3 = INIT_VAL[63:48];
    
    // 地址解码逻辑 - 仅对地址进行判断
    reg [3:0] segment_sel;
    
    always @(*) begin
        // 地址解码，生成one-hot选择信号
        segment_sel = 4'b0000;
        case(adr[1:0])
            2'b00: segment_sel[0] = 1'b1;
            2'b01: segment_sel[1] = 1'b1;
            2'b10: segment_sel[2] = 1'b1;
            2'b11: segment_sel[3] = 1'b1;
        endcase
    end
    
    // 数据选择逻辑 - 仅基于选择信号处理数据输出
    always @(*) begin
        // 数据多路复用器
        if (adr[2]) begin
            // 高位地址时输出0
            dat = 16'h0000;
        end else if (segment_sel[0]) begin
            dat = mem_segment_0;
        end else if (segment_sel[1]) begin
            dat = mem_segment_1;
        end else if (segment_sel[2]) begin
            dat = mem_segment_2;
        end else if (segment_sel[3]) begin
            dat = mem_segment_3;
        end else begin
            // 安全默认值
            dat = 16'h0000;
        end
    end
endmodule