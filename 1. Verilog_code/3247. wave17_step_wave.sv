module wave17_step_wave #(
    parameter WIDTH = 8,
    parameter STEP_COUNT = 4
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    reg [$clog2(STEP_COUNT)-1:0] state;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state    <= 0;
            wave_out <= 0;
        end else begin
            case(state)
                0: wave_out <= 8'd32;
                1: wave_out <= 8'd64;
                2: wave_out <= 8'd128;
                3: wave_out <= 8'd200;
            endcase
            state <= state + 1;
        end
    end
endmodule
