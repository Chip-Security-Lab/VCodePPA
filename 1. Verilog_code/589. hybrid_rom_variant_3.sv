//SystemVerilog
module hybrid_rom (
    input clk,
    input we,
    input [3:0] addr,
    input [7:0] din,
    output reg [7:0] data
);
    reg [7:0] rom [0:7];
    reg [7:0] ram [8:15];
    
    // Pipeline stage 1 signals
    reg [3:0] addr_stage1;
    reg we_stage1;
    reg [7:0] din_stage1;
    reg is_rom_stage1;
    
    // Pipeline stage 2 signals
    reg [7:0] rom_data_stage2;
    reg [7:0] ram_data_stage2;
    reg [3:0] addr_stage2;
    reg we_stage2;
    reg [7:0] din_stage2;
    reg is_rom_stage2;
    
    // Pipeline stage 3 signals
    reg [7:0] data_stage3;
    reg [3:0] addr_stage3;
    reg we_stage3;
    reg [7:0] din_stage3;
    reg is_rom_stage3;
    reg [7:0] rom_data_stage3;
    reg [7:0] ram_data_stage3;

    initial begin
        rom[0] = 8'hEE; rom[1] = 8'hFF;
    end

    // Stage 1: Address decoding
    always @(posedge clk) begin
        addr_stage1 <= addr;
        we_stage1 <= we;
        din_stage1 <= din;
        is_rom_stage1 <= (addr < 8);
    end

    // Stage 2: Memory read
    always @(posedge clk) begin
        addr_stage2 <= addr_stage1;
        we_stage2 <= we_stage1;
        din_stage2 <= din_stage1;
        is_rom_stage2 <= is_rom_stage1;
        
        if (addr_stage1 < 8) begin
            rom_data_stage2 <= rom[addr_stage1];
        end else begin
            ram_data_stage2 <= ram[addr_stage1];
        end
    end

    // Stage 3: Memory write and data selection
    always @(posedge clk) begin
        addr_stage3 <= addr_stage2;
        we_stage3 <= we_stage2;
        din_stage3 <= din_stage2;
        is_rom_stage3 <= is_rom_stage2;
        rom_data_stage3 <= rom_data_stage2;
        ram_data_stage3 <= ram_data_stage2;
        
        if (is_rom_stage2) begin
            data_stage3 <= rom_data_stage2;
        end else if (we_stage2) begin
            ram[addr_stage2] <= din_stage2;
            data_stage3 <= din_stage2;
        end else begin
            data_stage3 <= ram_data_stage2;
        end
    end

    // Stage 4: Output register
    always @(posedge clk) begin
        data <= data_stage3;
    end
endmodule