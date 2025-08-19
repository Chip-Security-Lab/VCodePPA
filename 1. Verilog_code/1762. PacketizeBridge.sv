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
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pkt_ready <= 0;
            pkt_out <= 0;
        end else begin
            case(state)
                IDLE: if (pkt_valid) begin
                    pkt_out <= HEADER;
                    state <= HEAD;
                end
                HEAD: begin
                    pkt_out <= payload;
                    state <= PAYLOAD;
                    pkt_ready <= 1;
                end
                PAYLOAD: begin
                    pkt_ready <= 0;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule