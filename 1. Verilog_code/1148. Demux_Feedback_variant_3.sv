//SystemVerilog
module Demux_Feedback #(parameter DW=8) (
    input clk, 
    input [DW-1:0] data_in,
    input [1:0] sel,
    input [3:0] busy,
    output reg [3:0][DW-1:0] data_out
);
    // Direct usage of inputs for combinational logic
    wire [3:0] output_enable;
    wire [3:0][DW-1:0] next_data;
    
    // Combinational logic to determine which output to update
    assign output_enable[0] = (sel == 2'b00) && !busy[0];
    assign output_enable[1] = (sel == 2'b01) && !busy[1];
    assign output_enable[2] = (sel == 2'b10) && !busy[2];
    assign output_enable[3] = (sel == 2'b11) && !busy[3];
    
    // Prepare next data values based on enable signals
    assign next_data[0] = output_enable[0] ? data_in : data_out[0];
    assign next_data[1] = output_enable[1] ? data_in : data_out[1];
    assign next_data[2] = output_enable[2] ? data_in : data_out[2];
    assign next_data[3] = output_enable[3] ? data_in : data_out[3];
    
    // Register outputs directly after combinational logic
    always @(posedge clk) begin
        data_out[0] <= next_data[0];
        data_out[1] <= next_data[1];
        data_out[2] <= next_data[2];
        data_out[3] <= next_data[3];
    end
endmodule