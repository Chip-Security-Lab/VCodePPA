//SystemVerilog
module three_level_rom_pipelined (
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg [7:0] data,
    output reg valid
);

    // Pipeline registers
    reg [3:0] addr_stage1;
    reg [3:0] addr_stage2;
    reg [3:0] addr_stage3;
    reg [3:0] addr_stage4;
    reg [7:0] rom_data_stage1;
    reg [7:0] rom_data_stage2;
    reg [7:0] rom_data_stage3;
    reg [7:0] cache_data_stage2;
    reg [7:0] cache_data_stage3;
    reg [7:0] cache_data_stage4;
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    reg valid_stage4;

    // Storage elements
    reg [7:0] cache [0:3];
    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'h77; rom[1] = 8'h88;
    end

    // Stage 1: Address decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= 1'b1;
        end
    end

    // Stage 2: ROM access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage2 <= 4'b0;
            rom_data_stage1 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            addr_stage2 <= addr_stage1;
            rom_data_stage1 <= rom[addr_stage1];
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Cache address preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage3 <= 4'b0;
            rom_data_stage2 <= 8'b0;
            valid_stage3 <= 1'b0;
        end else begin
            addr_stage3 <= addr_stage2;
            rom_data_stage2 <= rom_data_stage1;
            valid_stage3 <= valid_stage2;
        end
    end

    // Stage 4: Cache access
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage4 <= 4'b0;
            rom_data_stage3 <= 8'b0;
            cache_data_stage2 <= 8'b0;
            valid_stage4 <= 1'b0;
        end else begin
            addr_stage4 <= addr_stage3;
            rom_data_stage3 <= rom_data_stage2;
            cache[addr_stage3[1:0]] <= rom_data_stage2;
            cache_data_stage2 <= cache[addr_stage3[1:0]];
            valid_stage4 <= valid_stage3;
        end
    end

    // Stage 5: Output preparation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cache_data_stage3 <= 8'b0;
            valid <= 1'b0;
        end else begin
            cache_data_stage3 <= cache_data_stage2;
            valid <= valid_stage4;
        end
    end

    // Stage 6: Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'b0;
        end else begin
            data <= cache_data_stage3;
        end
    end

endmodule