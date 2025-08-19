//SystemVerilog
// 顶层模块
module sync_counter_up (
    input  wire       clk,           // 系统时钟
    input  wire       reset,         // 异步复位信号
    input  wire       valid_in,      // 输入有效信号
    input  wire       ready_out,     // 下游模块准备接收数据信号
    output wire       ready_in,      // 准备接收输入信号
    output wire       valid_out,     // 输出有效信号 
    output wire [7:0] count          // 8位计数器输出
);

    // 内部连接信号
    wire handshake_complete;

    // 握手控制模块实例化
    handshake_controller handshake_ctrl_inst (
        .clk                (clk),
        .reset              (reset),
        .valid_in           (valid_in),
        .ready_in           (ready_in),
        .handshake_complete (handshake_complete)
    );

    // 计数逻辑模块实例化
    counter_core counter_core_inst (
        .clk                (clk),
        .reset              (reset),
        .handshake_complete (handshake_complete),
        .ready_out          (ready_out),
        .valid_in           (valid_in),
        .valid_out          (valid_out),
        .count              (count)
    );

endmodule

// 握手控制模块
module handshake_controller (
    input  wire clk,
    input  wire reset,
    input  wire valid_in,
    output wire ready_in,
    output reg  handshake_complete
);

    // 握手逻辑: 当复位未激活时,准备接收输入
    assign ready_in = !reset;

    // 握手完成标志
    always @(posedge clk or posedge reset) begin
        if (reset)
            handshake_complete <= 1'b0;
        else
            handshake_complete <= valid_in && ready_in;
    end

endmodule

// 计数器核心模块
module counter_core (
    input  wire       clk,
    input  wire       reset,
    input  wire       handshake_complete,
    input  wire       ready_out,
    input  wire       valid_in,
    output reg        valid_out,
    output reg  [7:0] count
);

    // 计数逻辑处理
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            // 当握手成功且下游准备好接收数据时，更新计数值
            if (handshake_complete && ready_out) begin
                count <= count + 1'b1;
                valid_out <= 1'b1;
            end else if (!ready_out) begin
                // 保持当前值直到下游准备好
                valid_out <= 1'b1;
            end else if (!valid_in) begin
                // 无有效输入时，保持当前计数器值但标记输出无效
                valid_out <= 1'b0;
            end
        end
    end

endmodule