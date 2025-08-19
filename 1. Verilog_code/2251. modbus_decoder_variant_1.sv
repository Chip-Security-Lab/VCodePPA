//SystemVerilog
module modbus_decoder #(
    parameter TIMEOUT = 1000000
) (
    input  wire       clk,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,
    output reg        crc_err
);
    // 内部信号声明
    reg  [31:0] timer;
    reg  [15:0] crc;
    reg  [3:0]  bitcnt;
    wire [15:0] new_crc;
    wire        timeout_reset;
    wire        data_ready;
    
    // 实例化接收计时器模块
    rx_timer #(
        .TIMEOUT(TIMEOUT)
    ) u_rx_timer (
        .clk          (clk),
        .rx           (rx),
        .timer        (timer),
        .timeout_reset(timeout_reset)
    );
    
    // 实例化数据接收模块
    data_receiver u_data_receiver (
        .clk        (clk),
        .rx         (rx),
        .bitcnt     (bitcnt),
        .data       (data),
        .data_ready (data_ready)
    );
    
    // 实例化CRC计算模块
    crc_calculator u_crc_calculator (
        .data     (data),
        .crc_in   (crc),
        .crc_out  (new_crc)
    );
    
    // 实例化状态控制模块
    state_controller u_state_controller (
        .clk         (clk),
        .bitcnt      (bitcnt),
        .crc         (crc),
        .new_crc     (new_crc),
        .data_ready  (data_ready),
        .valid       (valid),
        .crc_err     (crc_err)
    );
    
    // CRC逻辑更新
    always @(posedge clk) begin
        if (bitcnt < 8) begin
            crc <= new_crc;
        end
    end
    
endmodule

// 接收计时器模块
module rx_timer #(
    parameter TIMEOUT = 1000000
) (
    input  wire        clk,
    input  wire        rx,
    output reg  [31:0] timer,
    output wire        timeout_reset
);
    always @(posedge clk) begin
        if (rx) 
            timer <= 32'h0;
        else if (timer < TIMEOUT) 
            timer <= timer + 32'h1;
    end
    
    assign timeout_reset = (timer >= TIMEOUT);
endmodule

// 数据接收模块
module data_receiver (
    input  wire       clk,
    input  wire       rx,
    output reg  [3:0] bitcnt,
    output reg  [7:0] data,
    output wire       data_ready
);
    // 数据接收逻辑
    always @(posedge clk) begin
        if (bitcnt < 8) begin
            data <= {data[6:0], rx};
            bitcnt <= bitcnt + 4'h1;
        end
        else if (bitcnt == 8) begin
            bitcnt <= 4'h0;
        end
    end
    
    assign data_ready = (bitcnt == 8);
endmodule

// CRC计算模块
module crc_calculator (
    input  wire [7:0]  data,
    input  wire [15:0] crc_in,
    output wire [15:0] crc_out
);
    // CRC16 计算功能
    function [15:0] crc16_step;
        input [15:0] crc;
        input bit    bit_value;
    begin
        if (bit_value)
            crc16_step = (crc >> 1) ^ 16'hA001;
        else
            crc16_step = (crc >> 1);
    end
    endfunction
    
    // 级联CRC逻辑以减少逻辑深度
    wire [15:0] xor_result = crc_in ^ {8'h00, data};
    wire [15:0] step1, step2, step3, step4;
    wire [15:0] step5, step6, step7, step8;
    
    assign step1 = crc16_step(xor_result, xor_result[0]);
    assign step2 = crc16_step(step1, step1[0]);
    assign step3 = crc16_step(step2, step2[0]);
    assign step4 = crc16_step(step3, step3[0]);
    assign step5 = crc16_step(step4, step4[0]);
    assign step6 = crc16_step(step5, step5[0]);
    assign step7 = crc16_step(step6, step6[0]);
    assign step8 = crc16_step(step7, step7[0]);
    
    assign crc_out = step8;
endmodule

// 状态控制模块
module state_controller (
    input  wire        clk,
    input  wire [3:0]  bitcnt,
    input  wire [15:0] crc,
    input  wire [15:0] new_crc,
    input  wire        data_ready,
    output reg         valid,
    output reg         crc_err
);
    // 控制状态逻辑
    always @(posedge clk) begin
        if (data_ready) begin
            if (crc == 16'h0000) begin
                crc_err <= 1'b0;
                valid <= 1'b1;
            end
            else begin
                crc_err <= 1'b1;
                valid <= 1'b0;
            end
        end
    end
endmodule