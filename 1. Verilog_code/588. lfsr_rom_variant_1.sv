//SystemVerilog
module lfsr_rom (
    input clk,
    input rst,
    output reg [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [3:0] addr_stage1;
    reg [3:0] addr_stage2;
    reg [3:0] addr_stage3;
    reg [7:0] data_stage1;
    reg [7:0] data_stage2;

    initial begin
        rom[0] = 8'hA0; rom[1] = 8'hB1;
    end

    // Stage 1: LFSR calculation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage1 <= 4'b1010;
        end else begin
            addr_stage1 <= {addr[2:0], addr[3] ^ addr[2]};
        end
    end

    // Stage 2: ROM address registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr_stage2 <= 4'b1010;
        end else begin
            addr_stage2 <= addr_stage1;
        end
    end

    // Stage 3: ROM data read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 8'h00;
            addr_stage3 <= 4'b1010;
        end else begin
            data_stage1 <= rom[addr_stage2];
            addr_stage3 <= addr_stage2;
        end
    end

    // Stage 4: Data pipeline
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage2 <= 8'h00;
        end else begin
            data_stage2 <= data_stage1;
        end
    end

    // Stage 5: Output registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 8'h00;
            addr <= 4'b1010;
        end else begin
            data <= data_stage2;
            addr <= addr_stage3;
        end
    end

endmodule