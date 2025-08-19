//SystemVerilog
module siso_shifter(
    input wire clock,
    input wire clear,
    input wire serial_data_in,
    output wire serial_data_out
);
    reg [3:0] shift_reg_main;
    reg [3:0] shift_reg_buf1;
    reg [3:0] shift_reg_buf2;

    wire [2:0] shifter_comb_buf1;
    wire [2:0] shifter_comb_buf2;

    // Main shift register logic
    always @(posedge clock) begin
        if (clear)
            shift_reg_main <= 4'b0000;
        else
            shift_reg_main <= {shift_reg_main[2:0], serial_data_in};
    end

    // First stage buffer for shift_reg
    always @(posedge clock) begin
        shift_reg_buf1 <= shift_reg_main;
    end

    // Second stage buffer for shift_reg
    always @(posedge clock) begin
        shift_reg_buf2 <= shift_reg_buf1;
    end

    // Buffered combinational logic using buffer stages
    assign shifter_comb_buf1 = {shift_reg_buf1[1:0], serial_data_in};
    assign shifter_comb_buf2 = {shift_reg_buf2[1:0], serial_data_in};

    // Buffered output
    assign serial_data_out = shift_reg_buf2[3];
endmodule