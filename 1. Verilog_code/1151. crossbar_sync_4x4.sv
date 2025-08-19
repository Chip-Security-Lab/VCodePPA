module crossbar_sync_4x4 (
    input wire clk, rst_n,
    input wire [7:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output reg [7:0] out0, out1, out2, out3
);
    // Synchronous crossbar with registered outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {out0, out1, out2, out3} <= 32'b0;
        end else begin
            out0 <= (sel0 == 2'b00) ? in0 : (sel0 == 2'b01) ? in1 : 
                   (sel0 == 2'b10) ? in2 : in3;
            out1 <= (sel1 == 2'b00) ? in0 : (sel1 == 2'b01) ? in1 : 
                   (sel1 == 2'b10) ? in2 : in3;
            out2 <= (sel2 == 2'b00) ? in0 : (sel2 == 2'b01) ? in1 : 
                   (sel2 == 2'b10) ? in2 : in3;
            out3 <= (sel3 == 2'b00) ? in0 : (sel3 == 2'b01) ? in1 : 
                   (sel3 == 2'b10) ? in2 : in3;
        end
    end
endmodule