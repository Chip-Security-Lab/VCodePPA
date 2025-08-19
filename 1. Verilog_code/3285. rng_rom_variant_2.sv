//SystemVerilog
module rng_rom_5(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rand_out
);
    reg [4:0] addr;
    reg [7:0] mem[0:31];

    // ROM initialization
    initial begin
        mem[0] = 8'hAF; mem[1] = 8'h3C; 
        mem[2] = 8'h77; mem[3] = 8'h12; 
        // ... 可自行添加初始化 ...
    end

    // Address reset logic
    // Handles address reset on 'rst'
    always @(posedge clk) begin
        if (rst)
            addr <= 5'd0;
    end

    // Address increment logic
    // Handles address increment on 'en' when not in reset
    always @(posedge clk) begin
        if (!rst && en)
            addr <= addr + 5'd1;
    end

    // Random output logic
    // Handles reading from ROM and output assignment
    always @(posedge clk) begin
        rand_out <= mem[addr];
    end
endmodule