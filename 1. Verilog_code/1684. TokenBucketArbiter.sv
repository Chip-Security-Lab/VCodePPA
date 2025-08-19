module TokenBucketArbiter #(parameter BUCKET_SIZE=16) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
reg [7:0] token_cnt [0:3];
integer i;
wire tokens_available;

assign tokens_available = |{token_cnt[0], token_cnt[1], token_cnt[2], token_cnt[3]};

always @(posedge clk) begin
    if(rst) begin
        for(i=0; i<4; i=i+1) 
            token_cnt[i] <= BUCKET_SIZE;
        grant <= 0;
    end else begin
        for(i=0; i<4; i=i+1) begin
            if(token_cnt[i] < BUCKET_SIZE)
                token_cnt[i] <= token_cnt[i] + 1;
                
            if(grant[i] && token_cnt[i] > 0)
                token_cnt[i] <= token_cnt[i] - 1;
        end
        grant <= req & {4{tokens_available}};
    end
end
endmodule