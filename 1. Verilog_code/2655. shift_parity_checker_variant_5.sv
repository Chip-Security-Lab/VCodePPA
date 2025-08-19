//SystemVerilog
module shift_parity_checker (
    input clk,          // 时钟信号
    input rst_n,        // 复位信号，低电平有效
    input serial_in,    // 串行输入数据
    input ready,        // 接收方准备好接收数据的信号
    output reg valid,   // 数据有效信号
    output reg parity   // 奇偶校验结果
);

// 流水线第一级：数据采集和移位操作
reg [7:0] shift_reg;
reg [2:0] bit_counter;
reg stage1_valid;

// 流水线第二级：半字节检查
reg [3:0] upper_nibble_stage2;
reg [3:0] lower_nibble_stage2;
reg stage2_valid;

// 流水线第三级：奇偶校验计算
reg [1:0] parity_upper_stage3;
reg [1:0] parity_lower_stage3;
reg stage3_valid;

// 流水线第四级：最终结果计算
reg parity_stage4;
reg stage4_valid;

// 第一级流水线：移位寄存器和位计数
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 8'd0;
        bit_counter <= 3'd0;
        stage1_valid <= 1'b0;
    end else begin
        if (ready) begin
            shift_reg <= {shift_reg[6:0], serial_in};
            
            if (bit_counter == 3'd7) begin
                bit_counter <= 3'd0;
                stage1_valid <= 1'b1;
            end else begin
                bit_counter <= bit_counter + 1'b1;
                stage1_valid <= 1'b0;
            end
        end else if (stage1_valid && !stage2_valid) begin
            stage1_valid <= 1'b0;
        end
    end
end

// 第二级流水线：拆分数据进行部分处理
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        upper_nibble_stage2 <= 4'd0;
        lower_nibble_stage2 <= 4'd0;
        stage2_valid <= 1'b0;
    end else begin
        if (stage1_valid) begin
            upper_nibble_stage2 <= shift_reg[7:4];
            lower_nibble_stage2 <= shift_reg[3:0];
            stage2_valid <= 1'b1;
        end else if (stage2_valid && !stage3_valid) begin
            stage2_valid <= 1'b0;
        end
    end
end

// 第三级流水线：计算部分奇偶校验
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_upper_stage3 <= 2'd0;
        parity_lower_stage3 <= 2'd0;
        stage3_valid <= 1'b0;
    end else begin
        if (stage2_valid) begin
            parity_upper_stage3 <= ^upper_nibble_stage2;
            parity_lower_stage3 <= ^lower_nibble_stage2;
            stage3_valid <= 1'b1;
        end else if (stage3_valid && !stage4_valid) begin
            stage3_valid <= 1'b0;
        end
    end
end

// 第四级流水线：计算最终奇偶校验
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity_stage4 <= 1'b0;
        stage4_valid <= 1'b0;
    end else begin
        if (stage3_valid) begin
            parity_stage4 <= parity_upper_stage3 ^ parity_lower_stage3;
            stage4_valid <= 1'b1;
        end else if (stage4_valid && !valid) begin
            stage4_valid <= 1'b0;
        end
    end
end

// 最终输出级：输出结果
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        parity <= 1'b0;
        valid <= 1'b0;
    end else begin
        if (stage4_valid) begin
            parity <= parity_stage4;
            valid <= 1'b1;
        end else if (ready && valid) begin
            valid <= 1'b0;
        end
    end
end

endmodule