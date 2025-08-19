//SystemVerilog
module PacketizeBridge #(
    parameter DW=32, 
    parameter HEADER=32'hCAFEBABE
)(
    input clk, rst_n,
    input [DW-1:0] payload,
    input pkt_valid,
    output reg [DW-1:0] pkt_out,
    output reg pkt_ready
);
    // 定义状态常量
    parameter IDLE = 2'b00;
    parameter HEAD = 2'b01;
    parameter PAYLOAD = 2'b10;
    
    // 状态寄存器和状态转换信号
    reg [1:0] state;
    reg [1:0] next_state;
    
    // 先行借位减法器信号
    wire [1:0] state_minus_one;
    wire [1:0] borrow;
    
    // 先行借位减法器实现 (2位)
    // 计算每一位的借位信号
    assign borrow[0] = (state[0] == 1'b0) ? 1'b1 : 1'b0;
    assign borrow[1] = ((state[1] == 1'b0) || ((state[1] == 1'b0) && borrow[0])) ? 1'b1 : 1'b0;
    
    // 使用借位信号计算差值
    assign state_minus_one[0] = (state[0] == 1'b0) ? 1'b1 : 1'b0;
    assign state_minus_one[1] = (state[1] ^ borrow[0]);

    // 状态转换逻辑
    always @(*) begin
        case(state)
            IDLE: next_state = pkt_valid ? HEAD : IDLE;
            HEAD: next_state = PAYLOAD;
            PAYLOAD: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 状态寄存器和输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pkt_ready <= 1'b0;
            pkt_out <= {DW{1'b0}};
        end else begin
            state <= next_state;
            
            case(state)
                IDLE: begin
                    if (pkt_valid) begin
                        pkt_out <= HEADER;
                        pkt_ready <= 1'b0;
                    end
                end
                HEAD: begin
                    pkt_out <= payload;
                    pkt_ready <= 1'b1;
                end
                PAYLOAD: begin
                    pkt_ready <= 1'b0;
                    // 此处可以使用先行借位减法器计算的结果进行特殊状态转换
                    // 例如实现回退操作，这里仅作为示例
                    if (state_minus_one == HEAD) begin
                        // 特殊条件下可以使用减法器结果
                    end
                end
                default: begin
                    pkt_ready <= 1'b0;
                end
            endcase
        end
    end
endmodule