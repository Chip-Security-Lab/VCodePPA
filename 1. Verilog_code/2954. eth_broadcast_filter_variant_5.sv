//SystemVerilog
module eth_broadcast_filter (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire frame_start,
    output reg [7:0] data_out,
    output reg data_valid_out,
    output reg broadcast_detected,
    input wire pass_broadcast
);
    // 计数器和状态寄存器
    reg [5:0] byte_counter;
    reg broadcast_frame;
    reg [47:0] dest_mac;
    
    // 阶段1：输入寄存
    reg [7:0] data_in_stage1;
    reg data_valid_stage1;
    reg frame_start_stage1;
    reg pass_broadcast_stage1;
    
    // 阶段2：初步判断
    reg [7:0] data_in_stage2;
    reg data_valid_stage2;
    reg frame_start_stage2;
    reg pass_broadcast_stage2;
    reg is_ff_byte_stage2;
    reg [5:0] byte_counter_stage2;
    
    // 阶段3：计算中间结果1
    reg [7:0] data_in_stage3;
    reg data_valid_stage3;
    reg frame_start_stage3;
    reg pass_broadcast_stage3;
    reg is_ff_byte_stage3;
    reg [5:0] byte_counter_stage3;
    reg [5:0] byte_counter_next_stage3;
    reg broadcast_frame_stage3;
    
    // 阶段4：计算中间结果2
    reg [7:0] data_in_stage4;
    reg data_valid_stage4;
    reg pass_broadcast_stage4;
    reg [5:0] byte_counter_next_stage4;
    reg broadcast_frame_next_stage4;
    reg broadcast_detected_next_stage4;
    reg data_valid_out_next_stage4;
    
    // 阶段5：最终计算并更新状态
    reg [7:0] data_in_stage5;
    reg [5:0] byte_counter_next_stage5;
    reg broadcast_frame_next_stage5;
    reg broadcast_detected_next_stage5;
    reg data_valid_out_next_stage5;
    
    // 第一级流水线：寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 8'd0;
            data_valid_stage1 <= 1'b0;
            frame_start_stage1 <= 1'b0;
            pass_broadcast_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            data_valid_stage1 <= data_valid;
            frame_start_stage1 <= frame_start;
            pass_broadcast_stage1 <= pass_broadcast;
        end
    end
    
    // 第二级流水线：初步判断
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= 8'd0;
            data_valid_stage2 <= 1'b0;
            frame_start_stage2 <= 1'b0;
            pass_broadcast_stage2 <= 1'b0;
            is_ff_byte_stage2 <= 1'b0;
            byte_counter_stage2 <= 6'd0;
        end else begin
            data_in_stage2 <= data_in_stage1;
            data_valid_stage2 <= data_valid_stage1;
            frame_start_stage2 <= frame_start_stage1;
            pass_broadcast_stage2 <= pass_broadcast_stage1;
            is_ff_byte_stage2 <= (data_in_stage1 == 8'hFF);
            byte_counter_stage2 <= byte_counter;
        end
    end
    
    // 第三级流水线：计算中间结果1 - 处理帧开始和字节计数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage3 <= 8'd0;
            data_valid_stage3 <= 1'b0;
            frame_start_stage3 <= 1'b0;
            pass_broadcast_stage3 <= 1'b0;
            is_ff_byte_stage3 <= 1'b0;
            byte_counter_stage3 <= 6'd0;
            byte_counter_next_stage3 <= 6'd0;
            broadcast_frame_stage3 <= 1'b0;
        end else begin
            data_in_stage3 <= data_in_stage2;
            data_valid_stage3 <= data_valid_stage2;
            frame_start_stage3 <= frame_start_stage2;
            pass_broadcast_stage3 <= pass_broadcast_stage2;
            is_ff_byte_stage3 <= is_ff_byte_stage2;
            byte_counter_stage3 <= byte_counter_stage2;
            broadcast_frame_stage3 <= broadcast_frame;
            
            // 计算byte_counter_next的部分逻辑
            if (frame_start_stage2) begin
                byte_counter_next_stage3 <= 6'd0;
            end else if (data_valid_stage2) begin
                if (byte_counter_stage2 < 6) begin
                    byte_counter_next_stage3 <= byte_counter_stage2 + 1'b1;
                end else begin
                    byte_counter_next_stage3 <= byte_counter_stage2;
                end
            end else begin
                byte_counter_next_stage3 <= byte_counter_stage2;
            end
        end
    end
    
    // 第四级流水线：计算中间结果2 - 处理广播帧检测和数据有效性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage4 <= 8'd0;
            data_valid_stage4 <= 1'b0;
            pass_broadcast_stage4 <= 1'b0;
            byte_counter_next_stage4 <= 6'd0;
            broadcast_frame_next_stage4 <= 1'b0;
            broadcast_detected_next_stage4 <= 1'b0;
            data_valid_out_next_stage4 <= 1'b0;
        end else begin
            data_in_stage4 <= data_in_stage3;
            data_valid_stage4 <= data_valid_stage3;
            pass_broadcast_stage4 <= pass_broadcast_stage3;
            byte_counter_next_stage4 <= byte_counter_next_stage3;

            // 计算broadcast_frame_next的逻辑
            if (frame_start_stage3) begin
                broadcast_frame_next_stage4 <= 1'b0;
                broadcast_detected_next_stage4 <= 1'b0;
            end else if (data_valid_stage3) begin
                if (byte_counter_stage3 < 6) begin
                    if (data_in_stage3 != 8'hFF) begin
                        broadcast_frame_next_stage4 <= 1'b0;
                    end else if (byte_counter_stage3 == 0) begin
                        broadcast_frame_next_stage4 <= 1'b1;
                    end else begin
                        broadcast_frame_next_stage4 <= broadcast_frame_stage3;
                    end
                    
                    broadcast_detected_next_stage4 <= broadcast_detected;
                end else begin
                    broadcast_frame_next_stage4 <= broadcast_frame_stage3;
                    
                    if (byte_counter_stage3 == 6 && broadcast_frame_stage3) begin
                        broadcast_detected_next_stage4 <= 1'b1;
                    end else begin
                        broadcast_detected_next_stage4 <= broadcast_detected;
                    end
                end
            end else begin
                broadcast_frame_next_stage4 <= broadcast_frame_stage3;
                broadcast_detected_next_stage4 <= broadcast_detected;
            end
            
            // 计算data_valid_out_next的逻辑
            if (data_valid_stage3) begin
                if (byte_counter_stage3 < 6) begin
                    data_valid_out_next_stage4 <= (pass_broadcast_stage3 || !broadcast_frame_stage3);
                end else begin
                    data_valid_out_next_stage4 <= (pass_broadcast_stage3 || !broadcast_detected);
                end
            end else begin
                data_valid_out_next_stage4 <= 1'b0;
            end
        end
    end
    
    // 第五级流水线：最终计算并准备更新状态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage5 <= 8'd0;
            byte_counter_next_stage5 <= 6'd0;
            broadcast_frame_next_stage5 <= 1'b0;
            broadcast_detected_next_stage5 <= 1'b0;
            data_valid_out_next_stage5 <= 1'b0;
        end else begin
            data_in_stage5 <= data_in_stage4;
            byte_counter_next_stage5 <= byte_counter_next_stage4;
            broadcast_frame_next_stage5 <= broadcast_frame_next_stage4;
            broadcast_detected_next_stage5 <= broadcast_detected_next_stage4;
            data_valid_out_next_stage5 <= data_valid_out_next_stage4;
        end
    end
    
    // 第六级流水线：更新状态寄存器和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter <= 6'd0;
            broadcast_frame <= 1'b0;
            broadcast_detected <= 1'b0;
            data_valid_out <= 1'b0;
            dest_mac <= 48'd0;
            data_out <= 8'd0;
        end else begin
            byte_counter <= byte_counter_next_stage5;
            broadcast_frame <= broadcast_frame_next_stage5;
            broadcast_detected <= broadcast_detected_next_stage5;
            data_valid_out <= data_valid_out_next_stage5;
            
            // 更新MAC地址寄存器
            if (data_valid_stage4 && byte_counter_stage3 < 6) begin
                dest_mac <= {dest_mac[39:0], data_in_stage4};
            end
            
            // 更新数据输出
            data_out <= data_in_stage5;
        end
    end
endmodule