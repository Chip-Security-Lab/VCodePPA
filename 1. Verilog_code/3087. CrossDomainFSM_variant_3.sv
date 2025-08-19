//SystemVerilog
module CrossDomainFSM (
    input clk_a, clk_b, 
    input rst_n,
    input req_a,
    output reg ack_b
);
    // 时钟域A信号
    reg req_a_stage1, req_a_stage2;
    
    // 时钟域B的多级同步器
    reg [1:0] sync_chain_a2b_stage1;
    reg [1:0] sync_chain_a2b_stage2;
    
    // 时钟域A的多级同步器
    reg [1:0] sync_chain_b2a_stage1;
    reg [1:0] sync_chain_b2a_stage2;
    
    // 时钟域B状态机信号
    reg state_b_stage1, state_b_stage2;
    reg ack_b_stage1;
    
    // valid信号控制流水线
    reg valid_stage1_b, valid_stage2_b;
    reg valid_stage1_a, valid_stage2_a;
    
    // 流水线第一级 - 请求捕获和同步开始
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a_stage1 <= 1'b0;
            valid_stage1_a <= 1'b0;
        end else begin
            req_a_stage1 <= req_a;
            valid_stage1_a <= 1'b1;
        end
    end
    
    // 流水线第二级 - A域请求处理
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            req_a_stage2 <= 1'b0;
            sync_chain_b2a_stage1 <= 2'b00;
            valid_stage2_a <= 1'b0;
        end else if (valid_stage1_a) begin
            req_a_stage2 <= req_a_stage1;
            sync_chain_b2a_stage1 <= {sync_chain_b2a_stage1[0], ack_b};
            valid_stage2_a <= 1'b1;
        end
    end
    
    // 完成A域同步
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) begin
            sync_chain_b2a_stage2 <= 2'b00;
        end else if (valid_stage2_a) begin
            sync_chain_b2a_stage2 <= sync_chain_b2a_stage1;
        end
    end
    
    // B域流水线第一级 - 开始A到B同步
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync_chain_a2b_stage1 <= 2'b00;
            valid_stage1_b <= 1'b0;
        end else begin
            sync_chain_a2b_stage1 <= {sync_chain_a2b_stage1[0], req_a};
            valid_stage1_b <= 1'b1;
        end
    end
    
    // B域流水线第二级 - 完成A到B同步
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            sync_chain_a2b_stage2 <= 2'b00;
            valid_stage2_b <= 1'b0;
        end else if (valid_stage1_b) begin
            sync_chain_a2b_stage2 <= sync_chain_a2b_stage1;
            valid_stage2_b <= 1'b1;
        end
    end
    
    // 时钟域B的状态机 - 流水线第一级
    localparam B_IDLE = 1'b0, B_ACK = 1'b1;
    
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            state_b_stage1 <= B_IDLE;
            ack_b_stage1 <= 1'b0;
        end else if (valid_stage2_b) begin
            case(state_b_stage1)
                B_IDLE: if (sync_chain_a2b_stage2[1]) begin
                    ack_b_stage1 <= 1'b1;
                    state_b_stage1 <= B_ACK;
                end
                B_ACK: if (!sync_chain_a2b_stage2[1]) begin
                    ack_b_stage1 <= 1'b0;
                    state_b_stage1 <= B_IDLE;
                end
                default: state_b_stage1 <= B_IDLE;
            endcase
        end
    end
    
    // 时钟域B的状态机 - 流水线第二级（输出寄存）
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            state_b_stage2 <= B_IDLE;
            ack_b <= 1'b0;
        end else begin
            state_b_stage2 <= state_b_stage1;
            ack_b <= ack_b_stage1;
        end
    end
endmodule