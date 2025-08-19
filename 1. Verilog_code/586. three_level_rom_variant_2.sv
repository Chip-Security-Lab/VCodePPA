//SystemVerilog
module three_level_rom (
    input clk,
    input [3:0] addr,
    input valid,
    output reg ready,
    output reg [7:0] data
);
    reg [7:0] cache [0:3]; // 小型缓存
    reg [7:0] rom [0:15];  // 真实ROM存储
    reg valid_reg;
    reg [3:0] addr_reg;
    reg data_valid;

    initial begin
        rom[0] = 8'h77; rom[1] = 8'h88;
    end

    always @(posedge clk) begin
        valid_reg <= valid;
        addr_reg <= addr;
        
        if (valid_reg && ready) begin
            cache[addr_reg[1:0]] <= rom[addr_reg]; // 模拟缓存层
            data <= cache[addr_reg[1:0]];
            data_valid <= 1'b1;
        end else if (!valid_reg) begin
            data_valid <= 1'b0;
        end
        
        // Ready signal generation
        if (valid_reg && !data_valid) begin
            ready <= 1'b1;
        end else if (valid_reg && data_valid) begin
            ready <= 1'b0;
        end else if (!valid_reg) begin
            ready <= 1'b1;
        end
    end
endmodule