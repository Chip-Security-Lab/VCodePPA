//SystemVerilog
module async_dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout_a, dout_b,
    input wire we_a, we_b,
    output reg valid_a, valid_b
);

    // RAM memory array
    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Pipeline stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg valid_a_stage1, valid_b_stage1;
    
    // Pipeline stage 2 registers
    reg [DATA_WIDTH-1:0] ram_out_a_stage2, ram_out_b_stage2;
    reg valid_a_stage2, valid_b_stage2;

    // Stage 1: Address and control signal registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            valid_a_stage1 <= 0;
            valid_b_stage1 <= 0;
        end else begin
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            valid_a_stage1 <= 1'b1;
            valid_b_stage1 <= 1'b1;
        end
    end

    // Write operations (combinational)
    always @(*) begin
        if (we_a_stage1) begin
            ram[addr_a_stage1] = din_a_stage1;
        end
        if (we_b_stage1) begin
            ram[addr_b_stage1] = din_b_stage1;
        end
    end

    // Stage 2: RAM read and output registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_out_a_stage2 <= 0;
            ram_out_b_stage2 <= 0;
            valid_a_stage2 <= 0;
            valid_b_stage2 <= 0;
        end else begin
            ram_out_a_stage2 <= ram[addr_a_stage1];
            ram_out_b_stage2 <= ram[addr_b_stage1];
            valid_a_stage2 <= valid_a_stage1;
            valid_b_stage2 <= valid_b_stage1;
        end
    end

    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_a <= 0;
            dout_b <= 0;
            valid_a <= 0;
            valid_b <= 0;
        end else begin
            dout_a <= ram_out_a_stage2;
            dout_b <= ram_out_b_stage2;
            valid_a <= valid_a_stage2;
            valid_b <= valid_b_stage2;
        end
    end

endmodule