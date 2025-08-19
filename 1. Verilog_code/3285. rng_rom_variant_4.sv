//SystemVerilog
module rng_rom_5(
    input            clk,
    input            rst,
    input            en,
    output reg [7:0] rand_out
);
    reg [4:0] addr_stage1;
    reg [4:0] addr_stage2;
    reg [7:0] mem[0:31];
    reg       en_stage1;
    reg       en_stage2;

    initial begin
        mem[0] = 8'hAF; mem[1] = 8'h3C; 
        mem[2] = 8'h77; mem[3] = 8'h12; 
        mem[4] = 8'hD2; mem[5] = 8'h8E; 
        mem[6] = 8'h45; mem[7] = 8'hB1; 
        mem[8] = 8'hE3; mem[9] = 8'h09; 
        mem[10] = 8'hA5; mem[11] = 8'h6C;
        mem[12] = 8'h2F; mem[13] = 8'h34;
        mem[14] = 8'hC7; mem[15] = 8'h81;
        mem[16] = 8'h5A; mem[17] = 8'hF4;
        mem[18] = 8'hBB; mem[19] = 8'h60;
        mem[20] = 8'h13; mem[21] = 8'h99;
        mem[22] = 8'h27; mem[23] = 8'hC2;
        mem[24] = 8'h78; mem[25] = 8'hE6;
        mem[26] = 8'hD8; mem[27] = 8'hB3;
        mem[28] = 8'h4C; mem[29] = 8'h52;
        mem[30] = 8'hFD; mem[31] = 8'hA9;
    end

    // Stage 1: Address update and enable pipeline
    always @(posedge clk) begin
        if(rst) begin
            addr_stage1 <= 5'd0;
            en_stage1   <= 1'b0;
        end else if(en) begin
            addr_stage1 <= addr_stage1 + 1'b1;
            en_stage1   <= 1'b1;
        end else begin
            addr_stage1 <= addr_stage1;
            en_stage1   <= 1'b0;
        end
    end

    // Stage 2: Address pipeline and enable pipeline
    always @(posedge clk) begin
        if(rst) begin
            addr_stage2 <= 5'd0;
            en_stage2   <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            en_stage2   <= en_stage1;
        end
    end

    // Stage 3: Output data pipeline
    always @(posedge clk) begin
        if(rst) begin
            rand_out <= 8'd0;
        end else if(en_stage2) begin
            rand_out <= mem[addr_stage2];
        end
    end

endmodule