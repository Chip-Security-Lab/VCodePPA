//SystemVerilog
module asym_bidir_shifter (
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号
    input wire [15:0] data,
    input wire [3:0] l_shift,  // 左移量
    input wire [2:0] r_shift,  // 右移量
    output reg [15:0] result
);

    // 分割左移和右移操作到单独的数据路径并增加管道
    reg [15:0] left_shift_stage1;
    reg [15:0] right_shift_stage1;
    reg [15:0] left_shift_stage2;
    reg [15:0] right_shift_stage2;
    
    // 第一级流水线 - 解码移位量
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_stage1 <= 16'b0;
            right_shift_stage1 <= 16'b0;
        end else begin
            // 左移操作 - 初始阶段
            case (l_shift)
                4'd0: left_shift_stage1 <= data;
                4'd1: left_shift_stage1 <= {data[14:0], 1'b0};
                4'd2: left_shift_stage1 <= {data[13:0], 2'b0};
                4'd3: left_shift_stage1 <= {data[12:0], 3'b0};
                4'd4: left_shift_stage1 <= {data[11:0], 4'b0};
                4'd5: left_shift_stage1 <= {data[10:0], 5'b0};
                4'd6: left_shift_stage1 <= {data[9:0], 6'b0};
                4'd7: left_shift_stage1 <= {data[8:0], 7'b0};
                4'd8: left_shift_stage1 <= {data[7:0], 8'b0};
                4'd9: left_shift_stage1 <= {data[6:0], 9'b0};
                4'd10: left_shift_stage1 <= {data[5:0], 10'b0};
                4'd11: left_shift_stage1 <= {data[4:0], 11'b0};
                4'd12: left_shift_stage1 <= {data[3:0], 12'b0};
                4'd13: left_shift_stage1 <= {data[2:0], 13'b0};
                4'd14: left_shift_stage1 <= {data[1:0], 14'b0};
                4'd15: left_shift_stage1 <= {data[0], 15'b0};
                default: left_shift_stage1 <= 16'b0;
            endcase
            
            // 右移操作 - 初始阶段
            case (r_shift)
                3'd0: right_shift_stage1 <= data;
                3'd1: right_shift_stage1 <= {1'b0, data[15:1]};
                3'd2: right_shift_stage1 <= {2'b0, data[15:2]};
                3'd3: right_shift_stage1 <= {3'b0, data[15:3]};
                3'd4: right_shift_stage1 <= {4'b0, data[15:4]};
                3'd5: right_shift_stage1 <= {5'b0, data[15:5]};
                3'd6: right_shift_stage1 <= {6'b0, data[15:6]};
                3'd7: right_shift_stage1 <= {7'b0, data[15:7]};
                default: right_shift_stage1 <= 16'b0;
            endcase
        end
    end
    
    // 第二级流水线 - 完成移位处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_stage2 <= 16'b0;
            right_shift_stage2 <= 16'b0;
        end else begin
            left_shift_stage2 <= left_shift_stage1;
            right_shift_stage2 <= right_shift_stage1;
        end
    end
    
    // 第三级流水线 - 合并结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 16'b0;
        end else begin
            result <= left_shift_stage2 | right_shift_stage2;
        end
    end

endmodule