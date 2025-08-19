//SystemVerilog
module crc32_ethernet (
    input clk, rst,
    input req,                 // 请求信号（替代valid）
    input [31:0] data_in,      // 数据输入
    output reg ack,            // 应答信号（替代ready）
    output reg [31:0] crc_out  // CRC计算结果
);
    parameter POLY = 32'h04C11DB7;
    
    // 内部状态
    reg busy;
    
    // 使用生成表达式优化位反转，减少逻辑资源占用
    wire [31:0] data_rev;
    genvar g;
    generate
        for (g = 0; g < 32; g = g + 1) begin : gen_bit_reverse
            assign data_rev[g] = data_in[31-g];
        end
    endgenerate
    
    // 简化CRC计算逻辑
    wire [31:0] crc_xord = crc_out ^ (busy ? data_rev : data_rev);
    wire msb = crc_xord[31];
    
    // 优化next_val计算，利用多项式特性减少逻辑门数
    wire [31:0] next_val;
    generate
        for (g = 0; g < 31; g = g + 1) begin : gen_next_val
            assign next_val[g] = crc_xord[g+1] ^ (msb & POLY[g]);
        end
    endgenerate
    assign next_val[31] = msb ^ (msb & POLY[31]);
    
    // 优化状态机，减少状态判断逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_out <= 32'hFFFFFFFF;
            ack <= 1'b0;
            busy <= 1'b0;
        end else begin
            case ({busy, ack, req})
                3'b000, 3'b001: begin  // 空闲或新请求到达
                    if (req) begin
                        busy <= 1'b1;
                        ack <= 1'b1;
                        crc_out <= next_val;
                    end
                end
                3'b110: begin  // 处理完成，清除ack
                    ack <= 1'b0;
                end
                3'b100: begin  // 准备接收新请求
                    busy <= 1'b0;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule