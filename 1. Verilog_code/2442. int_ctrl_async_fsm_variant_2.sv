//SystemVerilog
module int_ctrl_async_fsm #(parameter DW=4)(
    input wire clk,
    input wire reset_n,
    input wire en,
    input wire [DW-1:0] int_req,
    output reg int_valid,
    output reg ready_for_next
);

    // 增加到四级流水线寄存器
    reg [DW-1:0] int_req_stage1, int_req_stage2, int_req_stage3, int_req_stage4;
    reg en_stage1, en_stage2, en_stage3, en_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg [1:0] state_stage1, state_stage2, state_stage3, state_stage4;
    
    // 流水线控制信号
    reg pipeline_flush;
    
    // 先行借位减法器信号拆分
    wire gen_borrow_0;
    wire prop_borrow_1;
    wire [1:0] minuend;
    wire [1:0] subtrahend;
    wire [1:0] difference;
    reg [2:0] borrow_stage1; // 第一级流水线的借位信号
    reg [2:0] borrow_stage2; // 第二级流水线的借位信号
    reg [1:0] partial_diff_stage1; // 部分差值计算结果
    
    // 先行借位减法器的输入
    assign minuend = state_stage1;
    assign subtrahend = 2'b01;
    
    // 阶段1：输入捕获和借位生成
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_req_stage1 <= 0;
            en_stage1 <= 0;
            valid_stage1 <= 0;
            state_stage1 <= 0;
            borrow_stage1 <= 0;
        end else if (!pipeline_flush) begin
            int_req_stage1 <= int_req;
            en_stage1 <= en;
            
            // 生成借位信号第一部分
            borrow_stage1[0] <= 1'b0; // 初始无借位
            borrow_stage1[1] <= (minuend[0] < subtrahend[0]) ? 1'b1 : 1'b0;
            
            if (en && (state_stage1 == 0) && |int_req) begin
                valid_stage1 <= 1;
                state_stage1 <= 1;
            end else if (en && (state_stage1 == 1)) begin
                state_stage1 <= 2;
            end else if (en && (state_stage1 == 2)) begin
                valid_stage1 <= 0;
                // 减法器结果将在下一级计算
            end
        end
    end
    
    // 阶段2：借位传播和部分差值计算
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_req_stage2 <= 0;
            en_stage2 <= 0;
            valid_stage2 <= 0;
            state_stage2 <= 0;
            borrow_stage2 <= 0;
            partial_diff_stage1 <= 0;
        end else begin
            int_req_stage2 <= int_req_stage1;
            en_stage2 <= en_stage1;
            valid_stage2 <= valid_stage1;
            state_stage2 <= state_stage1;
            
            // 完成借位信号生成和传播
            borrow_stage2[0] <= borrow_stage1[0];
            borrow_stage2[1] <= borrow_stage1[1];
            borrow_stage2[2] <= ((state_stage1[1] < subtrahend[1]) || 
                              ((state_stage1[1] == subtrahend[1]) && borrow_stage1[1])) ? 1'b1 : 1'b0;
            
            // 计算第一位差值
            partial_diff_stage1[0] <= state_stage1[0] ^ subtrahend[0] ^ borrow_stage1[0];
        end
    end
    
    // 阶段3：完成差值计算和状态更新
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_req_stage3 <= 0;
            en_stage3 <= 0;
            valid_stage3 <= 0;
            state_stage3 <= 0;
        end else begin
            int_req_stage3 <= int_req_stage2;
            en_stage3 <= en_stage2;
            valid_stage3 <= valid_stage2;
            
            // 计算第二位差值并更新状态
            if (en_stage2 && (state_stage2 == 2)) begin
                // 计算完整差值
                state_stage3[0] <= partial_diff_stage1[0];
                state_stage3[1] <= state_stage2[1] ^ subtrahend[1] ^ borrow_stage2[1];
            end else begin
                state_stage3 <= state_stage2;
            end
        end
    end
    
    // 阶段4：中断验证和输出生成
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            int_req_stage4 <= 0;
            en_stage4 <= 0;
            valid_stage4 <= 0;
            state_stage4 <= 0;
            int_valid <= 0;
            ready_for_next <= 1;
        end else begin
            int_req_stage4 <= int_req_stage3;
            en_stage4 <= en_stage3;
            valid_stage4 <= valid_stage3;
            state_stage4 <= state_stage3;
            
            if (valid_stage3 && (state_stage3 == 1)) begin
                int_valid <= 1;
                ready_for_next <= 0;
            end else if (state_stage4 == 0) begin // 完成处理并返回到初始状态
                int_valid <= 0;
                ready_for_next <= 1;
            end
        end
    end
    
    // 流水线控制逻辑
    always @(*) begin
        pipeline_flush = 0;
        
        // 当最后阶段检测到中断请求处理完成时，刷新流水线
        if (state_stage4 == 0 && !valid_stage4) begin
            pipeline_flush = 1;
        end
    end

endmodule