//SystemVerilog
module crc_fsm (
    input clk, start, rst,
    input [7:0] data,
    output reg [15:0] crc,
    output done
);
    // 将枚举类型改为参数定义
    parameter IDLE = 0, CALC1 = 1, CALC2 = 2, CALC3 = 3, CALC4 = 4, FINISH = 5;
    reg [2:0] state;
    reg [2:0] state_buf1, state_buf2;
    
    // 数据缓冲寄存器，降低扇出负载
    reg [7:0] data_buf1, data_buf2, data_buf3;
    
    // IDLE状态缓冲，减少高扇出
    reg idle_status, idle_buf1, idle_buf2;
    
    // CRC计算中间结果寄存器
    reg [15:0] crc_temp_stage1, crc_temp_stage2, crc_temp_stage3, crc_temp_stage4;
    reg [15:0] crc_out;
    reg [15:0] crc_out_buf1, crc_out_buf2;
    
    // 循环计数器
    reg [2:0] i_stage1, i_stage2, i_stage3, i_stage4;
    reg [2:0] i_next;
    
    // 流水线控制信号
    reg calc_active_stage1, calc_active_stage2, calc_active_stage3, calc_active_stage4;
    
    // 用于存储每一级CRC计算的部分结果
    reg [15:0] crc_partial_stage1, crc_partial_stage2, crc_partial_stage3, crc_partial_stage4;
    
    // 部分CRC计算 - 将8bit的计算拆分为4个2bit计算
    function [15:0] crc_calculate_partial;
        input [7:0] data;
        input [15:0] crc_in;
        input [2:0] bit_index;
        reg [15:0] crc_out;
        integer j;
        begin
            crc_out = crc_in;
            for (j = 0; j < 2; j = j + 1) begin
                if ((data[bit_index+j] ^ crc_out[15]) == 1'b1)
                    crc_out = {crc_out[14:0], 1'b0} ^ 16'h1021;
                else
                    crc_out = {crc_out[14:0], 1'b0};
            end
            crc_calculate_partial = crc_out;
        end
    endfunction

    // 缓冲data输入信号，降低扇出
    always @(posedge clk) begin
        data_buf1 <= data;
        data_buf2 <= data_buf1;
        data_buf3 <= data_buf2;
    end
    
    // 缓冲IDLE状态，降低状态机扇出
    always @(posedge clk) begin
        idle_status <= (state == IDLE);
        idle_buf1 <= idle_status;
        idle_buf2 <= idle_buf1;
    end
    
    // 状态寄存器缓冲，降低状态扇出
    always @(posedge clk) begin
        if (!rst) begin
            state_buf1 <= state;
            state_buf2 <= state_buf1;
        end
    end

    // 主状态机逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            crc <= 16'hFFFF;
            crc_out <= 16'h0000;
            crc_temp_stage1 <= 16'hFFFF;
            crc_temp_stage2 <= 16'h0000;
            crc_temp_stage3 <= 16'h0000;
            crc_temp_stage4 <= 16'h0000;
            calc_active_stage1 <= 1'b0;
            calc_active_stage2 <= 1'b0;
            calc_active_stage3 <= 1'b0;
            calc_active_stage4 <= 1'b0;
            i_stage1 <= 3'd0;
            i_stage2 <= 3'd0;
            i_stage3 <= 3'd0;
            i_stage4 <= 3'd0;
        end else case(state)
            IDLE: begin
                if (start) begin
                    state <= CALC1;
                    crc_temp_stage1 <= crc;
                    i_stage1 <= 3'd0;
                    calc_active_stage1 <= 1'b1;
                end
            end
            CALC1: begin
                state <= CALC2;
                crc_temp_stage2 <= crc_partial_stage1;
                i_stage2 <= 3'd2;
                calc_active_stage2 <= 1'b1;
            end
            CALC2: begin
                state <= CALC3;
                crc_temp_stage3 <= crc_partial_stage2;
                i_stage3 <= 3'd4;
                calc_active_stage3 <= 1'b1;
            end
            CALC3: begin
                state <= CALC4;
                crc_temp_stage4 <= crc_partial_stage3;
                i_stage4 <= 3'd6;
                calc_active_stage4 <= 1'b1;
            end
            CALC4: begin
                state <= FINISH;
                crc_out <= crc_partial_stage4;
                calc_active_stage1 <= 1'b0;
                calc_active_stage2 <= 1'b0;
                calc_active_stage3 <= 1'b0;
                calc_active_stage4 <= 1'b0;
            end
            FINISH: state <= IDLE;
            default: state <= IDLE;
        endcase
    end
    
    // 流水线级1 - 处理前2位
    always @(posedge clk) begin
        if (!rst) begin
            if (calc_active_stage1) begin
                crc_partial_stage1 <= crc_calculate_partial(data_buf3, crc_temp_stage1, i_stage1);
            end
        end
    end
    
    // 流水线级2 - 处理中间2位
    always @(posedge clk) begin
        if (!rst) begin
            if (calc_active_stage2) begin
                crc_partial_stage2 <= crc_calculate_partial(data_buf3, crc_temp_stage2, i_stage2);
            end
        end
    end
    
    // 流水线级3 - 处理中间2位
    always @(posedge clk) begin
        if (!rst) begin
            if (calc_active_stage3) begin
                crc_partial_stage3 <= crc_calculate_partial(data_buf3, crc_temp_stage3, i_stage3);
            end
        end
    end
    
    // 流水线级4 - 处理最后2位
    always @(posedge clk) begin
        if (!rst) begin
            if (calc_active_stage4) begin
                crc_partial_stage4 <= crc_calculate_partial(data_buf3, crc_temp_stage4, i_stage4);
            end
        end
    end
    
    // 缓冲CRC输出结果，降低扇出
    always @(posedge clk) begin
        if (!rst) begin
            crc_out_buf1 <= crc_out;
            crc_out_buf2 <= crc_out_buf1;
            crc <= crc_out_buf2;
        end
    end

    // 使用缓冲后的状态来生成done信号
    assign done = (state_buf2 == FINISH);
endmodule