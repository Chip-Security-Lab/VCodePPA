//SystemVerilog
module sync_priority_single_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output reg [DATA_WIDTH-1:0] dout
);

    reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    
    // Pipeline stage 1 registers
    reg we_a_stage1, we_b_stage1;
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    
    // Pipeline stage 2 registers
    reg we_a_stage2, we_b_stage2;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    reg [DATA_WIDTH-1:0] din_stage2;
    reg [DATA_WIDTH-1:0] dout_stage2;

    // Stage 1: Register inputs
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
        end else begin
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
        end
    end

    // Stage 2: Write operation and read address selection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            we_a_stage2 <= 0;
            we_b_stage2 <= 0;
            addr_stage2 <= 0;
            din_stage2 <= 0;
            dout_stage2 <= 0;
        end else begin
            we_a_stage2 <= we_a_stage1;
            we_b_stage2 <= we_b_stage1;
            
            if (we_a_stage1) begin
                addr_stage2 <= addr_a_stage1;
                din_stage2 <= din_a_stage1;
            end else if (we_b_stage1) begin
                addr_stage2 <= addr_b_stage1;
                din_stage2 <= din_b_stage1;
            end
            
            dout_stage2 <= ram[addr_stage2];
        end
    end

    // Stage 3: Write to RAM and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 0;
        end else begin
            if (we_a_stage2 || we_b_stage2) begin
                ram[addr_stage2] <= din_stage2;
            end
            dout <= dout_stage2;
        end
    end
endmodule