//SystemVerilog
module sync_dual_port_ram_with_data_hold #(
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
    
    // Stage 1 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage1, addr_b_stage1;
    reg we_a_stage1, we_b_stage1;
    reg [DATA_WIDTH-1:0] din_a_stage1, din_b_stage1;
    
    // Stage 2 registers
    reg [ADDR_WIDTH-1:0] addr_a_stage2, addr_b_stage2;
    reg [DATA_WIDTH-1:0] ram_data_a_stage2, ram_data_b_stage2;
    reg addr_changed_a_stage2, addr_changed_b_stage2;
    
    // Stage 3 registers
    reg [DATA_WIDTH-1:0] dout_a_stage3, dout_b_stage3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Stage 1 reset
            addr_a_stage1 <= 0;
            addr_b_stage1 <= 0;
            we_a_stage1 <= 0;
            we_b_stage1 <= 0;
            din_a_stage1 <= 0;
            din_b_stage1 <= 0;
            
            // Stage 2 reset
            addr_a_stage2 <= 0;
            addr_b_stage2 <= 0;
            ram_data_a_stage2 <= 0;
            ram_data_b_stage2 <= 0;
            addr_changed_a_stage2 <= 0;
            addr_changed_b_stage2 <= 0;
            
            // Stage 3 reset
            dout_a_stage3 <= 0;
            dout_b_stage3 <= 0;
            dout_a <= 0;
            dout_b <= 0;
        end else begin
            // Stage 1: Input buffering
            addr_a_stage1 <= addr_a;
            addr_b_stage1 <= addr_b;
            we_a_stage1 <= we_a;
            we_b_stage1 <= we_b;
            din_a_stage1 <= din_a;
            din_b_stage1 <= din_b;
            
            // Stage 2: RAM access and address change detection
            addr_a_stage2 <= addr_a_stage1;
            addr_b_stage2 <= addr_b_stage1;
            addr_changed_a_stage2 <= (addr_a_stage1 != addr_a_stage2);
            addr_changed_b_stage2 <= (addr_b_stage1 != addr_b_stage2);
            
            // Write operations
            if (we_a_stage1) ram[addr_a_stage1] <= din_a_stage1;
            if (we_b_stage1) ram[addr_b_stage1] <= din_b_stage1;
            
            // Read operations
            if (addr_changed_a_stage2) begin
                ram_data_a_stage2 <= ram[addr_a_stage2];
            end
            
            if (addr_changed_b_stage2) begin
                ram_data_b_stage2 <= ram[addr_b_stage2];
            end
            
            // Stage 3: Output buffering
            dout_a_stage3 <= ram_data_a_stage2;
            dout_b_stage3 <= ram_data_b_stage2;
            dout_a <= dout_a_stage3;
            dout_b <= dout_b_stage3;
        end
    end
endmodule