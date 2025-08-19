module error_injection_crc(
    input wire clk,
    input wire rst,
    input wire [7:0] data,
    input wire data_valid,
    input wire inject_error,
    input wire [2:0] error_bit,
    output reg [7:0] crc_out
);
    parameter [7:0] POLY = 8'h07;
    reg [7:0] modified_data;
    always @(*) begin
        modified_data = data;
        if (inject_error) modified_data[error_bit] = ~data[error_bit];
    end
    always @(posedge clk) begin
        if (rst) crc_out <= 8'h00;
        else if (data_valid) begin
            crc_out <= {crc_out[6:0], 1'b0} ^ 
                      ((crc_out[7] ^ modified_data[0]) ? POLY : 8'h00);
        end
    end
endmodule