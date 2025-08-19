//SystemVerilog
module sync_dual_port_ram_with_enable #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire en,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] ram_a_reg_stage1, ram_b_reg_stage1;
    reg [DATA_WIDTH-1:0] ram_a_reg_stage2, ram_b_reg_stage2;
    reg en_stage1, en_stage2;
    reg we_a_stage1, we_b_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    wire [DATA_WIDTH-1:0] ram_a_next, ram_b_next;
    wire write_en_a, write_en_b;

    // Stage 1: Address and Control Pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            en_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
        end else begin
            en_stage1 <= en;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
        end
    end

    // Stage 2: RAM Access Pipeline
    assign write_en_a = en_stage1 & we_a_stage1;
    assign write_en_b = en_stage1 & we_b_stage1;
    assign ram_a_next = ram[addr_a_stage1];
    assign ram_b_next = ram[addr_b_stage1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_a_reg_stage1 <= 0;
            ram_b_reg_stage1 <= 0;
            en_stage2 <= 0;
        end else begin
            ram_a_reg_stage1 <= ram_a_next;
            ram_b_reg_stage1 <= ram_b_next;
            en_stage2 <= en_stage1;
            if (write_en_a) ram[addr_a_stage1] <= din_a_stage1;
            if (write_en_b) ram[addr_b_stage1] <= din_b_stage1;
        end
    end

    // Stage 3: Output Pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_a_reg_stage2 <= 0;
            ram_b_reg_stage2 <= 0;
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            ram_a_reg_stage2 <= ram_a_reg_stage1;
            ram_b_reg_stage2 <= ram_b_reg_stage1;
            dout_a <= en_stage2 ? ram_a_reg_stage2 : dout_a;
            dout_b <= en_stage2 ? ram_b_reg_stage2 : dout_b;
        end
    end
endmodule