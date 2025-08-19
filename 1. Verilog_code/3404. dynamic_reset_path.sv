module dynamic_reset_path(
    input wire clk,
    input wire [1:0] path_select,
    input wire [3:0] reset_sources,
    output reg reset_out
);
    always @(posedge clk) begin
        case (path_select)
            2'b00: reset_out <= reset_sources[0];
            2'b01: reset_out <= reset_sources[1];
            2'b10: reset_out <= reset_sources[2];
            2'b11: reset_out <= reset_sources[3];
        endcase
    end
endmodule
