module bcd_counter (
    input clock, clear_n,
    output reg [3:0] bcd,
    output reg carry
);
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            bcd <= 4'd0;
            carry <= 1'b0;
        end else begin
            if (bcd == 4'd9) begin
                bcd <= 4'd0;
                carry <= 1'b1;
            end else begin
                bcd <= bcd + 1'b1;
                carry <= 1'b0;
            end
        end
    end
endmodule