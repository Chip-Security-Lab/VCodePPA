//SystemVerilog
module sync_dual_port_ram_with_byte_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    input wire [DATA_WIDTH/8-1:0] byte_en_a, byte_en_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg [DATA_WIDTH/8-1:0] byte_en_a_stage1, byte_en_b_stage1;
    reg we_a_stage1, we_b_stage1;
    
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_a, ram_b;
    wire [DATA_WIDTH-1:0] ram_a_next, ram_b_next;
    wire [DATA_WIDTH-1:0] ram_a_mask, ram_b_mask;
    wire [DATA_WIDTH-1:0] ram_a_data, ram_b_data;

    // 地址和数据锁存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            {addr_a_stage1, addr_b_stage1, din_a_stage1, din_b_stage1} <= 0;
            {byte_en_a_stage1, byte_en_b_stage1, we_a_stage1, we_b_stage1} <= 0;
        end else begin
            {addr_a_stage1, addr_b_stage1} <= {addr_a, addr_b};
            {din_a_stage1, din_b_stage1} <= {din_a, din_b};
            {byte_en_a_stage1, byte_en_b_stage1} <= {byte_en_a, byte_en_b};
            {we_a_stage1, we_b_stage1} <= {we_a, we_b};
        end
    end

    // 生成字节掩码
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin : gen_mask
            assign ram_a_mask[i*8 +: 8] = {8{byte_en_a_stage1[i]}};
            assign ram_b_mask[i*8 +: 8] = {8{byte_en_b_stage1[i]}};
        end
    endgenerate

    // 计算写入数据
    assign ram_a_data = ram[addr_a_stage1] & ~ram_a_mask | din_a_stage1 & ram_a_mask;
    assign ram_b_data = ram[addr_b_stage1] & ~ram_b_mask | din_b_stage1 & ram_b_mask;

    // 选择写入数据
    assign ram_a_next = we_a_stage1 ? ram_a_data : ram[addr_a_stage1];
    assign ram_b_next = we_b_stage1 ? ram_b_data : ram[addr_b_stage1];

    // 写操作和读操作
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            if (we_a_stage1) ram[addr_a_stage1] <= ram_a_next;
            if (we_b_stage1) ram[addr_b_stage1] <= ram_b_next;
            dout_a <= ram[addr_a_stage1];
            dout_b <= ram[addr_b_stage1];
        end
    end
endmodule