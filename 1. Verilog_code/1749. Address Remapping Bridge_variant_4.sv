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

    reg [1:0] state;
    localparam IDLE = 2'b00;
    localparam PIPE = 2'b01;
    localparam WAIT = 2'b10;

    reg [AWIDTH-1:0] pipe_addr;
    reg [DWIDTH-1:0] pipe_data;
    reg pipe_valid, pipe_write;
    reg [AWIDTH-1:0] remapped_addr;
    reg [1:0] region_sel;
    reg addr_in_region;

    // 预计算区域边界
    wire [AWIDTH-1:0] region0_end = REMAP_BASE0 + REMAP_SIZE0;
    wire [AWIDTH-1:0] region1_end = REMAP_BASE1 + REMAP_SIZE1;
    wire [AWIDTH-1:0] region2_end = REMAP_BASE2 + REMAP_SIZE2;
    wire [AWIDTH-1:0] region3_end = REMAP_BASE3 + REMAP_SIZE3;

    // 区域检测逻辑
    wire in_region0 = (in_addr >= REMAP_BASE0) && (in_addr < region0_end);
    wire in_region1 = (in_addr >= REMAP_BASE1) && (in_addr < region1_end);
    wire in_region2 = (in_addr >= REMAP_BASE2) && (in_addr < region2_end);
    wire in_region3 = (in_addr >= REMAP_BASE3) && (in_addr < region3_end);

    // 地址偏移计算
    wire [AWIDTH-1:0] offset0 = in_addr - REMAP_BASE0;
    wire [AWIDTH-1:0] offset1 = in_addr - REMAP_BASE1;
    wire [AWIDTH-1:0] offset2 = in_addr - REMAP_BASE2;
    wire [AWIDTH-1:0] offset3 = in_addr - REMAP_BASE3;

    // 流水线阶段1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe_valid <= 1'b0;
            pipe_data <= {DWIDTH{1'b0}};
            pipe_write <= 1'b0;
            pipe_addr <= {AWIDTH{1'b0}};
            region_sel <= 2'b00;
            addr_in_region <= 1'b0;
        end else if (in_valid && in_ready) begin
            pipe_valid <= 1'b1;
            pipe_data <= in_data;
            pipe_write <= in_write;
            pipe_addr <= in_addr;
            
            case ({in_region3, in_region2, in_region1, in_region0})
                4'b0001: begin region_sel <= 2'b00; addr_in_region <= 1'b1; end
                4'b0010: begin region_sel <= 2'b01; addr_in_region <= 1'b1; end
                4'b0100: begin region_sel <= 2'b10; addr_in_region <= 1'b1; end
                4'b1000: begin region_sel <= 2'b11; addr_in_region <= 1'b1; end
                default: begin region_sel <= 2'b00; addr_in_region <= 1'b0; end
            endcase
        end else if (state == PIPE) begin
            pipe_valid <= 1'b0;
        end
    end

    // 流水线阶段2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            remapped_addr <= {AWIDTH{1'b0}};
        end else if (pipe_valid) begin
            if (addr_in_region) begin
                case (region_sel)
                    2'b00: remapped_addr <= REMAP_DEST0 + offset0;
                    2'b01: remapped_addr <= REMAP_DEST1 + offset1;
                    2'b10: remapped_addr <= REMAP_DEST2 + offset2;
                    2'b11: remapped_addr <= REMAP_DEST3 + offset3;
                endcase
            end else begin
                remapped_addr <= pipe_addr;
            end
        end
    end

    // 状态机控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            out_valid <= 1'b0;
            in_ready <= 1'b1;
            out_addr <= {AWIDTH{1'b0}};
            out_data <= {DWIDTH{1'b0}};
            out_write <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (in_valid && in_ready) begin
                        state <= PIPE;
                        in_ready <= 1'b0;
                    end
                end
                PIPE: begin
                    if (pipe_valid) begin
                        state <= WAIT;
                        out_data <= pipe_data;
                        out_write <= pipe_write;
                        out_valid <= 1'b1;
                        out_addr <= remapped_addr;
                    end
                end
                WAIT: begin
                    if (out_valid && out_ready) begin
                        state <= IDLE;
                        out_valid <= 1'b0;
                        in_ready <= 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule