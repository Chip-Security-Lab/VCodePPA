//SystemVerilog
module AddressArbiter #(parameter AW=32) (
    input clk, rst,
    input [4*AW-1:0] addr,
    input [3:0] req,
    output reg [3:0] grant
);

// Pipeline stage 1 signals
reg [4*AW-1:0] addr_stage1;
reg [3:0] req_stage1;
reg valid_stage1;

// Pipeline stage 2 signals
wire [AW-1:0] addr_array [0:3];
reg [3:0] req_stage2;
reg valid_stage2;

// Pipeline stage 3 signals
wire [3:0] pri_map;
reg [3:0] req_stage3;
reg valid_stage3;

// Stage 1: Input registration
always @(posedge clk or posedge rst) begin
    if (rst) begin
        addr_stage1 <= 0;
        req_stage1 <= 0;
        valid_stage1 <= 0;
    end else begin
        addr_stage1 <= addr;
        req_stage1 <= req;
        valid_stage1 <= 1;
    end
end

// Stage 2: Address extraction
AddressExtractor #(.AW(AW)) addr_extractor (
    .addr(addr_stage1),
    .addr_array(addr_array)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        req_stage2 <= 0;
        valid_stage2 <= 0;
    end else begin
        req_stage2 <= req_stage1;
        valid_stage2 <= valid_stage1;
    end
end

// Stage 3: Priority extraction
PriorityExtractor #(.AW(AW)) pri_extractor (
    .addr_array(addr_array),
    .pri_map(pri_map)
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        req_stage3 <= 0;
        valid_stage3 <= 0;
    end else begin
        req_stage3 <= req_stage2;
        valid_stage3 <= valid_stage2;
    end
end

// Stage 4: Arbitration
always @(posedge clk or posedge rst) begin
    if (rst) begin
        grant <= 0;
    end else if (valid_stage3) begin
        grant <= req_stage3 & (pri_map << 2);
    end else begin
        grant <= 0;
    end
end

endmodule

module AddressExtractor #(parameter AW=32) (
    input [4*AW-1:0] addr,
    output [AW-1:0] addr_array [0:3]
);

genvar g;
generate
    for (g = 0; g < 4; g = g + 1) begin: addr_extract
        assign addr_array[g] = addr[g*AW +: AW];
    end
endgenerate

endmodule

module PriorityExtractor #(parameter AW=32) (
    input [AW-1:0] addr_array [0:3],
    output [3:0] pri_map
);

assign pri_map = {
    addr_array[3][7],
    addr_array[2][7],
    addr_array[1][7],
    addr_array[0][7]
};

endmodule