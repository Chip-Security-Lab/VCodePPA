//SystemVerilog
module tdp_ram_cam #(
    parameter DW = 24,
    parameter AW = 6,
    parameter TAG_WIDTH = 16,
    parameter FANOUT_CLUSTER_SIZE = 16 // 每个缓冲区驱动的目标数量
)(
    input clk,
    input [AW-1:0] ram_addr,
    input [DW-1:0] ram_din,
    output reg [DW-1:0] ram_dout,
    input ram_we,
    input [TAG_WIDTH-1:0] cam_tag,
    output reg [AW-1:0] cam_match_addr,
    output reg cam_match
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [TAG_WIDTH-1:0] tag_table [0:(1<<AW)-1];

reg [AW-1:0] ram_addr_stage1;
reg [DW-1:0] ram_din_stage1;
reg ram_we_stage1;
reg [TAG_WIDTH-1:0] cam_tag_stage1;
reg [AW-1:0] cam_match_addr_stage1;
reg cam_match_stage1;

// 为高扇出信号添加多级缓冲区
reg [TAG_WIDTH-1:0] tag_table_stage2 [0:(1<<AW)-1];
reg [TAG_WIDTH-1:0] tag_table_buf[0:((1<<AW)-1)/FANOUT_CLUSTER_SIZE]; // 一级缓冲

// 将长数组分块，缩短关键路径
reg [TAG_WIDTH-1:0] tag_table_cluster[0:(1<<AW)/FANOUT_CLUSTER_SIZE-1][0:FANOUT_CLUSTER_SIZE-1];
reg [(1<<AW)/FANOUT_CLUSTER_SIZE-1:0] cluster_match;
reg [AW-1:0] cluster_match_addr[0:(1<<AW)/FANOUT_CLUSTER_SIZE-1];

reg [AW-1:0] cam_match_addr_stage2;
reg cam_match_stage2;

// 条件反相减法器相关信号
reg [TAG_WIDTH-1:0] tag_diff [0:(1<<AW)-1];
reg [TAG_WIDTH-1:0] tag_comp [0:(1<<AW)-1];
reg [TAG_WIDTH-1:0] tag_borrow [0:(1<<AW)-1];

always @(posedge clk) begin
    ram_addr_stage1 <= ram_addr;
    ram_din_stage1 <= ram_din;
    ram_we_stage1 <= ram_we;
    cam_tag_stage1 <= cam_tag;
end

always @(posedge clk) begin
    if (ram_we_stage1) begin
        mem[ram_addr_stage1] <= ram_din_stage1;
        tag_table[ram_addr_stage1] <= ram_din_stage1[DW-1:DW-TAG_WIDTH];
    end
    ram_dout <= mem[ram_addr_stage1];
    
    // 将tag_table分段加载到缓冲区
    for (integer i=0; i<((1<<AW)-1)/FANOUT_CLUSTER_SIZE+1; i=i+1) begin
        tag_table_buf[i] <= tag_table[i*FANOUT_CLUSTER_SIZE]; // 加载代表性元素
    end
    
    // 从tag_table加载到stage2，避免直接高扇出
    for (integer i=0; i<(1<<AW); i=i+1) begin
        tag_table_stage2[i] <= tag_table[i];
    end
end

// 添加一个周期用于加载tag_table到分块缓冲区
always @(posedge clk) begin
    for (integer i=0; i<(1<<AW)/FANOUT_CLUSTER_SIZE; i=i+1) begin
        for (integer j=0; j<FANOUT_CLUSTER_SIZE; j=j+1) begin
            if (i*FANOUT_CLUSTER_SIZE+j < (1<<AW)) begin
                tag_table_cluster[i][j] <= tag_table_stage2[i*FANOUT_CLUSTER_SIZE+j];
            end
        end
    end
end

// 按簇进行比较，降低关键路径长度
always @(posedge clk) begin
    for (integer i=0; i<(1<<AW)/FANOUT_CLUSTER_SIZE; i=i+1) begin
        cluster_match[i] <= 0;
        cluster_match_addr[i] <= 0;
        
        for (integer j=0; j<FANOUT_CLUSTER_SIZE; j=j+1) begin
            if (i*FANOUT_CLUSTER_SIZE+j < (1<<AW)) begin
                // 条件反相减法器实现
                tag_diff[i*FANOUT_CLUSTER_SIZE+j] = tag_table_cluster[i][j] ^ cam_tag_stage1;
                tag_comp[i*FANOUT_CLUSTER_SIZE+j] = ~tag_table_cluster[i][j];
                tag_borrow[i*FANOUT_CLUSTER_SIZE+j] = (tag_comp[i*FANOUT_CLUSTER_SIZE+j] + 1) & cam_tag_stage1;
                
                if (tag_diff[i*FANOUT_CLUSTER_SIZE+j] == 0 && tag_borrow[i*FANOUT_CLUSTER_SIZE+j] == 0) begin
                    cluster_match[i] <= 1;
                    cluster_match_addr[i] <= i*FANOUT_CLUSTER_SIZE+j;
                end
            end
        end
    end
end

// 合并簇匹配结果
always @(posedge clk) begin
    cam_match_stage2 <= 0;
    cam_match_addr_stage2 <= 0;
    
    for (integer i=0; i<(1<<AW)/FANOUT_CLUSTER_SIZE; i=i+1) begin
        if (cluster_match[i]) begin
            cam_match_stage2 <= 1;
            cam_match_addr_stage2 <= cluster_match_addr[i];
        end
    end
end

always @(posedge clk) begin
    cam_match <= cam_match_stage2;
    cam_match_addr <= cam_match_addr_stage2;
end

endmodule