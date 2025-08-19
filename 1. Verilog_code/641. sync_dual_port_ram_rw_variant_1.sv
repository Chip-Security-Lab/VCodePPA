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
    output reg [DATA_WIDTH-1:0] dout_a, dout_b
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg [DATA_WIDTH-1:0] ram_data_a_stage2, ram_data_b_stage2;

    // Address registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
        end
    end

    // Control signal registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
        end else begin
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
        end
    end

    // Data input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
        end else begin
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
        end
    end

    // RAM write operations
    always @(posedge clk) begin
        if (we_a_stage1) ram[addr_a_stage1] <= din_a_stage1;
        if (we_b_stage1) ram[addr_b_stage1] <= din_b_stage1;
    end

    // RAM read operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            ram_data_a_stage2 <= 0;
            ram_data_b_stage2 <= 0;
        end else begin
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            ram_data_a_stage2 <= ram[addr_a_stage1];
            ram_data_b_stage2 <= ram[addr_b_stage1];
        end
    end

    // Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            dout_a <= ram_data_a_stage2;
            dout_b <= ram_data_b_stage2;
        end
    end

endmodule