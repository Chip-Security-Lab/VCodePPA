module bytewise_crc16(
    input wire clk_i,
    input wire rst_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    output wire [15:0] crc_o
);
    localparam POLYNOMIAL = 16'h8005;
    reg [15:0] lfsr_q, lfsr_c;
    assign crc_o = lfsr_q;
    always @(*) begin
        lfsr_c = lfsr_q;
        if (data_valid_i) begin
            lfsr_c = {lfsr_q[7:0], 8'h00} ^ {8{lfsr_q[15]}} & POLYNOMIAL ^ {data_i};
        end
    end
    always @(posedge clk_i, posedge rst_i) begin
        if (rst_i) lfsr_q <= 16'hFFFF;
        else lfsr_q <= lfsr_c;
    end
endmodule