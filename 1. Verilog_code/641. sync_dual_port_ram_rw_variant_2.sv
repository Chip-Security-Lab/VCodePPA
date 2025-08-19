//SystemVerilog
module sync_dual_port_ram_rw #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire sub_en,
    input wire [DATA_WIDTH-1:0] sub_a, sub_b,
    output reg [DATA_WIDTH-1:0] sub_result_a, sub_result_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH:0] borrow_a, borrow_b;
    reg [DATA_WIDTH-1:0] temp_a, temp_b;
    integer i;

    // RAM写操作
    always @(posedge clk) begin
        if (we_a) ram[addr_a] <= din_a;
        if (we_b) ram[addr_b] <= din_b;
    end

    // RAM读操作
    always @(posedge clk) begin
        dout_a <= ram[addr_a];
        dout_b <= ram[addr_b];
    end

    // 端口A减法器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sub_result_a <= 0;
        end else if (sub_en) begin
            borrow_a[0] = 0;
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                temp_a[i] = sub_a[i] ^ sub_b[i] ^ borrow_a[i];
                borrow_a[i+1] = (~sub_a[i] & sub_b[i]) | ((~sub_a[i] | sub_b[i]) & borrow_a[i]);
            end
            sub_result_a <= temp_a;
        end
    end

    // 端口B减法器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sub_result_b <= 0;
        end else if (sub_en) begin
            borrow_b[0] = 0;
            for (i = 0; i < DATA_WIDTH; i = i + 1) begin
                temp_b[i] = sub_a[i] ^ sub_b[i] ^ borrow_b[i];
                borrow_b[i+1] = (~sub_a[i] & sub_b[i]) | ((~sub_a[i] | sub_b[i]) & borrow_b[i]);
            end
            sub_result_b <= temp_b;
        end
    end

endmodule