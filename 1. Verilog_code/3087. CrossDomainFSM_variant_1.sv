//SystemVerilog
module CrossDomainFSM (
    input clk_a, clk_b, 
    input rst_n,
    input req_a,
    output reg ack_b
);
    // 时钟域A信号
    reg req_a_sync;
    reg [1:0] sync_chain_a2b;

    // 时钟域B信号
    reg ack_b_sync;
    reg [1:0] sync_chain_b2a;

    // 时钟域A到B的同步器 - 第一级同步
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            sync_chain_a2b[0] <= 1'b0;
        else
            sync_chain_a2b[0] <= req_a;
    end

    // 时钟域A到B的同步器 - 第二级同步
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            sync_chain_a2b[1] <= 1'b0;
        else
            sync_chain_a2b[1] <= sync_chain_a2b[0];
    end

    // 时钟域B到A的同步器 - 第一级同步
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            sync_chain_b2a[0] <= 1'b0;
        else
            sync_chain_b2a[0] <= ack_b;
    end

    // 时钟域B到A的同步器 - 第二级同步
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            sync_chain_b2a[1] <= 1'b0;
        else
            sync_chain_b2a[1] <= sync_chain_b2a[0];
    end

    // 时钟域B的状态机 - 使用localparam代替typedef enum
    localparam B_IDLE = 1'b0, B_ACK = 1'b1;
    reg state_b, next_state_b;

    // 状态寄存器更新
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            state_b <= B_IDLE;
        else
            state_b <= next_state_b;
    end

    // 状态转换逻辑
    always @(*) begin
        case(state_b)
            B_IDLE: next_state_b = sync_chain_a2b[1] ? B_ACK : B_IDLE;
            B_ACK:  next_state_b = sync_chain_a2b[1] ? B_ACK : B_IDLE;
            default: next_state_b = B_IDLE;
        endcase
    end

    // 输出逻辑
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            ack_b <= 1'b0;
        else if (state_b == B_IDLE && next_state_b == B_ACK)
            ack_b <= 1'b1;
        else if (state_b == B_ACK && next_state_b == B_IDLE)
            ack_b <= 1'b0;
    end
endmodule