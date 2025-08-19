//SystemVerilog
module FixedPriorityArbiter #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [N-1:0] grant
);

reg [N-1:0] req_stage1;
reg [N-1:0] grant_stage1;
reg [N-1:0] req_comp;
reg [N-1:0] req_comp_plus_1;
reg [N-1:0] req_minus_1;

// Stage 1: Register input requests
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        req_stage1 <= 0;
    end else begin
        req_stage1 <= req;
    end
end

// Stage 2: Calculate req-1 using conditional sum subtraction
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        req_comp <= 0;
        req_comp_plus_1 <= 0;
        req_minus_1 <= 0;
    end else begin
        req_comp <= ~req_stage1;
        req_comp_plus_1 <= req_comp + 1;
        req_minus_1 <= req_comp_plus_1;
    end
end

// Stage 3: Calculate final grant
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        grant <= 0;
    end else begin
        grant <= req_stage1 & ~req_minus_1;
    end
end

endmodule