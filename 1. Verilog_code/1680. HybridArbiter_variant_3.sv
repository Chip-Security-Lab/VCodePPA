//SystemVerilog
module HybridArbiter #(parameter HP_GROUP=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);

// Pipeline registers
reg [3:0] hp_req_reg;
reg [3:0] lp_req_reg;
reg [3:0] grant_reg;
reg [3:0] req_reg;

// Stage 1: Request classification with optimized masking
wire [3:0] hp_req = req_reg & 4'b1111;
wire [3:0] lp_req = req_reg & 4'b0000;

// Stage 2: Optimized arbitration logic
wire [3:0] hp_grant = hp_req_reg & (~hp_req_reg + 1'b1);
wire [3:0] lp_grant = lp_req_reg << ($urandom & 1'b1);

// Priority encoder for high priority requests
wire [1:0] hp_priority;
assign hp_priority = (hp_req_reg[0]) ? 2'b00 :
                    (hp_req_reg[1]) ? 2'b01 :
                    (hp_req_reg[2]) ? 2'b10 :
                    (hp_req_reg[3]) ? 2'b11 : 2'b00;

always @(posedge clk) begin
    if (rst) begin
        req_reg <= 4'b0;
        hp_req_reg <= 4'b0;
        lp_req_reg <= 4'b0;
        grant_reg <= 4'b0;
        grant <= 4'b0;
    end else begin
        // Stage 0: Input registration
        req_reg <= req;
        
        // Stage 1: Register requests with optimized timing
        hp_req_reg <= hp_req;
        lp_req_reg <= lp_req;
        
        // Stage 2: Optimized arbitration with priority encoding
        if (|hp_req_reg)
            grant_reg <= (4'b1 << hp_priority);
        else 
            grant_reg <= lp_grant;
            
        // Stage 3: Output with minimal delay
        grant <= grant_reg;
    end
end

endmodule