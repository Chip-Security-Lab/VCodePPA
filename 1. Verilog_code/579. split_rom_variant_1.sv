//SystemVerilog
module rom_8bit (
    input clk,
    input [3:0] addr,
    input valid,
    output reg ready,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    
    initial begin
        rom[0] = 8'h12;
        rom[1] = 8'h34;
        ready = 1'b0;
    end
    
    always @(posedge clk) begin
        ready <= !valid;
        if (valid && ready) begin
            data <= rom[addr];
        end
    end
endmodule

module rom_8bit_high (
    input clk,
    input [3:0] addr,
    input valid,
    output reg ready,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    
    initial begin
        rom[0] = 8'hAB;
        rom[1] = 8'hCD;
        ready = 1'b0;
    end
    
    always @(posedge clk) begin
        ready <= !valid;
        if (valid && ready) begin
            data <= rom[addr];
        end
    end
endmodule

module split_rom (
    input clk,
    input [3:0] addr,
    input valid,
    output reg ready,
    output reg [15:0] data
);
    wire [7:0] data_low;
    wire [7:0] data_high;
    wire ready_low;
    wire ready_high;
    
    rom_8bit rom_low (
        .clk(clk),
        .addr(addr),
        .valid(valid),
        .ready(ready_low),
        .data(data_low)
    );
    
    rom_8bit_high rom_high (
        .clk(clk),
        .addr(addr),
        .valid(valid),
        .ready(ready_high),
        .data(data_high)
    );
    
    always @(posedge clk) begin
        ready <= !valid;
        if (valid && ready_low && ready_high) begin
            data <= {data_high, data_low};
        end
    end
endmodule