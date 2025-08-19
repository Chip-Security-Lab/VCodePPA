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
    // 使用2位编码替代3位单热编码，减少寄存器数量
    localparam IDLE = 2'b00;
    localparam HEAD = 2'b01;
    localparam PAYLOAD = 2'b10;
    
    reg [1:0] state, next_state;
    
    // 简化状态转换逻辑
    always @(*) begin
        case(state)
            IDLE:    next_state = pkt_valid ? HEAD : IDLE;
            HEAD:    next_state = PAYLOAD;
            PAYLOAD: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 简化输出逻辑
    wire next_pkt_ready = (state == IDLE) & pkt_valid;
    
    // 数据选择逻辑预计算
    reg [DW-1:0] next_pkt_out;
    always @(*) begin
        if (state == IDLE && pkt_valid)
            next_pkt_out = HEADER;
        else if (state == HEAD)
            next_pkt_out = payload;
        else
            next_pkt_out = pkt_out;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pkt_ready <= 1'b0;
            pkt_out <= {DW{1'b0}};
        end else begin
            state <= next_state;
            pkt_ready <= next_pkt_ready;
            pkt_out <= next_pkt_out;
        end
    end
endmodule