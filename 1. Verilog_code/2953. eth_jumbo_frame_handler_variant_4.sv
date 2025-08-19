//SystemVerilog
// 顶层模块
module eth_jumbo_frame_handler #(
    parameter STD_FRAME_SIZE = 1518,  // Standard Ethernet frame size
    parameter JUMBO_FRAME_SIZE = 9000 // Jumbo frame size limit
) (
    input wire clk,
    input wire reset,
    // Data input interface
    input wire [7:0] rx_data,
    input wire rx_valid,
    input wire frame_start,
    input wire frame_end,
    // Data output interface
    output wire [7:0] tx_data,
    output wire tx_valid,
    output wire frame_too_large,
    output wire jumbo_frame_detected
);
    // 内部连接信号
    wire [13:0] byte_count;
    wire std_size_reached;
    wire jumbo_size_reached;
    
    // 帧大小监控子模块
    frame_size_monitor #(
        .STD_FRAME_SIZE(STD_FRAME_SIZE),
        .JUMBO_FRAME_SIZE(JUMBO_FRAME_SIZE)
    ) size_monitor (
        .clk(clk),
        .reset(reset),
        .rx_valid(rx_valid),
        .frame_start(frame_start),
        .byte_count(byte_count),
        .std_size_reached(std_size_reached),
        .jumbo_size_reached(jumbo_size_reached)
    );
    
    // 帧状态控制子模块
    frame_status_controller frame_controller (
        .clk(clk),
        .reset(reset),
        .std_size_reached(std_size_reached),
        .jumbo_size_reached(jumbo_size_reached),
        .frame_start(frame_start),
        .jumbo_frame_detected(jumbo_frame_detected),
        .frame_too_large(frame_too_large)
    );
    
    // 数据传输子模块
    data_path_controller data_controller (
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .frame_start(frame_start),
        .frame_end(frame_end),
        .frame_too_large(frame_too_large),
        .tx_data(tx_data),
        .tx_valid(tx_valid)
    );
    
endmodule

// 帧大小监控子模块 - 负责计数和检测帧大小
module frame_size_monitor #(
    parameter STD_FRAME_SIZE = 1518,
    parameter JUMBO_FRAME_SIZE = 9000
) (
    input wire clk,
    input wire reset,
    input wire rx_valid,
    input wire frame_start,
    output reg [13:0] byte_count,
    output wire std_size_reached,
    output wire jumbo_size_reached
);
    // 字节计数器
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            byte_count <= 14'd0;
        end else if (frame_start) begin
            byte_count <= 14'd0;
        end else if (rx_valid) begin
            byte_count <= byte_count + 1'b1;
        end
    end
    
    // 大小检测逻辑
    assign std_size_reached = (byte_count == STD_FRAME_SIZE) && rx_valid;
    assign jumbo_size_reached = (byte_count >= JUMBO_FRAME_SIZE) && rx_valid;
    
endmodule

// 帧状态控制子模块 - 负责管理帧的状态标志
module frame_status_controller (
    input wire clk,
    input wire reset,
    input wire std_size_reached,
    input wire jumbo_size_reached,
    input wire frame_start,
    output reg jumbo_frame_detected,
    output reg frame_too_large
);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            jumbo_frame_detected <= 1'b0;
            frame_too_large <= 1'b0;
        end else if (frame_start) begin
            jumbo_frame_detected <= 1'b0;
            frame_too_large <= 1'b0;
        end else begin
            // 检测到标准帧大小
            if (std_size_reached) begin
                jumbo_frame_detected <= 1'b1;
            end
            
            // 检测到超过巨型帧大小
            if (jumbo_size_reached) begin
                frame_too_large <= 1'b1;
            end
        end
    end
    
endmodule

// 数据传输控制子模块 - 负责处理数据传输
module data_path_controller (
    input wire clk,
    input wire reset,
    input wire [7:0] rx_data,
    input wire rx_valid,
    input wire frame_start,
    input wire frame_end,
    input wire frame_too_large,
    output reg [7:0] tx_data,
    output reg tx_valid
);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_data <= 8'h00;
            tx_valid <= 1'b0;
        end else if (frame_start) begin
            tx_valid <= 1'b0;
        end else if (rx_valid && !frame_too_large) begin
            // 有效数据且帧大小正常，传输数据
            tx_data <= rx_data;
            tx_valid <= 1'b1;
        end else if (frame_end || (rx_valid && frame_too_large)) begin
            // 帧结束或帧过大，停止传输
            tx_valid <= 1'b0;
        end else begin
            tx_valid <= 1'b0;
        end
    end
    
endmodule