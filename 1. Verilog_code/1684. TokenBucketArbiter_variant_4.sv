//SystemVerilog
module TokenBucketArbiter #(parameter BUCKET_SIZE=16) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Token counter registers
reg [7:0] token_cnt [0:3];

// Token validity signals
wire [3:0] token_valid;
wire any_token_valid;

// Token validity logic
assign token_valid = {
    token_cnt[3] > 0,
    token_cnt[2] > 0,
    token_cnt[1] > 0,
    token_cnt[0] > 0
};

assign any_token_valid = |token_valid;

// Reset and token counter update for bucket 0
always @(posedge clk) begin
    if (rst) begin
        token_cnt[0] <= BUCKET_SIZE;
    end else begin
        token_cnt[0] <= (token_cnt[0] < BUCKET_SIZE) ? token_cnt[0] + 1'b1 : 
                       (grant[0] && token_cnt[0] > 0) ? token_cnt[0] - 1'b1 : token_cnt[0];
    end
end

// Reset and token counter update for bucket 1
always @(posedge clk) begin
    if (rst) begin
        token_cnt[1] <= BUCKET_SIZE;
    end else begin
        token_cnt[1] <= (token_cnt[1] < BUCKET_SIZE) ? token_cnt[1] + 1'b1 : 
                       (grant[1] && token_cnt[1] > 0) ? token_cnt[1] - 1'b1 : token_cnt[1];
    end
end

// Reset and token counter update for bucket 2
always @(posedge clk) begin
    if (rst) begin
        token_cnt[2] <= BUCKET_SIZE;
    end else begin
        token_cnt[2] <= (token_cnt[2] < BUCKET_SIZE) ? token_cnt[2] + 1'b1 : 
                       (grant[2] && token_cnt[2] > 0) ? token_cnt[2] - 1'b1 : token_cnt[2];
    end
end

// Reset and token counter update for bucket 3
always @(posedge clk) begin
    if (rst) begin
        token_cnt[3] <= BUCKET_SIZE;
    end else begin
        token_cnt[3] <= (token_cnt[3] < BUCKET_SIZE) ? token_cnt[3] + 1'b1 : 
                       (grant[3] && token_cnt[3] > 0) ? token_cnt[3] - 1'b1 : token_cnt[3];
    end
end

// Grant signal generation
always @(posedge clk) begin
    if (rst) begin
        grant <= 0;
    end else begin
        grant <= req & {4{any_token_valid}};
    end
end

endmodule