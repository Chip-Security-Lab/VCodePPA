//SystemVerilog
module DelayLatch #(parameter DW=8, DEPTH=3) (
    input clk, en,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    wire [DW-1:0] stage_out [0:DEPTH];
    
    DelayStage #(.DW(DW)) input_stage (
        .clk(clk),
        .en(en),
        .din(din),
        .dout(stage_out[0])
    );

    genvar i;
    generate
        for(i=1; i<DEPTH; i=i+1) begin: mid_stages
            DelayStage #(.DW(DW)) mid_stage (
                .clk(clk),
                .en(en),
                .din(stage_out[i-1]),
                .dout(stage_out[i])
            );
        end
    endgenerate

    DelayStage #(.DW(DW)) output_stage (
        .clk(clk),
        .en(en),
        .din(stage_out[DEPTH-1]),
        .dout(dout)
    );

endmodule

module DelayStage #(parameter DW=8) (
    input clk, en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);

    // LUT-based subtraction table
    reg [DW-1:0] sub_lut [0:255];
    reg [DW-1:0] lut_out;
    
    // Initialize LUT
    integer j;
    initial begin
        for(j=0; j<256; j=j+1) begin
            sub_lut[j] = j;
        end
    end

    always @(posedge clk) begin
        if(en) begin
            lut_out <= sub_lut[din];
            dout <= lut_out;
        end
    end

endmodule