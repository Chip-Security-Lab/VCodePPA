module ProbabilityArbiter #(parameter SEED=8'hA5) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
reg [7:0] lfsr = SEED;
wire [3:0] req_mask = req & {4{|req}}; // 防止空请求

always @(posedge clk) begin
    if(rst) begin
        lfsr <= SEED;
        grant <= 0;
    end else begin
        // LFSR随机数生成
        lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
        
        // 根据概率分布选择
        case(lfsr[1:0])
            2'b00: grant <= req_mask & 4'b0001;
            2'b01: grant <= req_mask & 4'b0010;
            2'b10: grant <= req_mask & 4'b0100;
            2'b11: grant <= req_mask & 4'b1000;
        endcase
    end
end
endmodule
