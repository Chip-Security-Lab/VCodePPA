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
    // 重映射表 - 使用参数而非initial块
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
    
    wire [AWIDTH-1:0] remapped_addr;
    reg [1:0] region;
    reg in_region;
    reg [AWIDTH-1:0] region_base, region_dest;
    wire [AWIDTH-1:0] offset;
    
    // 通过范围比较确定地址区域 - 重构为更清晰的case语句
    always @(*) begin
        case (in_addr[31:24])
            8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17,
            8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F: region = 2'd0; // 0x10xxxxxx
            8'h20, 8'h21, 8'h22, 8'h23, 8'h24, 8'h25, 8'h26, 8'h27,
            8'h28, 8'h29, 8'h2A, 8'h2B, 8'h2C, 8'h2D, 8'h2E, 8'h2F: region = 2'd1; // 0x20xxxxxx
            8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37,
            8'h38, 8'h39, 8'h3A, 8'h3B, 8'h3C, 8'h3D, 8'h3E, 8'h3F: region = 2'd2; // 0x30xxxxxx
            8'h40, 8'h41, 8'h42, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47,
            8'h48, 8'h49, 8'h4A, 8'h4B, 8'h4C, 8'h4D, 8'h4E, 8'h4F: region = 2'd3; // 0x40xxxxxx
            default: region = 2'd0; // 默认值，不影响结果
        endcase
    end
    
    // 检查是否在有效区域内 - 重构为结构化的if-else
    always @(*) begin
        if (in_addr >= REMAP_BASE0 && in_addr < (REMAP_BASE0 + REMAP_SIZE0)) begin
            in_region = 1'b1;
        end else if (in_addr >= REMAP_BASE1 && in_addr < (REMAP_BASE1 + REMAP_SIZE1)) begin
            in_region = 1'b1;
        end else if (in_addr >= REMAP_BASE2 && in_addr < (REMAP_BASE2 + REMAP_SIZE2)) begin
            in_region = 1'b1;
        end else if (in_addr >= REMAP_BASE3 && in_addr < (REMAP_BASE3 + REMAP_SIZE3)) begin
            in_region = 1'b1;
        end else begin
            in_region = 1'b0;
        end
    end
    
    // 多路选择器，选择相应的基地址和目标地址 - 重构为case语句
    always @(*) begin
        case (region)
            2'd0: begin
                region_base = REMAP_BASE0;
                region_dest = REMAP_DEST0;
            end
            2'd1: begin
                region_base = REMAP_BASE1;
                region_dest = REMAP_DEST1;
            end
            2'd2: begin
                region_base = REMAP_BASE2;
                region_dest = REMAP_DEST2;
            end
            2'd3: begin
                region_base = REMAP_BASE3;
                region_dest = REMAP_DEST3;
            end
            default: begin
                region_base = REMAP_BASE0;
                region_dest = REMAP_DEST0;
            end
        endcase
    end
    
    // 计算偏移量
    assign offset = in_addr - region_base;
    
    // 仅在有效区域内进行重映射
    assign remapped_addr = in_region ? (region_dest + offset) : in_addr;
    
    // 控制状态机
    localparam IDLE = 1'b0, BUSY = 1'b1;
    reg state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            in_ready <= 1'b1;
            out_addr <= {AWIDTH{1'b0}};
            out_data <= {DWIDTH{1'b0}};
            out_write <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (in_valid) begin
                        out_data <= in_data;
                        out_write <= in_write;
                        out_valid <= 1'b1;
                        in_ready <= 1'b0;
                        out_addr <= remapped_addr;
                        state <= BUSY;
                    end
                end
                BUSY: begin
                    if (out_ready) begin
                        out_valid <= 1'b0;
                        in_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule