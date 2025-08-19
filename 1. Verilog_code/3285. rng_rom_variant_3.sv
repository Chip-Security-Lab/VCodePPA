//SystemVerilog
// Top-level module: rng_rom_5
module rng_rom_5(
    input            clk,
    input            rst,
    input            en,
    output [7:0]     rand_out
);
    // Internal signal declarations
    wire [4:0]       addr_next;
    wire [4:0]       addr;
    wire [7:0]       mem_data;

    // Address generation submodule
    rng_rom_5_addr_gen u_addr_gen (
        .clk      (clk),
        .rst      (rst),
        .en       (en),
        .addr     (addr),
        .addr_next(addr_next)
    );

    // ROM memory submodule
    rng_rom_5_rom u_rom (
        .clk      (clk),
        .addr     (addr_next),
        .data     (mem_data)
    );

    // Output register submodule
    rng_rom_5_out_reg u_out_reg (
        .clk      (clk),
        .data_in  (mem_data),
        .rand_out (rand_out)
    );

endmodule

// Submodule: rng_rom_5_addr_gen
// Purpose: Generates address for ROM based on enable and reset, balanced logic
module rng_rom_5_addr_gen(
    input         clk,
    input         rst,
    input         en,
    output reg [4:0] addr,
    output     [4:0] addr_next
);
    wire [4:0] addr_inc;
    assign addr_inc = addr + 5'd1;
    assign addr_next = rst ? 5'd0 : (en ? addr_inc : addr);

    always @(posedge clk) begin
        if (rst)
            addr <= 5'd0;
        else if (en)
            addr <= addr_inc;
    end
endmodule

// Submodule: rng_rom_5_rom
// Purpose: 32x8 ROM, outputs data based on address
module rng_rom_5_rom(
    input         clk,
    input  [4:0]  addr,
    output reg [7:0] data
);
    reg [7:0] mem[0:31];
    initial begin
        mem[0]  = 8'hAF; mem[1]  = 8'h3C;
        mem[2]  = 8'h77; mem[3]  = 8'h12;
        mem[4]  = 8'h56; mem[5]  = 8'h9B;
        mem[6]  = 8'hE3; mem[7]  = 8'h21;
        mem[8]  = 8'h44; mem[9]  = 8'h8D;
        mem[10] = 8'h6A; mem[11] = 8'hC1;
        mem[12] = 8'h35; mem[13] = 8'hF2;
        mem[14] = 8'h7B; mem[15] = 8'h0E;
        mem[16] = 8'hD4; mem[17] = 8'hA8;
        mem[18] = 8'h5C; mem[19] = 8'h13;
        mem[20] = 8'hB7; mem[21] = 8'h2F;
        mem[22] = 8'h90; mem[23] = 8'h6D;
        mem[24] = 8'hC8; mem[25] = 8'h41;
        mem[26] = 8'h3A; mem[27] = 8'hF9;
        mem[28] = 8'h85; mem[29] = 8'h17;
        mem[30] = 8'h62; mem[31] = 8'hB0;
    end

    always @(posedge clk) begin
        data <= mem[addr];
    end
endmodule

// Submodule: rng_rom_5_out_reg
// Purpose: Registers ROM output to rand_out
module rng_rom_5_out_reg(
    input         clk,
    input  [7:0]  data_in,
    output reg [7:0] rand_out
);
    always @(posedge clk) begin
        rand_out <= data_in;
    end
endmodule