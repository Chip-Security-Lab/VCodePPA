//SystemVerilog
module rng_rom_5_pipeline (
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rand_out,
    output reg       rand_valid
);

    // ROM declaration
    reg [7:0] mem [0:31];

    // Stage 1: Address generation and enable pipelining
    reg [4:0] addr_stage1;
    reg       en_stage1;
    reg       flush_stage1;

    // Stage 2: ROM read
    reg [4:0] addr_stage2;
    reg [7:0] rom_data_stage2;
    reg       en_stage2;
    reg       flush_stage2;

    // Stage 3: Output register
    reg [7:0] rand_data_stage3;
    reg       en_stage3;
    reg       flush_stage3;

    // ROM initialization
    initial begin
        mem[0]  = 8'hAF; mem[1]  = 8'h3C;
        mem[2]  = 8'h77; mem[3]  = 8'h12;
        mem[4]  = 8'h55; mem[5]  = 8'hA1;
        mem[6]  = 8'h23; mem[7]  = 8'hB4;
        mem[8]  = 8'h98; mem[9]  = 8'hC3;
        mem[10] = 8'h6E; mem[11] = 8'h1F;
        mem[12] = 8'hD4; mem[13] = 8'hE2;
        mem[14] = 8'h35; mem[15] = 8'h0A;
        mem[16] = 8'hF1; mem[17] = 8'h9B;
        mem[18] = 8'h7C; mem[19] = 8'h60;
        mem[20] = 8'h42; mem[21] = 8'hD9;
        mem[22] = 8'h8E; mem[23] = 8'h2C;
        mem[24] = 8'hB7; mem[25] = 8'h11;
        mem[26] = 8'hA8; mem[27] = 8'h5D;
        mem[28] = 8'hC6; mem[29] = 8'h74;
        mem[30] = 8'h03; mem[31] = 8'hE7;
    end

    // Stage 1: Address generation and enable pipelining
    always @(posedge clk) begin
        if (rst) begin
            addr_stage1  <= 5'd0;
            en_stage1    <= 1'b0;
            flush_stage1 <= 1'b1;
        end else begin
            if (en) begin
                addr_stage1  <= addr_stage1 + 1'b1;
                en_stage1    <= 1'b1;
                flush_stage1 <= 1'b0;
            end else begin
                addr_stage1  <= addr_stage1;
                en_stage1    <= 1'b0;
                flush_stage1 <= 1'b1; // Flush if not enabled
            end
        end
    end

    // Stage 2: ROM read and enable pipelining
    always @(posedge clk) begin
        if (rst) begin
            addr_stage2    <= 5'd0;
            rom_data_stage2<= 8'd0;
            en_stage2      <= 1'b0;
            flush_stage2   <= 1'b1;
        end else begin
            addr_stage2      <= addr_stage1;
            rom_data_stage2  <= mem[addr_stage1];
            en_stage2        <= en_stage1;
            flush_stage2     <= flush_stage1;
        end
    end

    // Stage 3: Output register and enable pipelining
    always @(posedge clk) begin
        if (rst) begin
            rand_data_stage3 <= 8'd0;
            en_stage3        <= 1'b0;
            flush_stage3     <= 1'b1;
        end else begin
            rand_data_stage3 <= rom_data_stage2;
            en_stage3        <= en_stage2;
            flush_stage3     <= flush_stage2;
        end
    end

    // Output logic with valid signal
    always @(posedge clk) begin
        if (rst) begin
            rand_out   <= 8'd0;
            rand_valid <= 1'b0;
        end else if (en_stage3 && !flush_stage3) begin
            rand_out   <= rand_data_stage3;
            rand_valid <= 1'b1;
        end else begin
            rand_out   <= rand_out;
            rand_valid <= 1'b0;
        end
    end

endmodule