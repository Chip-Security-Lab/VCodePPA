module secure_regfile #(
    parameter DW = 32,
    parameter AW = 4,
    parameter N_DOMAINS = 4
)(
    input clk,
    input rst_n,
    input [1:0] curr_domain,   // 当前安全域
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg access_violation
);
// 安全策略配置
localparam DOMAIN0_MASK = 16'hFFFF; // 特权域可访问全部
localparam DOMAIN1_MASK = 16'h00FF;
localparam DOMAIN2_MASK = 16'h000F;
localparam DOMAIN3_MASK = 16'h0003;

reg [DW-1:0] storage [0:(1<<AW)-1];
reg [15:0] addr_mask;

// 地址访问权限解码
always @(*) begin
    case(curr_domain)
        2'b00: addr_mask = DOMAIN0_MASK;
        2'b01: addr_mask = DOMAIN1_MASK;
        2'b10: addr_mask = DOMAIN2_MASK;
        2'b11: addr_mask = DOMAIN3_MASK;
        default: addr_mask = DOMAIN0_MASK;
    endcase
end

// 访问控制逻辑
wire valid_access = (addr < (1<<AW)) && 
                   (addr_mask[addr] && (|addr_mask));

always @(posedge clk) begin
    if (!rst_n) begin
        integer i;
        for (i = 0; i < (1<<AW); i = i + 1) begin
            storage[i] <= {DW{1'b0}};
        end
        access_violation <= 0;
    end else begin
        access_violation <= 0;
        if (wr_en) begin
            if (valid_access) begin
                storage[addr] <= din;
            end else begin
                access_violation <= 1;
            end
        end
    end
end

assign dout = valid_access ? storage[addr] : {DW{1'b0}};
endmodule