//SystemVerilog
module crc8_gen (
    input        clk,
    input        rst_n,
    input  [7:0] data_in,
    output reg [7:0] crc_out
);
    reg [7:0] crc_next;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'b0;
        end else begin
            crc_next = crc_out ^ data_in;
            if (crc_next[7] == 1'b1) begin
                crc_out <= {crc_next[6:0], 1'b0} ^ 8'h07;
            end else begin
                crc_out <= {crc_next[6:0], 1'b0};
            end
        end
    end
endmodule