//SystemVerilog
module pipeline_mux(
    input clk,
    input resetn,
    input [15:0] in1, in2, in3, in4,
    input [1:0] sel,
    input valid,
    output reg ready,
    output reg [15:0] pipe_out
);
    reg [15:0] stage1;
    reg valid_stage1;
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {stage1, pipe_out} <= {32{1'b0}};
            valid_stage1 <= 1'b0;
            ready <= 1'b1;
        end else begin
            if (valid && ready) begin
                stage1 <= {in4, in3, in2, in1} >> (sel * 16);
                valid_stage1 <= 1'b1;
            end
            
            if (valid_stage1) begin
                pipe_out <= stage1;
                valid_stage1 <= 1'b0;
            end
            
            ready <= !valid_stage1;
        end
    end
endmodule