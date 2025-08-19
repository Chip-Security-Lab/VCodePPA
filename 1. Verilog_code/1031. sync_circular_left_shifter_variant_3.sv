//SystemVerilog
module sync_circular_left_shifter #(parameter WIDTH = 8) (
    input  wire                     clk,
    input  wire [2:0]               shift_amt,
    input  wire [WIDTH-1:0]         data_in,
    output reg  [WIDTH-1:0]         data_out
);

    reg  [2:0]                      shift_amt_reg;
    reg  [WIDTH-1:0]                data_in_reg;

    reg  [WIDTH-1:0]                shift1, shift2, shift3, shift4;
    reg  [WIDTH-1:0]                mux_01, mux_23, mux_0123, mux_final;

    always @(posedge clk) begin
        // Register inputs
        data_in_reg   <= data_in;
        shift_amt_reg <= shift_amt;

        // Compute shifted versions
        shift1 <= {data_in_reg[WIDTH-2:0], data_in_reg[WIDTH-1]};
        shift2 <= {data_in_reg[WIDTH-3:0], data_in_reg[WIDTH-1:WIDTH-2]};
        shift3 <= {data_in_reg[WIDTH-4:0], data_in_reg[WIDTH-1:WIDTH-3]};
        shift4 <= {data_in_reg[WIDTH-5:0], data_in_reg[WIDTH-1:WIDTH-4]};

        // Mux selection
        mux_01   <= (shift_amt_reg == 3'd1) ? shift1 : data_in_reg;
        mux_23   <= (shift_amt_reg == 3'd2) ? shift2 :
                    (shift_amt_reg == 3'd3) ? shift3 : data_in_reg;
        mux_0123 <= (shift_amt_reg[2] == 1'b0) ? mux_01 : mux_23;
        mux_final <= (shift_amt_reg == 3'd4) ? shift4 : mux_0123;

        // Output register
        data_out <= mux_final;
    end

endmodule