//SystemVerilog
module three_level_rom_pipelined (
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg [7:0] data,
    output reg valid
);
    // Stage 1: Address Decode
    reg [3:0] addr_stage1;
    reg valid_stage1;
    
    // Stage 2: ROM Access
    reg [7:0] rom_data_stage2;
    reg [3:0] addr_stage2;
    reg valid_stage2;
    
    // Stage 3: Cache Access
    reg [7:0] cache [0:3];
    reg [7:0] rom [0:15];
    reg [7:0] data_stage3;
    reg valid_stage3;

    initial begin
        rom[0] = 8'h77; rom[1] = 8'h88;
    end

    // Stage 1: Address Latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: ROM Access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage2 <= 8'b0;
            addr_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end else begin
            rom_data_stage2 <= rom[addr_stage1];
            addr_stage2 <= addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Cache Update and Data Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cache[0] <= 8'b0;
            cache[1] <= 8'b0;
            cache[2] <= 8'b0;
            cache[3] <= 8'b0;
            data_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                cache[addr_stage2[1:0]] <= rom_data_stage2;
                data_stage3 <= cache[addr_stage2[1:0]];
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // Output Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
            valid <= 1'b0;
        end else begin
            data <= data_stage3;
            valid <= valid_stage3;
        end
    end
endmodule