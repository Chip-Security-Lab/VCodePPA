//SystemVerilog
module crc_rom (
    input clk,
    input rst_n,
    input [3:0] addr,
    input req,
    output reg ack,
    output reg [7:0] data,
    output reg crc_error
);

    // ROM and CRC storage
    reg [7:0] rom [0:15];
    reg [3:0] crc [0:15];
    
    // Pipeline registers
    reg [3:0] addr_stage1;
    reg [7:0] rom_data_stage1;
    reg [3:0] crc_data_stage1;
    reg req_stage1;
    
    reg [7:0] rom_data_stage2;
    reg [3:0] crc_data_stage2;
    reg req_stage2;
    
    reg [7:0] rom_data_stage3;
    reg [3:0] crc_data_stage3;
    reg req_stage3;

    initial begin
        rom[0] = 8'h99; crc[0] = 4'hF;
    end

    // Stage 1: Address and ROM/CRC read
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'h0;
            rom_data_stage1 <= 8'h0;
            crc_data_stage1 <= 4'h0;
            req_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            rom_data_stage1 <= rom[addr];
            crc_data_stage1 <= crc[addr];
            req_stage1 <= req;
        end
    end

    // Stage 2: Data propagation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage2 <= 8'h0;
            crc_data_stage2 <= 4'h0;
            req_stage2 <= 1'b0;
        end else begin
            rom_data_stage2 <= rom_data_stage1;
            crc_data_stage2 <= crc_data_stage1;
            req_stage2 <= req_stage1;
        end
    end

    // Stage 3: CRC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rom_data_stage3 <= 8'h0;
            crc_data_stage3 <= 4'h0;
            req_stage3 <= 1'b0;
        end else begin
            rom_data_stage3 <= rom_data_stage2;
            crc_data_stage3 <= crc_data_stage2;
            req_stage3 <= req_stage2;
        end
    end

    // Stage 4: Output generation with flattened control flow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 8'h0;
            crc_error <= 1'b0;
            ack <= 1'b0;
        end else if (req_stage3) begin
            data <= rom_data_stage3;
            crc_error <= (^rom_data_stage3) != crc_data_stage3;
            ack <= 1'b1;
        end else begin
            data <= rom_data_stage3;
            crc_error <= 1'b0;
            ack <= 1'b0;
        end
    end

endmodule