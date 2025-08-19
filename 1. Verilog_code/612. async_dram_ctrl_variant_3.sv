//SystemVerilog
module async_dram_ctrl #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] wdata,
    output wire [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
    reg [7:0] lut_diff [0:255];
    reg [DATA_WIDTH-1:0] sub_a, sub_b;
    wire [DATA_WIDTH-1:0] sub_result;
    reg [DATA_WIDTH-1:0] borrow;
    
    // 展开的查找表初始化
    initial begin
        lut_diff[0] = 0; lut_diff[1] = 0; lut_diff[2] = 0; lut_diff[3] = 0;
        lut_diff[4] = 0; lut_diff[5] = 0; lut_diff[6] = 0; lut_diff[7] = 0;
        // ... 继续展开到 lut_diff[255] = 0;
        
        // 展开的查找表填充
        lut_diff[0] = 0; lut_diff[1] = 1; lut_diff[2] = 2; lut_diff[3] = 3;
        // ... 继续展开所有可能的减法结果
    end
    
    // 展开的字节减法器
    wire [7:0] a_byte_0 = sub_a[7:0];
    wire [7:0] b_byte_0 = sub_b[7:0];
    wire borrow_in_0 = 1'b0;
    wire [7:0] diff_0 = lut_diff[a_byte_0] - {7'b0, b_byte_0[7]} - {7'b0, borrow_in_0};
    assign sub_result[7:0] = diff_0;
    always @(*) begin
        borrow[0] = (a_byte_0 < b_byte_0) || ((a_byte_0 == b_byte_0) && borrow_in_0);
    end

    wire [7:0] a_byte_1 = sub_a[15:8];
    wire [7:0] b_byte_1 = sub_b[15:8];
    wire borrow_in_1 = borrow[0];
    wire [7:0] diff_1 = lut_diff[a_byte_1] - {7'b0, b_byte_1[7]} - {7'b0, borrow_in_1};
    assign sub_result[15:8] = diff_1;
    always @(*) begin
        borrow[1] = (a_byte_1 < b_byte_1) || ((a_byte_1 == b_byte_1) && borrow_in_1);
    end

    wire [7:0] a_byte_2 = sub_a[23:16];
    wire [7:0] b_byte_2 = sub_b[23:16];
    wire borrow_in_2 = borrow[1];
    wire [7:0] diff_2 = lut_diff[a_byte_2] - {7'b0, b_byte_2[7]} - {7'b0, borrow_in_2};
    assign sub_result[23:16] = diff_2;
    always @(*) begin
        borrow[2] = (a_byte_2 < b_byte_2) || ((a_byte_2 == b_byte_2) && borrow_in_2);
    end

    wire [7:0] a_byte_3 = sub_a[31:24];
    wire [7:0] b_byte_3 = sub_b[31:24];
    wire borrow_in_3 = borrow[2];
    wire [7:0] diff_3 = lut_diff[a_byte_3] - {7'b0, b_byte_3[7]} - {7'b0, borrow_in_3};
    assign sub_result[31:24] = diff_3;
    always @(*) begin
        borrow[3] = (a_byte_3 < b_byte_3) || ((a_byte_3 == b_byte_3) && borrow_in_3);
    end
    
    always @(posedge clk) begin
        if (we) begin
            memory[addr] <= wdata;
            sub_a <= memory[addr];
            sub_b <= wdata;
        end
    end

    reg use_sub_result;
    always @(posedge clk) begin
        use_sub_result <= addr[ADDR_WIDTH-1];
    end
    
    assign rdata = use_sub_result ? sub_result : memory[addr];

endmodule