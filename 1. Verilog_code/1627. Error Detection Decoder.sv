module error_detect_decoder (
    input [3:0] addr,
    output reg [7:0] select,
    output reg error
);
    always @(*) begin
        error = 1'b0;
        select = 8'h00;
        
        if (addr < 4'h8) begin
            select = (8'h01 << addr);
        end else begin
            error = 1'b1;
        end
    end
endmodule