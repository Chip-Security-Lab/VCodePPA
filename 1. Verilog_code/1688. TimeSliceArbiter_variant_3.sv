//SystemVerilog
module TimeSliceArbiter #(parameter SLICE_WIDTH=8) (
    input clk, rst,
    input [3:0] req,
    output [3:0] grant
);

    wire [1:0] slice_select;
    wire [3:0] grant_int;
    wire [3:0] slice_mask;

    Counter #(.WIDTH(SLICE_WIDTH)) counter_inst (
        .clk(clk),
        .rst(rst),
        .count(slice_select)
    );

    // Pre-compute slice masks
    assign slice_mask = 4'b0001 << slice_select;

    // Simplified grant logic with pre-computed mask
    assign grant_int = req & slice_mask;
    assign grant = grant_int;

endmodule

module Counter #(parameter WIDTH=8) (
    input clk, rst,
    output reg [1:0] count
);
    reg [WIDTH-1:0] counter;
    wire counter_reset;
    
    // Pre-compute reset condition
    assign counter_reset = rst || (counter == 4);
    
    always @(posedge clk) begin
        if (counter_reset)
            counter <= 0;
        else
            counter <= counter + 1;
    end
    
    assign count = counter[1:0];
endmodule