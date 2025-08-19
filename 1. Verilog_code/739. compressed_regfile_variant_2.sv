//SystemVerilog
module compressed_regfile #(
    parameter PACKED_WIDTH = 16,
    parameter UNPACKED_WIDTH = 32
)(
    input clk,
    input reset,
    input wr_en,
    input [3:0] addr,
    input [PACKED_WIDTH-1:0] din,
    input valid_in,
    output valid_out,
    output [UNPACKED_WIDTH-1:0] dout
);
    // 存储单元
    reg [PACKED_WIDTH-1:0] storage [0:15];
    
    // 流水线阶段寄存器
    reg [PACKED_WIDTH-1:0] data_stage1;
    reg valid_stage1;
    reg [3:0] addr_stage1;
    
    // 阶段1: 存储访问
    always @(posedge clk) begin
        if (reset) begin
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
            addr_stage1 <= addr;
            
            // 读取操作 - 第一阶段
            if (valid_in) begin
                data_stage1 <= storage[addr];
            end
            
            // 写入操作
            if (wr_en) begin
                storage[addr] <= din;
            end
        end
    end
    
    // 阶段2: 数据扩展与输出
    reg [UNPACKED_WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    always @(posedge clk) begin
        if (reset) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
            
            // 数据扩展 - 第二阶段
            if (valid_stage1) begin
                data_stage2 <= {{(UNPACKED_WIDTH-PACKED_WIDTH){1'b0}}, data_stage1};
            end
        end
    end
    
    // 输出赋值
    assign dout = data_stage2;
    assign valid_out = valid_stage2;
    
endmodule