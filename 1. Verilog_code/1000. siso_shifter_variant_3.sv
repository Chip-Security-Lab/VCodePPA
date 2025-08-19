//SystemVerilog
module siso_shifter(
    input wire clock,
    input wire clear,
    input wire serial_data_in,
    output wire serial_data_out
);
    reg [2:0] shift_reg_internal;
    reg serial_data_out_reg;

    always @(posedge clock) begin
        if (clear) begin
            shift_reg_internal <= 3'b000;
            serial_data_out_reg <= 1'b0;
        end else begin
            shift_reg_internal <= {shift_reg_internal[1:0], serial_data_in};
            serial_data_out_reg <= shift_reg_internal[2];
        end
    end

    assign serial_data_out = serial_data_out_reg;
endmodule