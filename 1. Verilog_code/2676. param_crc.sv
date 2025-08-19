module param_crc #(
    parameter WIDTH = 16,
    parameter POLY = 16'h1021,
    parameter INIT = 16'hFFFF,
    parameter REF_IN = 0,
    parameter REF_OUT = 0,
    parameter XOR_OUT = 16'h0000
)(
    input wire clock,
    input wire reset_n,
    input wire [7:0] data,
    input wire data_valid,
    output wire [WIDTH-1:0] crc_out
);
    reg [WIDTH-1:0] crc_reg;
    wire [7:0] data_in = REF_IN ? {<<{data}} : data;
    wire feedback = crc_reg[WIDTH-1] ^ data_in[7];
    assign crc_out = REF_OUT ? {<<{crc_reg}} ^ XOR_OUT : crc_reg ^ XOR_OUT;
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) crc_reg <= INIT;
        else if (data_valid) crc_reg <= {crc_reg[WIDTH-2:0], 1'b0} ^ 
                                       (feedback ? POLY : 0);
    end
endmodule