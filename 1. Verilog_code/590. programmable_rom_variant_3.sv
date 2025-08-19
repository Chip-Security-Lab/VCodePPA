//SystemVerilog
module programmable_rom (
    input clk,
    input prog_en,
    input [3:0] addr,
    input [7:0] din,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [15:0] programmed;

    always @(posedge clk) begin
        if (prog_en) begin
            if (!programmed[addr]) begin
                rom[addr] <= din;
                programmed[addr] <= 1'b1;
            end
        end
        data <= rom[addr];
    end
endmodule