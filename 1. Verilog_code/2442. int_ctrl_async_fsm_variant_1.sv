//SystemVerilog
module int_ctrl_async_fsm #(DW=4)(
    input  logic clk,
    input  logic en,
    input  logic rst_n, // 增加复位信号
    input  logic [DW-1:0] int_req,
    output logic int_valid,
    output logic ready_for_next // 增加ready信号表示可接收新请求
);
    // 流水线寄存器和状态定义
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        PROCESS = 2'b01,
        FINISH  = 2'b10
    } state_t;

    // 流水线阶段寄存器
    state_t state_stage1, state_stage2;
    logic [DW-1:0] int_req_stage1;
    logic valid_stage1, valid_stage2;
    logic borrow_stage1;
    logic [1:0] sub_result_stage1;
    
    // 流水线阶段1: 请求检测和子状态计算
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            int_req_stage1 <= '0;
            valid_stage1 <= 1'b0;
            borrow_stage1 <= 1'b0;
            sub_result_stage1 <= 2'b00;
        end
        else if (en) begin
            // 捕获输入请求
            int_req_stage1 <= int_req;
            
            // 计算借位逻辑 (将组合逻辑转为时序逻辑)
            borrow_stage1 <= 1'b0;
            
            // 计算条件反相减法器的结果
            sub_result_stage1[0] <= state_stage1[0] ^ 1'b1 ^ 1'b0;
            sub_result_stage1[1] <= state_stage1[1] ^ 1'b0 ^ 
                                   (~state_stage1[0] & 1'b1);
            
            // 状态转移逻辑
            case(state_stage1)
                IDLE:    state_stage1 <= (|int_req) ? PROCESS : IDLE;
                PROCESS: state_stage1 <= FINISH;
                FINISH:  state_stage1 <= IDLE;
                default: state_stage1 <= IDLE;
            endcase
            
            // 有效信号传递
            valid_stage1 <= (state_stage1 == IDLE && |int_req);
        end
    end
    
    // 流水线阶段2: 计算和输出生成
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            valid_stage2 <= 1'b0;
            int_valid <= 1'b0;
        end
        else if (en) begin
            // 传递状态到第二阶段
            state_stage2 <= state_stage1;
            valid_stage2 <= valid_stage1;
            
            // 输出逻辑
            if (valid_stage1 || state_stage1 == PROCESS)
                int_valid <= 1'b1;
            else
                int_valid <= 1'b0;
        end
    end
    
    // Ready信号生成 - 指示流水线是否可以接收新请求
    assign ready_for_next = (state_stage1 == IDLE) || 
                           (state_stage1 == FINISH && state_stage2 != PROCESS);
    
endmodule