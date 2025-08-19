//SystemVerilog
module decoder_qos #(BURST_SIZE=4) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

reg [1:0] counter_stage1;
reg [1:0] counter_stage2;
reg [3:0] req_stage1;
reg [3:0] grant_stage1;

// Stage 1: Counter update and request sampling
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter_stage1 <= 0;
        req_stage1 <= 0;
    end else if(counter_stage1 == BURST_SIZE-1) begin
        counter_stage1 <= 0;
        req_stage1 <= req;
    end else begin
        counter_stage1 <= counter_stage1 + 1;
        req_stage1 <= req;
    end
end

// Stage 2: Grant computation
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter_stage2 <= 0;
        grant_stage1 <= 0;
    end else begin
        counter_stage2 <= counter_stage1;
        grant_stage1 <= req_stage1 & (1 << counter_stage1);
    end
end

// Stage 3: Output registration
always @(posedge clk or posedge rst) begin
    if(rst) begin
        grant <= 0;
    end else begin
        grant <= grant_stage1;
    end
end

endmodule