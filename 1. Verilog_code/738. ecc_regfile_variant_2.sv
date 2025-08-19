//SystemVerilog
module ecc_regfile #(
    parameter DW = 32,
    parameter AW = 4
)(
    input clk,
    input rst,
    input wr_en,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output reg parity_err,
    input valid_in,
    output reg valid_out,
    input flush
);

    reg [DW:0] mem [0:(1<<AW)-1];
    reg [AW-1:0] addr_stage1, addr_stage2;
    reg [DW-1:0] din_stage1;
    reg wr_en_stage1;
    reg valid_stage1, valid_stage2;
    reg [DW:0] read_data_stage2;
    wire parity_bit;
    
    // 优化校验位计算
    assign parity_bit = ^din_stage1;
    
    // 合并流水线控制逻辑
    always @(posedge clk) begin
        if (rst || flush) begin
            {addr_stage1, din_stage1, wr_en_stage1, valid_stage1} <= 0;
            {addr_stage2, read_data_stage2, valid_stage2} <= 0;
            {parity_err, valid_out} <= 0;
        end else begin
            // 第一级流水线
            addr_stage1 <= addr;
            din_stage1 <= din;
            wr_en_stage1 <= wr_en;
            valid_stage1 <= valid_in;
            
            // 第二级流水线
            addr_stage2 <= addr_stage1;
            read_data_stage2 <= mem[addr_stage1];
            valid_stage2 <= valid_stage1;
            
            if (wr_en_stage1 && valid_stage1) begin
                mem[addr_stage1] <= {din_stage1, parity_bit};
            end
            
            // 第三级流水线
            parity_err <= valid_stage2 ? (^read_data_stage2) : parity_err;
            valid_out <= valid_stage2;
        end
    end
    
    assign dout = read_data_stage2[DW-1:0];
    
    // 优化初始化逻辑
    generate
        genvar i;
        for (i = 0; i < (1<<AW); i = i + 1) begin: INIT_MEM
            initial mem[i] = {(DW+1){1'b0}};
        end
    endgenerate
endmodule