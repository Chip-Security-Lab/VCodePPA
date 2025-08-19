//SystemVerilog
module i2c_tristate_slave(
    input clk_i, rst_i,
    input [6:0] addr_i,
    output reg [7:0] data_o,
    output reg valid_o,
    inout sda_io, scl_io
);
    // 内部信号定义
    reg sda_oe, sda_o, scl_oe, scl_o;
    reg [2:0] state_r, next_state;
    reg [7:0] shift_r, next_shift;
    reg [2:0] bit_cnt, next_bit_cnt;
    reg start_detected, start_detected_stage1;
    reg ack_needed;
    reg next_valid;
    reg [7:0] next_data;
    
    // 流水线阶段寄存器
    reg sda_i_stage1, scl_i_stage1;
    reg sda_i_stage2, scl_i_stage2;
    reg [2:0] state_stage1, state_stage2;
    reg [7:0] shift_stage1, shift_stage2;
    reg [2:0] bit_cnt_stage1, bit_cnt_stage2;
    reg [6:0] addr_stage1, addr_stage2;
    reg ack_needed_stage1, ack_needed_stage2;
    reg valid_stage1, valid_stage2;
    reg [7:0] data_stage1, data_stage2;
    
    // 三态控制（组合逻辑）
    assign sda_io = sda_oe ? 1'bz : sda_o;
    assign scl_io = scl_oe ? 1'bz : scl_o;
    
    wire sda_i = sda_io;
    wire scl_i = scl_io;
    
    // 第1级流水线 - 输入寄存
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sda_i_stage1 <= 1'b1;
            scl_i_stage1 <= 1'b1;
            addr_stage1 <= 7'h00;
        end else begin
            sda_i_stage1 <= sda_i;
            scl_i_stage1 <= scl_i;
            addr_stage1 <= addr_i;
        end
    end
    
    // 第2级流水线 - 延迟寄存以减轻关键路径
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sda_i_stage2 <= 1'b1;
            scl_i_stage2 <= 1'b1;
            addr_stage2 <= 7'h00;
            state_stage1 <= 3'b000;
            shift_stage1 <= 8'h00;
            bit_cnt_stage1 <= 3'b000;
        end else begin
            sda_i_stage2 <= sda_i_stage1;
            scl_i_stage2 <= scl_i_stage1;
            addr_stage2 <= addr_stage1;
            state_stage1 <= state_r;
            shift_stage1 <= shift_r;
            bit_cnt_stage1 <= bit_cnt;
        end
    end
    
    // 第3级流水线 - 进一步分解处理逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_stage2 <= 3'b000;
            shift_stage2 <= 8'h00;
            bit_cnt_stage2 <= 3'b000;
        end else begin
            state_stage2 <= state_stage1;
            shift_stage2 <= shift_stage1;
            bit_cnt_stage2 <= bit_cnt_stage1;
        end
    end
    
    // 起始条件检测（流水线化）
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            start_detected <= 1'b0;
            start_detected_stage1 <= 1'b0;
        end else begin
            // 第1级 - 检测条件
            if (scl_i_stage2 && sda_i_stage2 && !sda_o)
                start_detected_stage1 <= 1'b1;
            else
                start_detected_stage1 <= 1'b0;
                
            // 第2级 - 流水线寄存
            start_detected <= start_detected_stage1;
        end
    end
    
    // 组合逻辑部分 - 状态转换和输出计算（分成多级流水）
    always @(*) begin
        // 默认值设置
        next_state = state_stage2;
        next_shift = shift_stage2;
        next_bit_cnt = bit_cnt_stage2;
        next_valid = 1'b0;
        next_data = data_o;
        ack_needed = 1'b0;
        
        case(state_stage2)
            3'b000: begin // 空闲状态
                if (start_detected) begin
                    next_state = 3'b001;
                    next_bit_cnt = 3'b000;
                end
            end
            
            3'b001: begin // 地址接收状态
                if (bit_cnt_stage2 == 3'b111) begin
                    next_state = 3'b010;
                    if (shift_stage2[7:1] == addr_stage2)
                        ack_needed = 1'b1; // 地址匹配，需要应答
                end else if (scl_i_stage2) begin
                    next_shift = {shift_stage2[6:0], sda_i_stage2};
                    next_bit_cnt = bit_cnt_stage2 + 1;
                end
            end
            
            3'b010: begin // 应答状态
                next_state = 3'b011;
            end
            
            3'b011: begin // 数据接收状态
                if (bit_cnt_stage2 == 3'b111) begin
                    next_state = 3'b100;
                    next_data = shift_stage2;
                    next_valid = 1'b1;
                end else if (scl_i_stage2) begin
                    next_shift = {shift_stage2[6:0], sda_i_stage2};
                    next_bit_cnt = bit_cnt_stage2 + 1;
                end
            end
            
            3'b100: begin // 数据处理状态
                next_state = 3'b000;
            end
            
            default: next_state = 3'b000;
        endcase
    end
    
    // 流水线第4级 - 处理输出逻辑的中间结果
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            ack_needed_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            data_stage1 <= 8'h00;
        end else begin
            ack_needed_stage1 <= ack_needed;
            valid_stage1 <= next_valid;
            data_stage1 <= next_data;
        end
    end
    
    // 流水线第5级 - 继续分解处理逻辑
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            ack_needed_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            data_stage2 <= 8'h00;
        end else begin
            ack_needed_stage2 <= ack_needed_stage1;
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
        end
    end
    
    // 时序逻辑部分 - 最终状态和寄存器更新
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state_r <= 3'b000;
            shift_r <= 8'h00;
            bit_cnt <= 3'b000;
            sda_oe <= 1'b1;
            scl_oe <= 1'b1;
            sda_o <= 1'b1;
            scl_o <= 1'b1;
            data_o <= 8'h00;
            valid_o <= 1'b0;
        end else begin
            // 更新状态寄存器
            state_r <= next_state;
            shift_r <= next_shift;
            bit_cnt <= next_bit_cnt;
            data_o <= data_stage2;
            valid_o <= valid_stage2;
            
            // SDA输出使能控制
            if (ack_needed_stage2)
                sda_oe <= 1'b0; // 发送ACK
            else if (state_stage2 == 3'b010 && next_state == 3'b011)
                sda_oe <= 1'b1; // ACK完成，释放总线
        end
    end
    
endmodule