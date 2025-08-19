module enabled_mux (
    input wire clock,             // System clock
    input wire enable,            // Enable signal
    input wire [1:0] select,      // Input selector
    input wire [7:0] in_a, in_b, in_c, in_d, // Data inputs
    output reg [7:0] data_out     // Registered output
);
    always @(posedge clock) begin
        if (enable) begin
            case(select)
                2'b00: data_out <= in_a;
                2'b01: data_out <= in_b;
                2'b10: data_out <= in_c;
                2'b11: data_out <= in_d;
            endcase
        end
    end
endmodule