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

    // RAM memory array
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;
    
    // Pipeline stage 2 registers
    reg [DATA_WIDTH-1:0] ram_data_a_stage2, ram_data_b_stage2;
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg we_a_stage2, we_b_stage2;
    reg [DATA_WIDTH-1:0] din_a_stage2, din_b_stage2;

    // Stage 1: Address and control signal registration
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

    // Stage 2: RAM read and write with two's complement subtraction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ram_data_a_stage2 <= 0;
            ram_data_b_stage2 <= 0;
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            din_a_stage2 <= 0;
            din_b_stage2 <= 0;
        end else begin
            // Read data from RAM
            ram_data_a_stage2 <= ram[addr_a_stage1];
            ram_data_b_stage2 <= ram[addr_b_stage1];
            
            // Forward control signals
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            din_a_stage2 <= din_a_stage1;
            din_b_stage2 <= din_b_stage1;
            
            // Write to RAM if enabled using two's complement subtraction
            if (we_a_stage1) begin
                ram[addr_a_stage1] <= ~din_a_stage1 + 1'b1; // Two's complement
            end
            if (we_b_stage1) begin
                ram[addr_b_stage1] <= ~din_b_stage1 + 1'b1; // Two's complement
            end
        end
    end

    // Stage 3: Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            // Forward data to output
            dout_a <= ram_data_a_stage2;
            dout_b <= ram_data_b_stage2;
            
            // Handle write-through case
            if (we_a_stage2 && addr_a_stage2 == addr_a_stage1)
                dout_a <= ~din_a_stage2 + 1'b1; // Two's complement
            if (we_b_stage2 && addr_b_stage2 == addr_b_stage1)
                dout_b <= ~din_b_stage2 + 1'b1; // Two's complement
        end
    end

endmodule