//SystemVerilog
module CrossDomainFSM (
    input clk_a, clk_b,
    input rst_n,
    input req_a_valid,
    output reg req_a_ready,
    output reg ack_b_valid,
    input ack_b_ready
);

    // 时钟域A信号
    reg req_a_sync;
    reg [1:0] sync_chain_a2b;

    // 时钟域B信号  
    reg ack_b_sync;
    reg [1:0] sync_chain_b2a;

    // 状态定义
    localparam B_IDLE = 1'b0, B_ACK = 1'b1;
    reg state_b, next_state_b;
    reg ack_b_valid_next;
    reg req_a_ready_next;

    // 时钟域A到B的同步器 - 第一级同步
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            sync_chain_a2b[0] <= 1'b0;
        else
            sync_chain_a2b[0] <= req_a_valid;
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
            sync_chain_b2a[0] <= ack_b_valid;
    end

    // 时钟域B到A的同步器 - 第二级同步
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n)
            sync_chain_b2a[1] <= 1'b0;
        else
            sync_chain_b2a[1] <= sync_chain_b2a[0];
    end

    // 时钟域B的状态机 - 状态寄存器更新
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n)
            state_b <= B_IDLE;
        else
            state_b <= next_state_b;
    end

    // 时钟域B的状态机 - 输出寄存器更新
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            ack_b_valid <= 1'b0;
            req_a_ready <= 1'b0;
        end
        else begin
            ack_b_valid <= ack_b_valid_next;
            req_a_ready <= req_a_ready_next;
        end
    end

    // 时钟域B的状态机 - 状态转移逻辑
    always @(*) begin
        next_state_b = state_b;
        
        case(state_b)
            B_IDLE: begin
                if (sync_chain_a2b[1] && ack_b_ready)
                    next_state_b = B_ACK;
            end
            
            B_ACK: begin
                if (!sync_chain_a2b[1] || ack_b_ready)
                    next_state_b = B_IDLE;
            end
            
            default:
                next_state_b = B_IDLE;
        endcase
    end

    // 时钟域B的状态机 - 输出逻辑
    always @(*) begin
        ack_b_valid_next = ack_b_valid;
        req_a_ready_next = req_a_ready;
        
        case(state_b)
            B_IDLE: begin
                if (sync_chain_a2b[1] && ack_b_ready) begin
                    ack_b_valid_next = 1'b1;
                    req_a_ready_next = 1'b1;
                end
            end
            
            B_ACK: begin
                if (!sync_chain_a2b[1] || ack_b_ready) begin
                    ack_b_valid_next = 1'b0;
                    req_a_ready_next = 1'b0;
                end
            end
            
            default: begin
                ack_b_valid_next = 1'b0;
                req_a_ready_next = 1'b0;
            end
        endcase
    end

endmodule