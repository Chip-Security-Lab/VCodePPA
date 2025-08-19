module StageEnabledShifter #(parameter WIDTH=8) (
    input clk, 
    input [WIDTH-1:0] stage_en,
    input serial_in,
    output reg [WIDTH-1:0] parallel_out
);
genvar i;
generate
    for(i=0; i<WIDTH; i=i+1) begin : stage_logic
        always @(posedge clk) begin
            if (stage_en[i]) begin
                if(i==0) parallel_out[i] <= serial_in;
                else parallel_out[i] <= parallel_out[i-1];
            end
        end
    end
endgenerate
endmodule