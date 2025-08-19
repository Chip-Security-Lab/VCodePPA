//SystemVerilog
module PacketizeBridge #(
    parameter DW = 32, 
    parameter HEADER = 32'hCAFEBABE
)(
    input wire clk, rst_n,
    input wire [DW-1:0] payload,
    input wire pkt_valid,
    output reg [DW-1:0] pkt_out,
    output reg pkt_ready
);
    // 使用单热码状态编码以减少组合逻辑
    localparam [2:0] IDLE    = 3'b001;
    localparam [2:0] HEAD    = 3'b010;
    localparam [2:0] PAYLOAD = 3'b100;
    
    reg [2:0] current_state, next_state;
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    // 下一状态逻辑（组合逻辑）
    always @(*) begin
        case (1'b1) // 单热码优先编码
            current_state[0]: next_state = pkt_valid ? HEAD : IDLE;
            current_state[1]: next_state = PAYLOAD;
            current_state[2]: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pkt_out <= {DW{1'b0}};
            pkt_ready <= 1'b0;
        end else begin
            // 默认输出
            pkt_ready <= 1'b0;
            
            // 状态特定输出
            case (1'b1) // 使用单热码优化比较链
                current_state[0]: begin // IDLE
                    if (pkt_valid)
                        pkt_out <= HEADER;
                end
                current_state[1]: begin // HEAD
                    pkt_out <= payload;
                    pkt_ready <= 1'b1;
                end
                current_state[2]: begin // PAYLOAD
                    // 保持默认值
                end
            endcase
        end
    end
endmodule