//SystemVerilog
//IEEE 1364-2005
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
    reg [3:0] collision_count;
    reg [7:0] jam_counter;
    
    localparam JAM_SIZE = 8'd32; // 32-byte jam pattern (16-bit time)
    
    // 预计算冲突条件，提高时序性能
    wire collision_condition = transmitting && (receiving || carrier_sense);
    wire new_collision = collision_condition && !collision_detected;
    wire reset_collision_count = !transmitting && !receiving && !collision_detected && |collision_count;
    
    // 冲突检测状态控制 - 只处理collision_detected信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_detected <= 1'b0;
        end else begin
            if (collision_condition) begin
                collision_detected <= 1'b1;
            end else if (!transmitting) begin
                collision_detected <= 1'b0;
            end
        end
    end
    
    // 冲突计数器管理 - 专门管理collision_count
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            collision_count <= 4'd0;
        end else begin
            if (new_collision) begin
                collision_count <= collision_count + 1'b1;
            end else if (reset_collision_count) begin
                collision_count <= 4'd0;
            end
        end
    end
    
    // JAM激活状态控制 - 专注于jam_active信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            jam_active <= 1'b0;
        end else begin
            if (collision_condition && !jam_active) begin
                jam_active <= 1'b1;
            end else if (jam_active && jam_counter == 8'd0) begin
                jam_active <= 1'b0;
            end
        end
    end
    
    // JAM计数器控制 - 专门管理jam_counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            jam_counter <= 8'd0;
        end else begin
            if (collision_condition && !jam_active) begin
                jam_counter <= JAM_SIZE;
            end else if (jam_active && |jam_counter) begin
                jam_counter <= jam_counter - 1'b1;
            end
        end
    end
    
    // 退避计数器更新 - 只处理退避次数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            backoff_count <= 4'd0;
        end else begin
            if (new_collision) begin
                backoff_count <= collision_count + 1'b1;
            end
        end
    end
    
    // 退避时间计算 - 专门处理退避时间
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            backoff_time <= 16'd0;
        end else begin
            if (new_collision) begin
                if (collision_count < 4'd10) begin
                    // 使用移位操作直接计算2^k-1，简化计算路径
                    backoff_time <= (16'd1 << collision_count) - 16'd1;
                end else begin
                    backoff_time <= 16'd1023; // 2^10 - 1
                end
            end
        end
    end
endmodule