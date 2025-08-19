module tdp_ram_cam #(
    parameter DW = 24,
    parameter AW = 6,
    parameter TAG_WIDTH = 16
)(
    input clk,
    // RAM接口
    input [AW-1:0] ram_addr,
    input [DW-1:0] ram_din,
    output reg [DW-1:0] ram_dout,
    input ram_we,
    // CAM接口
    input [TAG_WIDTH-1:0] cam_tag,
    output reg [AW-1:0] cam_match_addr,
    output reg cam_match
);

reg [DW-1:0] mem [0:(1<<AW)-1];
reg [TAG_WIDTH-1:0] tag_table [0:(1<<AW)-1];
integer i;

// RAM操作
always @(posedge clk) begin
    if (ram_we) begin
        mem[ram_addr] <= ram_din;
        tag_table[ram_addr] <= ram_din[DW-1:DW-TAG_WIDTH];
    end
    ram_dout <= mem[ram_addr];
end

// CAM搜索
always @(posedge clk) begin
    cam_match <= 0;
    for (i=0; i<(1<<AW); i=i+1) begin
        if (tag_table[i] == cam_tag) begin
            cam_match <= 1;
            cam_match_addr <= i;
        end
    end
end
endmodule