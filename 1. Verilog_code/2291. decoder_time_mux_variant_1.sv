//SystemVerilog
module decoder_time_mux #(parameter TS_BITS=2) (
    input wire clk, rst_n,
    input wire [7:0] addr,
    output reg [3:0] decoded,
    // 流水线控制信号
    input wire valid_in,
    output reg valid_out
);
    // 流水线阶段寄存器与时间计数优化
    reg [TS_BITS-1:0] time_cnt;
    reg [7:0] addr_pipe1;
    reg valid_pipe1, valid_pipe2;
    reg [3:0] decoded_pipe2;
    
    // 阶段1: 更新时间计数器与输入缓存
    // 合并了计数器逻辑和输入缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            time_cnt <= {TS_BITS{1'b0}};
            addr_pipe1 <= 8'h0;
            valid_pipe1 <= 1'b0;
        end else begin
            time_cnt <= time_cnt + 1'b1;
            addr_pipe1 <= addr;
            valid_pipe1 <= valid_in;
        end
    end
    
    // 阶段2: 优化索引计算与解码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_pipe2 <= 4'h0;
            valid_pipe2 <= 1'b0;
        end else begin
            // 重构数据选择，使用参数化的位选择
            case (time_cnt)
                2'b00: decoded_pipe2 <= addr_pipe1[3:0];
                2'b01: decoded_pipe2 <= addr_pipe1[7:4];
                2'b10: decoded_pipe2 <= addr_pipe1[3:0]; // 循环使用低位
                2'b11: decoded_pipe2 <= addr_pipe1[7:4]; // 循环使用高位
                default: decoded_pipe2 <= 4'h0;
            endcase
            valid_pipe2 <= valid_pipe1;
        end
    end
    
    // 输出阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 4'h0;
            valid_out <= 1'b0;
        end else begin
            decoded <= decoded_pipe2;
            valid_out <= valid_pipe2;
        end
    end
endmodule