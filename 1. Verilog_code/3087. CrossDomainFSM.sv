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

    // 时钟域A到B的同步器
    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) sync_chain_a2b <= 2'b00;
        else sync_chain_a2b <= {sync_chain_a2b[0], req_a};
    end

    // 时钟域B到A的同步器
    always @(posedge clk_a or negedge rst_n) begin
        if (!rst_n) sync_chain_b2a <= 2'b00;
        else sync_chain_b2a <= {sync_chain_b2a[0], ack_b};
    end

    // 时钟域B的状态机 - 使用localparam代替typedef enum
    localparam B_IDLE = 1'b0, B_ACK = 1'b1;
    reg state_b;

    always @(posedge clk_b or negedge rst_n) begin
        if (!rst_n) begin
            state_b <= B_IDLE;
            ack_b <= 0;
        end else begin
            case(state_b)
                B_IDLE: if (sync_chain_a2b[1]) begin
                    ack_b <= 1;
                    state_b <= B_ACK;
                end
                B_ACK: if (!sync_chain_a2b[1]) begin
                    ack_b <= 0;
                    state_b <= B_IDLE;
                end
                default: state_b <= B_IDLE;
            endcase
        end
    end
endmodule