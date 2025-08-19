//SystemVerilog
`timescale 1ns/1ps
module sync_circular_left_shifter #(parameter WIDTH = 8) (
    input  wire                  clk,
    input  wire [2:0]            shift_amt,
    input  wire [WIDTH-1:0]      data_in,
    output reg  [WIDTH-1:0]      data_out
);

    // Pipeline stage 1: register inputs
    reg [2:0]              shift_amt_pipe1;
    reg [WIDTH-1:0]        data_in_pipe1;

    // Pipeline stage 2: partial rotate result
    reg [WIDTH-1:0]        rotate_result_pipe2;

    // Pipeline stage 1: Register input data and shift amount
    always @(posedge clk) begin
        shift_amt_pipe1   <= shift_amt;
        data_in_pipe1     <= data_in;
    end

    // Pipeline stage 2: Compute rotation result
    always @(posedge clk) begin
        case(shift_amt_pipe1)
            3'd1: rotate_result_pipe2 <= {data_in_pipe1[WIDTH-2:0], data_in_pipe1[WIDTH-1]};
            3'd2: rotate_result_pipe2 <= {data_in_pipe1[WIDTH-3:0], data_in_pipe1[WIDTH-1:WIDTH-2]};
            3'd3: rotate_result_pipe2 <= {data_in_pipe1[WIDTH-4:0], data_in_pipe1[WIDTH-1:WIDTH-3]};
            3'd4: rotate_result_pipe2 <= {data_in_pipe1[WIDTH-5:0], data_in_pipe1[WIDTH-1:WIDTH-4]};
            default: rotate_result_pipe2 <= data_in_pipe1;
        endcase
    end

    // Pipeline stage 3: Output register
    always @(posedge clk) begin
        data_out <= rotate_result_pipe2;
    end

endmodule