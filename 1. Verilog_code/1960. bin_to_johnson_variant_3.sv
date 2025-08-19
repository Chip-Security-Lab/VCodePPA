//SystemVerilog
module bin_to_johnson #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] bin_in,
    output reg  [2*WIDTH-1:0] johnson_out
);
    reg [WIDTH:0] pos; // WIDTH+1 bits to cover 0..2*WIDTH-1
    reg [2*WIDTH-1:0] mask;
    integer k;

    always @(*) begin
        pos = bin_in % (2*WIDTH);

        case (pos)
            0: begin
                mask = {2*WIDTH{1'b0}};
                johnson_out = mask;
            end
            2*WIDTH: begin
                mask = {2*WIDTH{1'b1}};
                johnson_out = mask;
            end
            default: begin
                mask = ({2*WIDTH{1'b1}} >> (2*WIDTH - pos));
                if (pos > WIDTH)
                    johnson_out = ~mask;
                else
                    johnson_out = mask;
            end
        endcase
    end
endmodule