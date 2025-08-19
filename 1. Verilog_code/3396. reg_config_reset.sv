module reg_config_reset(
    input wire clk,
    input wire [7:0] config_data,
    input wire config_valid,
    input wire reset_trigger,
    output reg [7:0] reset_out
);
    reg [7:0] config_reg;
    always @(posedge clk) begin
        if (config_valid)
            config_reg <= config_data;
        reset_out <= reset_trigger ? config_reg : 8'h0;
    end
endmodule