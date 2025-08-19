//SystemVerilog
module multi_level_intr_ctrl(
  input clk, reset_n,
  input [15:0] intr_source,
  input [1:0] level_sel,
  // Valid-Ready interface signals
  output reg [3:0] intr_id,
  output reg intr_valid,  // 表示有效数据
  input intr_ready       // 握手信号
);
    // Priority encoder function
    function [3:0] find_first_bit;
        input [3:0] vec;
        reg [3:0] result;
        begin
            result = 4'd0;
            if (vec[0]) result = 4'd0;
            else if (vec[1]) result = 4'd1;
            else if (vec[2]) result = 4'd2;
            else if (vec[3]) result = 4'd3;
            find_first_bit = result;
        end
    endfunction
    
    // 中断类别信号
    wire [3:0] high_id, med_id, low_id, sys_id;
    wire high_v, med_v, low_v, sys_v;
    
    // 状态信号
    reg intr_pending;  // 跟踪是否有待处理但未确认的中断
    reg [3:0] pending_id; // 保存待处理的中断ID
    
    // 中断选择信号
    reg [3:0] next_intr_id;
    reg next_intr_valid;
    
    // 每个类别中断检测 - 独立逻辑块
    assign high_v = |intr_source[15:12];
    assign med_v = |intr_source[11:8];
    assign low_v = |intr_source[7:4];
    assign sys_v = |intr_source[3:0];
    
    // 每个类别中断优先级编码 - 独立逻辑块
    assign high_id = find_first_bit(intr_source[15:12]);
    assign med_id = find_first_bit(intr_source[11:8]);
    assign low_id = find_first_bit(intr_source[7:4]);
    assign sys_id = find_first_bit(intr_source[3:0]);
    
    // 中断有效性检测 - 独立逻辑块
    always @(*) begin
        next_intr_valid = high_v | med_v | low_v | sys_v;
    end
    
    // 中断优先级选择 - 独立逻辑块
    always @(*) begin
        case (level_sel)
            2'b00: begin
                if (high_v) next_intr_id = {2'b11, high_id};
                else if (med_v) next_intr_id = {2'b10, med_id};
                else if (low_v) next_intr_id = {2'b01, low_id};
                else next_intr_id = {2'b00, sys_id};
            end
            2'b01: begin
                if (med_v) next_intr_id = {2'b10, med_id};
                else if (low_v) next_intr_id = {2'b01, low_id};
                else if (sys_v) next_intr_id = {2'b00, sys_id};
                else next_intr_id = {2'b11, high_id};
            end
            2'b10: begin
                if (low_v) next_intr_id = {2'b01, low_id};
                else if (sys_v) next_intr_id = {2'b00, sys_id};
                else if (high_v) next_intr_id = {2'b11, high_id};
                else next_intr_id = {2'b10, med_id};
            end
            2'b11: begin
                if (sys_v) next_intr_id = {2'b00, sys_id};
                else if (high_v) next_intr_id = {2'b11, high_id};
                else if (med_v) next_intr_id = {2'b10, med_id};
                else next_intr_id = {2'b01, low_id};
            end
            default: next_intr_id = 4'd0;
        endcase
    end

    // 复位逻辑 - 独立逻辑块
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            intr_id <= 4'd0;
            intr_valid <= 1'b0;
            intr_pending <= 1'b0;
            pending_id <= 4'd0;
        end
    end
    
    // 握手完成后的处理 - 独立逻辑块
    always @(posedge clk) begin
        if (reset_n && intr_valid && intr_ready) begin
            // 握手完成，数据已被接受
            intr_valid <= 1'b0;
            
            // 检查是否有新的待处理中断立即发送
            if (intr_pending) begin
                intr_id <= pending_id;
                intr_valid <= 1'b1;
                intr_pending <= 1'b0;
            end
            else if (next_intr_valid) begin
                intr_id <= next_intr_id;
                intr_valid <= 1'b1;
            end
        end
    end
    
    // 无活动事务时的处理 - 独立逻辑块
    always @(posedge clk) begin
        if (reset_n && !intr_valid && next_intr_valid) begin
            // 无活动事务，可以呈现新数据
            intr_id <= next_intr_id;
            intr_valid <= 1'b1;
        end
    end
    
    // 事务进行中的处理 - 独立逻辑块
    always @(posedge clk) begin
        if (reset_n && intr_valid && !intr_ready) begin
            // 有效但未就绪 - 事务进行中
            // 存储任何新的待处理中断
            if (next_intr_valid && (next_intr_id != intr_id)) begin
                intr_pending <= 1'b1;
                pending_id <= next_intr_id;
            end
        end
    end
endmodule