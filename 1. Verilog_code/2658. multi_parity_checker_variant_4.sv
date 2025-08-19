//SystemVerilog
module multi_parity_checker (
    input [1:0] mode,
    input [7:0] data,
    output reg [1:0] parity
);

wire even_p = ~^data;
wire odd_p = ^data;

always @(*) begin
    if (mode[0]) begin
        parity = {even_p, 1'b0};
    end else begin
        if (mode[1]) begin
            if (mode[0]) begin
                parity = {mode[1] & ~odd_p, mode[1]};
            end else begin
                parity = {mode[1] & odd_p, mode[1]};
            end
        end else begin
            parity = {1'b0, mode[1]};
        end
    end
end

endmodule