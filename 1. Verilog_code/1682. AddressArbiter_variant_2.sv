//SystemVerilog
module AddressArbiter #(parameter AW=32) (
    input clk, rst,
    input [4*AW-1:0] addr,
    input [3:0] req,
    output reg [3:0] grant
);

// Stage 1: Address Extraction
reg [AW-1:0] addr_array_stage1 [0:3];
reg [3:0] pri_map_stage1;
reg [3:0] req_stage1;

always @(posedge clk) begin
    if (rst) begin
        addr_array_stage1[0] <= 0;
        addr_array_stage1[1] <= 0;
        addr_array_stage1[2] <= 0;
        addr_array_stage1[3] <= 0;
        pri_map_stage1 <= 0;
        req_stage1 <= 0;
    end else begin
        // Extract addresses using bit slicing
        addr_array_stage1[0] <= addr[AW-1:0];
        addr_array_stage1[1] <= addr[2*AW-1:AW];
        addr_array_stage1[2] <= addr[3*AW-1:2*AW];
        addr_array_stage1[3] <= addr[4*AW-1:3*AW];
        
        // Priority mapping using direct bit selection
        pri_map_stage1 <= {
            addr_array_stage1[3][7],
            addr_array_stage1[2][7],
            addr_array_stage1[1][7],
            addr_array_stage1[0][7]
        };
        
        req_stage1 <= req;
    end
end

// Stage 2: Priority Resolution
reg [3:0] grant_stage2;

always @(posedge clk) begin
    if (rst) begin
        grant_stage2 <= 0;
    end else begin
        // Simplified priority resolution using bitwise operations
        grant_stage2 <= req_stage1 & {pri_map_stage1[1:0], 2'b00};
    end
end

// Stage 3: Output Register
always @(posedge clk) begin
    if (rst) begin
        grant <= 0;
    end else begin
        grant <= grant_stage2;
    end
end

endmodule