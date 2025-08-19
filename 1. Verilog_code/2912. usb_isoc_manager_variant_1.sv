//SystemVerilog
module usb_isoc_manager #(
    parameter NUM_ENDPOINTS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock, reset_b,
    input wire sof_received,
    input wire [10:0] frame_number,
    input wire [3:0] endpoint_select,
    input wire transfer_ready,
    input wire [DATA_WIDTH-1:0] tx_data,
    output reg transfer_active,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg [NUM_ENDPOINTS-1:0] endpoint_status,
    output reg [1:0] bandwidth_state
);
    // Bandwidth reservation states
    localparam IDLE = 2'b00;
    localparam RESERVED = 2'b01;
    localparam ACTIVE = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Per-endpoint configuration and state
    reg [2:0] interval [0:NUM_ENDPOINTS-1];
    reg [10:0] last_frame [0:NUM_ENDPOINTS-1];
    
    // Buffer registers for high fanout signal i
    reg [2:0] i_buffer1, i_buffer2;
    
    // 用于带状进位加法器的信号定义
    wire [10:0] frame_diff [0:NUM_ENDPOINTS-1];
    wire [10:0] interval_extended [0:NUM_ENDPOINTS-1];
    
    // 带状进位加法器信号
    genvar i;
    generate
        for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin: adder_signals
            // 用于存储减法结果的信号
            wire [10:0] sub_result;
            wire [10:0] inverted_last_frame;
            wire [10:0] carry_chain;
            
            // 对last_frame取反加1实现减法
            assign inverted_last_frame = ~last_frame[i];
            
            // 使用带状进位加法器实现frame_number - last_frame
            // 第一级进位生成
            assign carry_chain[0] = 1'b1; // 减法补1
            
            // 生成进位信号
            assign carry_chain[1] = (frame_number[0] & inverted_last_frame[0]) | 
                                   ((frame_number[0] | inverted_last_frame[0]) & carry_chain[0]);
            assign carry_chain[2] = (frame_number[1] & inverted_last_frame[1]) | 
                                   ((frame_number[1] | inverted_last_frame[1]) & carry_chain[1]);
            assign carry_chain[3] = (frame_number[2] & inverted_last_frame[2]) | 
                                   ((frame_number[2] | inverted_last_frame[2]) & carry_chain[2]);
            assign carry_chain[4] = (frame_number[3] & inverted_last_frame[3]) | 
                                   ((frame_number[3] | inverted_last_frame[3]) & carry_chain[3]);
            assign carry_chain[5] = (frame_number[4] & inverted_last_frame[4]) | 
                                   ((frame_number[4] | inverted_last_frame[4]) & carry_chain[4]);
            assign carry_chain[6] = (frame_number[5] & inverted_last_frame[5]) | 
                                   ((frame_number[5] | inverted_last_frame[5]) & carry_chain[5]);
            assign carry_chain[7] = (frame_number[6] & inverted_last_frame[6]) | 
                                   ((frame_number[6] | inverted_last_frame[6]) & carry_chain[6]);
            assign carry_chain[8] = (frame_number[7] & inverted_last_frame[7]) | 
                                   ((frame_number[7] | inverted_last_frame[7]) & carry_chain[7]);
            assign carry_chain[9] = (frame_number[8] & inverted_last_frame[8]) | 
                                   ((frame_number[8] | inverted_last_frame[8]) & carry_chain[8]);
            assign carry_chain[10] = (frame_number[9] & inverted_last_frame[9]) | 
                                    ((frame_number[9] | inverted_last_frame[9]) & carry_chain[9]);
            
            // 计算和
            assign sub_result[0] = frame_number[0] ^ inverted_last_frame[0] ^ carry_chain[0];
            assign sub_result[1] = frame_number[1] ^ inverted_last_frame[1] ^ carry_chain[1];
            assign sub_result[2] = frame_number[2] ^ inverted_last_frame[2] ^ carry_chain[2];
            assign sub_result[3] = frame_number[3] ^ inverted_last_frame[3] ^ carry_chain[3];
            assign sub_result[4] = frame_number[4] ^ inverted_last_frame[4] ^ carry_chain[4];
            assign sub_result[5] = frame_number[5] ^ inverted_last_frame[5] ^ carry_chain[5];
            assign sub_result[6] = frame_number[6] ^ inverted_last_frame[6] ^ carry_chain[6];
            assign sub_result[7] = frame_number[7] ^ inverted_last_frame[7] ^ carry_chain[7];
            assign sub_result[8] = frame_number[8] ^ inverted_last_frame[8] ^ carry_chain[8];
            assign sub_result[9] = frame_number[9] ^ inverted_last_frame[9] ^ carry_chain[9];
            assign sub_result[10] = frame_number[10] ^ inverted_last_frame[10] ^ carry_chain[10];
            
            // 结果存储到frame_diff
            assign frame_diff[i] = sub_result;
            
            // 扩展interval到11位宽
            assign interval_extended[i] = {8'd0, interval[i]};
        end
    endgenerate
    
    // Endpoint status processing with reduced fanout
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            transfer_active <= 1'b0;
            bandwidth_state <= IDLE;
            endpoint_status <= {NUM_ENDPOINTS{1'b0}};
            i_buffer1 <= 3'd0;
            i_buffer2 <= 3'd0;
            
            // Initialize arrays with buffered counter
            for (i_buffer1 = 0; i_buffer1 < NUM_ENDPOINTS; i_buffer1 = i_buffer1 + 1) begin
                interval[i_buffer1] <= 3'd1;         // Default interval of 1 frame
                last_frame[i_buffer1] <= 11'h7FF;    // Invalid frame number
            end
        end else if (sof_received) begin
            // First half of endpoints (using first buffer)
            for (i_buffer1 = 0; i_buffer1 < NUM_ENDPOINTS/2; i_buffer1 = i_buffer1 + 1) begin
                if (frame_diff[i_buffer1] >= interval_extended[i_buffer1])
                    endpoint_status[i_buffer1] <= 1'b1;
            end
            
            // Second half of endpoints (using second buffer)
            for (i_buffer2 = NUM_ENDPOINTS/2; i_buffer2 < NUM_ENDPOINTS; i_buffer2 = i_buffer2 + 1) begin
                if (frame_diff[i_buffer2] >= interval_extended[i_buffer2])
                    endpoint_status[i_buffer2] <= 1'b1;
            end
        end
    end
endmodule