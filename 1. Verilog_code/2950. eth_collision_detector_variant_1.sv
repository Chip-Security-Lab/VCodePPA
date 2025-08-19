//SystemVerilog
module eth_collision_detector (
    input wire clk,
    input wire rst_n,
    input wire transmitting,
    input wire receiving,
    input wire carrier_sense,
    output reg collision_detected,
    output reg jam_active,
    output reg [3:0] backoff_count,
    output reg [15:0] backoff_time
);
    // 内部信号定义
    reg [3:0] collision_count;
    reg [7:0] jam_counter;
    
    // 前推寄存器，捕获输入信号
    reg transmitting_r, receiving_r, carrier_sense_r;
    reg collision_condition; // 碰撞条件寄存器
    
    localparam JAM_SIZE = 8'd32; // 32-byte jam pattern (16-bit time)
    
    // 输入捕获和碰撞检测模块实例化
    input_capture_logic input_capture_inst (
        .clk(clk),
        .rst_n(rst_n),
        .transmitting(transmitting),
        .receiving(receiving),
        .carrier_sense(carrier_sense),
        .transmitting_r(transmitting_r),
        .receiving_r(receiving_r),
        .carrier_sense_r(carrier_sense_r),
        .collision_condition(collision_condition)
    );
    
    // 碰撞处理和退避计算模块实例化
    collision_handler_logic collision_handler_inst (
        .clk(clk),
        .rst_n(rst_n),
        .collision_condition(collision_condition),
        .transmitting_r(transmitting_r),
        .receiving_r(receiving_r),
        .collision_detected(collision_detected),
        .jam_active(jam_active),
        .backoff_count(backoff_count),
        .backoff_time(backoff_time),
        .collision_count(collision_count),
        .jam_counter(jam_counter),
        .JAM_SIZE(JAM_SIZE)
    );
endmodule

// 输入捕获和碰撞检测模块
module input_capture_logic (
    input wire clk,
    input wire rst_n,
    input wire transmitting,
    input wire receiving,
    input wire carrier_sense,
    output reg transmitting_r,
    output reg receiving_r,
    output reg carrier_sense_r,
    output reg collision_condition
);
    // 输入寄存器阶段 - 捕获输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            transmitting_r <= 1'b0;
            receiving_r <= 1'b0;
            carrier_sense_r <= 1'b0;
            collision_condition <= 1'b0;
        end else begin
            transmitting_r <= transmitting;
            receiving_r <= receiving;
            carrier_sense_r <= carrier_sense;
            // 在寄存器阶段提前计算碰撞条件
            collision_condition <= transmitting && (receiving || carrier_sense);
        end
    end
endmodule

// 碰撞处理和退避计算模块
module collision_handler_logic (
    input wire clk,
    input wire rst_n,
    input wire collision_condition,
    input wire transmitting_r,
    input wire receiving_r,
    output reg collision_detected,
    output reg jam_active,
    output reg [3:0] backoff_count,
    output reg [15:0] backoff_time,
    output reg [3:0] collision_count,
    output reg [7:0] jam_counter,
    input wire [7:0] JAM_SIZE
);
    // 主处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_detected <= 1'b0;
            jam_active <= 1'b0;
            backoff_count <= 4'd0;
            backoff_time <= 16'd0;
            collision_count <= 4'd0;
            jam_counter <= 8'd0;
        end else begin
            // 使用预先计算的碰撞条件
            if (collision_condition) begin
                collision_detected <= 1'b1;
                jam_active <= 1'b1;
                jam_counter <= JAM_SIZE;
                
                if (!collision_detected) begin
                    collision_count <= collision_count + 1'b1;
                    
                    // 使用截断的二进制指数退避算法计算退避时间
                    backoff_time <= calculate_backoff(collision_count);
                    backoff_count <= collision_count;
                end
            end else if (!transmitting_r) begin
                collision_detected <= 1'b0;
            end
            
            // Jam信号生成
            if (jam_active) begin
                if (jam_counter > 0)
                    jam_counter <= jam_counter - 1'b1;
                else
                    jam_active <= 1'b0;
            end
            
            // 成功传输后重置碰撞计数
            if (!transmitting_r && !receiving_r && !collision_detected && collision_count > 0) begin
                collision_count <= 4'd0;
            end
        end
    end
    
    // 退避计算函数
    function [15:0] calculate_backoff;
        input [3:0] coll_count;
        begin
            if (coll_count < 10) begin
                // r = 0到2^k-1之间的随机数，其中k = min(n, 10)
                calculate_backoff = (16'd1 << coll_count) - 1'b1;
            end else begin
                // 10次或更多碰撞的最大退避
                calculate_backoff = 16'd1023; // 2^10 - 1
            end
        end
    endfunction
endmodule