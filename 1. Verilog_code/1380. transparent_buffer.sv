module transparent_buffer (
    input wire [7:0] data_in,
    input wire enable,
    output reg [7:0] data_out
);
    always @* begin
        if (enable)
            data_out = data_in;
    end
endmodule