//SystemVerilog
module multi_waveform(
    input clk,
    input rst_n,
    input [1:0] wave_sel,
    output reg [7:0] wave_out
);
    // 流水线阶段1: 计数和波形类型选择
    reg [7:0] counter;
    reg direction;
    reg [1:0] wave_sel_stage1;
    reg [7:0] counter_stage1;
    reg direction_stage1;
    
    // 流水线阶段2: 波形计算
    reg [7:0] wave_out_stage2;
    reg [1:0] wave_sel_stage2;
    
    // 流水线阶段控制信号
    reg valid_stage1, valid_stage2;
    
    // 阶段1: 计数器逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            direction <= 1'b0;
            valid_stage1 <= 1'b0;
            wave_sel_stage1 <= 2'b00;
            counter_stage1 <= 8'd0;
            direction_stage1 <= 1'b0;
        end else begin
            counter <= counter + 8'd1;
            valid_stage1 <= 1'b1;
            
            // 注册阶段1数据
            wave_sel_stage1 <= wave_sel;
            counter_stage1 <= counter;
            direction_stage1 <= direction;
            
            // 三角波的方向控制放在阶段1
            if (wave_sel == 2'b10) begin  // 三角波
                if (!direction) begin
                    if (counter == 8'd255) direction <= 1'b1;
                end else begin
                    if (counter == 8'd0) direction <= 1'b0;
                end
            end
        end
    end
    
    // 阶段2: 波形生成逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave_out_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
            wave_sel_stage2 <= 2'b00;
        end else begin
            valid_stage2 <= valid_stage1;
            wave_sel_stage2 <= wave_sel_stage1;
            
            case (wave_sel_stage1)
                2'b00: // 方波
                    wave_out_stage2 <= (counter_stage1 < 8'd128) ? 8'd255 : 8'd0;
                2'b01: // 锯齿波
                    wave_out_stage2 <= counter_stage1;
                2'b10: // 三角波
                    if (!direction_stage1)
                        wave_out_stage2 <= counter_stage1;
                    else
                        wave_out_stage2 <= 8'd255 - counter_stage1;
                2'b11: // 阶梯波
                    wave_out_stage2 <= {counter_stage1[7:2], 2'b00};
            endcase
        end
    end
    
    // 阶段3: 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave_out <= 8'd0;
        end else if (valid_stage2) begin
            wave_out <= wave_out_stage2;
        end
    end
endmodule