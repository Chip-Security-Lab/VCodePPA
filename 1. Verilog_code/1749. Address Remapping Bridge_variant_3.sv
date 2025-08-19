//SystemVerilog
module remap_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    input [AWIDTH-1:0] in_addr,
    input [DWIDTH-1:0] in_data,
    input in_valid, in_write,
    output reg in_ready,
    output reg [AWIDTH-1:0] out_addr,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid, out_write,
    input out_ready
);

    // 重映射表配置
    parameter [AWIDTH-1:0] REMAP_BASE0 = 32'h1000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE0 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST0 = 32'h2000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE1 = 32'h2000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE1 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST1 = 32'h3000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE2 = 32'h3000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE2 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST2 = 32'h4000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE3 = 32'h4000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE3 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST3 = 32'h5000_0000;

    // 流水线寄存器
    reg [AWIDTH-1:0] addr_stage1;
    reg [DWIDTH-1:0] data_stage1;
    reg write_stage1, valid_stage1;
    reg [AWIDTH-1:0] remapped_addr_stage1;

    // 地址范围检查流水线
    wire [3:0] addr_in_range;
    wire [AWIDTH-1:0] offset [0:3];
    wire [AWIDTH-1:0] remapped_addr [0:3];

    // 第一阶段：地址范围检查
    assign addr_in_range[0] = (in_addr >= REMAP_BASE0) && (in_addr < (REMAP_BASE0 + REMAP_SIZE0));
    assign addr_in_range[1] = (in_addr >= REMAP_BASE1) && (in_addr < (REMAP_BASE1 + REMAP_SIZE1));
    assign addr_in_range[2] = (in_addr >= REMAP_BASE2) && (in_addr < (REMAP_BASE2 + REMAP_SIZE2));
    assign addr_in_range[3] = (in_addr >= REMAP_BASE3) && (in_addr < (REMAP_BASE3 + REMAP_SIZE3));

    // 第二阶段：偏移计算
    assign offset[0] = in_addr - REMAP_BASE0;
    assign offset[1] = in_addr - REMAP_BASE1;
    assign offset[2] = in_addr - REMAP_BASE2;
    assign offset[3] = in_addr - REMAP_BASE3;

    // 第三阶段：重映射地址计算
    assign remapped_addr[0] = REMAP_DEST0 + offset[0];
    assign remapped_addr[1] = REMAP_DEST1 + offset[1];
    assign remapped_addr[2] = REMAP_DEST2 + offset[2];
    assign remapped_addr[3] = REMAP_DEST3 + offset[3];

    // 第四阶段：地址选择
    wire [AWIDTH-1:0] final_remapped_addr;
    assign final_remapped_addr = addr_in_range[0] ? remapped_addr[0] :
                                addr_in_range[1] ? remapped_addr[1] :
                                addr_in_range[2] ? remapped_addr[2] :
                                addr_in_range[3] ? remapped_addr[3] :
                                in_addr;

    // 控制信号
    wire capture_data = in_valid && in_ready;
    wire clear_valid = out_valid && out_ready;

    // 流水线寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            data_stage1 <= 0;
            write_stage1 <= 0;
            valid_stage1 <= 0;
            remapped_addr_stage1 <= 0;
            out_valid <= 0;
            in_ready <= 1;
            out_addr <= 0;
            out_data <= 0;
            out_write <= 0;
        end else begin
            // 流水线第一级
            if (capture_data) begin
                addr_stage1 <= in_addr;
                data_stage1 <= in_data;
                write_stage1 <= in_write;
                valid_stage1 <= 1;
                remapped_addr_stage1 <= final_remapped_addr;
                in_ready <= 0;
            end

            // 流水线第二级
            if (valid_stage1) begin
                out_addr <= remapped_addr_stage1;
                out_data <= data_stage1;
                out_write <= write_stage1;
                out_valid <= 1;
                valid_stage1 <= 0;
            end

            if (clear_valid) begin
                out_valid <= 0;
                in_ready <= 1;
            end
        end
    end
endmodule