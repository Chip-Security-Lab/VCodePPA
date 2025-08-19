module byte_enable_reg(
    input clock, clear_n,
    input [31:0] data,
    input [3:0] byte_en,
    input load,
    output reg [31:0] q
);
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n)
            q <= 32'h0;
        else if (load) begin
            if (byte_en[0]) q[7:0] <= data[7:0];
            if (byte_en[1]) q[15:8] <= data[15:8];
            if (byte_en[2]) q[23:16] <= data[23:16];
            if (byte_en[3]) q[31:24] <= data[31:24];
        end
    end
endmodule