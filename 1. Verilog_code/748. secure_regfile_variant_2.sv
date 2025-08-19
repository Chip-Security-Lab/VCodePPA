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
    output [DW-1:0] dout,
    output access_violation
);
    // 安全掩码连接信号
    wire [15:0] addr_mask;
    
    // 访问控制连接信号
    wire valid_access;

    // 子模块实例化
    security_controller #(
        .AW(AW)
    ) security_ctrl_inst (
        .curr_domain(curr_domain),
        .addr(addr),
        .addr_mask(addr_mask),
        .valid_access(valid_access)
    );
    
    memory_unit #(
        .DW(DW),
        .AW(AW)
    ) mem_unit_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .addr(addr),
        .din(din),
        .valid_access(valid_access),
        .dout(dout),
        .access_violation(access_violation)
    );
endmodule

module security_controller #(
    parameter AW = 4
)(
    input [1:0] curr_domain,
    input [AW-1:0] addr,
    output reg [15:0] addr_mask,
    output valid_access
);
    // 安全策略配置
    localparam DOMAIN0_MASK = 16'hFFFF; // 特权域可访问全部
    localparam DOMAIN1_MASK = 16'h00FF;
    localparam DOMAIN2_MASK = 16'h000F;
    localparam DOMAIN3_MASK = 16'h0003;
    
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
    assign valid_access = (addr < (1<<AW)) && (addr_mask[addr] && (|addr_mask));
endmodule

module memory_unit #(
    parameter DW = 32,
    parameter AW = 4
)(
    input clk,
    input rst_n,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    input valid_access,
    output reg [DW-1:0] dout,
    output reg access_violation
);
    // 存储单元阵列
    reg [DW-1:0] storage [0:(1<<AW)-1];
    
    // 写入和违规检测逻辑
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
    
    // 读取逻辑
    always @(*) begin
        dout = valid_access ? storage[addr] : {DW{1'b0}};
    end
endmodule