//SystemVerilog
module regfile_2r1w_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH      = 32
)(
    // 时钟和复位
    input                        clk,
    input                        rst_n,
    // 写控制接口
    input                        wr_en,
    input      [ADDR_WIDTH-1:0]  wr_addr,
    input      [DATA_WIDTH-1:0]  wr_data,
    // 读取端口0接口
    input      [ADDR_WIDTH-1:0]  rd_addr0,
    output reg [DATA_WIDTH-1:0]  rd_data0,
    // 读取端口1接口
    input      [ADDR_WIDTH-1:0]  rd_addr1,
    output reg [DATA_WIDTH-1:0]  rd_data1
);

    // 寄存器文件存储器
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // 用于读操作的地址寄存器
    reg [ADDR_WIDTH-1:0] rd_addr0_r;
    reg [ADDR_WIDTH-1:0] rd_addr1_r;
    
    // 读写冲突标志
    reg rd0_wr_hazard, rd1_wr_hazard;
    
    // 写入逻辑 - 初始化和写入操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            integer i;
            for (i = 0; i < DEPTH; i = i + 1) begin
                mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end
    
    // 地址寄存和冲突检测
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_addr0_r <= {ADDR_WIDTH{1'b0}};
            rd_addr1_r <= {ADDR_WIDTH{1'b0}};
            rd0_wr_hazard <= 1'b0;
            rd1_wr_hazard <= 1'b0;
        end else begin
            rd_addr0_r <= rd_addr0;
            rd_addr1_r <= rd_addr1;
            rd0_wr_hazard <= wr_en && (rd_addr0 == wr_addr);
            rd1_wr_hazard <= wr_en && (rd_addr1 == wr_addr);
        end
    end
    
    // 读取逻辑 - 带前递处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_data0 <= {DATA_WIDTH{1'b0}};
            rd_data1 <= {DATA_WIDTH{1'b0}};
        end else begin
            rd_data0 <= rd0_wr_hazard ? wr_data : mem[rd_addr0_r];
            rd_data1 <= rd1_wr_hazard ? wr_data : mem[rd_addr1_r];
        end
    end
    
endmodule