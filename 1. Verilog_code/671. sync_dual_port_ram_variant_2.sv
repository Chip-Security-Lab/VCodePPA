//SystemVerilog
module sync_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    // Stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;

    // Stage 2 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg [DATA_WIDTH-1:0] ram_data_a_stage2, ram_data_b_stage2;

    // Stage 3 registers
    reg [DATA_WIDTH-1:0] ram_data_a_stage3, ram_data_b_stage3;
    reg [DATA_WIDTH-1:0] write_data_a_stage3, write_data_b_stage3;
    reg write_en_a_stage3, write_en_b_stage3;
    reg [ADDR_WIDTH-1:0] write_addr_a_stage3, write_addr_b_stage3;

    // Stage 4 registers
    reg [DATA_WIDTH-1:0] ram_data_a_stage4, ram_data_b_stage4;

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];

    // Stage 1: Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
        end
    end

    // Stage 2: Address and data propagation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            ram_data_a_stage2 <= 0;
            ram_data_b_stage2 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            ram_data_a_stage2 <= ram[addr_a_stage1];
            ram_data_b_stage2 <= ram[addr_b_stage1];
        end
    end

    // Stage 3: Write control and data preparation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a_stage3 <= 0;
            ram_data_b_stage3 <= 0;
            write_data_a_stage3 <= 0;
            write_data_b_stage3 <= 0;
            write_en_a_stage3 <= 0;
            write_en_b_stage3 <= 0;
            write_addr_a_stage3 <= 0;
            write_addr_b_stage3 <= 0;
        end else begin
            ram_data_a_stage3 <= ram_data_a_stage2;
            ram_data_b_stage3 <= ram_data_b_stage2;
            write_data_a_stage3 <= din_a_stage2;
            write_data_b_stage3 <= din_b_stage2;
            write_en_a_stage3 <= we_a_stage2;
            write_en_b_stage3 <= we_b_stage2;
            write_addr_a_stage3 <= addr_a_stage2;
            write_addr_b_stage3 <= addr_b_stage2;
        end
    end

    // Stage 4: Memory write and read data preparation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a_stage4 <= 0;
            ram_data_b_stage4 <= 0;
        end else begin
            if (write_en_a_stage3) ram[write_addr_a_stage3] <= write_data_a_stage3;
            if (write_en_b_stage3) ram[write_addr_b_stage3] <= write_data_b_stage3;
            ram_data_a_stage4 <= ram_data_a_stage3;
            ram_data_b_stage4 <= ram_data_b_stage3;
        end
    end

    // Stage 5: Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= ram_data_a_stage4;
            dout_b <= ram_data_b_stage4;
        end
    end

endmodule