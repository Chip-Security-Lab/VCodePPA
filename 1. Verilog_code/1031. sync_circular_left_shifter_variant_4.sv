//SystemVerilog
module sync_circular_left_shifter #(parameter WIDTH = 8) (
    input clk,
    input [2:0] shift_amt,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    // High fanout signal buffer registers
    reg [2:0] shift_amt_buf;
    reg [WIDTH-1:0] data_in_buf;

    // Lookup table for 3-bit subtraction (WIDTH-amount)
    reg [2:0] sub_lut [0:7];
    integer lut_idx;

    // Buffer for sub_lut output
    reg [2:0] rot_amt;

    // Buffer for index variable 'i'
    reg [2:0] index_buf;

    // LUT Initialization
    initial begin : LUT_INIT
        for (lut_idx = 0; lut_idx < 8; lut_idx = lut_idx + 1)
            sub_lut[lut_idx] = (lut_idx > WIDTH) ? 3'd0 : (WIDTH[2:0] + (~lut_idx + 1'b1)) & 3'b111;
    end

    // Merged always block for all synchronous logic
    always @(posedge clk) begin
        // Buffer shift_amt and data_in to reduce fanout at clk edge
        shift_amt_buf <= shift_amt;
        data_in_buf  <= data_in;

        // Buffer index for LUT access
        index_buf <= shift_amt_buf;

        // Buffer LUT output (rot_amt)
        rot_amt <= sub_lut[index_buf];

        // Synchronous left circular shift with buffered signals
        case (shift_amt_buf)
            3'd1: data_out <= {data_in_buf[WIDTH-2:0], data_in_buf[WIDTH-1]};
            3'd2: data_out <= {data_in_buf[WIDTH-3:0], data_in_buf[WIDTH-1:WIDTH-2]};
            3'd3: data_out <= {data_in_buf[WIDTH-4:0], data_in_buf[WIDTH-1:WIDTH-3]};
            3'd4: data_out <= {data_in_buf[WIDTH-5:0], data_in_buf[WIDTH-1:WIDTH-4]};
            default: data_out <= data_in_buf;
        endcase
    end

endmodule