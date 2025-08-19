//SystemVerilog
module crc_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    output reg [7:0] data,
    output reg crc_error
);

    reg [7:0] rom [0:15];
    reg [3:0] crc [0:15];
    
    reg [3:0] addr_stage1;
    reg [7:0] rom_data_stage1;
    reg [3:0] crc_data_stage1;
    reg parity_stage1;
    
    reg [7:0] rom_data_stage2;
    reg [3:0] crc_data_stage2;
    reg parity_stage2;
    
    reg [7:0] rom_data_stage3;
    reg [3:0] crc_data_stage3;
    reg parity_stage3;
    reg crc_error_stage3;

    initial begin
        rom[0] = 8'h99; 
        crc[0] = 4'hF;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
        end else begin
            addr_stage1 <= addr;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage1 <= 8'h0;
            crc_data_stage1 <= 4'h0;
            parity_stage1 <= 1'b0;
        end else begin
            rom_data_stage1 <= rom[addr_stage1];
            crc_data_stage1 <= crc[addr_stage1];
            parity_stage1 <= ^rom[addr_stage1];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage2 <= 8'h0;
            crc_data_stage2 <= 4'h0;
            parity_stage2 <= 1'b0;
        end else begin
            rom_data_stage2 <= rom_data_stage1;
            crc_data_stage2 <= crc_data_stage1;
            parity_stage2 <= parity_stage1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage3 <= 8'h0;
            crc_data_stage3 <= 4'h0;
            parity_stage3 <= 1'b0;
            crc_error_stage3 <= 1'b0;
        end else begin
            rom_data_stage3 <= rom_data_stage2;
            crc_data_stage3 <= crc_data_stage2;
            parity_stage3 <= parity_stage2;
            crc_error_stage3 <= parity_stage2 != crc_data_stage2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'h0;
            crc_error <= 1'b0;
        end else begin
            data <= rom_data_stage3;
            crc_error <= crc_error_stage3;
        end
    end

endmodule