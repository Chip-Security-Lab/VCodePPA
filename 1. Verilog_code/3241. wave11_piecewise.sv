module wave11_piecewise #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    reg [3:0] state;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state    <= 0;
            wave_out <= 8'd0;
        end else begin
            case(state)
                4'd0 : wave_out <= 8'd10;
                4'd1 : wave_out <= 8'd50;
                4'd2 : wave_out <= 8'd100;
                4'd3 : wave_out <= 8'd150;
                default: wave_out <= 8'd200;
            endcase
            if(state < 4'd4) state <= state + 1;
            else             state <= 0;
        end
    end
endmodule
