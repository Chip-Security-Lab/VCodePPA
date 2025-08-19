module wave12_glitch #(
    parameter WIDTH = 8,
    parameter GLITCH_PERIOD = 20
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    reg [WIDTH-1:0] main_cnt;
    reg glitch;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            main_cnt <= 0;
            glitch   <= 0;
        end else begin
            main_cnt <= main_cnt + 1;
            if(main_cnt == GLITCH_PERIOD) glitch <= ~glitch;
        end
    end
    assign wave_out = glitch ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
endmodule
