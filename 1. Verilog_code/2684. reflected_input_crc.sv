module reflected_input_crc(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h8005;
    wire [7:0] reflected_data;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: reflect
            assign reflected_data[i] = data_in[7-i];
        end
    endgenerate
    always @(posedge clk) begin
        if (reset) crc_out <= 16'hFFFF;
        else if (data_valid) begin
            crc_out <= {crc_out[14:0], 1'b0} ^ 
                      ((crc_out[15] ^ reflected_data[0]) ? POLY : 16'h0000);
        end
    end
endmodule