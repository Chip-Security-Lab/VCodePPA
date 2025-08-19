//SystemVerilog
module HybridArbiter #(parameter HP_GROUP=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Pipeline registers
reg [3:0] hp_req_reg;
reg [3:0] lp_req_reg;
reg [3:0] grant_next;

// Combinational logic split into two stages
wire [3:0] hp_req = req & {4{1'b1}};
wire [3:0] lp_req = req & {4{1'b0}};

// First pipeline stage
always @(posedge clk) begin
    if(rst) begin
        hp_req_reg <= 4'b0;
        lp_req_reg <= 4'b0;
    end else begin
        hp_req_reg <= hp_req;
        lp_req_reg <= lp_req;
    end
end

// Second pipeline stage - arbitration logic
always @(posedge clk) begin
    if(rst) begin
        grant_next <= 4'b0;
    end else begin
        if(|hp_req_reg)
            grant_next <= hp_req_reg & -hp_req_reg;
        else 
            grant_next <= lp_req_reg << $urandom%2;
    end
end

// Final output stage
always @(posedge clk) begin
    if(rst)
        grant <= 4'b0;
    else
        grant <= grant_next;
end

endmodule