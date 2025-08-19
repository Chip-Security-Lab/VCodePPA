//SystemVerilog
module priority_rom (
    input clk,
    input [3:0] addr_high,
    input [3:0] addr_low, 
    input high_priority,
    output reg [7:0] data
);

    reg [7:0] rom [0:15];
    reg [3:0] addr_sel;
    wire [7:0] rom_data;

    initial begin
        rom[0] = 8'h55; rom[1] = 8'h66;
    end

    always @(*) begin
        if (high_priority) begin
            addr_sel = addr_high;
        end else begin
            addr_sel = addr_low;
        end
    end

    assign rom_data = rom[addr_sel];

    always @(posedge clk) begin
        data <= rom_data;
    end

endmodule