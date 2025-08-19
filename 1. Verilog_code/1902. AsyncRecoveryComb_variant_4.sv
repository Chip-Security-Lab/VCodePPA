//SystemVerilog
module AsyncRecoveryComb #(
    parameter WIDTH = 8
)(
    input wire clk,                  // 时钟信号
    input wire rst_n,                // 复位信号
    input wire [WIDTH-1:0] din,      // 输入数据
    output reg [WIDTH-1:0] dout      // 输出数据
);

    // 内部信号定义 - 分割数据路径
    reg [WIDTH-1:0] din_registered;
    reg [WIDTH-1:0] shifted_data;
    reg [WIDTH-1:0] xor_result;
    
    // 时钟缓冲策略 - 为每个时序逻辑模块提供单独的缓冲时钟
    wire clk_buf1, clk_buf2, clk_buf3, clk_buf4;
    
    // 时钟缓冲器实例化 - 使用非反相缓冲器减少扇出负载
    (* dont_touch = "true" *) buf (clk_buf1, clk);
    (* dont_touch = "true" *) buf (clk_buf2, clk);
    (* dont_touch = "true" *) buf (clk_buf3, clk);
    (* dont_touch = "true" *) buf (clk_buf4, clk);

    // 第一级流水线：注册输入数据 - 使用单独缓冲时钟
    always @(posedge clk_buf1 or negedge rst_n) begin
        if (!rst_n) begin
            din_registered <= {WIDTH{1'b0}};
        end else begin
            din_registered <= din;
        end
    end

    // 第二级流水线：计算移位数据 - 使用单独缓冲时钟
    always @(posedge clk_buf2 or negedge rst_n) begin
        if (!rst_n) begin
            shifted_data <= {WIDTH{1'b0}};
        end else begin
            shifted_data <= {din_registered[WIDTH-2:0], 1'b0}; // 左移一位
        end
    end

    // 第三级流水线：计算XOR噪声消除 - 使用单独缓冲时钟
    always @(posedge clk_buf3 or negedge rst_n) begin
        if (!rst_n) begin
            xor_result <= {WIDTH{1'b0}};
        end else begin
            xor_result <= din_registered ^ shifted_data; // XOR噪声消除
        end
    end

    // 输出级：最终结果 - 使用单独缓冲时钟
    always @(posedge clk_buf4 or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {WIDTH{1'b0}};
        end else begin
            dout <= xor_result;
        end
    end

endmodule