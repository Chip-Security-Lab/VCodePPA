//SystemVerilog
module decoder_multi_protocol (
    input clk,
    input rst_n,
    input valid,
    output reg ready,
    input [1:0] mode,
    input [15:0] addr,
    output reg [7:0] select
);

reg [7:0] select_reg;
reg valid_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        select_reg <= 8'h00;
        valid_reg <= 1'b0;
        ready <= 1'b1;
    end else begin
        if (valid && ready) begin
            case(mode)
                2'b00: select_reg <= (addr[15:12] == 4'h1) ? 8'h01 : 8'h00;  // I2C模式
                2'b01: select_reg <= (addr[7:5] == 3'b101) ? 8'h02 : 8'h00;  // SPI模式
                2'b10: select_reg <= (addr[11:8] > 4'h7) ? 8'h04 : 8'h00;    // AXI模式
                default: select_reg <= 8'h00;
            endcase
            valid_reg <= 1'b1;
            ready <= 1'b0;
        end else if (!valid) begin
            ready <= 1'b1;
            valid_reg <= 1'b0;
        end
    end
end

assign select = valid_reg ? select_reg : 8'h00;

endmodule