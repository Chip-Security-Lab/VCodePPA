module bidir_decoder (
    input decode_mode,
    input [2:0] addr_in,
    input [7:0] onehot_in,
    output reg [2:0] addr_out,
    output reg [7:0] onehot_out,
    output reg error
);
    integer i;
    always @(*) begin
        error = 1'b0;
        addr_out = 3'b000;
        onehot_out = 8'b00000000;
        
        if (decode_mode) begin
            // Decoder mode
            onehot_out = (8'b00000001 << addr_in);
        end else begin
            // Encoder mode
            error = 1'b1;
            for (i = 0; i < 8; i = i + 1)
                if (onehot_in[i]) begin
                    addr_out = i[2:0];
                    error = ~(onehot_in == (8'b1 << i));
                end
        end
    end
endmodule