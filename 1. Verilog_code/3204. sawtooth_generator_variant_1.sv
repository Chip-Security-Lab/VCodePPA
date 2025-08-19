//SystemVerilog
module sawtooth_generator(
    input clock,
    input areset,
    input en,
    output reg [7:0] sawtooth
);
    // 缓冲异步复位信号，降低扇出负载
    reg areset_buf1, areset_buf2;
    // 缓冲使能信号，降低扇出负载
    reg en_buf1, en_buf2;
    // 定义控制信号
    reg [1:0] ctrl;
    // 寄存器缓冲的控制信号
    reg [1:0] ctrl_buf;
    
    // 对高扇出信号areset进行缓冲
    always @(posedge clock or posedge areset) begin
        if (areset) begin
            areset_buf1 <= 1'b1;
            areset_buf2 <= 1'b1;
        end else begin
            areset_buf1 <= 1'b0;
            areset_buf2 <= 1'b0;
        end
    end
    
    // 对高扇出信号en进行缓冲
    always @(posedge clock) begin
        en_buf1 <= en;
        en_buf2 <= en;
    end
    
    // 使用缓冲后的信号生成控制信号
    always @(*) begin
        ctrl = {areset_buf1, en_buf1};
    end
    
    // 控制信号的寄存缓冲，减少组合逻辑路径
    always @(posedge clock) begin
        ctrl_buf <= ctrl;
    end
    
    // 使用缓冲的控制信号
    always @(posedge clock or posedge areset_buf2) begin
        if (areset_buf2) begin
            sawtooth <= 8'h00;
        end else begin
            case(ctrl_buf)
                2'b10, 2'b11: sawtooth <= 8'h00;  // areset = 1, 不管en是什么值
                2'b01:        sawtooth <= sawtooth + 8'h01;  // areset = 0, en = 1
                2'b00:        sawtooth <= sawtooth;  // areset = 0, en = 0, 保持
                default:      sawtooth <= 8'h00;  // 默认情况
            endcase
        end
    end
endmodule