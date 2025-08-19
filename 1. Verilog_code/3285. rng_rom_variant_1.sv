//SystemVerilog
module rng_rom_5(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rand_out
);
    // Stage 1: Address generation
    reg [4:0] addr_stage1;
    reg       en_stage1;

    // Stage 2: Address register for ROM read
    reg [4:0] addr_stage2;
    reg       en_stage2;

    // Stage 3: ROM output register
    reg [7:0] rom_data_stage3;
    reg       en_stage3;

    // ROM memory
    reg [7:0] mem[0:31];
    initial begin
        mem[0] = 8'hAF; mem[1] = 8'h3C;
        mem[2] = 8'h77; mem[3] = 8'h12;
        mem[4] = 8'hB4; mem[5] = 8'hE2;
        mem[6] = 8'h56; mem[7] = 8'h89;
        mem[8] = 8'hCA; mem[9] = 8'h1D;
        mem[10] = 8'h34; mem[11] = 8'hA1;
        mem[12] = 8'hF0; mem[13] = 8'h63;
        mem[14] = 8'h9A; mem[15] = 8'h55;
        mem[16] = 8'hFE; mem[17] = 8'h20;
        mem[18] = 8'hD3; mem[19] = 8'h4B;
        mem[20] = 8'h7E; mem[21] = 8'hC6;
        mem[22] = 8'h11; mem[23] = 8'h90;
        mem[24] = 8'h3F; mem[25] = 8'h88;
        mem[26] = 8'hA9; mem[27] = 8'h62;
        mem[28] = 8'h1C; mem[29] = 8'h75;
        mem[30] = 8'hE7; mem[31] = 8'h4A;
    end

    // Stage 1: Address generation - addr_stage1
    always @(posedge clk) begin
        if (rst) begin
            addr_stage1 <= 5'd0;
        end else if (en) begin
            addr_stage1 <= addr_stage1 + 5'd1;
        end
    end

    // Stage 1: Address generation - en_stage1
    always @(posedge clk) begin
        if (rst) begin
            en_stage1 <= 1'b0;
        end else if (en) begin
            en_stage1 <= 1'b1;
        end else begin
            en_stage1 <= 1'b0;
        end
    end

    // Stage 2: Address pipeline register - addr_stage2
    always @(posedge clk) begin
        if (rst) begin
            addr_stage2 <= 5'd0;
        end else begin
            addr_stage2 <= addr_stage1;
        end
    end

    // Stage 2: Address pipeline register - en_stage2
    always @(posedge clk) begin
        if (rst) begin
            en_stage2 <= 1'b0;
        end else begin
            en_stage2 <= en_stage1;
        end
    end

    // Stage 3: ROM read - rom_data_stage3
    always @(posedge clk) begin
        if (rst) begin
            rom_data_stage3 <= 8'd0;
        end else begin
            rom_data_stage3 <= mem[addr_stage2];
        end
    end

    // Stage 3: ROM read - en_stage3
    always @(posedge clk) begin
        if (rst) begin
            en_stage3 <= 1'b0;
        end else begin
            en_stage3 <= en_stage2;
        end
    end

    // Output register
    always @(posedge clk) begin
        if (rst) begin
            rand_out <= 8'd0;
        end else if (en_stage3) begin
            rand_out <= rom_data_stage3;
        end
    end

endmodule