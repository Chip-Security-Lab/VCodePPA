//SystemVerilog
module multi_level_intr_ctrl(
  input clk, reset_n,
  input [15:0] intr_source,
  input [1:0] level_sel,
  input ack,
  output reg [3:0] intr_id,
  output reg req
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam REQ_SENT = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    // 高扇出信号的缓冲寄存器
    reg [15:0] intr_source_buf1, intr_source_buf2;
    reg [1:0] level_sel_buf1, level_sel_buf2;
    reg [1:0] IDLE_buf1, IDLE_buf2;
    reg [1:0] b00_buf1, b00_buf2;
    reg [1:0] b01_buf1, b01_buf2;
    
    reg [1:0] state, next_state;
    reg [3:0] pending_intr_id;
    reg pending_req;
    
    // 缓冲高扇出信号
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            intr_source_buf1 <= 16'h0;
            intr_source_buf2 <= 16'h0;
            level_sel_buf1 <= 2'b00;
            level_sel_buf2 <= 2'b00;
            IDLE_buf1 <= IDLE;
            IDLE_buf2 <= IDLE;
            b00_buf1 <= 2'b00;
            b00_buf2 <= 2'b00;
            b01_buf1 <= 2'b01;
            b01_buf2 <= 2'b01;
        end else begin
            intr_source_buf1 <= intr_source;
            intr_source_buf2 <= intr_source;
            level_sel_buf1 <= level_sel;
            level_sel_buf2 <= level_sel;
            IDLE_buf1 <= IDLE;
            IDLE_buf2 <= IDLE;
            b00_buf1 <= 2'b00;
            b00_buf2 <= 2'b00;
            b01_buf1 <= 2'b01;
            b01_buf2 <= 2'b01;
        end
    end
    
    // 简化的优先级编码器函数
    function [3:0] find_first_bit;
        input [3:0] vec;
        reg [3:0] result;
        begin
            casez(vec)
                4'b???1: result = 4'd0;
                4'b??10: result = 4'd1;
                4'b?100: result = 4'd2;
                4'b1000: result = 4'd3;
                default: result = 4'd0;
            endcase
            find_first_bit = result;
        end
    endfunction
    
    // 使用缓冲的中断源信号
    wire [3:0] high_grp, med_grp, low_grp, sys_grp;
    assign high_grp = intr_source_buf1[15:12];
    assign med_grp = intr_source_buf1[11:8];
    assign low_grp = intr_source_buf1[7:4];
    assign sys_grp = intr_source_buf1[3:0];
    
    // 确定每个类别中是否有中断处于活动状态
    reg high_v_stage1, med_v_stage1, low_v_stage1, sys_v_stage1;
    wire high_v, med_v, low_v, sys_v;
    
    // 分阶段计算信号存在以减少关键路径延迟
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            high_v_stage1 <= 1'b0;
            med_v_stage1 <= 1'b0;
            low_v_stage1 <= 1'b0;
            sys_v_stage1 <= 1'b0;
        end else begin
            high_v_stage1 <= |high_grp;
            med_v_stage1 <= |med_grp;
            low_v_stage1 <= |low_grp;
            sys_v_stage1 <= |sys_grp;
        end
    end
    
    assign high_v = high_v_stage1;
    assign med_v = med_v_stage1;
    assign low_v = low_v_stage1;
    assign sys_v = sys_v_stage1;
    
    // 任何中断信号的缓冲
    reg any_intr_stage1;
    wire any_intr;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            any_intr_stage1 <= 1'b0;
        end else begin
            any_intr_stage1 <= high_v | med_v | low_v | sys_v;
        end
    end
    
    assign any_intr = any_intr_stage1;
    
    // 找出每个类别中的最高优先级
    reg [3:0] high_id_reg, med_id_reg, low_id_reg, sys_id_reg;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            high_id_reg <= 4'd0;
            med_id_reg <= 4'd0;
            low_id_reg <= 4'd0;
            sys_id_reg <= 4'd0;
        end else begin
            high_id_reg <= find_first_bit(high_grp);
            med_id_reg <= find_first_bit(med_grp);
            low_id_reg <= find_first_bit(low_grp);
            sys_id_reg <= find_first_bit(sys_grp);
        end
    end
    
    wire [3:0] high_id, med_id, low_id, sys_id;
    assign high_id = high_id_reg;
    assign med_id = med_id_reg;
    assign low_id = low_id_reg;
    assign sys_id = sys_id_reg;
    
    // 中断ID和请求生成逻辑
    reg [3:0] selected_intr_id_stage1;
    wire [3:0] selected_intr_id;
    
    // 分两级计算选择的中断ID，使用缓冲的level_sel
    always @(*) begin
        case(level_sel_buf2)
            2'b00: begin
                if (high_v)
                    selected_intr_id_stage1 = {2'b11, high_id};
                else if (med_v)
                    selected_intr_id_stage1 = {2'b10, med_id};
                else if (low_v)
                    selected_intr_id_stage1 = {2'b01, low_id};
                else
                    selected_intr_id_stage1 = {2'b00, sys_id};
            end
            
            2'b01: begin
                if (med_v)
                    selected_intr_id_stage1 = {2'b10, med_id};
                else if (low_v)
                    selected_intr_id_stage1 = {2'b01, low_id};
                else if (sys_v)
                    selected_intr_id_stage1 = {2'b00, sys_id};
                else
                    selected_intr_id_stage1 = {2'b11, high_id};
            end
            
            2'b10: begin
                if (low_v)
                    selected_intr_id_stage1 = {2'b01, low_id};
                else if (sys_v)
                    selected_intr_id_stage1 = {2'b00, sys_id};
                else if (high_v)
                    selected_intr_id_stage1 = {2'b11, high_id};
                else
                    selected_intr_id_stage1 = {2'b10, med_id};
            end
            
            default: begin // 2'b11
                if (sys_v)
                    selected_intr_id_stage1 = {2'b00, sys_id};
                else if (high_v)
                    selected_intr_id_stage1 = {2'b11, high_id};
                else if (med_v)
                    selected_intr_id_stage1 = {2'b10, med_id};
                else
                    selected_intr_id_stage1 = {2'b01, low_id};
            end
        endcase
    end
    
    // 注册选择的中断ID以减少关键路径延迟
    reg [3:0] selected_intr_id_reg;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            selected_intr_id_reg <= 4'd0;
        end else begin
            selected_intr_id_reg <= selected_intr_id_stage1;
        end
    end
    
    assign selected_intr_id = selected_intr_id_reg;
    
    // FSM - 状态转换逻辑
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE_buf1;
            pending_intr_id <= 4'd0;
            pending_req <= 1'b0;
        end else begin
            state <= next_state;
            
            // 在IDLE状态捕获中断ID和请求
            if (state == IDLE_buf1 && any_intr) begin
                pending_intr_id <= selected_intr_id;
                pending_req <= 1'b1;
            end
            
            // 在接收到ACK后清除请求
            if (state == WAIT_ACK && ack) begin
                pending_req <= 1'b0;
            end
        end
    end
    
    // FSM - 下一状态和输出逻辑
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        
        case (state)
            IDLE_buf2: begin
                if (any_intr) begin
                    next_state = REQ_SENT;
                end
            end
            
            REQ_SENT: begin
                next_state = WAIT_ACK;
            end
            
            WAIT_ACK: begin
                if (ack) begin
                    next_state = IDLE_buf2;
                end
            end
            
            default: next_state = IDLE_buf2;
        endcase
    end
    
    // 输出逻辑 - Req-Ack握手
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            intr_id <= 4'd0;
            req <= 1'b0;
        end else begin
            // 在REQ_SENT状态发送请求和中断ID
            if (state == REQ_SENT) begin
                intr_id <= pending_intr_id;
                req <= pending_req;
            end
            // 在接收到ACK后清除请求
            else if (state == WAIT_ACK && ack) begin
                req <= 1'b0;
            end
        end
    end
endmodule