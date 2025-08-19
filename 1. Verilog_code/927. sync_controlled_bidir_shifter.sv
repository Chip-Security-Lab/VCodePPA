module sync_controlled_bidir_shifter (
    input                  clock,
    input                  resetn,
    input      [31:0]      data_in,
    input      [4:0]       shift_amount,
    input      [1:0]       mode,  // 00:left logical, 01:right logical
                                  // 10:left rotate, 11:right rotate
    output reg [31:0]      data_out
);
    // Temporary variables
    reg [31:0] shift_result;
    
    // Shift operation based on mode
    always @(*) begin
        case(mode)
            2'b00: shift_result = data_in << shift_amount;
            2'b01: shift_result = data_in >> shift_amount;
            2'b10: shift_result = {data_in, data_in} >> (32 - shift_amount);
            2'b11: shift_result = {data_in, data_in} >> shift_amount;
        endcase
    end
    
    // Register output
    always @(posedge clock or negedge resetn) begin
        if (!resetn)
            data_out <= 32'h0;
        else
            data_out <= shift_result;
    end
endmodule