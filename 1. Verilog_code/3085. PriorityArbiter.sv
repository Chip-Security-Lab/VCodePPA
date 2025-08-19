module PriorityArbiter #(
    parameter NUM_REQ = 4,
    parameter PRIO_MASK = 4'b0001  // 初始优先级掩码
)(
    input clk, rst_n,
    input [NUM_REQ-1:0] req,
    input [NUM_REQ-1:0] mask,
    output reg [NUM_REQ-1:0] grant
);
    reg [NUM_REQ-1:0] priority_mask;
    reg [NUM_REQ-1:0] arbiter_mask; // 临时掩码变量用于组合逻辑
    integer i;

    // 动态优先级更新 - 移动到时序逻辑中
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask <= PRIO_MASK;
            grant <= 0;
        end else begin
            // 更新grant寄存器
            grant <= arbiter_mask & req & mask;
            if (|grant) begin
                priority_mask <= {grant[NUM_REQ-2:0], grant[NUM_REQ-1]};
            end
        end
    end

    // 组合仲裁逻辑 - 不要修改寄存器
    always @(*) begin
        arbiter_mask = priority_mask;
        for (i = 0; i < NUM_REQ; i = i+1) begin
            if ((arbiter_mask & req & mask) != 0) begin
                break;
            end
            arbiter_mask = {arbiter_mask[NUM_REQ-2:0], arbiter_mask[NUM_REQ-1]};
        end
    end
endmodule