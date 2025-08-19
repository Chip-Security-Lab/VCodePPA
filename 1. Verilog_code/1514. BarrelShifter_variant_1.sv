//SystemVerilog
module BarrelShifter #(parameter SIZE=16, SHIFT_WIDTH=4) (
    input [SIZE-1:0] din,
    input [SHIFT_WIDTH-1:0] shift,
    input en, left,
    output reg [SIZE-1:0] dout
);

    wire [SIZE-1:0] stage [SHIFT_WIDTH:0];
    wire [SIZE-1:0] reversed_din;
    wire [SIZE-1:0] reversed_dout;
    
    // Reverse input for left shift
    genvar i;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : reverse_in
            assign reversed_din[i] = din[SIZE-1-i];
        end
    endgenerate
    
    // First stage
    assign stage[0] = left ? reversed_din : din;
    
    // Barrel shifter stages
    generate
        for (i = 0; i < SHIFT_WIDTH; i = i + 1) begin : shifter_stages
            assign stage[i+1] = shift[i] ? 
                {stage[i][SIZE-(1<<i)-1:0], {1<<i{1'b0}}} : 
                stage[i];
        end
    endgenerate
    
    // Reverse output for left shift
    generate
        for (i = 0; i < SIZE; i = i + 1) begin : reverse_out
            assign reversed_dout[i] = stage[SHIFT_WIDTH][SIZE-1-i];
        end
    endgenerate
    
    // Final output
    always @* begin
        if (en) begin
            dout = left ? reversed_dout : stage[SHIFT_WIDTH];
        end else begin
            dout = din;
        end
    end

endmodule