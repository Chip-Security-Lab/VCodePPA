//SystemVerilog
module tdp_ram_cam #(
    parameter DW = 24,
    parameter AW = 6,
    parameter TAG_WIDTH = 16
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
reg [TAG_WIDTH-1:0] tag_comp [0:(1<<AW)-1];
reg [TAG_WIDTH-1:0] tag_comp_result;
integer i;

// RAM操作
always @(posedge clk) begin
    if (ram_we) begin
        mem[ram_addr] <= ram_din;
        tag_table[ram_addr] <= ram_din[DW-1:DW-TAG_WIDTH];
    end
    ram_dout <= mem[ram_addr];
end

// CAM搜索 - 使用补码加法实现减法
always @(posedge clk) begin
    cam_match <= 0;
    for (i=0; i<(1<<AW); i=i+1) begin
        // 计算tag_table[i] + (~cam_tag + 1)的补码加法
        tag_comp[i] = ~cam_tag + 1'b1;  // 计算补码
        tag_comp_result = tag_table[i] + tag_comp[i];  // 执行补码加法
        
        // 检查结果是否为零（表示匹配）
        if (tag_comp_result == 0) begin
            cam_match <= 1;
            cam_match_addr <= i;
        end
    end
end
endmodule