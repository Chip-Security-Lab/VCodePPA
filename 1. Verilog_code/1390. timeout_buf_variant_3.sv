//SystemVerilog IEEE 1364-2005
module timeout_buf #(parameter DW=8, TIMEOUT=100) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid
);
    // 流水线阶段定义
    localparam STAGE_COUNT = 3;
    localparam STAGE_TIMEOUT = TIMEOUT/STAGE_COUNT;
    
    // 数据注册器
    reg [DW-1:0] data_stage1, data_stage2, data_stage3;
    
    // 控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [$clog2(STAGE_TIMEOUT+1)-1:0] timer_stage1, timer_stage2, timer_stage3;
    
    // 流水线阶段1：输入和请求处理
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_stage1 <= 0;
            valid_stage1 <= 0;
            timer_stage1 <= 0;
        end else begin
            if(wr_en) begin
                data_stage1 <= din;
                valid_stage1 <= 1'b1;
                timer_stage1 <= 0;
            end else if(valid_stage1) begin
                if(rd_en) begin
                    valid_stage1 <= 1'b0;
                end else if(timer_stage1 < STAGE_TIMEOUT) begin
                    timer_stage1 <= timer_stage1 + 1'b1;
                end else begin
                    timer_stage1 <= 0;
                end
            end
        end
    end
    
    // 流水线阶段2：超时计时中间阶段
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_stage2 <= 0;
            valid_stage2 <= 0;
            timer_stage2 <= 0;
        end else begin
            data_stage2 <= data_stage1;
            
            if(valid_stage1 && (timer_stage1 == STAGE_TIMEOUT)) begin
                valid_stage2 <= 1'b1;
                timer_stage2 <= 0;
            end else if(valid_stage2) begin
                if(rd_en) begin
                    valid_stage2 <= 1'b0;
                end else if(timer_stage2 < STAGE_TIMEOUT) begin
                    timer_stage2 <= timer_stage2 + 1'b1;
                end else begin
                    timer_stage2 <= 0;
                end
            end
        end
    end
    
    // 流水线阶段3：最终超时判断和输出
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_stage3 <= 0;
            valid_stage3 <= 0;
            timer_stage3 <= 0;
        end else begin
            data_stage3 <= data_stage2;
            
            if(valid_stage2 && (timer_stage2 == STAGE_TIMEOUT)) begin
                valid_stage3 <= 1'b1;
                timer_stage3 <= 0;
            end else if(valid_stage3) begin
                if(rd_en) begin
                    valid_stage3 <= 1'b0;
                end else if(timer_stage3 < STAGE_TIMEOUT) begin
                    timer_stage3 <= timer_stage3 + 1'b1;
                end else begin
                    // 在最后阶段超时
                    valid_stage3 <= 1'b0;
                end
            end
        end
    end
    
    // 输出赋值
    assign dout = data_stage3;
    assign valid = valid_stage3;
endmodule