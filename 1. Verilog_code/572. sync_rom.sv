module sync_rom (
    input clk,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34; rom[2] = 8'h56; rom[3] = 8'h78;
        rom[4] = 8'h9A; rom[5] = 8'hBC; rom[6] = 8'hDE; rom[7] = 8'hF0;
    end

    always @(posedge clk) begin
        data <= rom[addr];  
    end
endmodule
