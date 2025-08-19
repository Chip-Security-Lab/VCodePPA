//SystemVerilog
module nonlinear_quant #(parameter IN_W=8, OUT_W=4, LUT_SIZE=16) (
    input clk, 
    input [IN_W-1:0] data_in,
    output reg [OUT_W-1:0] quant_out
);
    reg [OUT_W-1:0] lut [0:LUT_SIZE-1];
    reg [3:0] state;
    reg [4:0] i;
    
    localparam IDLE = 4'd0;
    localparam INIT = 4'd1;
    localparam CALC = 4'd2;
    localparam DONE = 4'd3;
    
    always @(posedge clk) begin
        case(state)
            IDLE: begin
                i <= 0;
                state <= INIT;
            end
            
            INIT: begin
                if (i < LUT_SIZE) begin
                    state <= CALC;
                end else begin
                    state <= DONE;
                end
            end
            
            CALC: begin
                lut[i] <= ((i*i) >> (IN_W - OUT_W));
                i <= i + 1;
                state <= INIT;
            end
            
            DONE: begin
                quant_out <= lut[data_in[IN_W-1:IN_W-$clog2(LUT_SIZE)]];
            end
        endcase
    end
endmodule