//SystemVerilog
module hybrid_rom (
    input clk,
    input valid,
    input [3:0] addr,
    input [7:0] din,
    output reg ready,
    output reg [7:0] data
);
    reg [7:0] rom [0:7];
    reg [7:0] ram [8:15];
    reg [7:0] data_reg;
    reg valid_reg;
    reg [1:0] state;
    
    parameter IDLE = 2'b00;
    parameter READ = 2'b01;
    parameter WRITE = 2'b10;
    
    initial begin
        rom[0] = 8'hEE; rom[1] = 8'hFF;
        state = IDLE;
        ready = 1'b1;
        valid_reg = 1'b0;
    end

    always @(posedge clk) begin
        if (state == IDLE && valid && addr < 8) begin
            valid_reg <= 1'b1;
            data_reg <= rom[addr];
            state <= READ;
        end
        else if (state == IDLE && valid && addr >= 8) begin
            valid_reg <= 1'b1;
            state <= WRITE;
        end
        else if (state == READ) begin
            data <= data_reg;
            valid_reg <= 1'b0;
            state <= IDLE;
        end
        else if (state == WRITE && valid) begin
            ram[addr] <= din;
            data_reg <= din;
            data <= data_reg;
            valid_reg <= 1'b0;
            state <= IDLE;
        end
        else if (state == WRITE) begin
            data <= data_reg;
            valid_reg <= 1'b0;
            state <= IDLE;
        end
    end
endmodule