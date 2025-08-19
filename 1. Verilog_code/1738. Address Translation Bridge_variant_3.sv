//SystemVerilog
module addr_trans_bridge #(parameter DWIDTH=32, AWIDTH=16) (
    input clk, rst_n,
    input [AWIDTH-1:0] src_addr,
    input [DWIDTH-1:0] src_data,
    input src_valid,
    output reg src_ready,
    output reg [AWIDTH-1:0] dst_addr,
    output reg [DWIDTH-1:0] dst_data,
    output reg dst_valid,
    input dst_ready
);
    // 参数化寄存器定义
    reg [AWIDTH-1:0] base_addr = 'h1000;  // 基地址
    reg [AWIDTH-1:0] limit_addr = 'h2000; // 上限地址
    
    // 使用补码加法实现减法
    wire [AWIDTH-1:0] addr_offset = src_addr + (~base_addr + 1'b1);
    wire addr_in_range = addr_offset < (limit_addr - base_addr);
    
    // 简化状态控制，减少判断层级
    reg busy;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dst_valid <= 0;
            src_ready <= 1;
            busy <= 0;
        end else begin
            case ({busy, src_valid, dst_ready})
                3'b000, 3'b001: begin // 空闲状态
                    src_ready <= 1;
                end
                3'b010: begin // 新请求到达且在范围内
                    if (addr_in_range) begin
                        dst_addr <= addr_offset;
                        dst_data <= src_data;
                        dst_valid <= 1;
                        src_ready <= 0;
                        busy <= 1;
                    end
                end
                3'b100: begin // 等待目标ready
                    src_ready <= 0;
                end
                3'b101: begin // 目标已ready，传输完成
                    dst_valid <= 0;
                    src_ready <= 1;
                    busy <= 0;
                end
                3'b111, 3'b110: begin // 目标就绪时，可能同时有新请求
                    dst_valid <= 0;
                    src_ready <= 1;
                    busy <= 0;
                end
                default: begin
                    // 保持现有状态
                end
            endcase
        end
    end
endmodule