//SystemVerilog
module TokenBucketArbiter #(parameter BUCKET_SIZE=16) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// 寄存器信号
reg [7:0] token_cnt [0:3];
reg [7:0] next_token_cnt [0:3];
reg [3:0] next_grant;

// 组合逻辑信号
wire [3:0] token_valid;
wire tokens_available;
wire [3:0] grant_comb;

// 组合逻辑部分
genvar i;
generate
    for(i=0; i<4; i=i+1) begin: TOKEN_CHECK
        assign token_valid[i] = (token_cnt[i] > 0);
    end
endgenerate

assign tokens_available = |token_valid;
assign grant_comb = req & {4{tokens_available}};

// 组合逻辑计算下一个状态
always @(*) begin
    for(int i=0; i<4; i=i+1) begin
        next_token_cnt[i] = token_cnt[i];
        if(token_cnt[i] < BUCKET_SIZE) 
            next_token_cnt[i] = token_cnt[i] + 1;
        if(grant[i] && token_valid[i]) 
            next_token_cnt[i] = token_cnt[i] - 1;
    end
    next_grant = grant_comb;
end

// 时序逻辑部分
always @(posedge clk) begin
    if(rst) begin
        for(int i=0; i<4; i=i+1) begin
            token_cnt[i] <= BUCKET_SIZE;
        end
        grant <= 0;
    end else begin
        for(int i=0; i<4; i=i+1) begin
            token_cnt[i] <= next_token_cnt[i];
        end
        grant <= next_grant;
    end
end

endmodule