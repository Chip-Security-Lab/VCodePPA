//SystemVerilog
module secure_regfile #(
    parameter DW = 32,
    parameter AW = 4,
    parameter N_DOMAINS = 4
)(
    input clk,
    input rst_n,
    input [1:0] curr_domain,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg access_violation
);

localparam DOMAIN0_MASK = 16'hFFFF;
localparam DOMAIN1_MASK = 16'h00FF;
localparam DOMAIN2_MASK = 16'h000F;
localparam DOMAIN3_MASK = 16'h0003;

reg [DW-1:0] storage [0:(1<<AW)-1];
reg [15:0] addr_mask;
reg [DW-1:0] dout_reg;

// 条件反相减法器实现
wire [15:0] domain_diff;
wire [15:0] mask_diff;
wire [15:0] final_mask;

assign domain_diff = {16{curr_domain[1]}} ^ {16{curr_domain[0]}};
assign mask_diff = (curr_domain[1] ? DOMAIN2_MASK : DOMAIN0_MASK) ^ 
                  (curr_domain[0] ? DOMAIN1_MASK : DOMAIN3_MASK);
assign final_mask = domain_diff & mask_diff;

always @(*) begin
    addr_mask = final_mask;
end

wire valid_access = (addr < (1<<AW)) && 
                   (addr_mask[addr] && (|addr_mask));

always @(posedge clk) begin
    if (!rst_n) begin
        integer i;
        for (i = 0; i < (1<<AW); i = i + 1) begin
            storage[i] <= {DW{1'b0}};
        end
        access_violation <= 0;
        dout_reg <= {DW{1'b0}};
    end else begin
        access_violation <= 0;
        if (wr_en) begin
            if (valid_access) begin
                storage[addr] <= din;
            end else begin
                access_violation <= 1;
            end
        end
        dout_reg <= valid_access ? storage[addr] : {DW{1'b0}};
    end
end

assign dout = dout_reg;
endmodule