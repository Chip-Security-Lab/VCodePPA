//SystemVerilog
module TokenBucketArbiter #(parameter BUCKET_SIZE=16) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1: Token count update logic
reg [7:0] token_cnt [0:3];
reg [7:0] token_cnt_next [0:3];
reg [3:0] grant_next;
integer i;
wire tokens_available;
wire [3:0] grant_pre;

// Stage 1: Token availability check
assign tokens_available = |{token_cnt[0], token_cnt[1], token_cnt[2], token_cnt[3]};
assign grant_pre = req & {4{tokens_available}};

// Stage 1: Token count update calculation
always @(*) begin
    for(i=0; i<4; i=i+1) begin
        token_cnt_next[i] = token_cnt[i];
        if(token_cnt[i] < BUCKET_SIZE)
            token_cnt_next[i] = token_cnt[i] + 1;
        if(grant_pre[i] && token_cnt[i] > 0)
            token_cnt_next[i] = token_cnt[i] - 1;
    end
    grant_next = grant_pre;
end

// Stage 2: Register update
reg [7:0] token_cnt_stage2 [0:3];
reg [3:0] grant_stage2;

always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<4; i=i+1) begin
            token_cnt[i] <= BUCKET_SIZE;
            token_cnt_stage2[i] <= BUCKET_SIZE;
        end
        grant <= 0;
        grant_stage2 <= 0;
    end else begin
        // Stage 1 to Stage 2 pipeline
        for(i=0; i<4; i=i+1)
            token_cnt_stage2[i] <= token_cnt_next[i];
        grant_stage2 <= grant_next;
        
        // Stage 2 to output pipeline
        for(i=0; i<4; i=i+1)
            token_cnt[i] <= token_cnt_stage2[i];
        grant <= grant_stage2;
    end
end

endmodule