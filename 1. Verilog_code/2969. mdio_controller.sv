module mdio_controller #(
    parameter PHY_ADDR = 5'h01,
    parameter CLK_DIV = 64
)(
    input clk,
    input rst,
    input [4:0] reg_addr,
    input [15:0] data_in,
    input write_en,
    output reg [15:0] data_out,
    output reg mdio_done,
    inout mdio,
    output mdc
);
    reg [9:0] clk_counter;
    reg [3:0] bit_count;
    reg [31:0] shift_reg;
    reg mdio_oe;
    reg mdio_out;

    assign mdc = clk_counter[CLK_DIV/2];
    assign mdio = mdio_oe ? mdio_out : 1'bz;

    always @(posedge clk) begin
        if (rst) begin
            clk_counter <= 0;
            bit_count <= 0;
            mdio_oe <= 0;
            mdio_done <= 0;
        end else begin
            clk_counter <= clk_counter + 1;
            
            if (clk_counter == CLK_DIV-1) begin
                if (bit_count < 32) begin
                    shift_reg <= {shift_reg[30:0], mdio};
                    bit_count <= bit_count + 1;
                end else begin
                    data_out <= shift_reg[15:0];
                    mdio_done <= 1;
                end
            end

            if (write_en && !mdio_done) begin
                mdio_oe <= 1;
                shift_reg <= {2'b01, PHY_ADDR, reg_addr, 2'b10, data_in};
                mdio_out <= shift_reg[31];
            end
        end
    end
endmodule
