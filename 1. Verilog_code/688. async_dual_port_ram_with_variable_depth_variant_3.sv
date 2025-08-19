//SystemVerilog
module async_dual_port_ram_with_variable_depth #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter RAM_DEPTH = 256
)(
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    input wire sub_en,
    input wire [DATA_WIDTH-1:0] sub_a, sub_b,
    output reg [DATA_WIDTH-1:0] sub_result
);

    reg [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];
    wire [DATA_WIDTH-1:0] sub_b_comp;
    wire [DATA_WIDTH:0] sub_temp;
    wire [DATA_WIDTH-1:0] sub_result_next;

    // 补码减法实现
    assign sub_b_comp = ~sub_b + 1'b1;
    assign sub_temp = {1'b0, sub_a} + {1'b0, sub_b_comp};
    assign sub_result_next = sub_en ? sub_temp[DATA_WIDTH-1:0] : {DATA_WIDTH{1'b0}};

    // RAM读写逻辑
    always @* begin
        if (we_a) ram[addr_a] = din_a;
        if (we_b) ram[addr_b] = din_b;
        dout_a = ram[addr_a];
        dout_b = ram[addr_b];
    end

    // 减法结果输出
    always @* begin
        sub_result = sub_result_next;
    end

endmodule