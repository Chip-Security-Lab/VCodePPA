//SystemVerilog
module enabled_mux (
    input wire clock,             // System clock
    input wire enable,            // Enable signal
    input wire [1:0] select,      // Input selector
    input wire [7:0] in_a, in_b, in_c, in_d, // Data inputs
    output reg [7:0] data_out     // Registered output
);
    reg [7:0] mux_data;

    always @(*) begin
        case (select)
            2'b00: mux_data = in_a;
            2'b01: mux_data = in_b;
            2'b10: mux_data = in_c;
            default: mux_data = in_d;
        endcase
    end

    always @(posedge clock) begin
        if (enable) begin
            data_out <= mux_data;
        end
    end
endmodule