//SystemVerilog
module pipeline_rom (
    input clk,
    input valid,
    output reg ready,
    input [3:0] addr,
    output reg [7:0] data
);
    reg [7:0] rom [0:15];
    reg [3:0] addr_reg;
    reg [7:0] rom_data;
    reg [7:0] stage1, stage2;
    reg data_valid;

    initial begin
        rom[0] = 8'h12; rom[1] = 8'h34;
        ready = 1'b1;
        data_valid = 1'b0;
    end

    always @(posedge clk) begin
        if (valid && ready) begin
            addr_reg <= addr;
            ready <= 1'b0;
            data_valid <= 1'b0;
        end

        if (!ready) begin
            rom_data <= rom[addr_reg];
            stage1 <= rom_data;
            stage2 <= stage1;
            data <= stage2;
            data_valid <= 1'b1;
            ready <= 1'b1;
        end
    end
endmodule