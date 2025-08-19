//SystemVerilog
module bram_rom (
    input wire clk,
    input wire rst_n,
    input wire [3:0] addr,
    output reg [7:0] data_out
);
    // Stage 1: Address Registration
    reg [3:0] addr_reg;
    
    // Stage 2: Memory Definition and Pipeline Structure
    (* ram_style = "block" *) reg [7:0] rom_memory [0:15]; // Block RAM specification
    reg [7:0] data_reg;
    
    // ROM Initialization
    initial begin
        // Data values initialization
        rom_memory[0] = 8'h12; rom_memory[1] = 8'h34; rom_memory[2] = 8'h56; rom_memory[3] = 8'h78;
        rom_memory[4] = 8'h9A; rom_memory[5] = 8'hBC; rom_memory[6] = 8'hDE; rom_memory[7] = 8'hF0;
        rom_memory[8] = 8'h00; rom_memory[9] = 8'h11; rom_memory[10] = 8'h22; rom_memory[11] = 8'h33;
        rom_memory[12] = 8'h44; rom_memory[13] = 8'h55; rom_memory[14] = 8'h66; rom_memory[15] = 8'h77;
    end
    
    // Stage 1: Address Input Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 4'b0;
        end else begin
            addr_reg <= addr;
        end
    end
    
    // Stage 2: Memory Access Pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
        end else begin
            data_reg <= rom_memory[addr_reg];
        end
    end
    
    // Stage 3: Output Registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            data_out <= data_reg;
        end
    end
endmodule