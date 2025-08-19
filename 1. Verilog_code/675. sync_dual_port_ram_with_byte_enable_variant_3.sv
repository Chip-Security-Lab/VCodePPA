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

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;
    reg [DATA_WIDTH/8-1:0] byte_en_a_stage1, byte_en_b_stage1;
    reg [DATA_WIDTH/8-1:0] byte_en_a_stage2, byte_en_b_stage2;
    reg we_a_stage1, we_b_stage1;
    reg we_a_stage2, we_b_stage2;
    reg [DATA_WIDTH-1:0] ram_data_a_stage1, ram_data_b_stage1;
    reg [DATA_WIDTH-1:0] ram_data_a_stage2, ram_data_b_stage2;
    reg [DATA_WIDTH-1:0] ram_data_a_stage3, ram_data_b_stage3;
    integer i;

    // Stage 1: Input Latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            byte_en_a_stage1 <= 0;
            byte_en_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            byte_en_a_stage1 <= byte_en_a;
            byte_en_b_stage1 <= byte_en_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
        end
    end

    // Stage 2: RAM Read and Write Data Latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
            byte_en_a_stage2 <= 0;
            byte_en_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            ram_data_a_stage1 <= 0;
            ram_data_b_stage1 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            byte_en_a_stage2 <= byte_en_a_stage1;
            byte_en_b_stage2 <= byte_en_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            ram_data_a_stage1 <= ram[addr_a_stage1];
            ram_data_b_stage1 <= ram[addr_b_stage1];
        end
    end

    // Stage 3: Write Operation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a_stage2 <= 0;
            ram_data_b_stage2 <= 0;
        end else begin
            if (we_a_stage2) begin
                for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
                    if (byte_en_a_stage2[i]) 
                        ram[addr_a_stage2][i*8 +: 8] <= din_a_stage2[i*8 +: 8];
                end
            end
            if (we_b_stage2) begin
                for (i = 0; i < DATA_WIDTH/8; i = i + 1) begin
                    if (byte_en_b_stage2[i]) 
                        ram[addr_b_stage2][i*8 +: 8] <= din_b_stage2[i*8 +: 8];
                end
            end
            ram_data_a_stage2 <= ram_data_a_stage1;
            ram_data_b_stage2 <= ram_data_b_stage1;
        end
    end

    // Stage 4: Output Latch
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
            ram_data_a_stage3 <= 0;
            ram_data_b_stage3 <= 0;
        end else begin
            ram_data_a_stage3 <= ram_data_a_stage2;
            ram_data_b_stage3 <= ram_data_b_stage2;
            dout_a <= ram_data_a_stage3;
            dout_b <= ram_data_b_stage3;
        end
    end
endmodule