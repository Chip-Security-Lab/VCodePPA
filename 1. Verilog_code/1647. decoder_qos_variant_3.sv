//SystemVerilog
module decoder_qos #(BURST_SIZE=4) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Pipeline stage 1: Counter update
reg [1:0] counter_stage1;
reg [3:0] req_stage1;

// Pipeline stage 2: Grant calculation
reg [1:0] counter_stage2;
reg [3:0] req_stage2;
reg [3:0] grant_stage2;

// Pipeline control signals
reg valid_stage1;
reg valid_stage2;

// Stage 1: Counter and request sampling
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter_stage1 <= 0;
        req_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        counter_stage1 <= (counter_stage1 == BURST_SIZE-1) ? 0 : counter_stage1 + 1;
        req_stage1 <= req;
        valid_stage1 <= 1;
    end
end

// Stage 2: Grant calculation
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter_stage2 <= 0;
        req_stage2 <= 0;
        grant_stage2 <= 0;
        valid_stage2 <= 0;
    end else begin
        counter_stage2 <= counter_stage1;
        req_stage2 <= req_stage1;
        grant_stage2 <= req_stage1 & (1 << counter_stage1);
        valid_stage2 <= valid_stage1;
    end
end

// Output stage
always @(posedge clk or posedge rst) begin
    if(rst) begin
        grant <= 0;
    end else begin
        grant <= valid_stage2 ? grant_stage2 : 0;
    end
end

endmodule